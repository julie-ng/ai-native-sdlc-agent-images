# ADR-001: Use the official Goose image for agent-base

- **Status:** Accepted
- **Date:** 2026-10-22
- **Context:** Shared base for headless agents; deployment target `linux/amd64`.

## Context

`agent-base` needs Goose, Python, Node, the GitHub CLI and supporting tools. Later role images inherit from it.

Two bases were evaluated:

- `ghcr.io/aaif-goose/goose:v1.48.0` — Debian 12.
- `mcr.microsoft.com/devcontainers/base:ubuntu-24.04` — Ubuntu 24.04.

Earlier spike measurements used different toolchains and could not establish which base produced the smaller equivalent image.

## Decision

Use the official Goose image as the base for `agent-base`.

- Pin the upstream image by digest.
- Install tools as root; run as `goose`, UID 1000.
- Reset the inherited entrypoint; default command is `bash`.
- Supply provider/model selection through runtime environment variables.
- Remove Microsoft-specific build paths from the current Dockerfile. The original comparison remains reproducible from its recorded source commit.

Registry publishing and role images are outside this decision.

## Evidence

Both AMD64 comparison variants used the identical Goose binary, Python and Node distributions, and shared tool installation.

| | Official Goose | Microsoft Ubuntu |
|---|---:|---:|
| Finished image | 1.019 GB | 1.913 GB |
| Installed dpkg packages | 144 | 256 |

The Goose variant was **46.7% smaller**: 893,723,586 fewer bytes.

Sizes are cumulative uncompressed image sizes reported by Docker, not compressed registry transfer sizes. These measurements used Node 22 and included GitLab tooling; they predate the Node 24 upgrade and GitHub-only cleanup and are not the current image's size.

Both variants passed:

- Tool execution, Python imports and virtual-environment creation.
- Non-root identity, writable workspace/state and no usable sudo.
- Recipe validation.
- Runtime-only provider/model routing without an initial config file, using an offline mock endpoint.

Tests ran through AMD64 emulation on an ARM64 host. No real-model calls, Kubernetes execution, cold-start benchmark or vulnerability comparison were performed.

[Exact measurements, versions and reproduction commands](../../docs/base-comparison.md).

## Alternatives considered

### Microsoft devcontainers Ubuntu

Passed the same checks, but produced the larger image.

The finished comparison variant included gcc, g++, make, SSH and sudo, absent from the Goose variant. Those tools may help tasks compiling native dependencies.

It also required renaming `vscode`, moving its home/group and removing its passwordless sudo grant.

## Consequences

- Smaller measured image with the comparison toolchain.
- Runtime user matches upstream Goose; less user customization.
- Compiler tools must be added deliberately when tasks require them. Non-root agents cannot assume they can install missing system packages.
- Debian and Ubuntu package versions differ; this compares two concrete images, not fully minimized distributions.
- Builds are not fully reproducible: source images are digest-pinned, but OS repositories and transitive dependencies are not snapshot-locked.
- Image configuration does not establish the platform's isolation boundary.

## Revisit when

- Required task tooling substantially changes the size comparison.
- Upstream base contents or architecture support changes.
- Compatibility or security findings favor another base.
