FROM ubuntu:20.04
ENV DEBIAN_FRONTEND=noninteractive

# 1. Install dependencies
RUN apt-get update && apt-get install -y \
    openjdk-8-jdk \
    python2 \
    mysql-client \
    mongodb-clients \
    netcat \
    wget \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# 2. Manually download MySQL Connector/J
RUN mkdir -p /usr/share/java && \
    wget https://repo1.maven.org/maven2/mysql/mysql-connector-java/8.0.30/mysql-connector-java-8.0.30.jar -O /usr/share/java/mysql-connector-java.jar

# 3. Fix Python 2 symlink (Required for YCSB)
RUN ln -s /usr/bin/python2 /usr/bin/python

# 4. Create workspace directory (separate from YCSB mount point)
RUN mkdir -p /workspace/results

# 5. Copy scripts and source files to workspace
COPY auto_benchmark_all.sh /usr/local/bin/
COPY generate_report.py /usr/local/bin/
COPY custom_clients/ /workspace/custom_clients/
COPY compile_and_run_custom.sh /workspace/compile_and_run_custom.sh

RUN chmod +x /usr/local/bin/auto_benchmark_all.sh /workspace/compile_and_run_custom.sh

WORKDIR /workspace

# YCSB will be mounted at runtime to /ycsb-mounted (read-only)
# Workspace at /workspace contains our custom code

CMD ["/bin/bash"]