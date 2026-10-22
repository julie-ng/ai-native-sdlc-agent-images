# agent-coder

Implements the plan on the supplied branch, runs relevant checks, and commits and pushes changes. Records results and remaining problems.

## Parameters

| Parameter | Required | Purpose |
|---|---|---|
| `plan_file` | Yes | Absolute path to the staged implementation plan. |
| `branch` | Yes | Unique `agent/` task branch, already checked out with its remote configured. |
| `output_dir` | Yes | Fresh writable artifact directory outside the checkout. |
| `feedback_file` | No; default empty | Absolute path to staged rework feedback, when supplied. |

## Artifacts

- **Receives artifacts:** yes — plan and optional rework feedback.
- **Produces artifacts:** yes — `coder-notes.md` in `output_dir`, including changes, check results, commits, push result and remaining problems. Code changes travel through Git.
- **Status:** `/tmp/status` — `done` or `blocked`; `done` means the coding pass finished and pushed, not that QA is green.

Artifacts are local files; artifact-service transfer remains platform integration work. The caller prepares the checkout, Git authentication, agent identity and signing configuration.

[Shared runtime settings and recipe contracts](../../docs/role-images.md).
