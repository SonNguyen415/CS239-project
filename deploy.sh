#!/bin/bash

# PersistentVolumeClaims
PVC_FILES=(
    "k8s-mongo/grafana-data-persistentvolumeclaim.yaml"
    "k8s-mongo/prometheus-data-persistentvolumeclaim.yaml"
    "k8s-mongo/ycsb-results-persistentvolumeclaim.yaml"
    "k8s-mongo/user-db-pvc.yaml"
)

# Deployments
DEPLOYMENT_FILES=(
    "k8s-mongo/grafana-deployment.yaml"
    "k8s-mongo/prometheus-deployment.yaml"
    "k8s-mongo/user-db-deployment.yaml"
    "k8s-mongo/ycsb-interface-deployment.yaml"
)

# Horizontal Pod Autoscalers
HPA_FILES=(
    "k8s-mongo/user-db-hpa.yaml"
)

# ConfigMaps
CONFIGMAP_FILES=(
    "k8s-mongo/grafana-cm1-configmap.yaml"
    "k8s-mongo/prometheus-cm0-configmap.yaml"
)

# Services
SERVICE_FILES=(
    "k8s-mongo/grafana-service.yaml"
    "k8s-mongo-prometheus/prometheus-service.yaml"
    "k8s-mongo/user-db-service.yaml"
    "k8s-mongo/ycsb-interface-service.yaml"
)

# Function to apply a list of files
apply_files() {
    local files=("$@")
    for file in "${files[@]}"; do
        if [[ -f "$file" ]]; then
            echo "Applying $file..."
            kubectl apply -f "$file"
        else
            echo "Warning: $file does not exist, skipping."
        fi
    done
}

# Apply in order
apply_files "${PVC_FILES[@]}"
apply_files "${CONFIGMAP_FILES[@]}"
apply_files "${DEPLOYMENT_FILES[@]}"
apply_files "${HPA_FILES[@]}"
apply_files "${SERVICE_FILES[@]}"

echo "Deployment complete."
