# CS239-project


## Requirements
Docker - ensure the `Docker` daemon is running before continuing.

## Usage
Run `make help` for the list of usable commands.`make all` will run all of the commands explained below:
- `make install`: will install the Google Cloud SDK. If you already have it installed, then skip. Simply running `make` will do the rest of the pipeline without this step:
- `make configure`: will configure GCP to select project, create a GKE cluster, create an artifact registry, and run `build.sh`. You must pass in a cluster name as argument, or it will default to `sockshop-cluster`. You may also skip this step and configure via the GCP console per the [CSE239 Tutorials](https://docs.google.com/document/d/17wwMTqH1IiOC0xPB197kyeSXxt7sWPFGtcueRbRqm8M/edit?tab=t.4wznddm5tbzb).
- `make build` will build and push the required `Docker` images for `YCSB` onto the Artifact Registry. 
- `make deploy` will deploy the `yaml` files into pods. Check for pod status with `kubectl get pods` and wait until they are ready.

You can now run the workloads. The available workloads you can run are:
- `make mongo_benchmark`: to run the regular benchmarks on `MongoDB`
- `make mongo_sss`: to run the stress, soak, or spike benchmarks on `MongoDB`
- `make sql_benchmark`: to run the regular benchmarks on `SQL`
- `make sql_sss`: to run the stress, soak, or spike benchmarks on `SQL`

Run `make grafana` to start grafana on the background and observe latency metric in real time. You can check the Google Cloud Console for each pod to see resource utilization.

Clean up all deployments at the end via `make delete`.

### Grafana Logins
- username: `admin`
- password: `admin`

### Notes
1. CLI authentication will have to be done in the browser, simply click in the link provided in the terminal.
2. You can also make and set up a project as in the \link[CSE239 tutorial](https://docs.google.com/document/d/17wwMTqH1IiOC0xPB197kyeSXxt7sWPFGtcueRbRqm8M/edit?tab=t.utw4rgyxe61u) if the `build` and `configure` commands result in errors.
3. You can change the build directory `sqlYCSB/sql-ycsb/` in `scripts/build.sh` to `sqlYCSB` for a simpler image for the `sql` if the `sql-ycsb` results in errors (line 20).


## Known bugs
1. VPA DOES NOT WORK WITH THE YCSB WORKLOAD - IT NEEDS TO DELETE POD TO SCALE THEM CREATING DOWNTIME WHICH WILL CRASH THE YCSB. I HAVE YET TO FIGURE OUT HOW TO USE REPLICA SETS TO GUARANTEE AVAILABILITY



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

