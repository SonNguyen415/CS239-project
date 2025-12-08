# -----------------------------
# Makefile for Sockshop GKE Deployment
# -----------------------------

# Arguments
REPO_BASE ?= us-central1-docker.pkg.dev/sinuous-env-478221-k0/sock-shop
ARCH ?= $(shell uname -m)   # auto-detect architecture (x86_64, arm64, etc.)
CLUSTER_NAME ?= sockshop-cluster

# Script paths
SCRIPTS_DIR=scripts
GCLOUD_INSTALL=$(SCRIPTS_DIR)/gcloud_install.sh
GCLOUD_CONFIGURE_AUTOPILOT=$(SCRIPTS_DIR)/gcloud_configure.sh
GCLOUD_CONFIGURE_STANDARD=$(SCRIPTS_DIR)/gcloud_configure_standard.sh
BUILD=$(SCRIPTS_DIR)/build.sh
DEPLOY=$(SCRIPTS_DIR)/deploy.sh
DELETE=$(SCRIPTS_DIR)/delete.sh
MONGO_BENCHMARK=$(SCRIPTS_DIR)/mongo_ycsb_benchmark.sh
MONGO_SSS=$(SCRIPTS_DIR)/mongo_sss_benchmark.sh
SQL_BENCHMARK=$(SCRIPTS_DIR)/sql_ycsb_benchmark.sh
SQL_SSS=$(SCRIPTS_DIR)/sql_sss_benchmark.sh

# PID files for port-forward processes
GRAFANA_PID_FILE=/tmp/grafana-port-forward.pid
PROMETHEUS_PID_FILE=/tmp/prometheus-port-forward.pid

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
	$(GCLOUD_CONFIGURE_AUTOPILOT) $(CLUSTER_NAME)

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
	@echo "Starting Grafana port-forward in background (localhost:3000)..."
	@if [ -f $(GRAFANA_PID_FILE) ] && kill -0 $$(cat $(GRAFANA_PID_FILE)) 2>/dev/null; then \
		echo "Grafana port-forward already running (PID $$(cat $(GRAFANA_PID_FILE)))"; \
	else \
		kubectl port-forward svc/grafana 3000:80 > /dev/null 2>&1 & \
		echo $$! > $(GRAFANA_PID_FILE); \
		echo "Grafana port-forward started (PID $$(cat $(GRAFANA_PID_FILE)))"; \
		echo "Access at: http://localhost:3000"; \
	fi

prometheus:
	@echo "Starting Prometheus port-forward in background (localhost:9090)..."
	@if [ -f $(PROMETHEUS_PID_FILE) ] && kill -0 $$(cat $(PROMETHEUS_PID_FILE)) 2>/dev/null; then \
		echo "Prometheus port-forward already running (PID $$(cat $(PROMETHEUS_PID_FILE)))"; \
	else \
		kubectl port-forward svc/prometheus 9090:9090 > /dev/null 2>&1 & \
		echo $$! > $(PROMETHEUS_PID_FILE); \
		echo "Prometheus port-forward started (PID $$(cat $(PROMETHEUS_PID_FILE)))"; \
		echo "Access at: http://localhost:9090"; \
	fi

stop_grafana:
	@if [ -f $(GRAFANA_PID_FILE) ]; then \
		if kill -0 $$(cat $(GRAFANA_PID_FILE)) 2>/dev/null; then \
			kill $$(cat $(GRAFANA_PID_FILE)); \
			echo "Stopped Grafana port-forward (PID $$(cat $(GRAFANA_PID_FILE)))"; \
		else \
			echo "Grafana port-forward not running"; \
		fi; \
		rm -f $(GRAFANA_PID_FILE); \
	else \
		echo "No Grafana port-forward PID file found"; \
	fi

stop_prometheus:
	@if [ -f $(PROMETHEUS_PID_FILE) ]; then \
		if kill -0 $$(cat $(PROMETHEUS_PID_FILE)) 2>/dev/null; then \
			kill $$(cat $(PROMETHEUS_PID_FILE)); \
			echo "Stopped Prometheus port-forward (PID $$(cat $(PROMETHEUS_PID_FILE)))"; \
		else \
			echo "Prometheus port-forward not running"; \
		fi; \
		rm -f $(PROMETHEUS_PID_FILE); \
	else \
		echo "No Prometheus port-forward PID file found"; \
	fi

status:
	@echo "Port-forward status:"
	@if [ -f $(GRAFANA_PID_FILE) ] && kill -0 $$(cat $(GRAFANA_PID_FILE)) 2>/dev/null; then \
		echo "  Grafana: RUNNING (PID $$(cat $(GRAFANA_PID_FILE)), http://localhost:3000)"; \
	else \
		echo "  Grafana: STOPPED"; \
	fi
	@if [ -f $(PROMETHEUS_PID_FILE) ] && kill -0 $$(cat $(PROMETHEUS_PID_FILE)) 2>/dev/null; then \
		echo "  Prometheus: RUNNING (PID $$(cat $(PROMETHEUS_PID_FILE)), http://localhost:9090)"; \
	else \
		echo "  Prometheus: STOPPED"; \
	fi

mongo_benchmark:
	@$(MONGO_BENCHMARK)

mongo_sss:
	@$(MONGO_SSS)

sql_benchmark:
	@$(SQL_BENCHMARK)

sql_sss:
	@$(SQL_SSS)

# -----------------------------
# Help
# -----------------------------
help:
	@echo "Usage:"
	@echo "  make CLUSTER_NAME=<cluster> REPO_BASE=<repo> ARCH=<arch>                            # Configure, build, and deploy (assumes gcloud installed)"
	@echo "  make all CLUSTER_NAME=<cluster> REPO_BASE=<repo> ARCH=<arch> # Install gcloud + everything"
	@echo "  make install ARCH=<arch>                                     # Install gcloud SDK"
	@echo "  make configure CLUSTER_NAME=<cluster>                        # Configure gcloud, GKE, Artifact Registry, and build images"
	@echo "  make build REPO_BASE=<repo>                                  # Build Docker images"
	@echo "  make deploy                                                  # Deploy to GKE without VPA"
	@echo "  make deploy_vpa                                              # Deploy to GKE with VPA"
	@echo "  make grafana                                                 # Start Grafana port-forward (background, localhost:3000)"
	@echo "  make prometheus                                              # Start Prometheus port-forward (background, localhost:9090)"
	@echo "  make stop_grafana                                            # Stop Grafana port-forward"
	@echo "  make stop_prometheus                                         # Stop Prometheus port-forward"
	@echo "  make status                                                  # Check port-forward status"
	@echo "  make delete                                                  # Delete deployment from GKE"
	@echo "  make mongo_benchmark                                         # Run MongoDB YCSB benchmark"
	@echo "  make mongo_sss                                               # Run MongoDB SSS benchmark"
	@echo "  make sql_benchmark                                           # Run SQL YCSB benchmark"
	@echo "  make sql_sss                                                 # Run SQL SSS benchmark"
	@echo "  make help                                                    # Show this help message"

.PHONY: default all install configure build deploy deploy_vpa delete grafana prometheus stop_grafana stop_prometheus status mongo_benchmark help 