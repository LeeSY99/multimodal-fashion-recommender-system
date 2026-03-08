#!/usr/bin/env bash
set -euo pipefail

PYTHON_BIN=${PYTHON_BIN:-python3}
PYTEST_WORKERS=${PYTEST_WORKERS:-auto}

PYTEST_ARGS=(
  -q
  --cov=fashion_core
  --cov=service
  --cov=common
  --cov-report=term-missing
  --cov-report=xml
  --junitxml=pytest-report.xml
  --cov-fail-under=60
)

if "${PYTHON_BIN}" -c "import xdist" >/dev/null 2>&1; then
  PYTEST_ARGS+=(-n "${PYTEST_WORKERS}" --dist=loadscope)
fi

PYTHONPATH=. "${PYTHON_BIN}" -m pytest "${PYTEST_ARGS[@]}"
