# Commands and Files

Project ID:
```
kubernetes/project.yaml
```

To build and push YCSB image (if Dockerfile changes):
```sh
docker build -t gcr.io/sinuous-env-478221-k0/ycsb:latest .
docker push gcr.io/sinuous-env-478221-k0/ycsb:latest
```

To run iworkload:
```sh
./bin/ycsb run mongodb -s -P workloads/iworkload \
  -p mongodb.url=mongodb://carts-db:27017/ycsb
```