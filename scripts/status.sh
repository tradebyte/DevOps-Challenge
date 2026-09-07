#!/usr/bin/env bash
set -euo pipefail
kubectl get nodes
kubectl get pods,svc,hpa,pdb,ingress -n tradebyte
