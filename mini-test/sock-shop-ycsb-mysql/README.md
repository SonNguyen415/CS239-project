# Sock Shop YCSB Benchmark - MySQL Edition

This setup benchmarks MySQL (used in sock-shop) with the same YCSB workloads you ran on MongoDB.

## Quick Start

### 1. Create a New Directory for MySQL Tests

```bash
mkdir sock-shop-ycsb-mysql
cd sock-shop-ycsb-mysql
```

### 2. Save the Files

Save these files in your `sock-shop-ycsb-mysql` directory:
- `docker-compose.yml` - Docker Compose configuration with MySQL
- `Dockerfile.ycsb` - Same Dockerfile as before (reuse from MongoDB setup)
- `init-mysql.sql` - SQL script to initialize the database
- `setup-workloads.sh` - Script to create MySQL workload files
- `run-benchmarks.sh` - Script to run all benchmarks

### 3. Copy Dockerfile from MongoDB Setup

```bash
# If you still have the MongoDB setup directory
cp ../sock-shop-ycsb/Dockerfile.ycsb .

# Or create it fresh (same content as MongoDB version)
```

### 4. Make Scripts Executable

```bash
chmod +x setup-workloads.sh run-benchmarks.sh
```

### 5. Create Workload Files

```bash
./setup-workloads.sh
```

### 6. Start the Services

```bash
docker-compose up -d
```

Wait about 30 seconds for MySQL to fully initialize.

### 7. Verify Services are Running

```bash
docker-compose ps
```

You should see both `sock-shop-mysql` and `ycsb-benchmark` containers running and healthy.

### 8. Run the Benchmarks

```bash
./run-benchmarks.sh
```

This will run all three workloads sequentially. Each workload takes 5-10 minutes.

## MySQL vs MongoDB

### Key Differences

**MySQL (Relational)**
- Structured table with columns (FIELD0-FIELD9)
- ACID transactions with strong consistency
- Better for complex joins and relationships
- Row-based storage

**MongoDB (Document)**
- Flexible JSON documents
- Eventual consistency by default
- Better for hierarchical/nested data
- Document-based storage

### Expected Performance Characteristics

**Workload A (50/50 Read/Write)**
- MySQL: Slower due to transaction overhead, better consistency
- MongoDB: Faster writes, lower latency

**Workload B (95/5 Read Heavy)**
- MySQL: Good read performance with proper indexes
- MongoDB: Excellent read performance, especially for document retrieval

**Workload E (Range Scans)**
- MySQL: Optimized for range queries with B-tree indexes
- MongoDB: Good for range scans, especially with compound indexes

## Comparing Results

After running both setups, compare the key metrics:

```bash
# MongoDB results (from previous run)
cat ../sock-shop-ycsb/results/workloada_run.txt | grep "Takes(s):"

# MySQL results (current run)
cat results/workloada_run.txt | grep "Takes(s):"
```

### Metrics to Compare

1. **Throughput (OPS)**: Operations per second - higher is better
2. **Average Latency (Avg(us))**: Average response time - lower is better
3. **95th Percentile (95th(us))**: 95% of requests complete within this time
4. **99th Percentile (99th(us))**: Worst-case for most requests

## Database Access

### Connect to MySQL

```bash
docker exec -it sock-shop-mysql mysql -usockshop -psockshop sockshop
```

### Check Data

```sql
-- See how many records were loaded
SELECT COUNT(*) FROM usertable;

-- View sample records
SELECT * FROM usertable LIMIT 10;

-- Check table structure
DESCRIBE usertable;
```

### Connect to MongoDB (for comparison)

```bash
# If MongoDB is still running
docker exec -it sock-shop-db mongo sockshop
```

```javascript
// Check collection
db.usertable.count()
db.usertable.findOne()
```

## Cleanup

### Stop MySQL setup

```bash
docker-compose down
```

### Remove all data

```bash
docker-compose down -v
```

## Troubleshooting

### MySQL not ready

```bash
# Check MySQL logs
docker logs sock-shop-mysql

# Wait longer for initialization
sleep 30
```

### Connection refused

```bash
# Verify MySQL is healthy
docker-compose ps

# Check healthcheck status
docker inspect sock-shop-mysql | grep -A 10 Health
```

### Performance too slow

MySQL might be slower than MongoDB for these workloads because:
1. ACID transaction overhead
2. Row-based storage vs document storage
3. More complex query planning

This is expected and part of the comparison!

## Advanced Configuration

### Increase Dataset Size

Edit `ycsb-workloads/workloada` (and b, e):
```bash
recordcount=1000000
operationcount=500000
```

### Tune MySQL Performance

Add to `docker-compose.yml` under mysql command:
```yaml
command: >
  --default-authentication-plugin=mysql_native_password
  --innodb_buffer_pool_size=1G
  --max_connections=500
```

### Monitor MySQL Performance

```bash
# Watch queries in real-time
docker exec -it sock-shop-mysql mysql -usockshop -psockshop -e "SHOW PROCESSLIST;"

# Check InnoDB status
docker exec -it sock-shop-mysql mysql -usockshop -psockshop -e "SHOW ENGINE INNODB STATUS\G"
```

## Next Steps

1. Compare MySQL vs MongoDB performance
2. Try different workload configurations
3. Test with larger datasets
4. Deploy full sock-shop on Nautilus with both databases
5. Run load tests on the complete microservices setup

## Resources

- [MySQL Performance Tuning](https://dev.mysql.com/doc/refman/8.0/en/optimization.html)
- [YCSB Core Workloads](https://github.com/brianfrankcooper/YCSB/wiki/Core-Workloads)
- [Sock Shop Demo](https://github.com/ocp-power-demos/sock-shop-demo)