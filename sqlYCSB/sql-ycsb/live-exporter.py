#!/usr/bin/env python3
import re
import sys
import time
import threading
import prometheus_client

class YCSBExporter:
    TIMEOUT = 20  # seconds since last metric update before resetting
    OP_TYPES = ['INSERT', 'READ', 'UPDATE', 'DELETE', 'CLEANUP']  # adjust as needed

    def __init__(self):
        # Metrics
        self.current_ops_sec = prometheus_client.Gauge('ycsb_live_current_ops_sec', 'Current operations per second')
        self.total_operations = prometheus_client.Gauge('ycsb_live_total_operations', 'Total operations completed')
        self.elapsed_time_sec = prometheus_client.Gauge('ycsb_live_elapsed_time_sec', 'Elapsed time in seconds')

        self.op_count = prometheus_client.Gauge('ycsb_live_op_count', 'Operation count by type', ['op_type'])
        self.op_avg = prometheus_client.Gauge('ycsb_live_op_avg_us', 'Average latency by type', ['op_type'])
        self.op_min = prometheus_client.Gauge('ycsb_live_op_min_us', 'Min latency by type', ['op_type'])
        self.op_max = prometheus_client.Gauge('ycsb_live_op_max_us', 'Max latency by type', ['op_type'])
        self.op_p90 = prometheus_client.Gauge('ycsb_live_op_p90_us', '90th percentile latency by type', ['op_type'])
        self.op_p99 = prometheus_client.Gauge('ycsb_live_op_p99_us', '99th percentile latency by type', ['op_type'])
        self.op_p999 = prometheus_client.Gauge('ycsb_live_op_p999_us', '99.9th percentile latency by type', ['op_type'])
        self.op_p9999 = prometheus_client.Gauge('ycsb_live_op_p9999_us', '99.99th percentile latency by type', ['op_type'])

        # State
        self.last_update = None
        self.lock = threading.Lock()

    def parse_line(self, line):
        """Parse a line from YCSB stdout."""
        now = time.time()
        with self.lock:
            parsed = False

            # Extract main metrics
            time_match = re.search(r'(\d+) sec: (\d+) operations; ([\d.]+) current ops/sec', line)
            if time_match:
                elapsed = int(time_match.group(1))
                total_ops = int(time_match.group(2))
                current_ops = float(time_match.group(3))

                self.elapsed_time_sec.set(elapsed)
                self.total_operations.set(total_ops)
                self.current_ops_sec.set(current_ops)
                parsed = True

            # Extract per-op metrics
            op_pattern = r'\[(\w+): Count=(\d+), Max=([\d.]+), Min=([\d.]+), Avg=([\d.]+), 90=([\d.]+), 99=([\d.]+), 99\.9=([\d.]+), 99\.99=([\d.]+)\]'
            for match in re.finditer(op_pattern, line):
                op_type = match.group(1)
                self.op_count.labels(op_type=op_type).set(int(match.group(2)))
                self.op_max.labels(op_type=op_type).set(float(match.group(3)))
                self.op_min.labels(op_type=op_type).set(float(match.group(4)))
                self.op_avg.labels(op_type=op_type).set(float(match.group(5)))
                self.op_p90.labels(op_type=op_type).set(float(match.group(6)))
                self.op_p99.labels(op_type=op_type).set(float(match.group(7)))
                self.op_p999.labels(op_type=op_type).set(float(match.group(8)))
                self.op_p9999.labels(op_type=op_type).set(float(match.group(9)))
                parsed = True
                print(f"[{time.strftime('%H:%M:%S')}] Metrics updated for op_type={op_type}", file=sys.stderr)

            # Update last_update only if we successfully parsed a line
            if parsed:
                self.last_update = now

    def _reset_metrics_periodically(self):
        """Background thread: reset metrics to 0 if no new data arrives."""
        while True:
            time.sleep(2)  # check every 2 seconds
            now = time.time()
            with self.lock:
                if self.last_update is None:
                    continue
                if now - self.last_update > self.TIMEOUT:
                    # Reset all metrics
                    self.current_ops_sec.set(0)
                    self.total_operations.set(0)
                    self.elapsed_time_sec.set(0)
                    for op_type in self.OP_TYPES:
                        self.op_count.labels(op_type=op_type).set(0)
                        self.op_avg.labels(op_type=op_type).set(0)
                        self.op_min.labels(op_type=op_type).set(0)
                        self.op_max.labels(op_type=op_type).set(0)
                        self.op_p90.labels(op_type=op_type).set(0)
                        self.op_p99.labels(op_type=op_type).set(0)
                        self.op_p999.labels(op_type=op_type).set(0)
                        self.op_p9999.labels(op_type=op_type).set(0)

                    print(f"[{time.strftime('%H:%M:%S')}] Metrics reset due to timeout", file=sys.stderr)

if __name__ == '__main__':
    exporter = YCSBExporter()
    prometheus_client.start_http_server(8001)
    print("Live YCSB Exporter started on port 8001", file=sys.stderr, flush=True)

    # Start background thread for resetting metrics
    reset_thread = threading.Thread(target=exporter._reset_metrics_periodically, daemon=True)
    reset_thread.start()

    try:
        for line in sys.stdin:
            line = line.strip()
            if line:
                exporter.parse_line(line)
    except KeyboardInterrupt:
        print("\nShutting down...", file=sys.stderr)
