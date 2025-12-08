#!/bin/bash
set -e

# -----------------------------
# Arguments
# -----------------------------
REPO_BASE="$1"

if [ -z "$REPO_BASE" ]; then
    echo "Usage: $0 <repo_base>"
    exit 1
fi

# -----------------------------
# Constants: define images to build
# Format: "IMAGE_NAME:BUILD_DIR:YAML_FILE"
# -----------------------------
IMAGES=(
  "ycsb-new:k8s-mongo/ycsb-combined/:k8s-mongo/ycsb.yaml"
  "sqlYCSB:sqlYCSB/:sqlYCSB/ycsb-interface-deployment.yaml"
)
FLAGS="-t"
# -----------------------------

# The tag will be commit hash + timestamp
COMMIT_TAG="$(git rev-parse --short HEAD)-$(date +%s)"

for entry in "${IMAGES[@]}"; do
    IFS=":" read -r IMAGE_NAME BUILD_DIR YAML_FILE <<< "$entry"

    REPO="${REPO_BASE}/${IMAGE_NAME}:${COMMIT_TAG}"
    echo "Building Docker image '${IMAGE_NAME}' from '${BUILD_DIR}' with tag '${COMMIT_TAG}'..."

    docker build $FLAGS "${IMAGE_NAME}" "$BUILD_DIR"
    docker tag "${IMAGE_NAME}:latest" "${REPO}"
    docker push "${REPO}"
    echo "Successfully pushed ${REPO}"

    # Replace the tag in YAML - macOS and Linux compatible
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|<repo>/<project_id>/<repo_name>/<image_name>:<tag>|${REPO}|g; s|${REPO_BASE}/${IMAGE_NAME}:[^[:space:]]*|${REPO}|g" "$YAML_FILE"
    else
        sed -i "s|<repo>/<project_id>/<repo_name>/<image_name>:<tag>|${REPO}|g; s|${REPO_BASE}/${IMAGE_NAME}:[^[:space:]]*|${REPO}|g" "$YAML_FILE"
    fi
        
    echo "Updated $YAML_FILE with image path: ${REPO}"
done

