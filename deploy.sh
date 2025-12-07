#!/bin/bash

# Files
FILES=(
    "k8s-mongo/prometheus.yaml"
    "k8s-mongo/grafana.yaml"
    "k8s-mongo/user-db.yaml"
    "k8s-mongo/ycsb.yaml"
    "sqlYCSB/catalogue-db-deployment.yaml"
    "sqlYCSB/ycsb-interface-deployment.yaml"
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

apply_files "${FILES[@]}"

echo "Deployment complete."
