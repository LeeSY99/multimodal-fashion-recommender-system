#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PG_DIR="${ROOT_DIR}/postgres"
CONN="postgresql://fashion:fashion@localhost:5432/fashion"

cd "${PG_DIR}"
docker compose up -d

if ! command -v psql >/dev/null 2>&1; then
  echo "[ERROR] psql not found. Install: sudo apt-get install -y postgresql-client"
  exit 1
fi

psql "${CONN}" -f 03_benchmark_before.sql
psql "${CONN}" -f 04_add_indexes.sql
psql "${CONN}" -f 05_benchmark_after.sql

echo "[INFO] Done. Fill db_tuning/report-template.md with measured values."
