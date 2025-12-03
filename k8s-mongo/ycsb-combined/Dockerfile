FROM ubuntu:22.04

# Install Java, Python, wget, and other tools
RUN apt-get update && \
    apt-get install -y openjdk-11-jdk wget iputils-ping python3 python3-pip && \
    rm -rf /var/lib/apt/lists/*

# Download and extract YCSB
RUN cd /root && \
    wget -c https://github.com/brianfrankcooper/YCSB/releases/download/0.17.0/ycsb-0.17.0.tar.gz && \
    tar xfvz ycsb-0.17.0.tar.gz

# Create custom workload file
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

# Create custom workload file for Sock Shop user schema
RUN mkdir -p /root/ycsb-0.17.0/workloads && \
    printf "recordcount=1000\n\
operationcount=1000\n\
workload=site.ycsb.workloads.CoreWorkload\n\
\n\
# MongoDB specific settings\n\
mongodb.url=mongodb://docker-compose-user-db-1:27017/users\n\
mongodb.database=users\n\
mongodb.writeConcern=acknowledged\n\
\n\
# Use _id as the key field (YCSB will generate unique keys)\n\
mongodb.upsert=false\n\
\n\
# Field configuration to match Sock Shop user schema\n\
fieldcount=7\n\
fieldlengthunit=characters\n\
\n\
# Generate unique username based on YCSB key\n\
# YCSB generates keys like 'user0', 'user1', etc.\n\
insertstart=1000\n\
insertcount=1000\n\
\n\
# Define all required fields\n\
field.firstName=STRING\n\
field.lastName=STRING\n\
field.username=STRING\n\
field.password=STRING\n\
field.salt=STRING\n\
field.addresses=ARRAY\n\
field.cards=ARRAY\n\
\n\
# Field lengths\n\
fieldlengthdistribution=constant\n\
fieldlength=40\n\
\n\
# Read/Write all fields to maintain document integrity\n\
readallfields=true\n\
writeallfields=true\n\
dataintegrity=true\n\
\n\
# Operation mix (for load phase, use only inserts)\n\
readproportion=0\n\
updateproportion=0\n\
scanproportion=0\n\
insertproportion=1.0\n\
readmodifywriteproportion=0\n\
\n\
# Distribution\n\
requestdistribution=uniform\n\
\n\
# Insert order - sequential to avoid conflicts\n\
insertorder=ordered\n\
\n\
# Core table name\n\
table=customers\n" \
    > /root/ycsb-0.17.0/workloads/sockshop_workload

# Install Python dependencies for the exporter
RUN pip3 install prometheus-client==0.19.0 watchdog==3.0.0

# Create results directory
RUN mkdir -p /results

# Copy exporter script
COPY exporter.py /usr/local/bin/exporter.py
RUN chmod +x /usr/local/bin/exporter.py

# Copy startup script
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

WORKDIR /root/ycsb-0.17.0

# Expose exporter port
EXPOSE 8000

# Run startup script that launches both services
CMD ["/usr/local/bin/start.sh"]