FROM ubuntu:22.04

# Install Java + Python2 + wget + MySQL client
RUN apt-get update && \
    apt-get install -y openjdk-11-jdk python2 wget iputils-ping curl mysql-client && \
    ln -s /usr/bin/python2 /usr/bin/python && \
    rm -rf /var/lib/apt/lists/*

# Install Vim
RUN apt-get update && apt-get install -y vim 

# Download and extract YCSB
RUN cd /root && \
    wget -c https://github.com/brianfrankcooper/YCSB/releases/download/0.17.0/ycsb-0.17.0.tar.gz && \
    tar xfvz ycsb-0.17.0.tar.gz

# Download MySQL JDBC connector (correct Maven path)
RUN cd /root/ycsb-0.17.0/jdbc-binding/lib && \
    wget https://repo1.maven.org/maven2/com/mysql/mysql-connector-j/8.0.33/mysql-connector-j-8.0.33.jar

# Create basic YCSB workload
RUN mkdir -p /root/ycsb-0.17.0/workloads && \
    printf "recordcount=1000\n\
operationcount=1000\n\
workload=site.ycsb.workloads.CoreWorkload\n\
readallfields=true\n\
readproportion=0.2\n\
updateproportion=0.3\n\
scanproportion=0.3\n\
insertproportion=0\n\
readmodifywriteproportion=0.2\n\
requestdistribution=zipfian\n" \
    > /root/ycsb-0.17.0/workloads/iworkload

# Create Sock Shop catalogue workload for MySQL
RUN mkdir -p /root/ycsb-0.17.0/workloads && \
    printf "recordcount=10000\n\
operationcount=10000\n\
workload=site.ycsb.workloads.CoreWorkload\n\
\n\
# MySQL/JDBC specific settings\n\
db.driver=com.mysql.cj.jdbc.Driver\n\
db.url=jdbc:mysql://catalogue-db:3306/socksdb?useSSL=false&allowPublicKeyRetrieval=true\n\
db.user=catalogue_user\n\
db.passwd=default_password\n\
\n\
# Table configuration\n\
table=ycsb_usertable\n\
\n\
# Field configuration (YCSB standard: 10 fields)\n\
fieldcount=10\n\
fieldlengthunit=characters\n\
fieldlengthdistribution=constant\n\
fieldlength=100\n\
\n\
# Read/Write configuration\n\
readallfields=true\n\
writeallfields=true\n\
dataintegrity=true\n\
\n\
# Operation mix for RUN phase\n\
readproportion=0.5\n\
updateproportion=0.3\n\
scanproportion=0.1\n\
insertproportion=0.0\n\
readmodifywriteproportion=0.1\n\
\n\
# Distribution\n\
requestdistribution=zipfian\n\
\n\
# Insert configuration (for LOAD phase)\n\
insertstart=0\n\
insertcount=10000\n\
insertorder=hashed\n\
\n\
# Performance tuning\n\
jdbc.batchupdateapi=true\n\
jdbc.batchsize=1000\n\
jdbc.autocommit=true\n" \
    > /root/ycsb-0.17.0/workloads/sockshop_mysql_workload

# Create workload for LOAD phase (inserts only)
RUN printf "recordcount=10000\n\
operationcount=10000\n\
workload=site.ycsb.workloads.CoreWorkload\n\
\n\
# MySQL/JDBC specific settings\n\
db.driver=com.mysql.cj.jdbc.Driver\n\
db.url=jdbc:mysql://catalogue-db:3306/socksdb?useSSL=false&allowPublicKeyRetrieval=true\n\
db.user=catalogue_user\n\
db.passwd=default_password\n\
\n\
# Table configuration\n\
table=ycsb_usertable\n\
\n\
# Field configuration\n\
fieldcount=10\n\
fieldlengthunit=characters\n\
fieldlengthdistribution=constant\n\
fieldlength=100\n\
\n\
# Read/Write configuration\n\
readallfields=true\n\
writeallfields=true\n\
\n\
# LOAD phase: only inserts\n\
readproportion=0\n\
updateproportion=0\n\
scanproportion=0\n\
insertproportion=1.0\n\
readmodifywriteproportion=0\n\
\n\
# Distribution\n\
requestdistribution=uniform\n\
\n\
# Insert configuration\n\
insertstart=0\n\
insertcount=10000\n\
insertorder=hashed\n\
\n\
# Performance tuning\n\
jdbc.batchupdateapi=true\n\
jdbc.batchsize=1000\n\
jdbc.autocommit=true\n" \
    > /root/ycsb-0.17.0/workloads/sockshop_mysql_load

# Create a benchmark runner script
RUN printf '#!/bin/bash\n\
\n\
echo "================================================="\n\
echo "YCSB Benchmark for Sock Shop MySQL catalogue-db"\n\
echo "================================================="\n\
\n\
# Wait for MySQL to be ready\n\
echo "Waiting for MySQL to be ready..."\n\
until mysql -h catalogue-db -u catalogue_user -pdefault_password -e "SELECT 1" &>/dev/null; do\n\
  echo "MySQL is unavailable - sleeping"\n\
  sleep 2\n\
done\n\
\n\
echo "MySQL is ready!"\n\
\n\
# Create the table if it does not exist\n\
echo "Creating YCSB table..."\n\
mysql -h catalogue-db -u catalogue_user -pdefault_password socksdb <<EOF\n\
CREATE TABLE IF NOT EXISTS ycsb_usertable (\n\
  YCSB_KEY VARCHAR(255) PRIMARY KEY,\n\
  FIELD0 TEXT, FIELD1 TEXT, FIELD2 TEXT, FIELD3 TEXT, FIELD4 TEXT,\n\
  FIELD5 TEXT, FIELD6 TEXT, FIELD7 TEXT, FIELD8 TEXT, FIELD9 TEXT\n\
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;\n\
EOF\n\
\n\
echo "Table created successfully!"\n\
\n\
# Run LOAD phase\n\
echo ""\n\
echo "================================================="\n\
echo "Phase 1: LOADING data..."\n\
echo "================================================="\n\
./bin/ycsb load jdbc -P workloads/sockshop_mysql_load -s\n\
\n\
# Run benchmark phase\n\
echo ""\n\
echo "================================================="\n\
echo "Phase 2: RUNNING benchmark..."\n\
echo "================================================="\n\
./bin/ycsb run jdbc -P workloads/sockshop_mysql_workload -s\n\
\n\
echo ""\n\
echo "================================================="\n\
echo "Benchmark Complete!"\n\
echo "================================================="\n' \
    > /root/ycsb-0.17.0/run_benchmark.sh && \
    chmod +x /root/ycsb-0.17.0/run_benchmark.sh

WORKDIR /root/ycsb-0.17.0

CMD ["/bin/bash"]
