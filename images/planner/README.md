# agent-planner

Inspects an issue and the repository, then proposes a scoped implementation plan. Records clarification questions when needed.

## Parameters

| Parameter | Required | Purpose |
|---|---|---|
| `issue_file` | Yes | Absolute path to the staged issue text. |
| `output_dir` | Yes | Fresh writable artifact directory outside the checkout. |

## Artifacts

- **Receives artifacts:** yes — staged issue text through `issue_file`.
- **Produces artifacts:** yes — `plan.md` in `output_dir`, including approach, files to touch, acceptance criteria, checks and risks or a clarification question.
- **Status:** `/tmp/status` — `planned`, `needs_clarification` or `blocked`.

Artifacts are local files; artifact-service transfer remains platform integration work. The caller prepares the repository checkout and selects it as the working directory.

[Shared runtime settings and recipe contracts](../../docs/role-images.md).
