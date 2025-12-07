#!/bin/bash

# YCSB MongoDB Benchmarking Script
# This script automatically finds the YCSB pod and runs comprehensive benchmarks

set -e  # Exit on error

echo "======================================"
echo "YCSB MongoDB Benchmark Suite"
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

# Load Phase
echo "Starting YCSB benchmark sequence..."
echo ""

run_ycsb_command "LOAD PHASE - Loading 100,000 records" \
    "$YCSB_PATH load mongodb -s -P $WORKLOAD_PATH/workloada -p recordcount=100000 -p mongodb.url=\"$MONGO_URL\" -p mongodb.collection=$COLLECTION"

# Workload A - Update heavy workload (50% read, 50% update)
run_ycsb_command "WORKLOAD A - Update Heavy (50/50 read/update)" \
    "$YCSB_PATH run mongodb -s -P $WORKLOAD_PATH/workloada -p operationcount=1000 -p mongodb.url=\"$MONGO_URL\" -p mongodb.collection=$COLLECTION | tee -a /results/ycsb_output.txt"

# Workload B - Read mostly workload (95% read, 5% update)
run_ycsb_command "WORKLOAD B - Read Mostly (95/5 read/update)" \
    "$YCSB_PATH run mongodb -s -P $WORKLOAD_PATH/workloadb -p operationcount=1000 -p mongodb.url=\"$MONGO_URL\" -p mongodb.collection=$COLLECTION | tee -a /results/ycsb_output.txt"

# Workload E - Short ranges (95% scan, 5% insert)
run_ycsb_command "WORKLOAD E - Short Ranges (95/5 scan/insert)" \
    "$YCSB_PATH run mongodb -s -P $WORKLOAD_PATH/workloade -p operationcount=1000 -p mongodb.url=\"$MONGO_URL\" -p mongodb.collection=$COLLECTION | tee -a /results/ycsb_output.txt"

# Spike Test - High throughput burst
run_ycsb_command "SPIKE TEST - High throughput burst (10k ops/sec, 1000 threads)" \
    "$YCSB_PATH run mongodb -s -P $WORKLOAD_PATH/workloadb -p operationcount=20000 -p target=10000 -p threadcount=1000 -p mongodb.url=\"$MONGO_URL\" -p mongodb.collection=$COLLECTION | tee -a /results/ycsb_output.txt"

# Stress Test - Sustained high load
run_ycsb_command "STRESS TEST - Sustained high load (1M ops, 2k ops/sec, 1000 threads)" \
    "$YCSB_PATH run mongodb -s -P $WORKLOAD_PATH/workloadb -p operationcount=1000000 -p target=2000 -p threadcount=1000 -p mongodb.url=\"$MONGO_URL\" -p mongodb.collection=$COLLECTION | tee -a /results/ycsb_output.txt"

# Soak Test - Long duration stability test
run_ycsb_command "SOAK TEST - Long duration stability (450k ops, 500 ops/sec, 50 threads)" \
    "$YCSB_PATH run mongodb -s -P $WORKLOAD_PATH/workloadb -p operationcount=450000 -p target=500 -p threadcount=50 -p mongodb.url=\"$MONGO_URL\" -p mongodb.collection=$COLLECTION | tee -a /results/ycsb_output.txt"

echo "======================================"
echo "All benchmarks completed successfully!"
echo "Results saved to /results/ycsb_output.txt in pod: $YCSB_POD"
echo "======================================"
