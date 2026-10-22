# syntax=docker/dockerfile:1
# Comparison override: --build-arg BASE_IMAGE=mcr.microsoft.com/devcontainers/base:ubuntu-24.04@sha256:d94c97dd9cacf183d0a6fd12a8e87b526e9e928307674ae9c94139139c0c6eae
ARG BASE_IMAGE=ghcr.io/aaif-goose/goose:v1.48.0@sha256:ac918fcb8fcf2e3d541c62ae3a5cd6482282704f9f659eba2288106508c42fba
FROM ghcr.io/aaif-goose/goose:v1.48.0@sha256:ac918fcb8fcf2e3d541c62ae3a5cd6482282704f9f659eba2288106508c42fba AS goose-source
FROM node:22.20.0-bookworm-slim@sha256:b21fe589dfbe5cc39365d0544b9be3f1f33f55f3c86c87a76ff65a02f8f5848e AS node-source
FROM python:3.12.12-slim-bookworm@sha256:593bd06efe90efa80dc4eee3948be7c0fde4134606dd40d8dd8dbcade98e669c AS python-source

FROM ${BASE_IMAGE} AS base
USER root
ENV HOME=/home/goose PATH=/usr/local/bin:$PATH

# Both variants use the identical upstream Goose binary. Avoid adding a second
# binary layer when it is already present in the official base.
# https://github.com/aaif-goose/goose/blob/v1.48.0/Dockerfile
RUN --mount=from=goose-source,source=/usr/local/bin/goose,target=/tmp/goose-upstream \
    if [ ! -x /usr/local/bin/goose ]; then install -m 0755 /tmp/goose-upstream /usr/local/bin/goose; fi

COPY --from=python-source /usr/local/ /usr/local/
COPY --from=node-source /usr/local/bin/node /usr/local/bin/node
COPY --from=node-source /usr/local/lib/node_modules/npm /usr/local/lib/node_modules/npm
RUN ln -sf ../lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
    && ln -sf ../lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx

ARG GH_VERSION=2.99.0
ARG GLAB_VERSION=1.124.0
ARG UV_VERSION=0.9.4
ARG TYPESCRIPT_VERSION=5.9.3
ARG TSX_VERSION=4.20.6
RUN --mount=type=bind,source=scripts/install-tools.sh,target=/tmp/install-tools.sh \
    sh /tmp/install-tools.sh

# UID 1000 is goose upstream and vscode in the Microsoft base. Keep one runtime
# identity and remove the Microsoft base's passwordless sudo grant.
RUN set -eu; \
    if ! id goose >/dev/null 2>&1; then \
      usermod -l goose -d /home/goose -m vscode; groupmod -n goose vscode; \
    fi; \
    usermod -G '' goose; \
    rm -f /etc/sudoers.d/vscode; \
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
