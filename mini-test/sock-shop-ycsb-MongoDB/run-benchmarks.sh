#!/bin/bash

echo "================================================"
echo "YCSB Benchmark Suite for Sock Shop Demo"
echo "================================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# MongoDB connection details
MONGO_URL="mongodb://mongodb:27017/sockshop"
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
    echo "Phase 1: Loading data..."
    docker exec ycsb-mongodb-benchmark go-ycsb load mongodb \
        -P /workloads/workload${workload} \
        -p mongodb.url="$MONGO_URL" \
        -p mongodb.collection="$TABLE_NAME" \
        > results/workload${workload}_load.txt 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Data loaded successfully${NC}"
    else
        echo "✗ Load phase failed. Check results/workload${workload}_load.txt"
        return 1
    fi
    
    # Run phase
    echo "Phase 2: Running benchmark..."
    docker exec ycsb-mongodb-benchmark go-ycsb run mongodb \
        -P /workloads/workload${workload} \
        -p mongodb.url="$MONGO_URL" \
        -p mongodb.collection="$TABLE_NAME" \
        > results/workload${workload}_run.txt 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Benchmark completed successfully${NC}"
        echo ""
        echo "Results summary:"
        grep -E "Throughput|AverageLatency|95thPercentileLatency|99thPercentileLatency" results/workload${workload}_run.txt
    else
        echo "✗ Run phase failed. Check results/workload${workload}_run.txt"
        return 1
    fi
    
    echo ""
    echo "Full results saved to: results/workload${workload}_run.txt"
    echo ""
}

# Check if Docker containers are running
if ! docker ps | grep -q "ycsb-mongodb-benchmark"; then
    echo "Error: YCSB container is not running."
    echo "Please start the containers with: docker-compose up -d"
    exit 1
fi

# Create results directory
mkdir -p results

# Run each workload
run_workload "a" "A" "Update Heavy (50% reads, 50% updates) - Session/Shopping Cart"
sleep 5

run_workload "b" "B" "Read Heavy (95% reads, 5% updates) - Product Catalog Browsing"
sleep 5

run_workload "e" "E" "Short Ranges (95% scans, 5% inserts) - Analytics Queries"

echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}All benchmarks completed!${NC}"
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