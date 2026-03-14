#!/usr/bin/env bash
set -euo pipefail

SCENARIO=${1:-}

if [[ -z "${SCENARIO}" ]]; then
  echo "Usage: $0 <scenario>"
  echo "  scenario: pod-kill | pod-delay | all"
  echo ""
  echo "  pod-kill  - Remove pod-kill chaos"
  echo "  pod-delay - Remove network-delay chaos"
  echo "  all       - Remove all chaos experiments (apply delete to known scenario files)"
  exit 1
fi

case "${SCENARIO}" in
  pod-kill)
    FILE="k8s/chaos/pod-kill.yaml"
    echo ">> Deleting chaos scenario '${SCENARIO}' from ${FILE}"
    kubectl delete -f "${FILE}" --ignore-not-found=true
    ;;
  pod-delay)
    FILE="k8s/chaos/pod-delay.yaml"
    echo ">> Deleting chaos scenario '${SCENARIO}' from ${FILE}"
    kubectl delete -f "${FILE}" --ignore-not-found=true
    ;;
  all)
    echo ">> Deleting all chaos scenarios"
    for f in k8s/chaos/pod-kill.yaml k8s/chaos/pod-delay.yaml; do
      if [[ -f "${f}" ]]; then
        kubectl delete -f "${f}" --ignore-not-found=true
      fi
    done
    echo ">> Done."
    ;;
  *)
    echo "Unknown scenario '${SCENARIO}'. Use 'pod-kill', 'pod-delay', or 'all'."
    exit 1
    ;;
esac
