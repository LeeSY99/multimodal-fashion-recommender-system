#!/usr/bin/env bash
set -euo pipefail

if [[ ${EUID} -eq 0 ]]; then
  echo "[ERROR] sudo without root shell is expected. Run as ubuntu user." >&2
  exit 1
fi

APP_DIR="/opt/multimodal-fashion-recommender-system"
SERVICE_FILE="/etc/systemd/system/fashion-search.service"

sudo apt-get update
sudo apt-get install -y ca-certificates curl git jq

if ! command -v docker >/dev/null 2>&1; then
  curl -fsSL https://get.docker.com | sudo sh
fi

sudo usermod -aG docker "${USER}"
sudo mkdir -p /opt

if [[ ! -d "${APP_DIR}/.git" ]]; then
  sudo git clone https://github.com/LeeSY99/multimodal-fashion-recommender-system.git "${APP_DIR}"
else
  sudo git -C "${APP_DIR}" pull --ff-only
fi

sudo chown -R "${USER}:${USER}" "${APP_DIR}"
cd "${APP_DIR}"

cp -n docker-compose.yaml docker-compose.prod.yaml || true

docker compose -f docker-compose.prod.yaml pull || true
docker compose -f docker-compose.prod.yaml up -d

sudo cp infra/systemd/fashion-search.service "${SERVICE_FILE}"
sudo systemctl daemon-reload
sudo systemctl enable --now fashion-search.service

cat <<MSG
[INFO] Deploy complete.
[INFO] Verify: systemctl status fashion-search.service
[INFO] Verify: docker ps
MSG
