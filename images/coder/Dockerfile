# syntax=docker/dockerfile:1
# Local development default; release builds must supply a digest-pinned base.
ARG BASE_IMAGE=agent-base:dev
FROM ${BASE_IMAGE}
LABEL org.opencontainers.image.title="agent-coder" \
      io.julie.agent.role="coder"
COPY --chown=goose:goose images/coder/recipe.yaml /recipes/coder.yaml
# Inherit the base's non-root user, workspace and bash command.
