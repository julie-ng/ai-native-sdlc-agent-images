# Agent images

Shared base for headless Goose agents in the [AI-native SDLC platform](https://github.com/julie-ng/ai-native-sdlc). Role images are later work. Contributors: read [AGENTS.md](AGENTS.md).

Image name: **`agent-base`**. Registry/organization prefix and publishing workflow remain to be chosen; no images have been published by this work.

- Default: official Goose base. [Measured comparison](docs/base-comparison.md): 1.019 GB versus 1.913 GB on Microsoft Ubuntu, AMD64.
- Runtime: `goose`, UID/GID 1000, `/home/goose`, working directory `/workspace`; no usable sudo.
- Tools: Goose, Python/venv/uv, Node/npm/TypeScript/tsx, git, GPG, curl, jq, ripgrep, gh and glab.
- No Claude Code, Codex CLI, ACP adapters, baked skills, cloud CLIs, or Docker daemon added.
- Provider/model selection and secrets arrive at runtime. No baked `config.yaml` or automatic model invocation. Default command: `bash`; inherited entrypoint reset.

## Build and check

```sh
docker build --platform linux/amd64 -t agent-base:goose .
docker run --rm --network none --platform linux/amd64 agent-base:goose sh /usr/local/bin/agent-image-smoke-test
docker run --rm -i --network none --platform linux/amd64 agent-base:goose python3 - < scripts/check-runtime-config.py
```

The second check uses a loopback mock API with a synthetic key. It verifies routing from environment variables without a config file, not real-model behavior or gateway authentication.

For a real task, supply `GOOSE_PROVIDER`, `GOOSE_MODEL`, and the chosen provider's runtime authentication. Run `goose run --recipe /recipes/smoke-test.yaml` for the optional model-backed smoke recipe. That invocation makes model calls; it is not part of the offline checks. No real-model call has been run for this comparison.

The image does not implement secret-file delivery, Git authentication/identity setup, signing-key delivery, token-broker integration, or Kubernetes execution. Those are runtime/platform work. Repository cloning must arrange writable files and set the process working directory to the cloned repository.

## Build defaults

| Component | Version |
|---|---|
| Goose | 1.48.0 |
| Python | 3.12.12 |
| uv | 0.9.4 |
| Node / npm | 22.20.0 / 10.9.3 |
| TypeScript / tsx | 5.9.3 / 4.20.6 |
| gh / glab | 2.99.0 / 1.124.0 |

These are comparison defaults, not a claim of latest or security-approved versions. Goose follows the historical spike; Python 3.12 and Node 22 are initial choices, customizable later. Python and Node are copied from pinned official distribution images so both variants have the same versions. Python shared-library imports and venv creation passed on both distributions; this is not exhaustive cross-distribution compatibility testing.

Base/source images are digest-pinned. Debian/Ubuntu package repositories and transitive pip/npm dependencies are not snapshot-locked; release downloads are version-pinned but not checksum-verified. Builds are not fully reproducible. The build-context allowlist excludes Git metadata, credentials, handoffs and unrelated local files; it does not prove the absence of secrets in upstream images.

## Decision log

| Date/context | Decision and reasoning |
|---|---|
| 2026-10-22 bootstrap | Keep repository setup separate from the first Dockerfile PR so guidance and implementation can be reviewed independently. |
| 2026-10-22 image contract | Name the shared image `agent-base`; keep the project prefix in the registry/organization namespace. |
| 2026-10-22 comparison | Same Goose binary, Python/Node distributions, tool installation and smoke checks on both bases; isolate the base-image choice from different Goose installation methods. |
| 2026-10-22 architect agreement | `goose`, UID 1000, for both test variants; deployment target AMD64. Runtime environment variables select provider/model; no additional coding harness CLIs. |
| 2026-10-22 implementation defaults | Python 3.12 with venv/uv, Node 22 with TypeScript/tsx, gh/glab and GPG. GPG supports the documented runtime signing design; keys are not baked. Role skill selection and task recipes remain deferred; ship only an optional smoke recipe. |
| 2026-10-22 result | Keep Goose as the default: measured final AMD64 image is 46.7% smaller. Microsoft comparison remains reproducible with a base build argument; production choice remains subject to architect review. |
