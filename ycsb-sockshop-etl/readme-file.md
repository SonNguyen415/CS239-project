# YCSB to Sock Shop Carts ETL Pipeline

A Docker-based ETL pipeline that transforms YCSB (Yahoo! Cloud Serving Benchmark) workload data to the Sock Shop microservices Carts-1 MongoDB database format.

## Features

- ✅ Complete ETL pipeline (Extract, Transform, Load)
- ✅ YCSB workload simulation support (Load, A, B, E)
- ✅ Docker containerized for easy deployment
- ✅ Connects to existing Sock Shop MongoDB or standalone
- ✅ Comprehensive logging and performance metrics
- ✅ JSON export of results and statistics

## Quick Start

```bash
# Clone or download this directory
cd ycsb-sockshop-etl

# Create required directories
mkdir -p logs data

# Build the Docker image
docker-compose build

# Run with default settings (Load phase)
docker-compose up

# Run specific workload
docker-compose run -e YCSB_WORKLOAD=a -e OPERATION_COUNT=2000 ycsb-etl
```

## Project Structure

```
ycsb-sockshop-etl/
├── Dockerfile                  # Container definition
├── docker-compose.yml          # Orchestration configuration
├── requirements.txt            # Python dependencies
├── etl_pipeline.py            # Main ETL script
├── workloads/                 # YCSB workload definitions
│   ├── workload_a.json        # Update heavy (50/50)
│   ├── workload_b.json        # Read heavy (95/5)
│   └── workload_e.json        # Scan heavy (95/5)
├── config/
│   └── mongodb.conf           # MongoDB configuration
├── logs/                      # Pipeline logs (generated)
├── data/                      # Exported results (generated)
└── README.md                  # This file
```

## YCSB Workloads

### Load Phase
- **Description**: Initial data loading
- **Operations**: 100% inserts
- **Use**: Populate database with initial dataset

### Workload A - Update Heavy
- **Description**: Session store pattern
- **Operations**: 50% reads, 50% updates
- **Use Case**: Recording recent user actions

### Workload B - Read Heavy
- **Description**: Photo tagging pattern
- **Operations**: 95% reads, 5% updates
- **Use Case**: Mostly read operations with occasional updates

### Workload E - Scan Heavy
- **Description**: Threaded conversations
- **Operations**: 95% scans, 5% inserts
- **Use Case**: Range queries with continuous inserts

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `MONGODB_HOST` | `carts-db` | MongoDB hostname |
| `MONGODB_PORT` | `27017` | MongoDB port |
| `MONGODB_DATABASE` | `carts-1` | Target database name |
| `YCSB_WORKLOAD` | `load` | Workload type (load, a, b, e) |
| `OPERATION_COUNT` | `1000` | Number of operations to perform |
| `RECORD_COUNT` | `1000` | Number of records to generate |
| `BATCH_SIZE` | `100` | Batch size for bulk operations |

### Connecting to Existing Sock Shop

Edit `docker-compose.yml`:

```yaml
networks:
  sockshop:
    external: true
    name: microservices-demo_default  # Your Sock Shop network name
```

Then comment out the `carts-db` service if using existing MongoDB.

## Running Different Workloads

```bash
# Load phase (initial data)
docker-compose run -e YCSB_WORKLOAD=load ycsb-etl

# Workload A - Update heavy
docker-compose run -e YCSB_WORKLOAD=a -e OPERATION_COUNT=10000 ycsb-etl

# Workload B - Read heavy
docker-compose run -e YCSB_WORKLOAD=b -e OPERATION_COUNT=50000 ycsb-etl

# Workload E - Scan heavy
docker-compose run -e YCSB_WORKLOAD=e -e OPERATION_COUNT=5000 ycsb-etl
```

## Viewing Results

### Check Logs
```bash
# Real-time logs
docker-compose logs -f ycsb-etl

# Pipeline logs
cat logs/etl_pipeline.log
```

### View Exported Results
```bash
# Results are saved to data/ directory
cat data/results_*.json
```

### Query MongoDB
```bash
# Connect to MongoDB
docker exec -it carts-db mongosh

# In MongoDB shell
use carts-1
db.carts.count()
db.carts.findOne()
```

## Performance Monitoring

### MongoDB Operations
```bash
docker exec -it carts-db mongosh --eval "db.currentOp()"
```

### Container Stats
```bash
docker stats ycsb-sockshop-etl carts-db
```

## Troubleshooting

### Connection Issues

```bash
# Test network connectivity
docker exec ycsb-sockshop-etl ping carts-db

# Check if MongoDB is running
docker ps | grep carts-db

# View network details
docker network inspect sockshop
```

### MongoDB Not Starting

```bash
# Check MongoDB logs
docker logs carts-db

# Verify permissions
ls -la logs/ data/
```

### Python Errors

```bash
# Run interactively for debugging
docker-compose run --rm ycsb-etl bash

# Inside container
python etl_pipeline.py
```

## Advanced Usage

### Custom Workload Configuration

Edit workload JSON files in `workloads/` directory to customize operation distributions.

### MongoDB Authentication

Uncomment in `docker-compose.yml`:
```yaml
environment:
  - MONGODB_USERNAME=admin
  - MONGODB_PASSWORD=password
```

### Performance Tuning

Adjust in `config/mongodb.conf`:
- `cacheSizeGB`: Memory allocated to MongoDB
- `slowOpThresholdMs`: Slow query threshold
- `maxIncomingConnections`: Connection pool size

## Data Schema

### YCSB Format (Input)
```json
{
  "_id": "user0",
  "field0": "item-0-1234",
  "field1": "5",
  "field2": "1999",
  ...
}
```

### Sock Shop Cart Format (Output)
```json
{
  "_id": "user0",
  "customerId": "user0",
  "items": [
    {
      "itemId": "item-0-1234",
      "quantity": 5,
      "unitPrice": 19.99
    }
  ],
  "metadata": {
    "createdAt": "2024-11-25T10:30:00Z",
    "updatedAt": "2024-11-25T10:30:00Z",
    "source": "ycsb-etl",
    "workload": "load"
  }
}
```

## Cleanup

```bash
# Stop containers
docker-compose down

# Remove volumes (WARNING: deletes data)
docker-compose down -v

# Remove images
docker rmi ycsb-sockshop-etl_ycsb-etl
```

## Requirements

- Docker Engine 20.10+
- Docker Compose 2.0+
- 2GB RAM minimum
- 5GB disk space

## License

MIT License - See LICENSE file for details

## References

- [YCSB GitHub](https://github.com/brianfrankcooper/YCSB)
- [Sock Shop Demo](https://github.com/microservices-demo/microservices-demo)
- [MongoDB Docker](https://hub.docker.com/_/mongo)

## Support

For issues and questions:
1. Check the troubleshooting section
2. Review logs in `logs/etl_pipeline.log`
3. Verify MongoDB connectivity
4. Check Docker network configuration
