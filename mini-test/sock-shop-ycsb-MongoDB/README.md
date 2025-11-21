# Stop and remove existing containers
docker-compose down

# Rebuild with the new Dockerfile
docker-compose build

# Start the containers
docker-compose up -d

# Run the benchmarks
./run-benchmarks.sh