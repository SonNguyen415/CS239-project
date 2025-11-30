YAML=project.yaml
NAMESPACE=sock-shop
PROJECT_ID=$(gcloud config get-value project)

all:
	kubectl apply -f $(YAML)

delete:
	kubectl delete -f $(YAML)

status:
	kubectl get pods -n $(NAMESPACE)

ycsb:
	kubectl exec -it -n $(NAMESPACE) deployment/ycsb -- /bin/bash

