#!/usr/bin/env bash
# One-time setup for the Prayogshala Linux VM (Rocky/RHEL with dnf, or Ubuntu/Debian with apt).
# Installs only what is missing: a Python 3.10-3.12 interpreter, Docker, kubectl and kind.
# System installs do not persist after the VM is terminated, so re-run this in each fresh VM.
set -euo pipefail
log() { printf '\n\033[1;34m[setup] %s\033[0m\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }
py_ok() { "$1" -c 'import sys; sys.exit(0 if (3,10) <= sys.version_info[:2] <= (3,12) else 1)' 2>/dev/null; }

if have dnf; then PM=dnf; elif have apt-get; then PM=apt; else PM=none; fi
log "Package manager: $PM ($(. /etc/os-release && echo "$PRETTY_NAME"))"

log "Base tools"
case $PM in
  dnf) sudo dnf install -y git curl jq tar ;;
  apt) sudo apt-get update -y && sudo apt-get install -y git curl jq ca-certificates ;;
esac

# Python: the pinned stack (numpy 1.26, mlflow 2.17) needs 3.10-3.12.
PYOK=""
for c in python3.11 python3.12 python3.10 python3; do
  if have "$c" && py_ok "$c"; then PYOK=$c; break; fi
done
if [ -z "$PYOK" ]; then
  log "Installing Python 3.11"
  case $PM in
    dnf) sudo dnf install -y python3.11 python3.11-pip ;;
    apt) sudo apt-get install -y python3.11 python3.11-venv || sudo apt-get install -y python3.12 python3.12-venv ;;
  esac
else
  log "Using $PYOK ($($PYOK -V 2>&1))"
fi

# Docker
if ! have docker; then
  log "Installing Docker"
  case $PM in
    dnf) sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
         sudo dnf install -y docker-ce docker-ce-cli containerd.io ;;
    apt) sudo apt-get install -y docker.io ;;
  esac
fi
sudo systemctl enable --now docker 2>/dev/null || sudo service docker start || true
sudo usermod -aG docker "$USER" 2>/dev/null || true
# Disposable lab VM: allow the current user to use Docker without logging out and in again.
sudo chmod 666 /var/run/docker.sock

ARCH=$(uname -m); case $ARCH in x86_64) ARCH=amd64 ;; aarch64) ARCH=arm64 ;; esac
if ! have kubectl; then
  log "Installing kubectl"
  KVER=$(curl -fsSL https://dl.k8s.io/release/stable.txt)
  curl -fsSLo /tmp/kubectl "https://dl.k8s.io/release/${KVER}/bin/linux/${ARCH}/kubectl"
  sudo install -m 0755 /tmp/kubectl /usr/local/bin/kubectl
fi
if ! have kind; then
  log "Installing kind"
  curl -fsSLo /tmp/kind "https://kind.sigs.k8s.io/dl/v0.24.0/kind-linux-${ARCH}"
  sudo install -m 0755 /tmp/kind /usr/local/bin/kind
fi

# kind on RHEL-family hosts needs higher inotify limits for its node container.
sudo sysctl -w fs.inotify.max_user_watches=524288 fs.inotify.max_user_instances=512 >/dev/null || true

log "Versions"
${PYOK:-python3.11} -V; docker --version; kubectl version --client 2>/dev/null | head -1; kind version
docker info --format 'docker daemon OK: {{.ServerVersion}}, cgroup {{.CgroupVersion}}'
log "Setup complete - next: ./run_lab.sh"
