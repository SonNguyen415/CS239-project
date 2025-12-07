#!/bin/bash

# YCSB MySQL Benchmarking Script
# This script automatically finds the YCSB pod and runs comprehensive benchmarks

set -e  # Exit on error

echo "======================================"
echo "YCSB MySQL Benchmark Suite"
echo "======================================"
echo ""

# Display all running pods
echo "Checking running pods..."
kubectl get pods
echo ""

# Find the YCSB pod (exclude mysql-ycsb pods)
echo "Finding YCSB interface pod..."
YCSB_POD=$(kubectl get pods | grep "mysql-ycsb-interface" | awk '{print $1}' | head -n 1)

if [ -z "$YCSB_POD" ]; then
    echo "ERROR: Could not find YCSB interface pod"
    exit 1
fi

echo "Found YCSB pod: $YCSB_POD"
echo ""

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

run_ycsb_command "LOAD PHASE - Loading 1,000 records" \
	"./run_benchmark.sh"


echo "======================================"
echo "All benchmarks completed successfully!"
echo "======================================"
