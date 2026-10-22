# syntax=docker/dockerfile:1
# Local development default; release builds must supply a digest-pinned base.
ARG BASE_IMAGE=agent-base:dev
FROM ${BASE_IMAGE}
LABEL org.opencontainers.image.title="agent-reviewer" \
      io.julie.agent.role="reviewer"
COPY --chown=goose:goose images/reviewer/recipe.yaml \
    images/reviewer/instructions.md \
    images/reviewer/prompt.md \
    /recipes/reviewer/
# Inherit the base's non-root user, workspace and bash command.
