#!/bin/bash
set -e

ARCH="$1"

if [ -z "$ARCH" ]; then
  echo "Usage: $0 <linux|macos>"
  exit 1
fi

echo "Installing gcloud for: $ARCH"

case "$ARCH" in
  linux)
    echo "Installing Google Cloud SDK for Linux..."

    if ! command -v curl >/dev/null 2>&1; then
      echo "curl not found, installing..."
      sudo apt-get update && sudo apt-get install -y curl
    fi

    curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-linux-x86_64.tar.gz
    tar -xzf google-cloud-cli-linux-x86_64.tar.gz
    ./google-cloud-sdk/install.sh -q

    echo "Adding gcloud to PATH..."
    source ./google-cloud-sdk/path.bash.inc
    ;;

  macos)
    echo "Installing Google Cloud SDK for macOS..."

    if ! command -v brew >/dev/null 2>&1; then
      echo "Homebrew not found. Installing Homebrew first..."
      NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    brew install --cask google-cloud-sdk

    echo "Adding gcloud to PATH..."
    if [[ -d "/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk" ]]; then
      source "/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.bash.inc"
    elif [[ -d "/opt/homebrew/Caskroom/google-cloud-sdk/latest/google-cloud-sdk" ]]; then
      source "/opt/homebrew/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.bash.inc"
    fi
    ;;

  *)
    echo "Unsupported architecture: $ARCH"
    echo "Supported: linux, macos"
    exit 1
    ;;
esac

echo "Google Cloud SDK installation complete!"
echo "Run './configure_gcloud.sh <project_id>' next."
