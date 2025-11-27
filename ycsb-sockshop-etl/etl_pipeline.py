#!/usr/bin/env python3
"""
YCSB to Sock Shop Carts ETL Pipeline
Transforms YCSB benchmark data to Sock Shop microservices cart format
Supports workload phases: load, A, B, E
"""

import os
import sys
import time
import json
import random
import logging
from datetime import datetime
from typing import Dict, List, Optional
from pymongo import MongoClient
from pymongo.errors import ConnectionFailure, OperationFailure

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/app/logs/etl_pipeline.log'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)


class YCSBSockShopETL:
    """ETL Pipeline for transforming YCSB data to Sock Shop Carts format"""
    
    def __init__(self):
        """Initialize MongoDB connection and configuration"""
        # MongoDB configuration from environment
        self.mongo_host = os.getenv('MONGODB_HOST', 'localhost')
        self.mongo_port = int(os.getenv('MONGODB_PORT', 27017))
        self.database_name = os.getenv('MONGODB_DATABASE', 'carts-1')
        self.mongo_username = os.getenv('MONGODB_USERNAME', '')
        self.mongo_password = os.getenv('MONGODB_PASSWORD', '')
        
        # Workload configuration
        self.workload_type = os.getenv('YCSB_WORKLOAD', 'load')
        self.operation_count = int(os.getenv('OPERATION_COUNT', 1000))
        self.record_count = int(os.getenv('RECORD_COUNT', 1000))
        self.batch_size = int(os.getenv('BATCH_SIZE', 100))
        
        # Initialize MongoDB client
        self.client = None
        self.db = None
        self.carts_collection = None
        
        self._connect_mongodb()
        
    def _connect_mongodb(self):
        """Establish MongoDB connection with retry logic"""
        max_retries = 5
        retry_delay = 5
        
        for attempt in range(max_retries):
            try:
                # Build connection string
                if self.mongo_username and self.mongo_password:
                    connection_string = (
                        f'mongodb://{self.mongo_username}:{self.mongo_password}@'
                        f'{self.mongo_host}:{self.mongo_port}/'
                    )
                else:
                    connection_string = f'mongodb://{self.mongo_host}:{self.mongo_port}/'
                
                self.client = MongoClient(
                    connection_string,
                    serverSelectionTimeoutMS=5000
                )
                
                # Test connection
                self.client.admin.command('ping')
                
                # Set database and collection
                self.db = self.client[self.database_name]
                self.carts_collection = self.db['carts']
                
                logger.info(f"Connected to MongoDB at {self.mongo_host}:{self.mongo_port}")
                logger.info(f"Using database: {self.database_name}")
                return
                
            except (ConnectionFailure, OperationFailure) as e:
                logger.warning(
                    f"MongoDB connection attempt {attempt + 1}/{max_retries} failed: {e}"
                )
                if attempt < max_retries - 1:
                    logger.info(f"Retrying in {retry_delay} seconds...")
                    time.sleep(retry_delay)
                else:
                    logger.error("Failed to connect to MongoDB after maximum retries")
                    raise
    
    def extract_ycsb_data(self) -> List[Dict]:
        """
        Extract/Generate YCSB formatted data
        
        Returns:
            List of YCSB records with field0-field9 structure
        """
        logger.info(f"\n{'='*60}")
        logger.info(f"[EXTRACT] Generating {self.record_count} YCSB records...")
        logger.info(f"{'='*60}")
        
        ycsb_records = []
        
        for i in range(self.record_count):
            record = {
                '_id': f'user{i}',
                'field0': f'item-{i}-{random.randint(1000, 9999)}',
                'field1': str(random.randint(1, 10)),
                'field2': str(random.randint(1000, 10000)),
                'field3': f'item-{i}-{random.randint(2000, 9999)}',
                'field4': str(random.randint(1, 5)),
                'field5': str(random.randint(1500, 7500)),
                'field6': f'metadata-{i}',
                'field7': datetime.utcnow().isoformat(),
                'field8': f'tag-{random.choice(["electronics", "clothing", "books", "toys"])}',
                'field9': str(random.randint(0, 1))  # active flag
            }
            ycsb_records.append(record)
            
            # Log progress
            if (i + 1) % 100 == 0:
                logger.info(f"[EXTRACT] Generated {i + 1}/{self.record_count} records")
        
        logger.info(f"[EXTRACT] Successfully extracted {len(ycsb_records)} records")
        return ycsb_records
    
    def transform_to_carts(self, ycsb_records: List[Dict]) -> List[Dict]:
        """
        Transform YCSB records to Sock Shop cart format
        
        Args:
            ycsb_records: List of YCSB formatted records
            
        Returns:
            List of Sock Shop cart documents
        """
        logger.info(f"\n{'='*60}")
        logger.info(f"[TRANSFORM] Transforming {len(ycsb_records)} records to Carts format...")
        logger.info(f"{'='*60}")
        
        carts = []
        errors = 0
        
        for idx, record in enumerate(ycsb_records):
            try:
                # Extract and transform fields
                quantity1 = int(record.get('field1', '1'))
                price1 = float(record.get('field2', '1999')) / 100
                quantity2 = int(record.get('field4', '1'))
                price2 = float(record.get('field5', '2999')) / 100
                
                cart = {
                    '_id': record['_id'],
                    'customerId': record['_id'],
                    'items': [
                        {
                            'itemId': record.get('field0', f"item-{idx}-1"),
                            'quantity': quantity1,
                            'unitPrice': round(price1, 2)
                        },
                        {
                            'itemId': record.get('field3', f"item-{idx}-2"),
                            'quantity': quantity2,
                            'unitPrice': round(price2, 2)
                        }
                    ],
                    'metadata': {
                        'createdAt': datetime.utcnow().isoformat(),
                        'updatedAt': datetime.utcnow().isoformat(),
                        'source': 'ycsb-etl',
                        'workload': self.workload_type,
                        'originalFields': {
                            'field6': record.get('field6'),
                            'field7': record.get('field7'),
                            'field8': record.get('field8'),
                            'field9': record.get('field9')
                        }
                    }
                }
                
                carts.append(cart)
                
                # Log progress
                if (idx + 1) % 100 == 0:
                    logger.info(f"[TRANSFORM] Transformed {idx + 1}/{len(ycsb_records)} records")
                    
            except Exception as e:
                errors += 1
                logger.error(f"[TRANSFORM] Error transforming record {record.get('_id')}: {e}")
        
        logger.info(f"[TRANSFORM] Successfully transformed {len(carts)} records")
        if errors > 0:
            logger.warning(f"[TRANSFORM] Encountered {errors} errors during transformation")
        
        return carts
    
    def load_to_mongodb(self, carts: List[Dict]):
        """
        Load cart documents into MongoDB
        
        Args:
            carts: List of cart documents to insert
        """
        logger.info(f"\n{'='*60}")
        logger.info(f"[LOAD] Loading {len(carts)} records to MongoDB...")
        logger.info(f"{'='*60}")
        
        # Clear existing data for fresh load
        delete_result = self.carts_collection.delete_many({})
        logger.info(f"[LOAD] Cleared {delete_result.deleted_count} existing cart records")
        
        # Batch insert
        total_loaded = 0
        batch_count = 0
        
        for i in range(0, len(carts), self.batch_size):
            batch = carts[i:i + self.batch_size]
            
            try:
                insert_result = self.carts_collection.insert_many(batch)
                total_loaded += len(insert_result.inserted_ids)
                batch_count += 1
                logger.info(
                    f"[LOAD] Batch {batch_count}: Loaded {len(batch)} records "
                    f"({total_loaded}/{len(carts)})"
                )
            except Exception as e:
                logger.error(f"[LOAD] Error loading batch {batch_count}: {e}")
        
        logger.info(f"[LOAD] Successfully loaded {total_loaded} records to MongoDB")
        
        # Create indexes for performance
        self.carts_collection.create_index('customerId')
        logger.info("[LOAD] Created index on customerId")
    
    def _calculate_ycsb_metrics(self, stats: Dict, elapsed_time: float, workload: str) -> Dict:
        """Calculate YCSB-style benchmark metrics"""
        total_ops = sum([stats.get('reads', 0), stats.get('updates', 0), 
                        stats.get('scans', 0), stats.get('inserts', 0)])
        
        metrics = {
            'workload': workload,
            'runtime_seconds': round(elapsed_time, 2),
            'total_operations': total_ops,
            'throughput_ops_sec': round(total_ops / elapsed_time, 2),
            'operations': {
                'reads': stats.get('reads', 0),
                'updates': stats.get('updates', 0),
                'scans': stats.get('scans', 0),
                'inserts': stats.get('inserts', 0)
            },
            'errors': stats.get('errors', 0),
            'latency_ms': {}
        }
        
        # Calculate latency metrics for each operation type
        for op_type in ['read', 'update', 'scan', 'insert']:
            latencies_key = f'{op_type}_latencies'
            if latencies_key in stats and stats[latencies_key]:
                latencies = sorted(stats[latencies_key])
                n = len(latencies)
                
                metrics['latency_ms'][op_type] = {
                    'min': round(min(latencies), 2),
                    'max': round(max(latencies), 2),
                    'avg': round(sum(latencies) / n, 2),
                    'p50': round(latencies[int(n * 0.50)], 2),
                    'p95': round(latencies[int(n * 0.95)], 2),
                    'p99': round(latencies[int(n * 0.99)], 2),
                    'p999': round(latencies[int(n * 0.999)] if n > 1000 else latencies[-1], 2)
                }
        
        # Create summary string
        summary_parts = [
            f"Completed in {metrics['runtime_seconds']}s",
            f"Throughput: {metrics['throughput_ops_sec']} ops/sec",
            f"Total: {total_ops} ops"
        ]
        
        if metrics['operations']['reads'] > 0:
            summary_parts.append(f"Reads: {metrics['operations']['reads']}")
        if metrics['operations']['updates'] > 0:
            summary_parts.append(f"Updates: {metrics['operations']['updates']}")
        if metrics['operations']['scans'] > 0:
            summary_parts.append(f"Scans: {metrics['operations']['scans']}")
        if metrics['operations']['inserts'] > 0:
            summary_parts.append(f"Inserts: {metrics['operations']['inserts']}")
        if metrics['errors'] > 0:
            summary_parts.append(f"Errors: {metrics['errors']}")
            
        metrics['summary'] = ", ".join(summary_parts)
        
        return metrics
    
    def run_workload_a(self) -> Dict:
        """
        Execute YCSB Workload A: Update Heavy
        50% reads, 50% updates
        
        Returns:
            Dictionary with operation statistics
        """
        logger.info(f"\n{'='*60}")
        logger.info(f"[WORKLOAD A] Running update-heavy workload")
        logger.info(f"[WORKLOAD A] Operations: {self.operation_count}")
        logger.info(f"[WORKLOAD A] Distribution: 50% reads, 50% updates")
        logger.info(f"{'='*60}")
        
        stats = {
            'reads': 0, 
            'updates': 0, 
            'errors': 0, 
            'read_latencies': [],
            'update_latencies': []
        }
        
        # Get sample user IDs
        user_ids = [
            doc['_id'] 
            for doc in self.carts_collection.find({}, {'_id': 1}).limit(100)
        ]
        
        if not user_ids:
            logger.error("[WORKLOAD A] No carts found in database!")
            return stats
        
        start_time = time.time()
        
        for i in range(self.operation_count):
            op_start = time.time()
            
            try:
                if random.random() < 0.5:
                    # Read operation
                    user_id = random.choice(user_ids)
                    self.carts_collection.find_one({'_id': user_id})
                    latency = (time.time() - op_start) * 1000
                    stats['read_latencies'].append(latency)
                    stats['reads'] += 1
                else:
                    # Update operation
                    user_id = random.choice(user_ids)
                    new_qty = random.randint(1, 10)
                    self.carts_collection.update_one(
                        {'_id': user_id},
                        {
                            '$set': {
                                'items.0.quantity': new_qty,
                                'metadata.updatedAt': datetime.utcnow().isoformat()
                            }
                        }
                    )
                    latency = (time.time() - op_start) * 1000
                    stats['update_latencies'].append(latency)
                    stats['updates'] += 1
                    
            except Exception as e:
                stats['errors'] += 1
                logger.error(f"[WORKLOAD A] Operation error: {e}")
            
            # Progress logging
            if (i + 1) % 1000 == 0:
                logger.info(f"[WORKLOAD A] Progress: {i+1}/{self.operation_count} ops")
        
        elapsed_time = time.time() - start_time
        
        # Calculate YCSB-style metrics
        metrics = self._calculate_ycsb_metrics(stats, elapsed_time, 'A')
        logger.info(f"[WORKLOAD A] {metrics['summary']}")
        
        return metrics
    
    def run_workload_b(self) -> Dict:
        """
        Execute YCSB Workload B: Read Heavy
        95% reads, 5% updates
        
        Returns:
            Dictionary with operation statistics
        """
        logger.info(f"\n{'='*60}")
        logger.info(f"[WORKLOAD B] Running read-heavy workload")
        logger.info(f"[WORKLOAD B] Operations: {self.operation_count}")
        logger.info(f"[WORKLOAD B] Distribution: 95% reads, 5% updates")
        logger.info(f"{'='*60}")
        
        stats = {
            'reads': 0, 
            'updates': 0, 
            'errors': 0,
            'read_latencies': [],
            'update_latencies': []
        }
        
        user_ids = [
            doc['_id'] 
            for doc in self.carts_collection.find({}, {'_id': 1}).limit(100)
        ]
        
        if not user_ids:
            logger.error("[WORKLOAD B] No carts found in database!")
            return stats
        
        start_time = time.time()
        
        for i in range(self.operation_count):
            op_start = time.time()
            
            try:
                if random.random() < 0.95:
                    # Read operation
                    user_id = random.choice(user_ids)
                    self.carts_collection.find_one({'_id': user_id})
                    latency = (time.time() - op_start) * 1000
                    stats['read_latencies'].append(latency)
                    stats['reads'] += 1
                else:
                    # Update operation
                    user_id = random.choice(user_ids)
                    new_qty = random.randint(1, 10)
                    self.carts_collection.update_one(
                        {'_id': user_id},
                        {
                            '$set': {
                                'items.0.quantity': new_qty,
                                'metadata.updatedAt': datetime.utcnow().isoformat()
                            }
                        }
                    )
                    latency = (time.time() - op_start) * 1000
                    stats['update_latencies'].append(latency)
                    stats['updates'] += 1
                    
            except Exception as e:
                stats['errors'] += 1
                logger.error(f"[WORKLOAD B] Operation error: {e}")
            
            if (i + 1) % 1000 == 0:
                logger.info(f"[WORKLOAD B] Progress: {i+1}/{self.operation_count} ops")
        
        elapsed_time = time.time() - start_time
        metrics = self._calculate_ycsb_metrics(stats, elapsed_time, 'B')
        logger.info(f"[WORKLOAD B] {metrics['summary']}")
        
        return metrics
    
    def run_workload_e(self) -> Dict:
        """
        Execute YCSB Workload E: Scan Heavy
        95% scans, 5% inserts
        
        Returns:
            Dictionary with operation statistics
        """
        logger.info(f"\n{'='*60}")
        logger.info(f"[WORKLOAD E] Running scan-heavy workload")
        logger.info(f"[WORKLOAD E] Operations: {self.operation_count}")
        logger.info(f"[WORKLOAD E] Distribution: 95% scans, 5% inserts")
        logger.info(f"{'='*60}")
        
        stats = {
            'scans': 0, 
            'inserts': 0, 
            'errors': 0,
            'scan_latencies': [],
            'insert_latencies': []
        }
        
        start_time = time.time()
        
        for i in range(self.operation_count):
            op_start = time.time()
            
            try:
                if random.random() < 0.95:
                    # Scan operation
                    limit = random.randint(1, 20)
                    list(self.carts_collection.find({}).limit(limit))
                    latency = (time.time() - op_start) * 1000
                    stats['scan_latencies'].append(latency)
                    stats['scans'] += 1
                else:
                    # Insert operation
                    timestamp = int(time.time() * 1000)
                    new_cart = {
                        '_id': f'user{timestamp}_{i}',
                        'customerId': f'user{timestamp}_{i}',
                        'items': [
                            {
                                'itemId': f'item-{timestamp}-{i}',
                                'quantity': random.randint(1, 5),
                                'unitPrice': round(random.uniform(10.0, 50.0), 2)
                            }
                        ],
                        'metadata': {
                            'createdAt': datetime.utcnow().isoformat(),
                            'updatedAt': datetime.utcnow().isoformat(),
                            'source': 'workload-e',
                            'workload': 'e'
                        }
                    }
                    self.carts_collection.insert_one(new_cart)
                    latency = (time.time() - op_start) * 1000
                    stats['insert_latencies'].append(latency)
                    stats['inserts'] += 1
                    
            except Exception as e:
                stats['errors'] += 1
                logger.error(f"[WORKLOAD E] Operation error: {e}")
            
            if (i + 1) % 1000 == 0:
                logger.info(f"[WORKLOAD E] Progress: {i+1}/{self.operation_count} ops")
        
        elapsed_time = time.time() - start_time
        metrics = self._calculate_ycsb_metrics(stats, elapsed_time, 'E')
        logger.info(f"[WORKLOAD E] {metrics['summary']}")
        
        return metrics
    
    def export_results(self, stats: Optional[Dict] = None):
        """
        Export results to JSON file
        
        Args:
            stats: Optional workload statistics to include
        """
        results = {
            'timestamp': datetime.utcnow().isoformat(),
            'configuration': {
                'workload_type': self.workload_type,
                'operation_count': self.operation_count,
                'record_count': self.record_count,
                'batch_size': self.batch_size
            },
            'database': {
                'host': self.mongo_host,
                'port': self.mongo_port,
                'database': self.database_name
            }
        }
        
        if stats:
            results['statistics'] = stats
        
        # Save to file
        filename = f'/app/data/results_{self.workload_type}_{int(time.time())}.json'
        with open(filename, 'w') as f:
            json.dump(results, f, indent=2)
        
        logger.info(f"Results exported to {filename}")
    
    def run_pipeline(self):
        """Execute the complete ETL pipeline with selected workload"""
        pipeline_start = time.time()
        
        logger.info("="*60)
        logger.info("YCSB to Sock Shop Carts ETL Pipeline")
        logger.info("="*60)
        logger.info(f"Workload: {self.workload_type.upper()}")
        logger.info(f"Records: {self.record_count}")
        logger.info(f"Operations: {self.operation_count}")
        logger.info("="*60)
        
        try:
            # Phase 1: Extract
            ycsb_data = self.extract_ycsb_data()
            
            # Phase 2: Transform
            carts_data = self.transform_to_carts(ycsb_data)
            
            # Phase 3: Load
            self.load_to_mongodb(carts_data)
            
            # Phase 4: Run workload simulation
            workload_stats = None
            
            if self.workload_type == 'a':
                workload_stats = self.run_workload_a()
            elif self.workload_type == 'b':
                workload_stats = self.run_workload_b()
            elif self.workload_type == 'e':
                workload_stats = self.run_workload_e()
            elif self.workload_type == 'load':
                logger.info("[LOAD] Skipping workload simulation for load phase")
            else:
                logger.warning(f"[PIPELINE] Unknown workload type: {self.workload_type}")
            
            # Export results
            self.export_results(workload_stats)
            
            pipeline_duration = time.time() - pipeline_start
            
            logger.info("\n" + "="*60)
            logger.info("Pipeline completed successfully!")
            logger.info(f"Total duration: {pipeline_duration:.2f} seconds")
            logger.info("="*60)
            
        except Exception as e:
            logger.error(f"Pipeline failed: {e}", exc_info=True)
            raise
        finally:
            if self.client:
                self.client.close()
                logger.info("MongoDB connection closed")


def main():
    """Main entry point"""
    try:
        etl = YCSBSockShopETL()
        etl.run_pipeline()
        sys.exit(0)
    except Exception as e:
        logger.error(f"Fatal error: {e}", exc_info=True)
        sys.exit(1)


if __name__ == '__main__':
    main()