FROM python:3.11-slim

ARG REQUIREMENTS_FILE=requirements-ci.txt

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /opt/ci

COPY requirements.txt /opt/ci/requirements.txt
COPY ${REQUIREMENTS_FILE} /opt/ci/requirements-ci.txt

RUN python -m pip install -U pip && \
    python -m pip install -r /opt/ci/requirements-ci.txt && \
    python -c "import nltk; nltk.download('stopwords', quiet=True)"
