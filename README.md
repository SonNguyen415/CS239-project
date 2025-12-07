# CS239-project

## Usage
Run `make help` for the list of usable commands.`make all` will run all of the commands explained below:
- `make install`: will install the Google Cloud SDK. If you already have it installed, then skip. Simply running `make` will do the rest of the pipeline without this step.
- `make configure`: will 

## VPA
`kubectl delete configmap vpa-script`
`kubectl create configmap vpa-script --from-file="k8s-mongo/vpa.py"`
VPA DOES NOT WORK WITH THE YCSB WORKLOAD - IT NEEDS TO DELETE POD TO SCALE THEM CREATING DOWNTIME WHICH WILL CRASH THE YCSB. I HAVE YET TO FIGURE OUT HOW TO USE REPLICA SETS TO MAKE THEM HIGHLY AVAILABLE



## To run mongo benchmark - quick - from within CGP:
### Download the updated script from GitHub
```sh
curl -o mongo_ycsb_benchmark.sh https://raw.githubusercontent.com/SonNguyen415/CS239-project/main/scripts/mongo_ycsb_benchmark.sh
```

### Make it executable
```sh
chmod +x mongo_ycsb_benchmark.sh
```

### Run the script
```sh
./mongo_ycsb_benchmark.sh
```

# To run Mongo benchmark - spike, stress, soak - from within GCP. Please note this will take several minutes to complete (30m+):
# Download from GitHub
```sh
curl -o sss_mongo_ycsb_benchmark.sh https://raw.githubusercontent.com/SonNguyen415/CS239-project/main/
scripts/sss_mongo_ycsb_benchmark.sh
```

# Make it executable
```sh
chmod +x sss_mongo_ycsb_benchmark.sh
```

# Run it
```
./sss_mongo_ycsb_benchmark.sh
```

## To Run the MySQL benchmarks
### Download scripts
```sh
curl -o mysql_ycsb_benchmark.sh https://raw.githubusercontent.com/SonNguyen415/CS239-project/main/scripts/mysql_ycsb_benchmark.sh
curl -o sss_mysql_ycsb_benchmark.sh https://raw.githubusercontent.com/SonNguyen415/CS239-project/main/scripts/sss_mysql_ycsb_benchmark.sh
```

### Make them executable and Run
```
chmod +x mysql_ycsb_benchmark.sh
chmod +x sss_mysql_ycsb_benchmark.sh
```

