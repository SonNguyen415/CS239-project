#!/bin/bash

# SSS (Spike, Stress, Soak) MongoDB YCSB Benchmark Script
# This script runs high-load performance tests on MongoDB

set -e  # Exit on error

echo "======================================"
echo "SSS MongoDB Benchmark Suite"
echo "Spike | Stress | Soak Tests"
echo "======================================"
echo ""

# Display all running pods
echo "Checking running pods..."
kubectl get pods
echo ""

# Find the YCSB pod (exclude mysql-ycsb pods)
echo "Finding YCSB interface pod..."
YCSB_POD=$(kubectl get pods | grep "ycsb-interface" | grep -v "mysql-ycsb" | awk '{print $1}' | head -n 1)

if [ -z "$YCSB_POD" ]; then
    echo "ERROR: Could not find YCSB interface pod"
    exit 1
fi

echo "Found YCSB pod: $YCSB_POD"
echo ""

# Find the MongoDB user-db pod
echo "Finding MongoDB user-db pod..."
MONGO_POD=$(kubectl get pods | grep "user-db" | grep -v "mysql" | awk '{print $1}' | head -n 1)

if [ -z "$MONGO_POD" ]; then
    echo "ERROR: Could not find MongoDB user-db pod"
    exit 1
fi

echo "Found MongoDB pod: $MONGO_POD"
echo ""

# MongoDB connection details
MONGO_URL="mongodb://user-db:27017/users"
COLLECTION="usertable"
YCSB_PATH="~/ycsb-0.17.0/bin/ycsb.sh"
WORKLOAD_PATH="~/ycsb-0.17.0/workloads"

# Function to run YCSB commands in the pod
run_ycsb_command() {
    local description="$1"
    local command="$2"
    
    echo "======================================"
    echo "$description"
    echo "======================================"
    kubectl exec -it "$YCSB_POD" -- bash -c "$command"
    echo ""
    echo "Completed: $description"
    echo ""
}

# Drop existing usertable collection
echo "======================================"
echo "Step 1: Dropping existing usertable collection..."
echo "======================================"
kubectl exec -it "$MONGO_POD" -- mongo users --eval "db.usertable.drop()"
echo ""
echo "Collection dropped successfully"
echo ""

# Load Phase with 1 million records
echo "======================================"
echo "Step 2: Loading 1,000,000 records..."
echo "======================================"
run_ycsb_command "LOAD PHASE - Loading 1M records" \
    "$YCSB_PATH load mongodb -s -P $WORKLOAD_PATH/workloadb -p recordcount=1000000 -p mongodb.url=\"$MONGO_URL\" -p mongodb.collection=$COLLECTION"

# Ask user which benchmark to run
echo "======================================"
echo "Step 3: Select Benchmark Test"
echo "======================================"
echo ""
echo "Available benchmarks:"
echo "  1) Spike Test   - High throughput burst (20k ops, 10k ops/sec, 1000 threads)"
echo "  2) Stress Test  - Sustained high load (1M ops, 2k ops/sec, 1000 threads)"
echo "  3) Soak Test    - Long duration stability (450k ops, 500 ops/sec, 50 threads)"
echo "  4) All Tests    - Run all three tests sequentially"
echo ""
read -p "Enter your choice (1-4): " choice

echo ""
echo "======================================"
echo "Running selected benchmark(s)..."
echo "======================================"
echo ""

case $choice in
    1)
        # Spike Test
        run_ycsb_command "SPIKE TEST - High throughput burst (20k ops, 10k ops/sec, 1000 threads)" \
            "$YCSB_PATH run mongodb -s -P $WORKLOAD_PATH/workloadb -p operationcount=20000 -p target=10000 -p threadcount=1000 -p mongodb.url=\"$MONGO_URL\" -p mongodb.collection=$COLLECTION | tee -a /results/ycsb_spike.txt"
        ;;
    2)
        # Stress Test
        run_ycsb_command "STRESS TEST - Sustained high load (1M ops, 2k ops/sec, 1000 threads)" \
            "$YCSB_PATH run mongodb -s -P $WORKLOAD_PATH/workloadb -p operationcount=1000000 -p target=2000 -p threadcount=1000 -p mongodb.url=\"$MONGO_URL\" -p mongodb.collection=$COLLECTION | tee -a /results/ycsb_stress.txt"
        ;;
    3)
        # Soak Test
        run_ycsb_command "SOAK TEST - Long duration stability (450k ops, 500 ops/sec, 50 threads)" \
            "$YCSB_PATH run mongodb -s -P $WORKLOAD_PATH/workloadb -p operationcount=450000 -p target=500 -p threadcount=50 -p mongodb.url=\"$MONGO_URL\" -p mongodb.collection=$COLLECTION | tee -a /results/ycsb_soak.txt"
        ;;
    4)
        # All Tests
        run_ycsb_command "SPIKE TEST - High throughput burst (20k ops, 10k ops/sec, 1000 threads)" \
            "$YCSB_PATH run mongodb -s -P $WORKLOAD_PATH/workloadb -p operationcount=20000 -p target=10000 -p threadcount=1000 -p mongodb.url=\"$MONGO_URL\" -p mongodb.collection=$COLLECTION | tee -a /results/ycsb_spike.txt"
        
        run_ycsb_command "STRESS TEST - Sustained high load (1M ops, 2k ops/sec, 1000 threads)" \
            "$YCSB_PATH run mongodb -s -P $WORKLOAD_PATH/workloadb -p operationcount=1000000 -p target=2000 -p threadcount=1000 -p mongodb.url=\"$MONGO_URL\" -p mongodb.collection=$COLLECTION | tee -a /results/ycsb_stress.txt"
        
        run_ycsb_command "SOAK TEST - Long duration stability (450k ops, 500 ops/sec, 50 threads)" \
            "$YCSB_PATH run mongodb -s -P $WORKLOAD_PATH/workloadb -p operationcount=450000 -p target=500 -p threadcount=50 -p mongodb.url=\"$MONGO_URL\" -p mongodb.collection=$COLLECTION | tee -a /results/ycsb_soak.txt"
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

echo "======================================"
echo "Benchmark(s) completed successfully!"
echo "Results saved to /results/ directory in pod: $YCSB_POD"
echo "======================================"
echo ""
echo "To retrieve results, use:"
echo "  kubectl cp $YCSB_POD:/results/ycsb_spike.txt ./ycsb_spike.txt"
echo "  kubectl cp $YCSB_POD:/results/ycsb_stress.txt ./ycsb_stress.txt"
echo "  kubectl cp $YCSB_POD:/results/ycsb_soak.txt ./ycsb_soak.txt"
