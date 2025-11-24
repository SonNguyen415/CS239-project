#!/bin/bash
set -e

# Configuration
YCSB_HOME="/ycsb-mounted"
CUSTOM_SRC="/workspace/custom_clients"
WORK_DIR="/workspace"
OUTPUT_JAR="custom-sockshop-binding.jar"

cd $WORK_DIR

# --- CLASSPATH CONSTRUCTION ---
echo "Building classpath..."
CLASSPATH="$WORK_DIR/$OUTPUT_JAR:$YCSB_HOME/conf"

# Add all jars from YCSB lib and binding libs
for jar in $YCSB_HOME/lib/*.jar $YCSB_HOME/jdbc-binding/lib/*.jar $YCSB_HOME/mongodb-binding/lib/*.jar; do
    if [ -f "$jar" ]; then CLASSPATH="$CLASSPATH:$jar"; fi
done

# Add MySQL Connector
if [ -f "/usr/share/java/mysql-connector-java.jar" ]; then
    CLASSPATH="$CLASSPATH:/usr/share/java/mysql-connector-java.jar"
fi

export CLASSPATH

echo "========================================================"
echo "Compiling Custom Sock Shop YCSB Bindings"
echo "========================================================"

mkdir -p classes
rm -f $OUTPUT_JAR

if javac -d classes $CUSTOM_SRC/*.java; then
    echo "✓ Compilation successful"
else
    echo "ERROR: Compilation failed"
    exit 1
fi

jar -cf $OUTPUT_JAR -C classes .
echo "✓ Created $OUTPUT_JAR"

echo ""
echo "========================================================"
echo "Running Benchmark (Direct Java Invocation)"
echo "========================================================"
mkdir -p results

# ---------------------------------------------------------
# 1. MySQL Benchmark
# ---------------------------------------------------------
echo ""
echo ">>> Benchmarking Catalogue (MySQL)"
echo "--------------------------------------------------------"

# LOAD PHASE
echo "Running LOAD..."
java site.ycsb.Client -load \
    -db com.sockshop.ycsb.SockShopMySQLClient \
    -P $YCSB_HOME/workloads/workloada \
    -p db.driver=com.mysql.cj.jdbc.Driver \
    -p db.url="jdbc:mysql://catalogue-db:3306/socksdb?useSSL=false&allowPublicKeyRetrieval=true" \
    -p db.user=root \
    -p db.passwd="" \
    -p recordcount=1000 \
    -s > results/catalogue_custom_load.txt 2>&1

if grep -q "Return=OK" results/catalogue_custom_load.txt; then
    echo "✓ LOAD Success"
else
    echo "✗ LOAD Failed"
    tail -n 5 results/catalogue_custom_load.txt
fi

# RUN PHASE
echo "Running TRANSACTION..."
java site.ycsb.Client -t \
    -db com.sockshop.ycsb.SockShopMySQLClient \
    -P $YCSB_HOME/workloads/workloada \
    -p db.driver=com.mysql.cj.jdbc.Driver \
    -p db.url="jdbc:mysql://catalogue-db:3306/socksdb?useSSL=false&allowPublicKeyRetrieval=true" \
    -p db.user=root \
    -p db.passwd="" \
    -p operationcount=5000 \
    -p recordcount=1000 \
    -s > results/catalogue_custom_run.txt 2>&1

if grep -q "Return=OK" results/catalogue_custom_run.txt; then
    echo "✓ RUN Success"
else
    echo "✗ RUN Failed"
    tail -n 5 results/catalogue_custom_run.txt
fi

# ---------------------------------------------------------
# 2. MongoDB Benchmark
# ---------------------------------------------------------
echo ""
echo ">>> Benchmarking Orders (MongoDB)"
echo "--------------------------------------------------------"

# LOAD PHASE
echo "Running LOAD..."
java site.ycsb.Client -load \
    -db com.sockshop.ycsb.SockShopMongoClient \
    -P $YCSB_HOME/workloads/workloada \
    -p mongodb.url="mongodb://orders-db:27017/orders" \
    -p mongodb.database=orders \
    -p mongodb.collection=orders \
    -p recordcount=1000 \
    -s > results/orders_custom_load.txt 2>&1

if grep -q "Return=OK" results/orders_custom_load.txt; then
    echo "✓ LOAD Success"
else
    echo "✗ LOAD Failed"
    tail -n 5 results/orders_custom_load.txt
fi

# RUN PHASE
echo "Running TRANSACTION..."
java site.ycsb.Client -t \
    -db com.sockshop.ycsb.SockShopMongoClient \
    -P $YCSB_HOME/workloads/workloada \
    -p mongodb.url="mongodb://orders-db:27017/orders" \
    -p mongodb.database=orders \
    -p mongodb.collection=orders \
    -p operationcount=5000 \
    -p recordcount=1000 \
    -s > results/orders_custom_run.txt 2>&1

if grep -q "Return=OK" results/orders_custom_run.txt; then
    echo "✓ RUN Success"
else
    echo "✗ RUN Failed"
    tail -n 5 results/orders_custom_run.txt
fi

echo ""
echo "========================================================"
echo "Benchmarks Complete!"
echo "========================================================"