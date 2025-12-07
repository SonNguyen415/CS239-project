# CS239-project

### VPA
`kubectl delete configmap vpa-script`
`kubectl create configmap vpa-script --from-file="k8s-mongo/vpa.py"`
VPA DOES NOT WORK WITH THE YCSB WORKLOAD - IT NEEDS TO DELETE POD TO SCALE THEM CREATING DOWNTIME WHICH WILL CRASH THE YCSB. I HAVE YET TO FIGURE OUT HOW TO USE REPLICA SETS TO MAKE THEM HIGHLY AVAILABLE

# To run mongo benchmark - quick - from within CGP:
# Download the updated script from GitHub
curl -o mongo_ycsb_benchmark.sh https://raw.githubusercontent.com/SonNguyen415/CS239-project/main/scripts/mongo_ycsb_benchmark.sh

# Make it executable
chmod +x mongo_ycsb_benchmark.sh

# Run the script
./mongo_ycsb_benchmark.sh

# To run Mongo benchmark - spike, stress, soak - from within GCP. Please note this will take several minutes to complete (30m+):
# Download from GitHub
curl -o sss_mongo_ycsb_benchmark.sh https://raw.githubusercontent.com/SonNguyen415/CS239-project/main/
scripts/sss_mongo_ycsb_benchmark.sh

# Make it executable
chmod +x sss_mongo_ycsb_benchmark.sh

# Run it
./sss_mongo_ycsb_benchmark.sh
