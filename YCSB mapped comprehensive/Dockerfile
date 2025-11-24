FROM ubuntu:20.04
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies: Java 8 (YCSB), Python 2 (Scripts), DB Clients, Netcat
RUN apt-get update && apt-get install -y \
    openjdk-8-jdk \
    python2 \
    mysql-client \
    mongodb-clients \
    netcat \
    wget \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# Fix: Symlink python2 to python (Required for YCSB)
RUN ln -s /usr/bin/python2 /usr/bin/python

WORKDIR /ycsb

# Copy logic scripts
COPY auto_benchmark_all.sh /usr/local/bin/
COPY generate_report.py /usr/local/bin/

# Make them executable
RUN chmod +x /usr/local/bin/auto_benchmark_all.sh

# Default command (can be overridden)
CMD ["/bin/bash"]