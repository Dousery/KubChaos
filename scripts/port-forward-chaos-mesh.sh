#!/usr/bin/env bash
set -euo pipefail

NAMESPACE=${NAMESPACE:-chaos-mesh}
PORT=${PORT:-2333}

# there is no fragile because there is only one pod in the namespace
POD=$(kubectl -n "${NAMESPACE}" get pod -l app.kubernetes.io/component=dashboard -o jsonpath='{.items[0].metadata.name}')

echo ">> Forwarding Chaos Mesh dashboard to http://localhost:${PORT}"
kubectl -n "${NAMESPACE}" port-forward "${POD}" "${PORT}:2333"

