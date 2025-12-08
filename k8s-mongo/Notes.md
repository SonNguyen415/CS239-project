# see what pods are running
kubectl get pods

# Connect to the YCSB pod 
kubectl exec -it ycsb-interface-56cdb55444-4rxf7 -- /bin/bash

# Load phase 
~/ycsb-0.17.0/bin/ycsb.sh load mongodb -s -P ~/ycsb-0.17.0/workloads/workloada -p recordcount=1000 -p mongodb.url="mongodb://user-db:27017/users" -p mongodb.collection=usertable \ -p mongodb.upsert=true

# Run workload A - quick example
~/ycsb-0.17.0/bin/ycsb.sh run mongodb -s -P ~/ycsb-0.17.0/workloads/workloada \ -p operationcount=1000 \ -p mongodb.url="mongodb://user-db:27017/users" \ -p mongodb.collection=usertable

# Run workload B - quick example
~/ycsb-0.17.0/bin/ycsb.sh run mongodb -s -P ~/ycsb-0.17.0/workloads/workloadb \ -p operationcount=1000 \ -p mongodb.url="mongodb://user-db:27017/users" \ -p mongodb.collection=usertable  

# Run workload E - quick example
~/ycsb-0.17.0/bin/ycsb.sh run mongodb -s -P ~/ycsb-0.17.0/workloads/workloade \ -p operationcount=1000 \ -p mongodb.url="mongodb://user-db:27017/users" \ -p mongodb.collection=usertable

# Load phase 
~/ycsb-0.17.0/bin/ycsb.sh load mongodb -s -P ~/ycsb-0.17.0/workloads/workloadb -p recordcount=1000000 -p mongodb.url="mongodb://user-db:27017/users" -p mongodb.collection=usertable \ -p mongodb.upsert=true

# spike Test
~/ycsb-0.17.0/bin/ycsb.sh run mongodb -s -P ~/ycsb-0.17.0/workloads/workloadb -p operationcount=20000 -p target=10000 -p threadcount=1000 -p mongodb.url="mongodb://user-db:27017/users" -p mongodb.upsert=true

# stress test
~/ycsb-0.17.0/bin/ycsb.sh run mongodb -s -P ~/ycsb-0.17.0/workloads/workloadb \ -p operationcount=1000000 \ -p target=2000 \ -p mongodb.url="mongodb://user-db:27017/users" \ -p mongodb.collection=usertable \ -p threadcount=1000 \ -p mongodb.upsert=true

# Soak test
~/ycsb-0.17.0/bin/ycsb.sh run mongodb -s -P ~/ycsb-0.17.0/workloads/workloadb \
  -p operationcount=450000 \
  -p target=500 \
  -p threadcount=50 \
  -p mongodb.url="mongodb://user-db:27017/users" \
  -p mongodb.collection=usertable \ 
  -p mongodb.upsert=true

# Exec into user-db and manipulate the database
kubectl exec -it user-db-7f86694cb8-tzjgg  -- bash

# enter the mongo database and look at new usertable
mongo \
show dbs \
use users \
show collections \
db.usertable.find()

# drop usertable
mongo users --eval "db.usertable.drop()"
