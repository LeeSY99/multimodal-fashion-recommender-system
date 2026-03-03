#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <domain> <email>"
  exit 1
fi

DOMAIN="$1"
EMAIL="$2"

if command -v apt-get >/dev/null 2>&1; then
  sudo apt-get update
  sudo apt-get install -y nginx certbot python3-certbot-nginx
elif command -v dnf >/dev/null 2>&1; then
  sudo dnf update -y
  sudo dnf install -y nginx certbot python3-certbot-nginx
else
  echo "[ERROR] Unsupported package manager. Need apt-get or dnf." >&2
  exit 1
fi

sudo mkdir -p /var/www/certbot

if [[ -d /etc/nginx/sites-available ]]; then
  sudo cp infra/nginx/fashion-search.conf /etc/nginx/sites-available/fashion-search.conf
  sudo sed -i "s/YOUR_DOMAIN/${DOMAIN}/g" /etc/nginx/sites-available/fashion-search.conf
  sudo ln -sf /etc/nginx/sites-available/fashion-search.conf /etc/nginx/sites-enabled/fashion-search.conf
else
  sudo cp infra/nginx/fashion-search.conf /etc/nginx/conf.d/fashion-search.conf
  sudo sed -i "s/YOUR_DOMAIN/${DOMAIN}/g" /etc/nginx/conf.d/fashion-search.conf
fi

sudo systemctl enable --now nginx
sudo nginx -t
sudo systemctl reload nginx

sudo certbot --nginx -d "${DOMAIN}" --non-interactive --agree-tos -m "${EMAIL}" --redirect
sudo systemctl reload nginx

echo "[INFO] HTTPS is enabled for ${DOMAIN}" 
