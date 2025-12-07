# -----------------------------
# Makefile for Sockshop GKE Deployment
# -----------------------------

# Variables
GGCLOUD_INSTALL=./gcloud_install.sh
GGCLOUD_CONFIGURE=./gcloud_configure.sh
BUILD=./build.sh
DEPLOY=./deploy.sh

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
	@echo "Installing gcloud SDK..."
	$(GGCLOUD_INSTALL)

configure:
	@echo "Configuring gcloud, GKE, Artifact Registry, and building images..."
	$(GGCLOUD_CONFIGURE)

build:
	@echo "Building Docker images..."
	$(BUILD)

deploy:
	@echo "Deploying to GKE..."
	$(DEPLOY)


# -----------------------------
# Help
# -----------------------------
.PHONY: help
help:
	@echo "Usage:"
	@echo "  make 			 # Configure, build, and deploy (assumes gcloud is already installed)"
	@echo "  make all        # Install gcloud, configure, build, and deploy from scratch"
	@echo "  make install    # Install gcloud SDK only"
	@echo "  make configure  # Configure gcloud, GKE, Artifact Registry, and build images"
	@echo "  make build      # Build Docker images only"
	@echo "  make deploy     # Deploy to GKE only"
	@echo "  make help       # Show this help message"


.PHONY: default all install configure build deploy help