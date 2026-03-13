#!/usr/bin/env bash
set -euo pipefail

NAMESPACE=${NAMESPACE:-test-app}

kubectl create namespace "${NAMESPACE}" >/dev/null 2>&1 || true

echo ">> Deploying demo-http app into namespace '${NAMESPACE}'"
kubectl apply -f k8s/test-app/deployment.yaml
kubectl apply -f k8s/test-app/service.yaml
kubectl apply -f k8s/test-app/downstream-deployment.yaml
kubectl apply -f k8s/test-app/downstream-service.yaml

echo ">> Waiting for pods to be Ready..."
kubectl -n "${NAMESPACE}" rollout status deployment/demo-api --timeout=300s
kubectl -n "${NAMESPACE}" rollout status deployment/demo-downstream --timeout=300s

echo "demo-http service should be reachable at http://localhost:30080"

