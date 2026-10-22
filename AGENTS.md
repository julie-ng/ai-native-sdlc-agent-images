# AGENTS.md

Rules for any agent working in this repository, regardless of harness or model. This file is the single source of truth for repository instructions.

## Git & GitHub configuration

- Use the configured agent identity, never the human developer's identity.
- In a dev container, load the provided read-only agent environment and follow its instructions. Consult the hosting checkout's devcontainer configuration for mounts; do not copy mount paths into documentation.
- Set repository-local `user.name` and `user.email` from `GIT_USER_NAME` and `GIT_USER_EMAIL`. Import the provided private GPG key, configure repository-local `user.signingkey` and `commit.gpgsign=true`, and sign all commits.
- Authenticate as `GITHUB_USERNAME` using `GITHUB_PAT`; export `GH_TOKEN="$GITHUB_PAT"` for `gh`, and use `gh auth setup-git` for HTTPS Git authentication. Never print or commit credential values.
- Codex commits include `Co-Authored-By: Codex <version> <model> <codex@users.noreply.github.com>`, for example `Co-Authored-By: Codex 6.1 Sol <codex@users.noreply.github.com>`. Keep the configured agent as author. Other model co-author trailers should include model name and version.

## About this repository

- Dockerfiles and supporting assets for headless agent images. Shared image name: **`agent-base`**; an organization/registry prefix is separate.
- Shared base first; later role images inherit from it and differ in baked skills and labels. Do not invent role contents or implement them unasked.
- Cloud runtime: Goose calls model providers; no Claude Code, Codex CLI or ACP adapters added to the base.
- Provider/model selection comes from runtime environment variables. No baked provider/model defaults or interactive configuration.
- Deployment target: `linux/amd64`, including when building on an ARM64 development machine. Runtime user: `goose`, UID 1000.
- GitHub-only demo: use `gh`; do not add GitLab tooling.
- Python and Node belong in the shared base; exact versions and additional tools are implementation defaults to document, not permanent architecture decisions.
- Platform design and ADRs live in [ai-native-sdlc](https://github.com/julie-ng/ai-native-sdlc/tree/main/architecture). This repository owns image implementation and measured findings. Flag conflicts rather than silently choosing.
- **The docs are the memory.** Record agreed changes, defaults, tradeoffs and verification limits alongside the implementation.

## Working mode and reading order

- Read this file, then the root README, then docs and source relevant to the task. Consult the platform ADRs when changing an architectural contract.
- Default to interactive work with the human architect. An explicit task or issue defines scope for independent work. Ask when direction is unclear; do not invent a design decision.
- Distinguish proposals, agreed decisions, implementation defaults and verified findings. Goals describe intended state, not necessarily current implementation.
- Check the repository before asking for information it may already contain. Flag adjacent problems; do not fix them unasked.

## Verify, don't guess

- Check technical claims against source, commands or primary documentation. Mark unverified claims in the file itself, not just chat.
- Prefer primary sources; identify secondary evidence when used. Describe the mechanism, not "it's handled."
- For image comparisons, keep the toolchain and test conditions equivalent. Record base digests, architecture, size units/method, version differences and inherited tools. Do not compare a bare base against a provisioned image as if equivalent.
- Build the affected target and run relevant smoke checks. Check tool execution, runtime identity, writable workspace/home/state, recipe validity and configuration behavior as applicable. Do not claim a model call, Kubernetes execution or security audit happened unless it did.
- Offline checks should not need real credentials or paid model calls. Separate process exit from actual task completion.
- For experiments, state the narrow question and per-layer go/no-go criteria before running. Keep partial findings and record failures plainly with actual output.

## Images and security

- No API keys, tokens, SSH/private signing keys or cloud credentials in build args, Dockerfile ENV, build context or image layers. Keep a restrictive `.dockerignore`; inspect changes to build inputs and image configuration/history.
- Runtime signing/authentication setup is separate from image construction. Do not copy the build agent's identity, keys or Git credentials into the image.
- Install system tools as root, provision ownership, then drop privileges for runtime. No usable passwordless sudo for the runtime user.
- Do not add cloud CLIs, Docker-in-Docker, runtime skill fetching or token-broker logic without a scoped request.
- Pin images and downloaded tools deliberately; document floating dependencies and reproducibility limits. Use primary upstream sources and validate architecture support.
- **Config != boundary.** Prompt rules, recipe settings, image naming and baked skill selection are not isolation boundaries. Container/VM/restricted-user mechanisms and platform permissions need their own evidence.
- Do not put `sandbox` in image names: the image alone provides no isolation guarantee.

## Writing and decisions

- Succinct, load-bearing information; bullets and compact tables when useful. Link to external docs rather than restating them.
- No hard line breaks inside paragraphs. Use `> [!NOTE]` / `> [!IMPORTANT]` for callouts and `<details>` for occasional reference material.
- Every document tracking an evolving design gets a decision log: date/context → decision and reasoning. Preserve tradeoffs after deciding; label inherited or unevaluated choices honestly.
- Report what changed, what passed/failed and what remains unverified or intentionally omitted.

## Changes

### Security

- Do not edit/commit directly on `main`, push to it or merge into it.
- Creating task branches/worktrees is authorized. In the configured dev container, signed commits and normal pushes of task changes to the agent's own branch are authorized. Session-specific instructions about pushing take precedence.
- Amends, squashes, force pushes and re-writing published history of non-protected branches is ALLOWED and encouraged, in order to keep a clean git history.

**Sandbox escalation is pre-authorized for the Git operations allowed above**; use the harness approval mechanism without asking me to repeat that authorization. Branch rulesets provide additional enforcement, but do not authorize changes to protected branches or bypassing their protections.

### Guidance

- Fetch the remote default branch before creating a task branch or worktree.
- Create independent task branches (prefixed with `agent/`) from the fetched remote default branch, not the current checkout or another task branch.
- Target PRs at the repository's default branch.
- Only stack branches/PRs when explicitly requested. State the dependency before creating them.
- After a prerequisite PR merges, retarget dependent PRs and verify their state before branch cleanup.
- Use a separate worktree when another agent is working in the repository. Do not modify another agent's checkout or task branch; establish ownership before concurrent writes.
- Request harness escalation for authorized operations blocked by the sandbox; repository instructions do not override harness restrictions.
- Commit coherent completed changes at meaningful checkpoints, before handoff or switching tasks. Prefer small atomic Conventional Commits.
- Push at review-ready milestones or handoff when authorized; report whether work is uncommitted, committed locally or pushed. Never commit secrets.
