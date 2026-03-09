#!/usr/bin/env bash
set -euo pipefail

NAMESPACE=${NAMESPACE:-test-app}

kubectl create namespace "${NAMESPACE}" >/dev/null 2>&1 || true

echo ">> Deploying demo-http app into namespace '${NAMESPACE}'"
kubectl apply -f k8s/test-app/deployment.yaml
kubectl apply -f k8s/test-app/service.yaml

echo ">> Waiting for pods to be Ready..."
kubectl -n "${NAMESPACE}" rollout status deployment/demo-http --timeout=300s

echo "demo-http service should be reachable at http://localhost:30080"

