#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR/infra"

if command -v terragrunt >/dev/null 2>&1; then
  terragrunt destroy --auto-approve || true
fi

if command -v minikube >/dev/null 2>&1; then
  minikube delete || true  # <-- FIXED HERE (Removed -p tradebyte)
fi

echo "TradeByte local environment destroyed."
