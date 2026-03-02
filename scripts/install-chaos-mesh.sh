#!/usr/bin/env bash
set -euo pipefail

NAMESPACE=${NAMESPACE:-chaos-mesh}
RELEASE_NAME=${RELEASE_NAME:-chaos-mesh}
VALUES_FILE=${VALUES_FILE:-helm/chaos-mesh/values.yaml}

helm repo add chaos-mesh https://charts.chaos-mesh.org >/dev/null 2>&1 || true
helm repo update

kubectl create namespace "${NAMESPACE}" >/dev/null 2>&1 || true

echo ">> Installing Chaos Mesh into namespace '${NAMESPACE}'"

helm upgrade --install "${RELEASE_NAME}" chaos-mesh/chaos-mesh \
  --namespace "${NAMESPACE}" \
  -f "${VALUES_FILE}"

echo ">> Waiting for Chaos Mesh pods to be Ready..."
kubectl -n "${NAMESPACE}" wait --for=condition=Ready pods --all --timeout=300s

