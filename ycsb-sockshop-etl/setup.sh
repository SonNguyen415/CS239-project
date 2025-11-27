#!/bin/bash
# Setup script for YCSB to Sock Shop ETL Pipeline
# Pre-configured for docker-compose_default network

set -e

echo "================================================"
echo "YCSB to Sock Shop ETL Pipeline Setup"
echo "================================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# PRE-CONFIGURED VALUES
NETWORK_NAME="docker-compose_default"
MONGO_HOST="docker-compose-carts-db-1"
MONGO_PORT="27017"
MONGO_DB="carts"

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is installed
print_info "Checking Docker installation..."
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi
print_info "Docker found: $(docker --version)"

# Check if Docker Compose is installed
print_info "Checking Docker Compose installation..."
if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi
print_info "Docker Compose found: $(docker-compose --version)"

# Create required directories
print_info "Creating required directories..."
mkdir -p logs
mkdir -p data
mkdir -p workloads
mkdir -p config
print_info "Directories created successfully"

# Set permissions
print_info "Setting directory permissions..."
chmod 755 logs data workloads config
print_info "Permissions set successfully"

# Display configuration
echo ""
print_info "Using pre-configured settings:"
echo "  Network: $NETWORK_NAME"
echo "  MongoDB Host: $MONGO_HOST"
echo "  MongoDB Port: $MONGO_PORT"
echo "  MongoDB Database: $MONGO_DB"
echo ""

# Check if network exists
print_info "Checking if network exists..."
if docker network inspect $NETWORK_NAME &> /dev/null; then
    print_info "Network '$NETWORK_NAME' found ✓"
else
    print_error "Network '$NETWORK_NAME' not found!"
    echo ""
    echo "Available networks:"
    docker network ls
    echo ""
    print_error "Please ensure your Sock Shop microservices are running."
    exit 1
fi

# Check if MongoDB container exists
print_info "Checking if MongoDB container exists..."
if docker ps -a --format '{{.Names}}' | grep -q "^${MONGO_HOST}$"; then
    MONGO_STATUS=$(docker inspect -f '{{.State.Status}}' $MONGO_HOST)
    if [ "$MONGO_STATUS" == "running" ]; then
        print_info "MongoDB container '$MONGO_HOST' is running ✓"
    else
        print_warning "MongoDB container '$MONGO_HOST' exists but is not running (status: $MONGO_STATUS)"
        read -p "Do you want to start it? (y/n): " START_MONGO
        if [ "$START_MONGO" == "y" ]; then
            docker start $MONGO_HOST
            print_info "MongoDB container started"
        fi
    fi
else
    print_warning "MongoDB container '$MONGO_HOST' not found"
    print_warning "Will attempt to connect anyway - make sure MongoDB is running"
fi

# Remove old sockshop network if it exists
if docker network ls --format "{{.Name}}" | grep -q "^sockshop$"; then
    print_info "Removing old 'sockshop' network..."
    docker network rm sockshop 2>/dev/null || true
    print_info "Old network removed"
fi

# Update docker-compose.yml
print_info "Updating docker-compose.yml..."
cat > docker-compose.yml << EOF
version: '3.8'

services:
  ycsb-etl:
    build: .
    container_name: ycsb-sockshop-etl
    hostname: ycsb-etl
    networks:
      - sockshop
    environment:
      # MongoDB Configuration
      - MONGODB_HOST=$MONGO_HOST
      - MONGODB_PORT=$MONGO_PORT
      - MONGODB_DATABASE=$MONGO_DB
      
      # YCSB Workload Configuration
      - YCSB_WORKLOAD=load
      - OPERATION_COUNT=1000
      - RECORD_COUNT=1000
      - BATCH_SIZE=100
      
      # Python Configuration
      - PYTHONUNBUFFERED=1
    
    volumes:
      # Mount logs directory for output
      - ./logs:/app/logs
      # Mount data directory for exports
      - ./data:/app/data
    
    # Don't restart automatically - run once per workload
    restart: "no"

networks:
  sockshop:
    external: true
    name: $NETWORK_NAME
EOF

print_info "docker-compose.yml created successfully"

# Create .env file
print_info "Creating .env file..."
cat > .env << EOF
MONGODB_HOST=$MONGO_HOST
MONGODB_PORT=$MONGO_PORT
MONGODB_DATABASE=$MONGO_DB
YCSB_WORKLOAD=load
OPERATION_COUNT=1000
RECORD_COUNT=1000
BATCH_SIZE=100
EOF
print_info ".env file created with your settings"

# Build Docker image
echo ""
print_info "Building Docker image..."
docker-compose build
print_info "Docker image built successfully"

# Test MongoDB connectivity
echo ""
print_info "Testing MongoDB connectivity..."
if docker run --rm --network=$NETWORK_NAME mongo:3.4 mongo --host $MONGO_HOST --port $MONGO_PORT --eval "db.adminCommand('ping')" --quiet > /dev/null 2>&1; then
    print_info "✓ MongoDB connection test PASSED"
else
    print_warning "MongoDB connection test failed - you may need to check your MongoDB setup"
fi

# Verify database exists
print_info "Checking if database '$MONGO_DB' exists..."
DB_CHECK=$(docker run --rm --network=$NETWORK_NAME mongo:3.4 mongo --host $MONGO_HOST --port $MONGO_PORT --quiet --eval "db.adminCommand('listDatabases').databases.map(d => d.name).join(',')" 2>/dev/null || echo "")
if echo "$DB_CHECK" | grep -q "$MONGO_DB"; then
    print_info "✓ Database '$MONGO_DB' found"
else
    print_warning "Database '$MONGO_DB' not found - it will be created on first run"
fi

# Create helper scripts
print_info "Creating helper scripts..."

# Run workload script
cat > run_workload.sh << 'EOF'
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
EOF
chmod +x run_workload.sh
print_info "Created run_workload.sh"

# View results script
cat > view_results.sh << 'EOF'
#!/bin/bash
# Helper script to view results

echo "Recent Results:"
echo "=============="
ls -lht data/results_*.json 2>/dev/null | head -5 || echo "No results found"

echo ""
echo "Latest Result:"
echo "============="
LATEST=$(ls -t data/results_*.json 2>/dev/null | head -1)
if [ -f "$LATEST" ]; then
    cat "$LATEST" | python -m json.tool
else
    echo "No results available yet"
fi
EOF
chmod +x view_results.sh
print_info "Created view_results.sh"

# MongoDB shell script
cat > mongo_shell.sh << EOF
#!/bin/bash
# Helper script to connect to MongoDB

docker exec -it $MONGO_HOST mongo $MONGO_DB
EOF
chmod +x mongo_shell.sh
print_info "Created mongo_shell.sh"

# Create usage guide
cat > USAGE.md << 'EOF'
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
EOF
print_info "Created USAGE.md"

# Summary
echo ""
echo "================================================"
print_info "Setup completed successfully!"
echo "================================================"
echo ""
echo "Configuration:"
echo "  • Network: $NETWORK_NAME"
echo "  • MongoDB Host: $MONGO_HOST"
echo "  • MongoDB Port: $MONGO_PORT"
echo "  • Database: $MONGO_DB"
echo ""
echo "Next steps:"
echo "  1. Verify Sock Shop is running: docker ps | grep mongo"
echo "  2. Run load phase: ./run_workload.sh load 1000"
echo "  3. Run workloads: ./run_workload.sh a 10000"
echo "  4. View results: ./view_results.sh"
echo ""
echo "Helper scripts created:"
echo "  - run_workload.sh   : Run different workloads"
echo "  - view_results.sh   : View pipeline results"
echo "  - mongo_shell.sh    : Connect to MongoDB"
echo "  - USAGE.md          : Quick reference guide"
echo ""
print_info "For detailed documentation, see README.md"
echo "================================================"