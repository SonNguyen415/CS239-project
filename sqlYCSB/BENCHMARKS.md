YCSB Benchmarks for MySQL and MongoDB

Benchmark A (Updated Heavy 50/50 read/update)
    record count    : 10,000
    operation count : 10,000
    Reads           : .50
    Update          : .50

Benchmark B (Read Heavy (95% Read, 5% update)
    record count    : 10,000
    operation count : 10,000
    Reads           : .95
    Writes          : .05

Benchmark C (Read Only)
    record count    : 10,000
    operation count : 10,000
    Reads           : 1.0 
    Writes          : 0 

Benchmark D (Read Latest 95% read, 5% insert)
    record count    : 10,000
    operation count : 10,000
    Reads           : 0.95 
    Insert          : 0.05 

Benchmark D Scan Heavy (95% scan, 5% insert)
    record count    : 10,000
    operation count : 10,000
    scan            : 0.95 
    Insert          : 0.05 

Stress:
    record count    : 50,000
    operation count : 100,000
    read            : 0.50
    update          : 0.30
    scan            : 0.10
    read/modify     : 0.10

Spike:
    record count    : 10,000
    operation count : 50,000
    read            : 0.70
    update          : 0.20
    scan            : 0.10

Spike:
    record count    : 20,000
    operation count : 200,000
    read            : 0.60
    update          : 0.25
    scan            : 0.10
    read/modify     : 0.05
