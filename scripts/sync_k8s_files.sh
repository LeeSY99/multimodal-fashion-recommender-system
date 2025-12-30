#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

mkdir -p "$ROOT_DIR/k8s/base/scripts" "$ROOT_DIR/k8s/base/config"

cp -f "$ROOT_DIR/scripts/fetch_assets.sh" "$ROOT_DIR/k8s/base/scripts/fetch_assets.sh"
cp -f "$ROOT_DIR/config/als_model.yaml" "$ROOT_DIR/k8s/base/config/als_model.yaml"

echo "[OK] Synced scripts/config -> k8s/base"
