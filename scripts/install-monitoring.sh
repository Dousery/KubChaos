#!/usr/bin/env bash
set -euo pipefail

NAMESPACE=${NAMESPACE:-monitoring}
RELEASE_NAME=${RELEASE_NAME:-monitoring}
VALUES_FILE=${VALUES_FILE:-helm/monitoring/values.yaml}

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null 2>&1 || true
helm repo update

kubectl create namespace "${NAMESPACE}" >/dev/null 2>&1 || true

echo ">> Installing kube-prometheus-stack into namespace '${NAMESPACE}'"

helm upgrade --install "${RELEASE_NAME}" prometheus-community/kube-prometheus-stack \
  --namespace "${NAMESPACE}" \
  -f "${VALUES_FILE}"

echo ">> Waiting for monitoring stack pods to be Ready..."
kubectl -n "${NAMESPACE}" wait --for=condition=Ready pods --all --timeout=600s

echo "Grafana should be available on NodePort 30090 (http://localhost:30090) after pods are Ready."

