# see what pods are running
kubectl get pods

# Connect to the YCSB pod 
kubectl exec -it ycsb-interface-56cdb55444-vh7xm -- /bin/bash

# Load phase 
~/ycsb-0.17.0/bin/ycsb.sh load mongodb -s -P ~/ycsb-0.17.0/workloads/iworkload -p recordcount=100000 -p mongodb.url="mongodb://user-db:27017/users" -p mongodb.collection=usertable

# Run workload A - quick example
~/ycsb-0.17.0/bin/ycsb.sh run mongodb -s -P ~/ycsb-0.17.0/workloads/workloada \ -p operationcount=1000 \ -p mongodb.url="mongodb://user-db:27017/users" \ -p mongodb.collection=usertable | tee -a /results/ycsb_output.txt 

# Run workload B - quick example
~/ycsb-0.17.0/bin/ycsb.sh run mongodb -s -P ~/ycsb-0.17.0/workloads/workloadb \ -p operationcount=1000 \ -p mongodb.url="mongodb://user-db:27017/users" \ -p mongodb.collection=usertable | tee -a /results/ycsb_output.txt 

# Run workload E - quick example
~/ycsb-0.17.0/bin/ycsb.sh run mongodb -s -P ~/ycsb-0.17.0/workloads/workloade \ -p operationcount=1000 \ -p mongodb.url="mongodb://user-db:27017/users" \ -p mongodb.collection=usertable | tee -a /results/ycsb_output.txt

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

