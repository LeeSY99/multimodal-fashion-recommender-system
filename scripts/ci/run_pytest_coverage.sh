#!/usr/bin/env bash
set -euo pipefail

PYTHON_BIN=${PYTHON_BIN:-python3}

PYTHONPATH=. "${PYTHON_BIN}" -m pytest -q \
  --cov=fashion_core \
  --cov=service \
  --cov=common \
  --cov-report=term-missing \
  --cov-report=xml \
  --junitxml=pytest-report.xml \
  --cov-fail-under=60
