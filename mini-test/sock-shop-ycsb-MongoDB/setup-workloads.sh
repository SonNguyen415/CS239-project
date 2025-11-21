#!/bin/bash

# Create workload directory structure
mkdir -p ycsb-workloads
mkdir -p results

# Workload A - Update Heavy (50% reads, 50% updates)
cat > ycsb-workloads/workloada << 'EOF'
# Yahoo! Cloud System Benchmark
# Workload A: Update heavy workload (Session/Shopping Cart)
recordcount=100000
operationcount=100000
workload=core

readallfields=true

readproportion=0.50
updateproportion=0.50
scanproportion=0
insertproportion=0

requestdistribution=zipfian
EOF

# Workload B - Read Heavy (95% reads, 5% updates)
cat > ycsb-workloads/workloadb << 'EOF'
# Yahoo! Cloud System Benchmark
# Workload B: Read mostly workload (Product Catalog)
recordcount=100000
operationcount=100000
workload=core

readallfields=true

readproportion=0.95
updateproportion=0.05
scanproportion=0
insertproportion=0

requestdistribution=zipfian
EOF

# Workload E - Short Ranges (95% scans, 5% inserts)
cat > ycsb-workloads/workloade << 'EOF'
# Yahoo! Cloud System Benchmark
# Workload E: Short ranges (Analytics queries)
recordcount=100000
operationcount=100000
workload=core

readallfields=true

readproportion=0
updateproportion=0
scanproportion=0.95
insertproportion=0.05

requestdistribution=zipfian

# Scan length distribution
maxscanlength=100
scanlengthdistribution=uniform
EOF

echo "Workload files created successfully!"
echo "Files created in ./ycsb-workloads/"