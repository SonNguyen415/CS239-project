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
GCLOUD_CONFIGURE=$(SCRIPTS_DIR)/gcloud_configure.sh
BUILD=$(SCRIPTS_DIR)/build.sh
DEPLOY=$(SCRIPTS_DIR)/deploy.sh

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
	$(GCLOUD_CONFIGURE) $(PROJECT_ID) $(REPO_BASE)

build:
	@echo "Building Docker images..."
	$(BUILD) $(REPO_BASE)

deploy:
	@echo "Deploying to GKE..."
	$(DEPLOY)

# -----------------------------
# Help
# -----------------------------
.PHONY: help
help:
	@echo "Usage:"
	@echo "  make PROJECT_ID=<project> REPO_BASE=<repo> ARCH=<arch>    	# Configure, build, and deploy (assumes gcloud installed)"
	@echo "  make all PROJECT_ID=<project> REPO_BASE=<repo> ARCH=<arch> # Install gcloud + everything"
	@echo "  make install ARCH=<arch>    								# Install gcloud SDK"
	@echo "  make configure PROJECT_ID=<project> 						# Configure gcloud, GKE, Artifact Registry, and build images"
	@echo "  make build REPO_BASE=<repo>     							# Build Docker images"
	@echo "  make deploy     											# Deploy to GKE"
	@echo "  make help       											# Show this help message"

.PHONY: default all install configure build deploy help
