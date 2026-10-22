# agent-reviewer

Independently compares the implementation with the plan and check evidence. Produces a verdict and actionable findings without editing code.

## Parameters

| Parameter | Required | Purpose |
|---|---|---|
| `plan_file` | Yes | Absolute path to the staged implementation plan. |
| `base_ref` | Yes | Base commit SHA available in the checkout; review compares it with `HEAD`. |
| `checks_file` | Yes | Absolute path to staged deterministic check results. |
| `output_dir` | Yes | Fresh writable artifact directory outside the checkout. |

## Artifacts

- **Receives artifacts:** yes — plan and check evidence; code is inspected in the prepared checkout.
- **Produces artifacts:** yes — `review.md` in `output_dir`, including verdict, findings, required changes and verification limits.
- **Status:** `/tmp/status` — `approved`, `changes` or `blocked`.

Artifacts are local files; artifact-service transfer remains platform integration work. The caller prepares the repository checkout and selects it as the working directory.

[Shared runtime settings and recipe contracts](../../docs/role-images.md).
