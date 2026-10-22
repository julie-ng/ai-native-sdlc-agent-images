# Agent images

Images for headless Goose agents in the [AI-native SDLC platform](https://github.com/julie-ng/ai-native-sdlc). Contributors: read [AGENTS.md](AGENTS.md).

- **Image:** `agent-base`; registry/organization prefix and publishing workflow remain to be chosen.
- **Role images:** `agent-planner`, `agent-coder`, `agent-reviewer`; each inherits the base and adds its own Goose recipe and labels. [Builds, contracts and checks](docs/role-images.md).
- **Base:** official Goose on Debian 12. [ADR-001](architecture/decisions/001-agent-base-image.md) records the choice and historical size comparison.
- **Target:** `linux/amd64`; development hosts may be ARM64.
- **Runtime:** `goose`, UID/GID 1000; home `/home/goose`; working directory `/workspace`; no usable sudo.
- **Configuration:** provider/model and secrets arrive at runtime. No baked `config.yaml` or automatic model invocation.
- **Default command:** `bash`, with the inherited Goose entrypoint reset.
- **Demo scope:** GitHub only. Role recipes are packaged; additional skills and platform integration remain later work. No images published yet.

## Build and check

```sh
docker build --platform linux/amd64 -f images/base/Dockerfile -t agent-base:dev .
docker run --rm --network none --platform linux/amd64 agent-base:dev sh /usr/local/bin/agent-image-smoke-test
docker run --rm -i --network none --platform linux/amd64 agent-base:dev python3 - < scripts/check-runtime-config.py
```

- The first check exercises the toolchain, runtime permissions and recipe validation.
- The second uses a loopback mock API with a synthetic key. It verifies environment-only provider/model routing without a config file.
- Neither check makes real-model calls or verifies gateway authentication.
- All builds use the repository root as their build context. The base Dockerfile and smoke recipe live together under `images/base/`; installation and check scripts remain shared under `scripts/`.

For a real task:

- Supply `GOOSE_PROVIDER`, `GOOSE_MODEL`, and the chosen provider's runtime authentication.
- Run `goose run --recipe /recipes/smoke-test.yaml` for the optional model-backed smoke recipe. It makes model calls and is separate from the offline checks.
- Prepare a writable checkout and set the process working directory to it. For role tasks, use the corresponding image and its [recipe inputs](docs/role-images.md#recipe-contracts).

Runtime/platform work remains:

- Secret-file delivery and Git authentication/identity setup.
- Signing-key delivery and token-broker integration.
- Kubernetes execution and real-model integration checks.

## Build defaults

| Component | Version | Description |
|---|---|---|
| Goose | 1.48.0 | Headless agent runtime; inherited from the pinned upstream image. |
| Python | 3.12.12 | Python tasks and virtual environments via `venv`. |
| uv | 0.9.4 | Python package and environment tooling. |
| Node | 24.22.1 | Latest LTS verified on 2026-10-22; JavaScript runtime. |
| npm / npx | 11.19.1 | Bundled Node package manager and package runner. |
| TypeScript | 5.9.3 | TypeScript compiler (`tsc`). |
| tsx | 4.20.6 | Run TypeScript files directly. |
| gh | 2.99.0 | GitHub CLI for issues, pull requests and API access. |

Version and build notes:

- Node follows the [latest LTS release](https://nodejs.org/en/about/previous-releases), pinned to a concrete version and image digest; [official release index](https://nodejs.org/dist/index.json). Upgrade deliberately rather than floating with each build.
- Goose follows the historical spike. Python 3.12 and the other tool versions are initial defaults, customizable later; no claim that every component is the latest or security-approved version.
- Python and Node come from pinned official distribution images. System tools include git, GPG, curl, jq and ripgrep from Debian packages.
- Source images are digest-pinned. Debian repositories and transitive pip/npm dependencies are not snapshot-locked; release archives are version-pinned but not checksum-verified. Builds are not fully reproducible.
- The build-context allowlist excludes Git metadata, credentials, handoffs and unrelated local files. It does not audit upstream images.

The AMD64 toolchain baseline measured **0.956 GB** uncompressed before the role-image restructure. Build measurements and their limits are in [the comparison report](docs/base-comparison.md). The historical 46.7% comparison predates Node 24 and GitLab removal.

## Decision log

| Date/context | Decision and reasoning |
|---|---|
| 2026-10-22 role images | Add thin planner/coder/reviewer images with distinct recipes and inherited shared tools/skills. Runtime credentials and platform permissions remain separate. [Contracts and verification](docs/role-images.md). |
| 2026-10-22 image layout | Group Dockerfiles and recipes under `images/<role>/`, starting with the base. Keep a root build context for shared scripts; this move does not change runtime behavior. |
| 2026-10-22 bootstrap | Review repository guidance separately from the first Dockerfile PR. |
| 2026-10-22 image contract | Name the image `agent-base`; keep the project prefix in the registry/organization namespace. |
| 2026-10-22 runtime | `goose`, UID 1000, on AMD64; environment variables select provider/model. Goose calls model providers without additional coding harness CLIs. |
| 2026-10-22 base accepted | Use official Goose/Debian; remove Microsoft-specific build paths. [ADR-001](architecture/decisions/001-agent-base-image.md) preserves the comparison and tradeoffs. |
| 2026-10-22 Node LTS | Upgrade Node 22 to the latest verified LTS, 24.22.1, with bundled npm 11.19.1; pin the image digest. |
| 2026-10-22 GitHub-only demo | Remove GitLab CLI from installation and smoke checks; this demo only needs GitHub. |
| 2026-10-22 remaining defaults | Python 3.12 with venv/uv, TypeScript/tsx and GPG. Keys arrive at runtime. Role skills/task recipes are deferred; ship only an optional smoke recipe. |
