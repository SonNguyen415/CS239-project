#!/bin/bash
set -e

echo "========================================================"
echo "STEP 2: Generating Performance Report"
echo "========================================================"

# 1. Check if image exists (Build if missing)
if [[ "$(docker images -q ycsb-sockshop-bench 2> /dev/null)" == "" ]]; then
    echo "Image not found. Building..."
    docker build -t ycsb-sockshop-bench .
fi

# 2. Run Report Script
# FIX: We mount (-v) the local generate_report.py to overwrite the one in the container
docker run --rm \
    -v "$(pwd)/results":/results \
    -v "$(pwd)/generate_report.py":/usr/local/bin/generate_report.py \
    ycsb-sockshop-bench \
    python2 /usr/local/bin/generate_report.py