#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

log() { printf '\n==> %s\n' "$*"; }

"$ROOT_DIR/scripts/prerequisites.sh"

log "Starting/reusing Minikube"
# Check if the default minikube cluster is running. If not, spin it up with your custom 2GB profile.
if ! minikube status >/dev/null 2>&1; then
  minikube start --cpus=2 --memory=2048 --driver=docker
else
  minikube status
fi

log "Enabling Kubernetes addons"
for addon in metrics-server ingress default-storageclass storage-provisioner; do
  minikube addons enable "$addon" >/dev/null
  printf '    ✓ %s enabled\n' "$addon"
done

log "Building application image"
docker build -t tradebyte-app:local .

log "Loading image into Minikube"
minikube image load tradebyte-app:local

log "Applying Terraform/Terragrunt"
(
  cd "$ROOT_DIR/infra"
  terragrunt init
  terragrunt apply --auto-approve
)

log "Hydrating local HashiCorp Vault secrets engine"
kubectl wait --namespace tradebyte --for=condition=ready pod --selector=app=vault --timeout=60s

# Extract environment keys directly from your local .env file and feed them into Vault
export $(cat .env | xargs)
kubectl exec -n tradebyte deployment/vault -- sh -c "
  export VAULT_ADDR='http://127.0.0.1:8200'
  export VAULT_TOKEN='root'
  vault kv put secret/tradebyte-app ENVIRONMENT='${ENVIRONMENT}' REDIS_DB='${REDIS_DB}'
  echo 'path \"secret/data/tradebyte-app\" { capabilities = [\"read\"] }' > /tmp/policy.hcl
  vault policy write tradebyte-policy /tmp/policy.hcl
"
# ========================================================
log "Waiting for workloads"
# Natively target the default context that Terraform initialized
kubectl rollout status deployment/redis -n tradebyte --timeout=180s
kubectl rollout status deployment/tradebyte-app -n tradebyte --timeout=180s

log "Waiting for metrics-server"
for _ in $(seq 1 30); do
  if kubectl top pods -n tradebyte >/dev/null 2>&1; then
    break
  fi
  sleep 5
done

log "Configuring local hostname"
MINIKUBE_IP="$(minikube ip)"
if grep -qE "^[[:space:]]*${MINIKUBE_IP}[[:space:]]+tradebyte\.local([[:space:]]|$)" /etc/hosts 2>/dev/null; then
  echo "    ✓ /etc/hosts already contains tradebyte.local"
elif command -v sudo >/dev/null 2>&1 && sudo sh -c "printf '%s\ttradebyte.local\n' '$MINIKUBE_IP' >> /etc/hosts"; then
  echo "    ✓ Added tradebyte.local to WSL /etc/hosts"
else
  echo "    ! Could not update /etc/hosts automatically"
  echo "      Add: $MINIKUBE_IP tradebyte.local"
fi

log "Deployment status"
kubectl get pods,svc,hpa,pdb,ingress -n tradebyte

printf '\n==============================================\n'
printf 'TradeByte challenge is ready.\n\n'
printf 'Minikube IP : %s\n' "$MINIKUBE_IP"
printf 'App URL     : http://tradebyte.local\n'
printf '\nSmoke test:\n  ./scripts/smoke-test.sh\n'
printf '\nIf the Windows browser cannot resolve tradebyte.local, add this to the\nWindows hosts file as Administrator:\n  %s tradebyte.local\n' "$MINIKUBE_IP"
printf '==============================================\n'
