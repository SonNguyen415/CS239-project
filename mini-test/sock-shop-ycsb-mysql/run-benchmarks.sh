#!/bin/bash

echo "================================================"
echo "YCSB MySQL Benchmark Suite for Sock Shop Demo"
echo "================================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# MySQL connection details
MYSQL_HOST="sock-shop-mysql-db"
MYSQL_PORT="3306"
MYSQL_USER="sockshop"
MYSQL_PASSWORD="sockshop"
MYSQL_DB="sockshop"
TABLE_NAME="usertable"

# Function to run a workload
run_workload() {
    local workload=$1
    local workload_name=$2
    local description=$3
    
    echo -e "${BLUE}========================================${NC}"
    echo -e "${GREEN}Running Workload $workload_name${NC}"
    echo -e "${BLUE}Description: $description${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    # Load phase
    echo "Phase 1: Loading data into MySQL..."
    docker exec ycsb-mysql-benchmark go-ycsb load mysql \
        -P /workloads/workload${workload} \
        -p mysql.host="mysql" \
        -p mysql.port="3306" \
        -p mysql.user="sockshop" \
        -p mysql.password="sockshop" \
        -p mysql.db="sockshop" \
        > results/workload${workload}_load.txt 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Data loaded successfully${NC}"
    else
        echo -e "${YELLOW}✗ Load phase failed. Check results/workload${workload}_load.txt${NC}"
        return 1
    fi
    
    # Run phase
    echo "Phase 2: Running benchmark..."
    docker exec ycsb-mysql-benchmark go-ycsb run mysql \
        -P /workloads/workload${workload} \
        -p mysql.host="$MYSQL_HOST" \
        -p mysql.port="$MYSQL_PORT" \
        -p mysql.user="$MYSQL_USER" \
        -p mysql.password="$MYSQL_PASSWORD" \
        -p mysql.db="$MYSQL_DB" \
        > results/workload${workload}_run.txt 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Benchmark completed successfully${NC}"
        echo ""
        echo "Results summary:"
        # Extract key metrics from the output
        grep "Takes(s):" results/workload${workload}_run.txt | tail -5
    else
        echo -e "${YELLOW}✗ Run phase failed. Check results/workload${workload}_run.txt${NC}"
        return 1
    fi
    
    echo ""
    echo "Full results saved to: results/workload${workload}_run.txt"
    echo ""
}

# Check if Docker containers are running
if ! docker ps | grep -q "ycsb-mysql-benchmark"; then
    echo "Error: YCSB container is not running."
    echo "Please start the containers with: docker-compose up -d"
    exit 1
fi

if ! docker ps | grep -q "sock-shop-mysql-db"; then
    echo "Error: MySQL container is not running."
    echo "Please start the containers with: docker-compose up -d"
    exit 1
fi

# Create results directory
mkdir -p results

# Wait a bit for MySQL to be fully ready
echo "Waiting for MySQL to be ready..."
sleep 5

echo ""
echo -e "${GREEN}Starting benchmarks...${NC}"
echo ""

# Run each workload
run_workload "a" "A" "Update Heavy (50% reads, 50% updates) - Session/Shopping Cart"
sleep 5

run_workload "b" "B" "Read Heavy (95% reads, 5% updates) - Product Catalog Browsing"
sleep 5

run_workload "e" "E" "Short Ranges (95% scans, 5% inserts) - Analytics Queries"

echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}All MySQL benchmarks completed!${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo "Results are saved in the ./results/ directory:"
echo "  - workloada_load.txt & workloada_run.txt"
echo "  - workloadb_load.txt & workloadb_run.txt"
echo "  - workloade_load.txt & workloade_run.txt"
echo ""
echo "To view detailed results:"
echo "  cat results/workloada_run.txt"
echo "  cat results/workloadb_run.txt"
echo "  cat results/workloade_run.txt"
echo ""
echo "To compare with MongoDB results, check your previous results directory"