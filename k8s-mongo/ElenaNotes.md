~/ycsb-0.17.0/bin/ycsb.sh load mongodb -s -P ~/ycsb-0.17.0/workloads/iworkload -p recordcount=1000 -threads 8 -p mongodb.url="mongodb://docker-compose-carts-db-1:27017/mymongodb"


# Target a specific database and collection

~/ycsb-0.17.0/bin/ycsb.sh load mongodb -s -P ~/ycsb-0.17.0/workloads/workloada -p recordcount=1000 -p mongodb.url="mongodb://docker-compose-user-db-1:27017/users" -p mongodb.collection=usertable



# This command worked kinda
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
  docker exec -it docker-compose-user-db-1 /bin/bash 

use users  // Make sure you're in the correct database
db.customers.find().pretty()


# add this to the end of ycsb to log

~/ycsb-0.17.0/bin/ycsb.sh run mongodb -s -P ~/ycsb-0.17.0/workloads/workloada \
  -p operationcount=1000000 \
  -p mongodb.url="mongodb://user-db:27017/users" \
  -p mongodb.collection=usertable | tee /results/ycsb_output.txt


  ~/ycsb-0.17.0/bin/ycsb.sh run mongodb -s -P ~/ycsb-0.17.0/workloads/workloadb \
  -p operationcount=1000 \
  -p mongodb.url="mongodb://user-db:27017/users" \
  -p mongodb.collection=usertable | tee -a /results/ycsb_output.txt