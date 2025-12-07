#!/bin/bash

TAG="$1"
if [ -z "$TAG" ]; then
    echo "Error: You must specify a tag (e.g., v1)"
    echo "Usage: $0 <tag>"
    exit 1
fi

IMAGE_NAME="ycsb-new"
REPO="us-central1-docker.pkg.dev/sinuous-env-478221-k0/sock-shop/${IMAGE_NAME}:${TAG}"
YAML_FILE="k8s-mongo/ycsb.yaml"
FLAGS="-t"

# Build
docker build $FLAGS "${IMAGE_NAME}" k8s-mongo/ycsb-combined/
docker tag "${IMAGE_NAME}:latest" "${REPO}"
docker push "${REPO}"
echo "Successfully pushed ${REPO}"

# Update YAML
sed -i "s#ycsb-new:.*#ycsb-new:${TAG}#g" "$YAML_FILE"
echo "Updated $YAML_FILE to use image tag: ${TAG}"

./deploy.sh
