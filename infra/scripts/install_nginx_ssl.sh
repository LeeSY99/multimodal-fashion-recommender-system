#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <domain> <email>"
  exit 1
fi

DOMAIN="$1"
EMAIL="$2"

sudo apt-get update
sudo apt-get install -y nginx certbot python3-certbot-nginx

sudo mkdir -p /var/www/certbot
sudo cp infra/nginx/fashion-search.conf /etc/nginx/sites-available/fashion-search.conf
sudo sed -i "s/YOUR_DOMAIN/${DOMAIN}/g" /etc/nginx/sites-available/fashion-search.conf

sudo ln -sf /etc/nginx/sites-available/fashion-search.conf /etc/nginx/sites-enabled/fashion-search.conf
sudo nginx -t
sudo systemctl reload nginx

sudo certbot --nginx -d "${DOMAIN}" --non-interactive --agree-tos -m "${EMAIL}" --redirect
sudo systemctl reload nginx

echo "[INFO] HTTPS is enabled for ${DOMAIN}" 
