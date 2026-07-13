# syntax=docker/dockerfile:1.7

ARG PYTHON_IMAGE=python:3.13-slim-bookworm

FROM ${PYTHON_IMAGE}

ARG FAVA_TAG

LABEL org.opencontainers.image.title="Fava" \
      org.opencontainers.image.description="Multi-architecture Fava container image" \
      org.opencontainers.image.source="https://github.com/beancount/fava" \
      org.opencontainers.image.version="${FAVA_TAG}" \
      org.opencontainers.image.licenses="MIT"

ENV FAVA_HOST=0.0.0.0 \
    FAVA_PORT=5000 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

RUN test -n "${FAVA_TAG}" \
    && FAVA_VERSION="${FAVA_TAG#v}" \
    && python -m pip install --no-cache-dir "fava==${FAVA_VERSION}" \
    && FAVA_VERSION="${FAVA_VERSION}" python -c 'import os; from importlib.metadata import version; from pathlib import Path; import fava; assert version("fava") == os.environ["FAVA_VERSION"]; assert list(Path(fava.__file__).parent.rglob("_layout.html"))' \
    && useradd --create-home --uid 10001 --shell /usr/sbin/nologin fava

USER fava
WORKDIR /data

EXPOSE 5000
VOLUME ["/data"]

ENTRYPOINT ["fava"]
CMD ["/data/ledger.beancount"]
