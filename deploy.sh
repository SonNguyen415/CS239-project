#!/bin/bash
# List of YAML files to apply
YAML_FILES=(
    "k8s-mongo/grafana-cm1-configmap.yaml"
    "k8s-mongo/grafana-data-persistentvolumeclaim.yaml"
    "k8s-mongo/grafana-deployment.yaml"
    "k8s-mongo/grafana-service.yaml"
    "k8s-mongo-prometheus/prometheus-configmap.yaml"
    "k8s-mongo-prometheus/prometheus-persistentvolumeclaim.yaml"
    "k8s-mongo-prometheus/prometheus-deployment.yaml"
    "k8s-mongo-prometheus/prometheus-service.yaml"
    "k8s-mongo/user-db-deployment.yaml"
    "k8s-mongo/user-db-service.yaml"
    "k8s-mongo/ycsb-results-persistentvolumeclaim.yaml"
    "k8s-mongo/ycsb-interface-deployment.yaml"
    "k8s-mongo/ycsb-interface-service.yaml"
)

# Loop over the files and apply them
for file in "${YAML_FILES[@]}"; do
  if [[ -f "$file" ]]; then
    echo "Applying $file..."
    kubectl apply -f "$file"
  else
    echo "Warning: $file does not exist, skipping."
  fi
done

echo "Deployment complete."
