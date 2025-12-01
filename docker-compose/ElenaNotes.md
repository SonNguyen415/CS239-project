# inside ycsb_interface
# Target a specific database and add collection usertable (ycsb standard)
# Load phase (you can use workload a,b,e or iworkload interchangeably)
~/ycsb-0.17.0/bin/ycsb.sh load mongodb -s -P ~/ycsb-0.17.0/workloads/iworkload -p recordcount=1000 -p mongodb.url="mongodb://user-db:27017/users" -p mongodb.collection=usertable
# Run workload A - copy from code not preview
~/ycsb-0.17.0/bin/ycsb.sh run mongodb -s -P ~/ycsb-0.17.0/workloads/workloada \
  -p operationcount=1000 \
  -p mongodb.url="mongodb://user-db:27017/users" \
  -p mongodb.collection=usertable | tee -a /results/ycsb_output.txt
# Run workload B - copy from code not preview
~/ycsb-0.17.0/bin/ycsb.sh run mongodb -s -P ~/ycsb-0.17.0/workloads/workloadb \
  -p operationcount=1000 \
  -p mongodb.url="mongodb://user-db:27017/users" \
  -p mongodb.collection=usertable | tee -a /results/ycsb_output.txt
# Run workload E - copy from code not preview
~/ycsb-0.17.0/bin/ycsb.sh run mongodb -s -P ~/ycsb-0.17.0/workloads/workloade \
  -p operationcount=1000 \
  -p mongodb.url="mongodb://user-db:27017/users" \
  -p mongodb.collection=usertable | tee -a /results/ycsb_output.txt

# inside users-db (new name for docker-compose-db-1)
# look at new usertable
mongo \
show dbs \
use users \
show collections \
db.usertable.find()
# drop usertable
mongo users --eval "db.usertable.drop()"



# This command worked kinda -deprecated
~/ycsb-0.17.0/bin/ycsb.sh load mongodb \
  -s \
  -P ~/ycsb-0.17.0/workloads/iworkload \
  -p mongodb.url="mongodb://docker-compose-user-db-1:27017/users" \
  -p table=customers \
  -p recordcount=2000


~/ycsb-0.17.0/bin/ycsb.sh load mongodb \
  -s \
  -P ~/ycsb-0.17.0/workloads/sockshop_workload \
  -p mongodb.url="mongodb://docker-compose-user-db-1:27017/users" \
  -p table=customers \
  -p recordcount=2000 
  
  \ 
  -p readproportion=0.5 \
  -p updateproportion=0.3 \
  -p scanproportion=0.2



  # Exec into container from terminal
  docker exec -it user-db /bin/bash 

use users  // Make sure you're in the correct database
db.usertable.find().pretty()

# references
https://learn.arm.com/learning-paths/servers-and-cloud-computing/glibc-with-lse/mongo_benchmark/ 
