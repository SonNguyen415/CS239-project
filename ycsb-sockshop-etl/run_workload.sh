#!/bin/bash
# Helper script to run different workloads

WORKLOAD=${1:-load}
OPS=${2:-1000}

echo "Running YCSB Workload: $WORKLOAD"
echo "Operation Count: $OPS"
echo "=================================="

docker-compose run --rm \
  -e YCSB_WORKLOAD=$WORKLOAD \
  -e OPERATION_COUNT=$OPS \
  ycsb-etl
