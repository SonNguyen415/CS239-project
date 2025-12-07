# -----------------------------
# Makefile for Sockshop GKE Deployment
# -----------------------------

# Arguments
PROJECT_ID ?= my-project-id
REPO_BASE ?= us-central1-docker.pkg.dev/sinuous-env-478221-k0/sock-shop
ARCH ?= $(shell uname -m)   # auto-detect architecture (x86_64, arm64, etc.)

# Script paths
SCRIPTS_DIR=scripts
GCLOUD_INSTALL=$(SCRIPTS_DIR)/gcloud_install.sh
GCLOUD_CONFIGURE_AUTOPILOT=$(SCRIPTS_DIR)/gcloud_configure.sh
GCLOUD_CONFIGURE_STANDARD=$(SCRIPTS_DIR)/gcloud_configure_standard.sh
BUILD=$(SCRIPTS_DIR)/build.sh
DEPLOY=$(SCRIPTS_DIR)/deploy.sh
DELETE=$(SCRIPTS_DIR)/delete.sh

# -----------------------------
# Default target -- assumed that gcloud is already installed
# -----------------------------
default: configure deploy

# -----------------------------
# Full install + configure + build + deploy
# -----------------------------
all: install configure deploy
	@echo "All steps complete."

install:
	@echo "Installing gcloud SDK for architecture $(ARCH)..."
	$(GCLOUD_INSTALL) $(ARCH)

configure:
	@echo "Configuring gcloud, GKE, Artifact Registry, and building images..."
	$(GCLOUD_CONFIGURE_AUTOPILOT) $(PROJECT_ID) $(REPO_BASE)

build:
	@echo "Building Docker images..."
	$(BUILD) $(REPO_BASE)

deploy:
	@echo "Deploying to GKE (without VPA)..."
	$(DEPLOY)

deploy_vpa:
	@echo "Deploying to GKE with VPA enabled..."
	$(DEPLOY) true

delete:
	@echo "Deleting deployment from GKE..."
	$(DELETE)

grafana:
	@kubectl port-forward svc/grafana 3000:80

# -----------------------------
# Help
# -----------------------------
.PHONY: help
help:
	@echo "Usage:"
	@echo "  make PROJECT_ID=<project> REPO_BASE=<repo> ARCH=<arch>         # Configure, build, and deploy (assumes gcloud installed)"
	@echo "  make all PROJECT_ID=<project> REPO_BASE=<repo> ARCH=<arch>    	# Install gcloud + everything"
	@echo "  make install ARCH=<arch>                                       # Install gcloud SDK"
	@echo "  make configure PROJECT_ID=<project>                            # Configure gcloud, GKE, Artifact Registry, and build images"
	@echo "  make build REPO_BASE=<repo>                                    # Build Docker images"
	@echo "  make deploy                                                    # Deploy to GKE without VPA"
	@echo "  make deploy_vpa                                                # Deploy to GKE with VPA"
	@echo "  make grafana                                                  	# Port-forward Grafana service to localhost:3000"
	@echo "  make delete                                                 	# Delete deployment from GKE"
	@echo "  make help                                                      # Show this help message"

.PHONY: default all install configure build deploy deploy_vpa delete help