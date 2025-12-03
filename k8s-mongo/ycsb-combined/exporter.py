#!/usr/bin/env python3
import re
import time
import os
import sys
from prometheus_client import start_http_server, Gauge, Counter
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

# Define Prometheus metrics
read_latency_avg = Gauge('ycsb_read_latency_avg_us', 'Average READ latency in microseconds')
read_latency_min = Gauge('ycsb_read_latency_min_us', 'Minimum READ latency in microseconds')
read_latency_max = Gauge('ycsb_read_latency_max_us', 'Maximum READ latency in microseconds')
read_latency_p95 = Gauge('ycsb_read_latency_95th_us', '95th percentile READ latency in microseconds')
read_latency_p99 = Gauge('ycsb_read_latency_99th_us', '99th percentile READ latency in microseconds')

update_latency_avg = Gauge('ycsb_update_latency_avg_us', 'Average UPDATE latency in microseconds')
update_latency_min = Gauge('ycsb_update_latency_min_us', 'Minimum UPDATE latency in microseconds')
update_latency_max = Gauge('ycsb_update_latency_max_us', 'Maximum UPDATE latency in microseconds')
update_latency_p95 = Gauge('ycsb_update_latency_95th_us', '95th percentile UPDATE latency in microseconds')
update_latency_p99 = Gauge('ycsb_update_latency_99th_us', '99th percentile UPDATE latency in microseconds')

read_ops = Counter('ycsb_read_operations_total', 'Total READ operations')
update_ops = Counter('ycsb_update_operations_total', 'Total UPDATE operations')

throughput = Gauge('ycsb_throughput_ops_sec', 'Overall throughput in ops/sec')
runtime = Gauge('ycsb_runtime_ms', 'Total runtime in milliseconds')

class YCSBLogHandler(FileSystemEventHandler):
    def __init__(self, log_file):
        self.log_file = log_file
        self.file_pos = 0
        
    def on_modified(self, event):
        if event.src_path.endswith(os.path.basename(self.log_file)):
            self.parse_log()
    
    def parse_log(self):
        try:
            if not os.path.exists(self.log_file):
                return
                
            with open(self.log_file, 'r') as f:
                f.seek(self.file_pos)
                lines = f.readlines()
                self.file_pos = f.tell()
                
                for line in lines:
                    self.parse_line(line)
        except Exception as e:
            print(f"Error parsing log: {e}")
    
    def parse_line(self, line):
        # Parse YCSB output format
        # Example: [READ], AverageLatency(us), 1234.56
        
        if '[READ]' in line:
            if 'AverageLatency(us)' in line:
                match = re.search(r'AverageLatency\(us\),\s*([\d.]+)', line)
                if match:
                    read_latency_avg.set(float(match.group(1)))
            elif 'MinLatency(us)' in line:
                match = re.search(r'MinLatency\(us\),\s*([\d.]+)', line)
                if match:
                    read_latency_min.set(float(match.group(1)))
            elif 'MaxLatency(us)' in line:
                match = re.search(r'MaxLatency\(us\),\s*([\d.]+)', line)
                if match:
                    read_latency_max.set(float(match.group(1)))
            elif '95thPercentileLatency(us)' in line:
                match = re.search(r'95thPercentileLatency\(us\),\s*([\d.]+)', line)
                if match:
                    read_latency_p95.set(float(match.group(1)))
            elif '99thPercentileLatency(us)' in line:
                match = re.search(r'99thPercentileLatency\(us\),\s*([\d.]+)', line)
                if match:
                    read_latency_p99.set(float(match.group(1)))
            elif 'Operations,' in line:
                match = re.search(r'Operations,\s*([\d]+)', line)
                if match:
                    read_ops._value.set(float(match.group(1)))
        
        elif '[UPDATE]' in line:
            if 'AverageLatency(us)' in line:
                match = re.search(r'AverageLatency\(us\),\s*([\d.]+)', line)
                if match:
                    update_latency_avg.set(float(match.group(1)))
            elif 'MinLatency(us)' in line:
                match = re.search(r'MinLatency\(us\),\s*([\d.]+)', line)
                if match:
                    update_latency_min.set(float(match.group(1)))
            elif 'MaxLatency(us)' in line:
                match = re.search(r'MaxLatency\(us\),\s*([\d.]+)', line)
                if match:
                    update_latency_max.set(float(match.group(1)))
            elif '95thPercentileLatency(us)' in line:
                match = re.search(r'95thPercentileLatency\(us\),\s*([\d.]+)', line)
                if match:
                    update_latency_p95.set(float(match.group(1)))
            elif '99thPercentileLatency(us)' in line:
                match = re.search(r'99thPercentileLatency\(us\),\s*([\d.]+)', line)
                if match:
                    update_latency_p99.set(float(match.group(1)))
            elif 'Operations,' in line:
                match = re.search(r'Operations,\s*([\d]+)', line)
                if match:
                    update_ops._value.set(float(match.group(1)))
        
        elif '[OVERALL]' in line:
            if 'Throughput(ops/sec)' in line:
                match = re.search(r'Throughput\(ops/sec\),\s*([\d.]+)', line)
                if match:
                    throughput.set(float(match.group(1)))
            elif 'RunTime(ms)' in line:
                match = re.search(r'RunTime\(ms\),\s*([\d.]+)', line)
                if match:
                    runtime.set(float(match.group(1)))

def main():
    # Start Prometheus metrics server
    start_http_server(8000)
    print("YCSB Exporter started on port 8000", flush=True)
    sys.stdout.flush()
    
    # Watch for YCSB output files
    log_file = '/results/ycsb_output.txt'
    
    # Create results directory if it doesn't exist
    os.makedirs('/results', exist_ok=True)
    
    # Create a placeholder file
    if not os.path.exists(log_file):
        with open(log_file, 'w') as f:
            f.write("# Waiting for YCSB results...\n")
    
    handler = YCSBLogHandler(log_file)
    observer = Observer()
    observer.schedule(handler, path='/results', recursive=False)
    observer.start()
    
    print(f"Watching for YCSB results in {log_file}", flush=True)
    sys.stdout.flush()
    
    try:
        while True:
            time.sleep(1)
            handler.parse_log()
    except KeyboardInterrupt:
        observer.stop()
    
    observer.join()

if __name__ == '__main__':
    main()