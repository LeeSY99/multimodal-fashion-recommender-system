#!/usr/bin/env bash
set -euo pipefail

DOMAIN="${1:-}"

echo "== Docker =="
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'

echo "\n== systemd =="
systemctl is-active fashion-search.service || true

echo "\n== Port check =="
sudo ss -ltnp | grep -E ':80|:443|:3000' || true

echo "\n== Nginx error tail =="
sudo tail -n 20 /var/log/nginx/fashion_error.log || true

echo "\n== Service logs tail =="
CID=$(docker ps --filter "name=multimodal-fashion-search" -q | head -n1)
if [[ -n "${CID}" ]]; then
  docker logs --tail 20 "${CID}" || true
fi

if [[ -n "${DOMAIN}" ]]; then
  echo "\n== TLS cert check (${DOMAIN}) =="
  echo | openssl s_client -servername "${DOMAIN}" -connect "${DOMAIN}:443" 2>/dev/null | openssl x509 -noout -dates || true
fi
