#!/bin/bash
set -e

echo "========================================================"
echo "STEP 1: Sock Shop Auto-Benchmark (Execution Phase)"
echo "========================================================"

# 1. Setup YCSB Path
YCSB_LOCAL_DIR=$(ls -d ../ycsb-0.17.0 2>/dev/null | head -n 1)
if [ -z "$YCSB_LOCAL_DIR" ]; then
    echo "ERROR: YCSB 0.17.0 not found at ../ycsb-0.17.0"
    exit 1
fi
YCSB_ABS_PATH=$(cd "$YCSB_LOCAL_DIR" && pwd)

# 2. Find Network
CONTAINER_NAME=$(docker ps --format '{{.Names}}' | grep -E 'catalogue-db|user-db' | head -n 1)
if [ -z "$CONTAINER_NAME" ]; then
    echo "ERROR: Sock Shop not running."
    exit 1
fi
NET_NAME=$(docker inspect "$CONTAINER_NAME" -f '{{range $k, $v := .NetworkSettings.Networks}}{{printf "%s\n" $k}}{{end}}' 2>/dev/null | head -n 1)

# 3. Build Image
echo "Building Benchmark Image..."
docker build -t ycsb-sockshop-bench .

# 4. Run Benchmark
echo "Starting Benchmark Container..."
# Clean previous results
rm -rf ./results/*
mkdir -p ./results

docker run --rm \
    --network "$NET_NAME" \
    -v "$YCSB_ABS_PATH":/ycsb \
    -v "$(pwd)/results":/results \
    --name ycsb-bench-runner \
    ycsb-sockshop-bench \
    auto_benchmark_all.sh

echo ""
echo "Benchmark Complete."
echo "Raw data saved to ./results/"
echo "Run './run_report.sh' to view the summary."