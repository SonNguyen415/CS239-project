#!/bin/bash

# Start the YCSB exporter in the background
echo "Starting YCSB Prometheus Exporter..."
python3 /usr/local/bin/exporter.py &

# Wait a moment for the exporter to start
sleep 2

# Start an interactive bash shell
echo "YCSB Interface Ready. Exporter running on port 8000."
echo "Run your YCSB benchmarks with: ~/ycsb-0.17.0/bin/ycsb.sh run mongodb -s -P ~/ycsb-0.17.0/workloads/workloada ..."
echo ""

# Keep container running with interactive bash
exec /bin/bash