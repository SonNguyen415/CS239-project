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

# Find the MongoDB user-db pod
echo "Finding MongoDB user-db pod..."
MONGO_POD=$(kubectl get pods | grep "user-db" | grep -v "mysql" | awk '{print $1}' | head -n 1)

if [ -z "$MONGO_POD" ]; then
    echo "ERROR: Could not find MongoDB user-db pod"
    exit 1
fi

echo "Found MongoDB pod: $MONGO_POD"
echo ""

# Drop existing usertable collection before loading
echo "======================================"
echo "Dropping existing usertable collection..."
echo "======================================"
kubectl exec -it "$MONGO_POD" -- mongo users --eval "db.usertable.drop()"
echo ""
echo "Collection dropped successfully"
echo ""

# Load Phase
echo "Starting YCSB benchmark sequence..."
echo ""

run_ycsb_command "LOAD PHASE - Loading 1,000 records" \
    "$YCSB_PATH load mongodb -s -P $WORKLOAD_PATH/workloada -p recordcount=1000 -p mongodb.url=\"$MONGO_URL\" -p mongodb.collection=$COLLECTION"

# Workload A - Update heavy workload (50% read, 50% update)
run_ycsb_command "WORKLOAD A - Update Heavy (50/50 read/update)" \
    "$YCSB_PATH run mongodb -s -P $WORKLOAD_PATH/workloada -p operationcount=1000 -p mongodb.url=\"$MONGO_URL\" -p mongodb.collection=$COLLECTION | tee -a /results/ycsb_output.txt"

# Workload B - Read mostly workload (95% read, 5% update)
run_ycsb_command "WORKLOAD B - Read Mostly (95/5 read/update)" \
    "$YCSB_PATH run mongodb -s -P $WORKLOAD_PATH/workloadb -p operationcount=1000 -p mongodb.url=\"$MONGO_URL\" -p mongodb.collection=$COLLECTION | tee -a /results/ycsb_output.txt"

# Workload E - Short ranges (95% scan, 5% insert)
run_ycsb_command "WORKLOAD E - Short Ranges (95/5 scan/insert)" \
    "$YCSB_PATH run mongodb -s -P $WORKLOAD_PATH/workloade -p operationcount=1000 -p mongodb.url=\"$MONGO_URL\" -p mongodb.collection=$COLLECTION | tee -a /results/ycsb_output.txt"

echo "======================================"
echo "All benchmarks completed successfully!"
echo "Results saved to /results/ycsb_output.txt in pod: $YCSB_POD"
echo "======================================"
