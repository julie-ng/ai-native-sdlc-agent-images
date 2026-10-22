# syntax=docker/dockerfile:1
# Local development default; release builds must supply a digest-pinned base.
ARG BASE_IMAGE=agent-base:dev
FROM ${BASE_IMAGE}
LABEL org.opencontainers.image.title="agent-planner" \
      io.julie.agent.role="planner"
COPY --chown=goose:goose images/planner/recipe.yaml /recipes/planner.yaml
# Inherit the base's non-root user, workspace and bash command.
