# Agent images

Container images for headless coding agents in the [AI-native SDLC platform](https://github.com/julie-ng/ai-native-sdlc).

- Shared image: **`agent-base`**. Registry/organization prefix and publishing workflow remain to be chosen.
- Goose runs the agent loop against model providers. No additional coding harness CLIs or ACP adapters planned for the shared base.
- Python and Node in the base; provider/model selection and credentials supplied at runtime.
- Deployment target: `linux/amd64`. Development hosts may be ARM64.
- Later role images inherit from the base and carry their own skills and labels. Role contents remain to be defined.

This bootstrap branch contains repository guidance and documentation. Dockerfile implementation, build instructions and the Goose-versus-Microsoft-base size comparison follow in a separate PR. No images have been published by this work.

Contributors: read [AGENTS.md](AGENTS.md). Platform decisions: [architecture ADRs](https://github.com/julie-ng/ai-native-sdlc/tree/main/architecture/decisions).

## Decision log

| Date/context | Decision and reasoning |
|---|---|
| 2026-10-22 bootstrap | Keep repository setup separate from the first Dockerfile PR so guidance and implementation can be reviewed independently. |
| 2026-10-22 image contract | Name the shared image `agent-base`; keep the project prefix in the registry/organization namespace. Use runtime provider/model configuration; build role images later. |
