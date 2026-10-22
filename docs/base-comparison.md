# Base-image comparison

Historical comparison from commit `b244ea3124aa615305e4b9f2efe512fe7ad0b96c`, before the Node 24 upgrade and GitHub-only cleanup. The current Dockerfile only builds the accepted Goose/Debian variant; these sizes do not describe the current image. [Decision: ADR-001](../architecture/decisions/001-agent-base-image.md).

2026-10-22. Docker Engine 29.8.0 / BuildKit 0.33.0, ARM64 host, AMD64 images executed through emulation. Both builds and offline checks passed.

## Method and criteria

- One Dockerfile; override only `BASE_IMAGE`. Same Goose binary (SHA-256 `c871670b3df09b1d6238d001d88d936b7e5c6da7cc0f335cde6f583fad1feffb`), Python/Node distributions, tool versions, user and test commands.
- Go/no-go for the implementation: build AMD64; tools execute; Python imports and venv work; npm cache writable; workspace/log/session directories writable; UID 1000; no usable sudo; recipe validates; environment-only provider/model selection reaches a local mock without baked config.
- The source distro differs: Debian 12 versus Ubuntu 24.04. OS package versions and inherited tools intentionally remain distro-specific. This compares these two concrete finished images, not minimally optimized Debian versus Ubuntu.
- No real credentials supplied to builds or checks. Build-context allowlist plus final configuration/history inspection found no task-supplied secrets or provider/model defaults. Upstream layers were not independently audited.

## Measurements

`docker image inspect --platform linux/amd64 … --format '{{.Size}}'`; cumulative uncompressed image size, decimal GB. Not compressed registry transfer size or unique local disk usage.

| | Official Goose | Microsoft devcontainers Ubuntu |
|---|---:|---:|
| Bare base, bytes | 481,127,158 | 1,040,308,746 |
| Finished image, bytes | 1,019,041,904 | 1,912,765,490 |
| Finished image, GB | 1.019 | 1.913 |
| Installed dpkg packages | 144 | 256 |

The Goose variant saved **893,723,586 bytes (46.7%)** relative to Microsoft. This was an equivalent-toolchain comparison; the older ARM64 spike numbers were not equivalent.

## Tradeoffs

| | Official Goose | Microsoft devcontainers Ubuntu |
|---|---|---|
| Runtime contents | Smaller starting point; need to add task tools deliberately | Includes gcc, g++, make, ssh and sudo in the measured final image; those commands were absent from the Goose variant |
| User setup | Upstream `goose`, UID 1000 | Rename `vscode`, move home/group, remove passwordless sudo grant |
| Goose provisioning | Already installed | Copy identical upstream binary; required libc/libstdc++ dependencies provided by Ubuntu |
| OS package examples | git 2.39.5, jq 1.6, ripgrep 13.0.0 | git 2.43.0, jq reports 1.7, ripgrep 14.1.0 |
| Maintenance | Follows upstream Goose's Debian base | Follows Microsoft's Ubuntu image plus separately sourced Goose |

The Microsoft tools can help tasks compiling native dependencies. The smaller Goose image may need those added for such tasks. Non-root execution means an unattended agent cannot assume it can install missing system packages. Neither image configuration establishes a Kubernetes isolation boundary; pod/container policy is separate.

No cold-start, registry-transfer, native AMD64 performance, vulnerability or real-model comparison was performed. More packages do not by themselves establish a vulnerability count. No build-speed conclusion: shared BuildKit cache and parallel builds would confound it.

## Reproduce the historical comparison

Extract the recorded source snapshot first; the current Dockerfile no longer accepts a Microsoft base override. This snapshot includes Node 22 and GitLab CLI to preserve the original conditions.

```sh
comparison_dir="$(mktemp -d)"
git archive b244ea3124aa615305e4b9f2efe512fe7ad0b96c | tar -x -C "$comparison_dir"
docker build --platform linux/amd64 -t agent-base:comparison-goose "$comparison_dir"
docker build --platform linux/amd64 \
  --build-arg BASE_IMAGE=mcr.microsoft.com/devcontainers/base:ubuntu-24.04@sha256:d94c97dd9cacf183d0a6fd12a8e87b526e9e928307674ae9c94139139c0c6eae \
  -t agent-base:comparison-microsoft "$comparison_dir"
```

Run the checks from that snapshot against each tag. Exact byte-for-byte reproduction is not guaranteed: OS repositories and transitive dependencies were not snapshot-locked.

Source images and versions are pinned in the snapshot. Primary sources: [Goose Dockerfile](https://github.com/aaif-goose/goose/blob/v1.48.0/Dockerfile), [Microsoft base source](https://github.com/devcontainers/images/tree/main/src/base-ubuntu), [gh](https://github.com/cli/cli/releases/tag/v2.99.0). Observed image behavior, not current documentation alone, determines the results above.

## Current Goose/Debian build

After accepting Goose/Debian, upgrading to Node 24.22.1 (npm 11.19.1), removing GitLab CLI and deleting Microsoft-specific build paths:

- AMD64 `agent-base:dev`: **956,107,246 bytes** (0.956 GB), using the same uncompressed size method.
- Offline toolchain and runtime-only configuration checks passed under AMD64 emulation on ARM64.
- Confirmed Debian 12, Node/npm versions and absence of `glab`.
- No new Microsoft image was built with this toolchain; do not reuse 46.7% as a comparison of the current image.

## Decision log

| Date/context | Decision and reasoning |
|---|---|
| 2026-10-22 | Default to the Goose variant for review: the agreed tools and offline runtime checks passed, with a 46.7% size saving. The comparison snapshot records the Microsoft build option and its additional tools. No images published. |
| 2026-10-22 architect review | Accept Goose/Debian and remove Microsoft-specific code from the current Dockerfile. Preserve comparison reproduction through its source commit; upgrade Node to LTS and remove GitLab from the current image. |
