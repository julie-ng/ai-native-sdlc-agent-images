# agent-base

Provides the shared Goose runtime and toolchain inherited by the role images. Includes an optional smoke-test recipe for checking the installed tools.

## Parameters

The smoke-test recipe accepts no parameters. Model-backed runs use these runtime settings:

| Setting | Required | Purpose |
|---|---|---|
| `GOOSE_PROVIDER` | Yes | Select the model provider. |
| `GOOSE_MODEL` | Yes | Select the model. |
| Provider authentication | Provider-dependent | Supply authentication at runtime; none is baked into the image. |

## Artifacts

- **Receives artifacts:** no task artifacts.
- **Produces artifacts:** no task artifacts; smoke-test results go to stdout/stderr.

[Build and runtime details](../../README.md).
