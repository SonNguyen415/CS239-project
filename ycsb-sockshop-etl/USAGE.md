# YCSB ETL Pipeline - Quick Usage Guide

## Running Workloads

### Load Phase (Initial Data)
```bash
./run_workload.sh load 1000
```

### Workload A (Update Heavy - 50/50)
```bash
./run_workload.sh a 10000
```

### Workload B (Read Heavy - 95/5)
```bash
./run_workload.sh b 50000
```

### Workload E (Scan Heavy - 95/5)
```bash
./run_workload.sh e 5000
```

## Viewing Results

### View Latest Results
```bash
./view_results.sh
```

### View Logs
```bash
tail -f logs/etl_pipeline.log
```

### Docker Compose Logs
```bash
docker-compose logs -f ycsb-etl
```

## MongoDB Access

### Connect to MongoDB Shell
```bash
./mongo_shell.sh
```

### Query Carts Collection
```bash
docker exec -it docker-compose-carts-db-1 mongo carts --eval "db.carts.count()"
```

## Maintenance

### Stop All Services
```bash
docker-compose down
```

### Clean Data (WARNING: Deletes all data)
```bash
rm -rf logs/* data/*
docker-compose down -v
```

### Rebuild Image
```bash
docker-compose build --no-cache
```

## Monitoring

### Container Stats
```bash
docker stats ycsb-sockshop-etl docker-compose-carts-db-1
```

### MongoDB Performance
```bash
docker exec -it docker-compose-carts-db-1 mongo --eval "db.serverStatus()"
```
