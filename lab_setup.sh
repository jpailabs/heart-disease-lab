#!/usr/bin/env bash
# One-time setup for the Prayogshala Linux VM (Ubuntu/Debian, sudo available).
# Installs Python venv tooling, Docker, kubectl and kind. Installs do not persist
# after the VM is terminated, so re-run this in each fresh VM.
set -euo pipefail
log() { printf '\n\033[1;34m[setup] %s\033[0m\n' "$*"; }

log "System packages"
sudo apt-get update -y
sudo apt-get install -y python3 python3-venv python3-pip git curl ca-certificates jq

# The pinned stack needs Python 3.10-3.12; add 3.12 if the distro default is newer/older.
if ! python3 -c 'import sys; sys.exit(0 if (3,10) <= sys.version_info[:2] <= (3,12) else 1)'; then
  log "Installing Python 3.12 (default python3 is $(python3 -V 2>&1))"
  if ! sudo apt-get install -y python3.12 python3.12-venv; then
    sudo apt-get install -y software-properties-common
    sudo add-apt-repository -y ppa:deadsnakes/ppa
    sudo apt-get update -y
    sudo apt-get install -y python3.12 python3.12-venv
  fi
fi

if ! command -v docker >/dev/null 2>&1; then
  log "Installing Docker"
  sudo apt-get install -y docker.io
fi
sudo systemctl enable --now docker 2>/dev/null || sudo service docker start
# Let the lab user talk to the Docker daemon without re-login (disposable VM).
sudo usermod -aG docker "$USER" || true
sudo chmod 666 /var/run/docker.sock

ARCH=$(dpkg --print-architecture)   # amd64 / arm64
if ! command -v kubectl >/dev/null 2>&1; then
  log "Installing kubectl"
  KVER=$(curl -fsSL https://dl.k8s.io/release/stable.txt)
  curl -fsSLo /tmp/kubectl "https://dl.k8s.io/release/${KVER}/bin/linux/${ARCH}/kubectl"
  sudo install -m 0755 /tmp/kubectl /usr/local/bin/kubectl
fi
if ! command -v kind >/dev/null 2>&1; then
  log "Installing kind"
  curl -fsSLo /tmp/kind "https://kind.sigs.k8s.io/dl/v0.24.0/kind-linux-${ARCH}"
  sudo install -m 0755 /tmp/kind /usr/local/bin/kind
fi

log "Versions"
python3 --version; docker --version; kubectl version --client | head -1; kind version
