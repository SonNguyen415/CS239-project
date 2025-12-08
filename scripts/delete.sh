#!/bin/bash
set -e

# -----------------------------
# Files to delete
# -----------------------------
FILES=(
    "k8s-mongo/prometheus.yaml"
    "k8s-mongo/grafana.yaml"
    "k8s-mongo/user-db.yaml"
    "k8s-mongo/ycsb.yaml"
    "k8s-mongo/mongodb-exporter.yaml"
    "k8s-mongo/vpa.yaml"
    "sqlYCSB/catalogue-db-deployment.yaml"
    "sqlYCSB/ycsb-interface-deployment.yaml"
)

# -----------------------------
# Function to apply a list of files
# -----------------------------
delete_deployments() {
    local files=("$@")
    for file in "${files[@]}"; do
        if [[ -f "$file" ]]; then
            echo "Deleting deployment $file..."
            kubectl delete -f "$file" --ignore-not-found=true
        else
            echo "Warning: $file does not exist, skipping."
        fi
    done
}

# -----------------------------
# Apply files
# -----------------------------
delete_deployments "${FILES[@]}"

echo "Deletion complete."
