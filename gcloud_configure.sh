#!/bin/bash
set -e

PROJECT_ID="$1"

if [ -z "$PROJECT_ID" ]; then
    echo "Usage: $0 <project_id>"
    exit 1
fi

# -----------------------------
# CONSTANT CONFIG
# -----------------------------
REGION="us-central1"
CLUSTER_NAME="my-gke-cluster"
NODE_COUNT=3
MACHINE_TYPE="e2-standard-2"
REPO_NAME="sockshop"
# -----------------------------

echo "Initializing gcloud..."
gcloud init

echo "Logging in user..."
gcloud auth login

echo "Setting project to: $PROJECT_ID"
gcloud config set project "$PROJECT_ID"

echo "Installing GKE auth plugin..."
gcloud components install gke-gcloud-auth-plugin -q

# -----------------------------
# Create GKE cluster
# -----------------------------
echo "Creating GKE cluster '$CLUSTER_NAME' in $REGION with $NODE_COUNT nodes..."
gcloud container clusters create "$CLUSTER_NAME" \
  --region "$REGION" \
  --num-nodes "$NODE_COUNT" \
  --machine-type "$MACHINE_TYPE" \
  --release-channel "regular"

echo "Fetching cluster credentials..."
gcloud container clusters get-credentials "$CLUSTER_NAME" --region "$REGION"

# -----------------------------
# Set up Artifact Registry
# -----------------------------
echo "Enabling Artifact Registry API..."
gcloud services enable artifactregistry.googleapis.com

echo "Creating Artifact Registry repository '$REPO_NAME' in $REGION..."
gcloud artifacts repositories create "$REPO_NAME" \
  --repository-format=docker \
  --location="$REGION" \
  --description="Sockshop Docker repo" || echo "Repository might already exist, continuing..."

# Compose REPO_BASE dynamically
REPO_BASE="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}"
echo "Using Artifact Registry base: $REPO_BASE"

echo "Configuring Docker to authenticate to Artifact Registry..."
gcloud auth configure-docker "${REGION}-docker.pkg.dev"

# -----------------------------
# Run build script
# -----------------------------
if [ -f "./build.sh" ]; then
    echo "Running build.sh with REPO_BASE argument..."
    ./build.sh "$REPO_BASE"
else
    echo "Warning: build.sh not found. Skipping build step."
fi

echo "Gcloud + GKE + Artifact Registry setup complete!"
