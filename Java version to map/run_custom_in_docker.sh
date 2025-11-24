#!/bin/bash

echo "========================================================"
echo "Sock Shop Custom Benchmark (Docker Wrapper)"
echo "========================================================"

# Configuration
YCSB_PATH="/Users/elenavindrola/Desktop/UCSC/CSE293- Advanced Cloud Computing/Project/ycsb-0.17.0"
NETWORK="docker-compose_default"
IMAGE_NAME="ycsb-sockshop-bench"

echo "Using YCSB at: $YCSB_PATH"
echo "Using Docker Network: $NETWORK"

# Verify YCSB exists
if [ ! -d "$YCSB_PATH" ]; then
    echo "ERROR: YCSB not found at $YCSB_PATH"
    exit 1
fi

if [ ! -f "$YCSB_PATH/bin/ycsb" ]; then
    echo "ERROR: YCSB binary not found. Is this a valid YCSB release?"
    exit 1
fi

# Build/Update Image
echo "Building/Updating Benchmark Image..."
docker build -t $IMAGE_NAME .

echo ""
echo ">>> Starting Container Execution..."
echo "--------------------------------------------------------"

# Run container with YCSB mounted and results volume
docker run --rm \
    --network=$NETWORK \
    -v "$YCSB_PATH:/ycsb-mounted:ro" \
    -v "$(pwd)/results:/workspace/results" \
    $IMAGE_NAME \
    /workspace/compile_and_run_custom.sh

echo ""
echo "========================================================"
echo "Benchmark Complete!"
echo "Results saved to: $(pwd)/results/"
echo "========================================================"