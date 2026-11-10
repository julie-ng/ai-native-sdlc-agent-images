# Agent images

Shared base for headless Goose agents in the [AI-native SDLC platform](https://github.com/julie-ng/ai-native-sdlc). Contributors: read [AGENTS.md](AGENTS.md).

- **Image:** `agent-base`; registry/organization prefix and publishing workflow remain to be chosen.
- **Base:** official Goose on Debian 12. [ADR-001](architecture/decisions/001-agent-base-image.md) records the choice and historical size comparison.
- **Target:** `linux/amd64`; development hosts may be ARM64.
- **Runtime:** `goose`, UID/GID 1000; home `/home/goose`; working directory `/workspace`; no usable sudo.
- **Configuration:** provider/model and secrets arrive at runtime. No baked `config.yaml` or automatic model invocation.
- **Default command:** `bash`, with runtime secret setup before command execution.
- **Demo scope:** GitHub only. Role images and skills are later work; no images published yet.

## Build and check

```sh
docker build --platform linux/amd64 -t agent-base:dev .
docker run --rm --network none --platform linux/amd64 agent-base:dev sh /usr/local/bin/agent-image-smoke-test
docker run --rm -i --network none --platform linux/amd64 agent-base:dev python3 - < scripts/check-runtime-config.py
docker run --rm -i --network none --platform linux/amd64 agent-base:dev sh -s < scripts/check-entrypoint.sh
```

- The first check exercises the toolchain, runtime permissions and recipe validation.
- The second uses a loopback mock API with a synthetic key. It verifies environment-only provider/model routing without a config file.
- The third checks runtime secret loading and commit signing with fake credentials.
- These checks make no real-model calls and do not verify gateway authentication.

For a real task:

- Supply `GOOSE_PROVIDER`, `GOOSE_MODEL`, and the chosen provider's runtime authentication.
- Run `goose run --recipe /recipes/smoke-test.yaml` for the optional model-backed smoke recipe. It makes model calls and is separate from the offline checks.
- Clone the repository with writable files and set the process working directory to that checkout.

Runtime/platform work remains:

- CSI secret delivery and token-broker integration.
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

The current AMD64 image measures **0.956 GB** uncompressed. Build measurements and their limits are in [the comparison report](docs/base-comparison.md). The historical 46.7% comparison predates Node 24 and GitLab removal.

## Decision log

| Date/context | Decision and reasoning |
|---|---|
| 2026-10-22 bootstrap | Review repository guidance separately from the first Dockerfile PR. |
| 2026-10-22 image contract | Name the image `agent-base`; keep the project prefix in the registry/organization namespace. |
| 2026-10-22 runtime | `goose`, UID 1000, on AMD64; environment variables select provider/model. Goose calls model providers without additional coding harness CLIs. |
| 2026-10-22 base accepted | Use official Goose/Debian; remove Microsoft-specific build paths. [ADR-001](architecture/decisions/001-agent-base-image.md) preserves the comparison and tradeoffs. |
| 2026-10-22 Node LTS | Upgrade Node 22 to the latest verified LTS, 24.22.1, with bundled npm 11.19.1; pin the image digest. |
| 2026-10-22 GitHub-only demo | Remove GitLab CLI from installation and smoke checks; this demo only needs GitHub. |
| 2026-10-22 remaining defaults | Python 3.12 with venv/uv, TypeScript/tsx and GPG. Keys arrive at runtime. Role skills/task recipes are deferred; ship only an optional smoke recipe. |
| 2026-11-10 issue #7 | Load optional CSI files at startup; keep credentials out of image layers and use a fresh private GPG home to select only the mounted signing key. |

## Publishing

Images are published to Azure Container Registry when changes are pushed to `main`.

## Runtime secrets and Git setup

The entrypoint reads optional files from `AGENT_SECRETS_DIR` (default `/mnt/agent-secrets`) as `goose`, then executes the supplied command. With no files or identity variables, it starts `bash` as before. Mounted files override corresponding environment values; absent files leave them unchanged.

| File | Runtime setup |
|---|---|
| `vercel-ai-gateway-api-key` | Exports `AI_GATEWAY_API_KEY`. |
| `julieio-goose-github-pat` | Exports `GH_TOKEN`; configures the GitHub HTTPS credential helper without storing the token. |
| `agent-gpg-private-key` | Imports an unencrypted ASCII-armored private key into a fresh private `GNUPGHOME` under `$HOME`; sets global Git signing fingerprint and enables commit signing. Invalid keys fail startup. |

The workflow supplies `GIT_USER_NAME` and `GIT_USER_EMAIL`; each nonempty value sets the corresponding global Git identity. `$HOME` must be writable. Provider/model selection remains in `GOOSE_PROVIDER` and `GOOSE_MODEL`. Secrets and signing state are runtime-only; do not persist the runtime home into an image.

CI runs the entrypoint check from the checkout via stdin; it exercises missing secrets, environment preservation, fake mounted credentials, a generated throwaway signing key and a verified signed commit, with networking disabled. It does not verify CSI delivery or real GitHub authentication.

Local verification (2026-11-10): AMD64 build, entrypoint signing check, default shell/UID and offline provider routing passed on an ARM64 host. The full smoke check stopped at `uv --version` with a QEMU signal 11; native AMD64 CI validation remains unverified.
