#!/bin/bash
set -e

# -----------------------------
# Arguments
# -----------------------------
VPA=${1:-false}  # optional argument: "true" to deploy vpa.yaml, default is false

# -----------------------------
# Files to deploy
# -----------------------------
FILES=(
    "k8s-mongo/prometheus.yaml"
    "k8s-mongo/grafana.yaml"
    "k8s-mongo/user-db.yaml"
    "k8s-mongo/ycsb.yaml"
    "k8s-mongo/mongodb-exporter.yaml"
    "sqlYCSB/catalogue-db-deployment.yaml"
    "sqlYCSB/ycsb-interface-deployment.yaml"
)

# Add VPA file if requested
if [[ "$VPA" == "true" ]]; then
    FILES+=("k8s-mongo/vpa.yaml")
    echo "VPA deployment enabled: vpa.yaml will be applied."
else
    echo "VPA deployment disabled: skipping vpa.yaml."
fi

# -----------------------------
# Function to apply a list of files
# -----------------------------
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

# -----------------------------
# Apply files
# -----------------------------
apply_files "${FILES[@]}"

echo "Deployment complete."
