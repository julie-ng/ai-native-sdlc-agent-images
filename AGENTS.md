# AGENTS.md

Project-specific instructions for any agent working in this repository, alongside the shared instructions below.

## About this repository

- Dockerfiles and supporting assets for headless agent images. Shared image name: **`agent-base`**; an organization/registry prefix is separate.
- Shared base first; later role images inherit from it and differ in baked skills and labels. Do not invent role contents or implement them unasked.
- Cloud runtime: Goose calls model providers; no Claude Code, Codex CLI or ACP adapters added to the base.
- Provider/model selection comes from runtime environment variables. No baked provider/model defaults or interactive configuration.
- Deployment target: `linux/amd64`, including when building on an ARM64 development machine. Runtime user: `goose`, UID 1000.
- GitHub-only demo: use `gh`; do not add GitLab tooling.
- Python and Node belong in the shared base; exact versions and additional tools are implementation defaults to document, not permanent architecture decisions.
- Platform design and ADRs live in [ai-native-sdlc](https://github.com/julie-ng/ai-native-sdlc/tree/main/architecture). This repository owns image implementation and measured findings. Flag conflicts rather than silently choosing.

## Working mode and reading order

- Read this file, then the root README, then docs and source relevant to the task. Consult the platform ADRs when changing an architectural contract.

## Verify, don't guess

- For image comparisons, keep the toolchain and test conditions equivalent. Record base digests, architecture, size units/method, version differences and inherited tools. Do not compare a bare base against a provisioned image as if equivalent.
- Build the affected target and run relevant smoke checks. Check tool execution, runtime identity, writable workspace/home/state, recipe validity and configuration behavior as applicable. Do not claim a model call, Kubernetes execution or security audit happened unless it did.

## Images and security

- No API keys, tokens, SSH/private signing keys or cloud credentials in build args, Dockerfile ENV, build context or image layers. Keep a restrictive `.dockerignore`; inspect changes to build inputs and image configuration/history.
- Runtime signing/authentication setup is separate from image construction. Do not copy the build agent's identity, keys or Git credentials into the image.
- Install system tools as root, provision ownership, then drop privileges for runtime. No usable passwordless sudo for the runtime user.
- Do not add cloud CLIs, Docker-in-Docker, runtime skill fetching or token-broker logic without a scoped request.
- Pin images and downloaded tools deliberately; document floating dependencies and reproducibility limits. Use primary upstream sources and validate architecture support.
- **Config != boundary.** Prompt rules, recipe settings, image naming and baked skill selection are not isolation boundaries. Container/VM/restricted-user mechanisms and platform permissions need their own evidence.
- Do not put `sandbox` in image names: the image alone provides no isolation guarantee.

## Commit attribution

- Codex commits include `Co-Authored-By: Codex <version> <model> <codex@users.noreply.github.com>`, for example `Co-Authored-By: Codex 6.1 Sol <codex@users.noreply.github.com>`. Keep the configured agent as author. Other model co-author trailers should include model name and version.

## Shared instructions

Read and follow these alongside this repo’s project-specific instructions. Explicit project-specific exceptions override shared defaults; otherwise both apply.

- [Communication and writing](./.agents/shared/communication.md)
- [Git & GitHub workflow](./.agents/shared/github-workflow.md)
- [Cross-session memory](./.agents/shared/memory.md)
- [Working practices](./.agents/shared/working-practices.md)
