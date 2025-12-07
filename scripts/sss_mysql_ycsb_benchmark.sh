#!/bin/bash

# SSS (Spike, Stress, Soak) MySQL YCSB Benchmark Script
# This script runs high-load performance tests on MySQL

set -e  # Exit on error

echo "======================================"
echo "SSS MySQL Benchmark Suite"
echo "Spike | Stress | Soak Tests"
echo "======================================"
echo ""

# Display all running pods
echo "Checking running pods..."
kubectl get pods
echo ""

# Find the YCSB pod (exclude mysql-ycsb pods)
echo "Finding YCSB interface pod..."
YCSB_POD=$(kubectl get pods | grep "mysql-ycsb-interface"  | awk '{print $1}' | head -n 1)


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
		"./bin/ycsb run jdbc -P workloads/spike_test -s"
        ;;
    2)
        # Stress Test
        run_ycsb_command "STRESS TEST - Sustained high load (1M ops, 2k ops/sec, 1000 threads)" \
		"./bin/ycsb run jdbc -P workloads/stress_test_load -s && ./bin/ycsb run jdbc -P workloads/stress_test -s"
        ;;
    3)
        # Soak Test
        run_ycsb_command "SOAK TEST - Long duration stability (450k ops, 500 ops/sec, 50 threads)" \
		"./bin/ycsb run jdbc -P workloads/soak_test_load -s && ./bin/ycsb run jdbc -P workloads/soak_test -s"
        ;;
    4)
        # All Tests
        run_ycsb_command "SPIKE TEST - High throughput burst (20k ops, 10k ops/sec, 1000 threads)" \
		"./spike_soak_benchmarks.sh"
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

echo "======================================"
echo "Benchmark(s) completed successfully!"
echo "======================================"
echo ""
