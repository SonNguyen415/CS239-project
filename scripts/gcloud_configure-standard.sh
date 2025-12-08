#!/bin/bash
set -e

CLUSTER_NAME="$1"

# -----------------------------
# CONSTANT CONFIG
# -----------------------------
REGION="us-central1"
REPO_NAME="sockshop"
NODE_COUNT=2
MACHINE_TYPE="e2-standard-2"
# -----------------------------

echo "Initializing gcloud..."
gcloud init

echo "Logging in user..."
gcloud auth login

# Get the current project ID (auto-detected after login)
PROJECT_ID=$(gcloud config get-value project)

if [ -z "$PROJECT_ID" ]; then
    echo "Error: No project ID found. Please select a project during 'gcloud init'."
    exit 1
fi

echo "Using project: $PROJECT_ID"

echo "Installing GKE auth plugin..."
gcloud components install gke-gcloud-auth-plugin -q

# -----------------------------
# Create GKE Autopilot cluster
# -----------------------------
echo "Creating GKE Autopilot cluster '$CLUSTER_NAME' in $REGION..."
gcloud container clusters create-auto "$CLUSTER_NAME" \
  --region "$REGION" \
  --release-channel "regular"

echo "Fetching cluster credentials..."
gcloud container clusters get-credentials "$CLUSTER_NAME" --region "$REGION"

# -----------------------------
# Set up Artifact Registry
# -----------------------------
echo "Enabling Artifact Registry API..."
gcloud services enable artifactregistry.googleapis.com

echo "Creating GKE cluster '$CLUSTER_NAME' in $REGION with $NODE_COUNT nodes..."
gcloud container clusters create "$CLUSTER_NAME" \
  --region "$REGION" \
  --num-nodes "$NODE_COUNT" \
  --machine-type "$MACHINE_TYPE" \
  --release-channel "regular"


# Compose REPO_BASE dynamically
REPO_BASE="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}"
echo "Using Artifact Registry base: $REPO_BASE"

echo "Configuring Docker to authenticate to Artifact Registry..."
gcloud auth configure-docker "${REGION}-docker.pkg.dev"

# -----------------------------
# Run build script
# -----------------------------
if [ -f "$(dirname "$0")/build.sh" ]; then
    echo "Running build.sh with REPO_BASE=$REPO_BASE"
    "$(dirname "$0")/build.sh" "$REPO_BASE"
elif [ -f "./build.sh" ]; then
    echo "Running build.sh with REPO_BASE=$REPO_BASE"
    ./build.sh "$REPO_BASE"
else
    echo "Warning: build.sh not found. Skipping build step."
fi

echo "Gcloud + GKE Autopilot + Artifact Registry setup complete!"
echo "Project ID: ${PROJECT_ID}"
echo "Repository: ${REPO_BASE}"