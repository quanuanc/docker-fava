# syntax=docker/dockerfile:1.7

ARG NODE_IMAGE=node:24-bookworm-slim
ARG PYTHON_IMAGE=python:3.13-slim-bookworm

FROM ${NODE_IMAGE} AS frontend-builder

ARG FAVA_TAG

RUN test -n "${FAVA_TAG}" \
    && apt-get update \
    && apt-get install --yes --no-install-recommends ca-certificates git \
    && rm -rf /var/lib/apt/lists/* \
    && git clone --depth 1 --branch "${FAVA_TAG}" \
        https://github.com/beancount/fava.git /src/fava

WORKDIR /src/fava/frontend

RUN npm ci \
    && npm run build \
    && rm -rf node_modules


FROM ${PYTHON_IMAGE} AS wheel-builder

ARG FAVA_TAG

COPY --from=frontend-builder /src/fava /src/fava

RUN SETUPTOOLS_SCM_PRETEND_VERSION_FOR_FAVA="${FAVA_TAG#v}" \
    python -m pip wheel --no-cache-dir --wheel-dir /wheels /src/fava


FROM ${PYTHON_IMAGE} AS runtime

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

COPY --from=wheel-builder /wheels /wheels

RUN python -m pip install --no-cache-dir --no-index \
        --find-links=/wheels /wheels/fava-*.whl \
    && rm -rf /wheels \
    && useradd --create-home --uid 10001 --shell /usr/sbin/nologin fava

USER fava
WORKDIR /data

EXPOSE 5000
VOLUME ["/data"]

ENTRYPOINT ["fava"]
CMD ["/data/ledger.beancount"]
