#!/usr/bin/env bash
set -euo pipefail

SCENARIO=${1:-pod-kill}

case "${SCENARIO}" in
  pod-kill)
    FILE="k8s/chaos/pod-kill.yaml"
    ;;
  pod-delay)
    FILE="k8s/chaos/pod-delay.yaml"
    ;;
  *)
    echo "Unknown scenario '${SCENARIO}'. Use 'pod-kill' or 'pod-delay'."
    exit 1
    ;;
esac

echo ">> Applying chaos scenario '${SCENARIO}' from ${FILE}"
kubectl apply -f "${FILE}"

