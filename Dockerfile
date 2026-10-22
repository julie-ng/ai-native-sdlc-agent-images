# syntax=docker/dockerfile:1
FROM node:24.22.1-bookworm-slim@sha256:55fb5f5a527ea2c5c4a95f963e48ef90aa38c7b346054fdc8ee9957a2b55d205 AS node-source
FROM python:3.12.12-slim-bookworm@sha256:593bd06efe90efa80dc4eee3948be7c0fde4134606dd40d8dd8dbcade98e669c AS python-source

FROM ghcr.io/aaif-goose/goose:v1.48.0@sha256:ac918fcb8fcf2e3d541c62ae3a5cd6482282704f9f659eba2288106508c42fba AS base
USER root
ENV HOME=/home/goose PATH=/usr/local/bin:$PATH

COPY --from=python-source /usr/local/ /usr/local/
COPY --from=node-source /usr/local/bin/node /usr/local/bin/node
COPY --from=node-source /usr/local/lib/node_modules/npm /usr/local/lib/node_modules/npm
RUN ln -sf ../lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
    && ln -sf ../lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx

ARG GH_VERSION=2.99.0
ARG UV_VERSION=0.9.4
ARG TYPESCRIPT_VERSION=5.9.3
ARG TSX_VERSION=4.20.6
RUN --mount=type=bind,source=scripts/install-tools.sh,target=/tmp/install-tools.sh \
    sh /tmp/install-tools.sh

# Upstream supplies goose, UID/GID 1000. Provision writable runtime state.
# https://github.com/aaif-goose/goose/blob/v1.48.0/Dockerfile
RUN set -eu; \
    mkdir -p /workspace /home/goose/.config/goose \
      /home/goose/.local/state/goose/logs /home/goose/.local/share/goose; \
    chown -R goose:goose /workspace /home/goose

COPY --chown=goose:goose recipes/ /recipes/
COPY scripts/smoke-test.sh /usr/local/bin/agent-image-smoke-test
USER goose
WORKDIR /workspace
# No provider, model, or credential defaults. Select these at runtime.
ENTRYPOINT []
CMD ["bash"]
