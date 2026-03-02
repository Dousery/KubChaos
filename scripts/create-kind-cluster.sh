#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME=${CLUSTER_NAME:-chaos-lab}
CONFIG_PATH=${CONFIG_PATH:-infra/kind/cluster.yaml}

echo ">> Creating kind cluster '${CLUSTER_NAME}' using '${CONFIG_PATH}'"

if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
  echo "Cluster '${CLUSTER_NAME}' already exists."
  read -r -p "Delete and recreate? (y/N): " answer
  if [[ "${answer}" =~ ^[Yy]$ ]]; then
    kind delete cluster --name "${CLUSTER_NAME}"
  else
    echo "Aborting without changes."
    exit 0
  fi
fi

kind create cluster --name "${CLUSTER_NAME}" --config "${CONFIG_PATH}"

kubectl cluster-info

echo ">> Creating base namespaces"
kubectl apply -f k8s/namespaces.yaml

