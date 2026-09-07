#!/usr/bin/env bash
set -euo pipefail

# Installs lightweight CLI prerequisites on Debian/Ubuntu-based WSL.
# Docker Desktop/WSL2 integration is intentionally not installed automatically:
# it is a host-level dependency and may require Windows administrator/reboot actions.

log()  { printf '\n==> %s\n' "$*"; }
ok()   { printf '    ✓ %s\n' "$*"; }
warn() { printf '    ! %s\n' "$*" >&2; }
fail() { printf '    ✗ %s\n' "$*" >&2; exit 1; }

need_cmd() { command -v "$1" >/dev/null 2>&1; }

install_apt_prereqs() {
  if ! need_cmd curl || ! need_cmd ca-certificates || ! need_cmd unzip; then
    log "Installing basic packages"
    if ! need_cmd sudo; then fail "sudo is required to install packages."; fi
    sudo apt-get update
    sudo apt-get install -y curl ca-certificates unzip git
  fi
}

install_kubectl() {
  need_cmd kubectl && return
  log "Installing kubectl"
  local version
  version="$(curl -fsSL https://dl.k8s.io/release/stable.txt)"
  curl -fsSL -o /tmp/kubectl "https://dl.k8s.io/release/${version}/bin/linux/amd64/kubectl"
  curl -fsSL -o /tmp/kubectl.sha256 "https://dl.k8s.io/release/${version}/bin/linux/amd64/kubectl.sha256"
  echo "$(cat /tmp/kubectl.sha256)  /tmp/kubectl" | sha256sum --check
  sudo install -m 0755 /tmp/kubectl /usr/local/bin/kubectl
  rm -f /tmp/kubectl /tmp/kubectl.sha256
  ok "kubectl $(kubectl version --client -o json 2>/dev/null | grep -o 'v[0-9][^\"]*' | head -1 || true)"
}

install_minikube() {
  need_cmd minikube && return
  log "Installing Minikube"
  curl -fsSL -o /tmp/minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
  sudo install -m 0755 /tmp/minikube /usr/local/bin/minikube
  rm -f /tmp/minikube
  ok "Minikube $(minikube version --short 2>/dev/null || true)"
}

install_terraform() {
  need_cmd terraform && return
  log "Installing Terraform"
  local version url
  version="$(curl -fsSL https://checkpoint-api.hashicorp.com/v1/check/terraform | python3 -c 'import json,sys; print(json.load(sys.stdin)["current_version"])')"
  url="https://releases.hashicorp.com/terraform/${version}/terraform_${version}_linux_amd64.zip"
  curl -fsSL -o /tmp/terraform.zip "$url"
  unzip -o /tmp/terraform.zip -d /tmp/terraform-bin >/dev/null
  sudo install -m 0755 /tmp/terraform-bin/terraform /usr/local/bin/terraform
  rm -rf /tmp/terraform.zip /tmp/terraform-bin
  ok "Terraform $(terraform version -json | python3 -c 'import json,sys; print(json.load(sys.stdin)["terraform_version"])')"
}

install_terragrunt() {
  need_cmd terragrunt && return
  log "Installing Terragrunt"
  local arch version asset
  arch="$(uname -m)"
  case "$arch" in
    x86_64) asset="terragrunt_linux_amd64" ;;
    aarch64|arm64) asset="terragrunt_linux_arm64" ;;
    *) fail "Unsupported CPU architecture for Terragrunt: $arch" ;;
  esac
  version="$(curl -fsSL https://api.github.com/repos/gruntwork-io/terragrunt/releases/latest | python3 -c 'import json,sys; print(json.load(sys.stdin)["tag_name"])')"
  curl -fsSL -o /tmp/terragrunt "https://github.com/gruntwork-io/terragrunt/releases/download/${version}/${asset}"
  sudo install -m 0755 /tmp/terragrunt /usr/local/bin/terragrunt
  rm -f /tmp/terragrunt
  ok "Terragrunt $(terragrunt --version | head -1)"
}

log "Checking WSL/Linux environment"
if [ -r /proc/version ] && grep -qi microsoft /proc/version; then
  ok "WSL detected"
else
  warn "WSL was not detected; continuing because the tooling is Linux-compatible."
fi

install_apt_prereqs

log "Checking Docker"
if ! need_cmd docker; then
  cat >&2 <<'MSG'
    ✗ Docker CLI is not installed.

      For this challenge on WSL, install Docker Desktop on Windows and enable
      WSL2 integration for this distribution. Then reopen WSL and run:

        docker info

      The project intentionally does not install Docker Desktop automatically.
MSG
  exit 1
fi
if ! docker info >/dev/null 2>&1; then
  cat >&2 <<'MSG'
    ✗ Docker CLI exists, but the Docker daemon is not reachable.

      Start Docker Desktop on Windows and ensure WSL2 integration is enabled
      for this WSL distribution, then run this script again.
MSG
  exit 1
fi
ok "Docker daemon reachable"

install_kubectl
install_minikube
install_terraform
install_terragrunt

log "Versions"
docker --version
kubectl version --client --output=yaml | grep gitVersion | head -1 || true
minikube version --short || true
terraform version | head -1
terragrunt --version | head -1
