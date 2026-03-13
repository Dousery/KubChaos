#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo ">> Building demo-api image"
docker build \
  -t demo-api:latest \
  "${ROOT_DIR}/app/demo-api"

echo ">> Building demo-downstream image"
docker build \
  -t demo-downstream:latest \
  "${ROOT_DIR}/app/demo-downstream"

echo "Images built:"
docker images | grep "demo-"

