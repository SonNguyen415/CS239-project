#!/usr/bin/env python3
"""
Latency-Based Vertical Pod Autoscaler
Scales pod resources based on YCSB latency metrics from Prometheus
"""

import time
import logging
import requests
from kubernetes import client, config
from kubernetes.client.rest import ApiException
from enum import Enum

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)
class ScalingPolicy(Enum):
    P90 = "max(ycsb_live_op_p90_us)"
    AVG = "sum(ycsb_live_op_avg_us * ycsb_live_op_count) / sum(ycsb_live_op_count)"
    MAX = "max(ycsb_live_op_max_us)"

    @property
    def prom_query(self):
        return self.value

# Scaling factors - set by policy / arguments
SCALE_UP_FACTOR = 1.5
SCALE_DOWN_FACTOR = 0.8
RESOURCE_LIMIT_FACTOR = 1.2

# Resource bounds - this doesn't matter will be set  
MIN_CPU = "50m"
MAX_CPU = "200m"
MIN_MEMORY = "64Mi"
MAX_MEMORY = "256Mi"

# Cooldown period (seconds)
COOLDOWN_PERIOD = 30 # for testing

class LatencyBasedVPA:
    def __init__(self, prometheus_url, namespace="default", check_interval=30):
        try:
            config.load_incluster_config()
        except:
            config.load_kube_config()
        
        self.apps_v1 = client.AppsV1Api()
        self.namespace = namespace
        self.check_interval = check_interval
        self.prometheus_url = prometheus_url.rstrip('/')

        self.policy = ScalingPolicy.MAX # Default policy
        
        # Latency thresholds (microseconds)
        self.scale_up_threshold = 2000  # 2ms in us
        self.scale_down_threshold = 1000  # 1ms in us
        
        self.last_scale_time = 0
        
    def query_prometheus(self, query):
        try:
            url = f"{self.prometheus_url}/api/v1/query"
            response = requests.get(url, params={'query': query}, timeout=10)
            response.raise_for_status()
            
            data = response.json()
            if data['status'] == 'success' and data['data']['result']:
                return float(data['data']['result'][0]['value'][1])
            return None
        except Exception as e:
            logger.error(f"Error querying Prometheus: {e}")
            return None
    
    def get_latency_metric(self, deployment_name):
        """Get latency in microseconds from YCSB metrics - monitors ALL operations"""

        QUERY_MAP = {
            ScalingPolicy.P90: (
                "max(ycsb_live_op_p90_us)",
                "p90_all_ops",
            ),
            ScalingPolicy.AVG: (
                "sum(ycsb_live_op_avg_us * ycsb_live_op_count) / sum(ycsb_live_op_count)",
                "avg_all_ops",
            ),
            ScalingPolicy.MAX: (
                "max(ycsb_live_op_max_us)",
                "max_all_ops",
            ),
        }

        if self.policy not in QUERY_MAP:
            raise ValueError(f"Unsupported scaling policy: {self.policy}")

        query, metric_name = QUERY_MAP[self.policy]
        value = self.query_prometheus(query)
        return (value, metric_name) if value is not None else (None, None)

    
    def _parse_cpu(self, cpu_str):
        """Parse CPU string to millicores"""
        if cpu_str.endswith('m'):
            return int(cpu_str[:-1])
        return int(float(cpu_str) * 1000)
    
    def _parse_memory(self, memory_str):
        """Parse memory string to Mi"""
        units = {'Ki': 1/1024, 'Mi': 1, 'Gi': 1024}
        for unit, multiplier in units.items():
            if memory_str.endswith(unit):
                return int(memory_str[:-len(unit)]) * multiplier
        return int(memory_str) / (1024 * 1024)
    
    def _format_cpu(self, millicores):
        return f"{int(millicores)}m"
    
    def _format_memory(self, mi):
        if mi >= 1024:
            return f"{int(mi/1024)}Gi"
        return f"{int(mi)}Mi"
    
    def calculate_new_resources(self, latency_us, current_cpu, current_memory):
        logger.info(f"Current resources - CPU: {current_cpu}m, Memory: {current_memory}Mi")
        
        # Check cooldown
        time_since_last_scale = time.time() - self.last_scale_time
        if time_since_last_scale < COOLDOWN_PERIOD:
            remaining = int(COOLDOWN_PERIOD - time_since_last_scale)
            return current_cpu, current_memory, "cooldown", f"Cooldown: {remaining}s left"
        
        # Determine scaling action
        if latency_us > self.scale_up_threshold:
            new_cpu = current_cpu * SCALE_UP_FACTOR
            new_memory = current_memory * SCALE_UP_FACTOR
            action = "scale_up"
            reason = f"High latency: {latency_us:.0f}us > {self.scale_up_threshold}us"
        elif latency_us < self.scale_down_threshold:
            new_cpu = current_cpu * SCALE_DOWN_FACTOR
            new_memory = current_memory * SCALE_DOWN_FACTOR
            action = "scale_down"
            reason = f"Low latency: {latency_us:.0f}us < {self.scale_down_threshold}us"
        else:
            return current_cpu, current_memory, "no_change", f"Latency OK: {latency_us:.0f}us"
        
        # Apply bounds
        min_cpu = self._parse_cpu(MIN_CPU)
        max_cpu = self._parse_cpu(MAX_CPU)
        min_mem = self._parse_memory(MIN_MEMORY)
        max_mem = self._parse_memory(MAX_MEMORY)
        
        new_cpu = max(min_cpu, min(max_cpu, new_cpu))
        new_memory = max(min_mem, min(max_mem, new_memory))
        
        self.last_scale_time = time.time()
        return new_cpu, new_memory, action, reason
    
    def update_deployment_resources(self, deployment_name, container_name, new_cpu, new_memory):
        try:
            deployment = self.apps_v1.read_namespaced_deployment(
                name=deployment_name, namespace=self.namespace
            )
            
            updated = False
            for container in deployment.spec.template.spec.containers:
                if container.name == container_name:
                    container.resources.requests['cpu'] = self._format_cpu(new_cpu)
                    container.resources.requests['memory'] = self._format_memory(new_memory)
                    container.resources.limits['cpu'] = self._format_cpu(new_cpu * RESOURCE_LIMIT_FACTOR)
                    container.resources.limits['memory'] = self._format_memory(new_memory * RESOURCE_LIMIT_FACTOR)
                    updated = True
                    break
            
            if not updated:
                logger.error(f"Container {container_name} not found")
                return False
            
            self.apps_v1.patch_namespaced_deployment(
                name=deployment_name, namespace=self.namespace, body=deployment
            )
            
            logger.info(f"✓ Updated {deployment_name}: CPU={self._format_cpu(new_cpu)}, Memory={self._format_memory(new_memory)}")
            return True
            
        except Exception as e:
            logger.error(f"Error updating deployment: {e}")
            return False
    
    def get_current_resources(self, deployment_name, container_name):
        try:
            deployment = self.apps_v1.read_namespaced_deployment(
                name=deployment_name, namespace=self.namespace
            )
            
            for container in deployment.spec.template.spec.containers:
                if container.name == container_name:
                    cpu = self._parse_cpu(container.resources.requests.get('cpu', MIN_CPU))
                    memory = self._parse_memory(container.resources.requests.get('memory', MIN_MEMORY))
                    return cpu, memory
            
            return None, None
        except Exception as e:
            logger.error(f"Error reading deployment: {e}")
            return None, None
    
    def monitor_and_scale(self, deployment_name, container_name):
        while True:
            try:
                logger.info(f"\n{'='*60}")
                logger.info(f"Checking {deployment_name} at {time.strftime('%H:%M:%S')}")
                
                latency_us, metric_name = self.get_latency_metric(deployment_name)
                if latency_us is None:
                    logger.warning("No YCSB latency metrics found")
                    time.sleep(self.check_interval)
                    continue
                
                logger.info(f"Latency ({metric_name}): {latency_us:.0f}us")
                
                current_cpu, current_memory = self.get_current_resources(deployment_name, container_name)
                if current_cpu is None:
                    time.sleep(self.check_interval)
                    continue
                
                new_cpu, new_memory, action, reason = self.calculate_new_resources(
                    latency_us, current_cpu, current_memory
                )
                
                if action in ["scale_up", "scale_down"]:
                    logger.info(f"Action: {action.upper()} - {reason}")
                    self.update_deployment_resources(deployment_name, container_name, new_cpu, new_memory)
                else:
                    logger.info(f"Status: {reason}")
                
                time.sleep(self.check_interval)
                
            except KeyboardInterrupt:
                logger.info("\nShutting down VPA...")
                break
            except Exception as e:
                logger.error(f"Error in monitoring loop: {e}")
                time.sleep(self.check_interval)


if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description='Latency-Based VPA')
    parser.add_argument('--prometheus-url', required=True)
    parser.add_argument('--deployment', required=True)
    parser.add_argument('--container', required=True)
    parser.add_argument('--policy', choices=['p90', 'avg', 'max'], default='max')
    parser.add_argument('--namespace', default='default')
    parser.add_argument('--interval', type=int, default=30)
    parser.add_argument('--scale-up-threshold', type=float, default=300000, help='Scale up threshold in microseconds')
    parser.add_argument('--scale-down-threshold', type=float, default=100000, help='Scale down threshold in microseconds')
    
    args = parser.parse_args()
    
    vpa = LatencyBasedVPA(
        prometheus_url=args.prometheus_url,
        namespace=args.namespace,
        check_interval=args.interval
    )
    
    vpa.scale_up_threshold = args.scale_up_threshold
    vpa.scale_down_threshold = args.scale_down_threshold
    vpa.policy = ScalingPolicy[args.policy.upper()]
    vpa.monitor_and_scale(args.deployment, args.container)