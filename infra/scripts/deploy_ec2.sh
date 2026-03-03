#!/usr/bin/env bash
set -euo pipefail

if [[ ${EUID} -eq 0 ]]; then
  echo "[ERROR] sudo without root shell is expected. Run as regular user." >&2
  exit 1
fi

APP_DIR="/opt/multimodal-fashion-recommender-system"
SERVICE_FILE="/etc/systemd/system/fashion-search.service"
SERVICE_TMPL="infra/systemd/fashion-search.service"
RUN_USER="${USER}"
RUN_GROUP="$(id -gn)"

if command -v apt-get >/dev/null 2>&1; then
  sudo apt-get update
  sudo apt-get install -y ca-certificates curl git jq
elif command -v dnf >/dev/null 2>&1; then
  sudo dnf update -y
  sudo dnf install -y ca-certificates curl git jq shadow-utils
else
  echo "[ERROR] Unsupported package manager. Need apt-get or dnf." >&2
  exit 1
fi

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

sed \
  -e "s/__RUN_USER__/${RUN_USER}/g" \
  -e "s/__RUN_GROUP__/${RUN_GROUP}/g" \
  "${SERVICE_TMPL}" | sudo tee "${SERVICE_FILE}" >/dev/null
sudo systemctl daemon-reload
sudo systemctl enable --now fashion-search.service

cat <<MSG
[INFO] Deploy complete.
[INFO] Verify: systemctl status fashion-search.service
[INFO] Verify: docker ps
MSG
