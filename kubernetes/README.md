# Commands and Files

Project ID:
```
kubernetes/project.yaml
```

To build and push YCSB image (if Dockerfile changes):
```sh
docker build -t <artifact>/<project_id>/<image_name>:latest .
docker push <registry_path>/<image_name>:latest
```

To run `iworkload`:
```sh
./bin/ycsb run mongodb -s -P workloads/iworkload \
  -p mongodb.url=mongodb://carts-db:27017/ycsb
```