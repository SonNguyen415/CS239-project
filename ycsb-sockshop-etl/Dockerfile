# Dockerfile for YCSB to Sock Shop ETL Pipeline
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    curl \
    vim \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better layer caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY etl_pipeline.py .
COPY workloads/ ./workloads/
COPY config/ ./config/

# Create directories for logs and data
RUN mkdir -p /app/logs /app/data

# Environment variables with defaults
ENV MONGODB_HOST=carts-db \
    MONGODB_PORT=27017 \
    MONGODB_DATABASE=carts-1 \
    MONGODB_USERNAME="" \
    MONGODB_PASSWORD="" \
    YCSB_WORKLOAD=load \
    OPERATION_COUNT=1000 \
    RECORD_COUNT=1000 \
    BATCH_SIZE=100 \
    PYTHONUNBUFFERED=1

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "from pymongo import MongoClient; MongoClient('mongodb://${MONGODB_HOST}:${MONGODB_PORT}/', serverSelectionTimeoutMS=2000).admin.command('ping')" || exit 1

# Run the ETL pipeline
CMD ["python", "etl_pipeline.py"]
