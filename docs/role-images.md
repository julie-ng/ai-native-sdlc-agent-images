# Role images

Planner, coder and reviewer inherit `agent-base`. Each adds a Goose recipe with companion Markdown files and role labels; tools, skills, user and default command are inherited unchanged. This repository currently bakes no additional skills. A future shared skill set belongs in the base; distinct skill sets can be added to the role images when chosen.

## Layout and builds

```text
images/
├── base/
│   ├── Dockerfile
│   └── recipes/smoke-test.yaml
├── planner/
│   ├── Dockerfile
│   ├── recipe.yaml
│   ├── instructions.md
│   └── prompt.md
├── coder/
│   ├── Dockerfile
│   ├── recipe.yaml
│   ├── instructions.md
│   └── prompt.md
└── reviewer/
    ├── Dockerfile
    ├── recipe.yaml
    ├── instructions.md
    └── prompt.md
scripts/                         # shared installation and offline checks
```

Run builds from the repository root, using it as the build context:

```sh
docker build --platform linux/amd64 -f images/base/Dockerfile -t agent-base:dev .
for role in planner coder reviewer; do
  docker build --platform linux/amd64 \
    --build-arg BASE_IMAGE=agent-base:dev \
    -f "images/$role/Dockerfile" -t "agent-$role:dev" .
done
```

`BASE_IMAGE=agent-base:dev` is a local-development default. Release builds must override it with the published base's digest-qualified reference (`registry/agent-base@sha256:…`). No registry or publishing pipeline is configured here; local development tags are mutable. All three role builds should use the same base reference.

The base installs the toolchain and shared smoke recipe. A role image adds `/recipes/<role>/{recipe.yaml,instructions.md,prompt.md}` and `io.julie.agent.role`; it does not contain the other role recipes. All images retain `CMD ["bash"]`. The caller explicitly starts Goose and supplies provider/model selection and authentication at runtime.

## Recipe source files

- `recipe.yaml` holds metadata, parameters, extension configuration and settings.
- `instructions.md` holds the role's standing instructions.
- `prompt.md` holds the task prompt, including runtime parameter placeholders.

Goose v1.48.0 resolves native Jinja includes relative to the recipe directory. Keep all three files together in source and in the image; no generator or runtime fetching is involved. The `indent(2)` filter keeps the included Markdown inside its YAML block without indentation in the Markdown source:

```yaml
instructions: |
  {% filter indent(2) %}{% include "instructions.md" %}{% endfilter %}
prompt: |
  {% filter indent(2) %}{% include "prompt.md" %}{% endfilter %}
```

These recipe files are Goose templates; validate them with `goose recipe validate`, which resolves includes, rather than treating the source as plain YAML. Goose substitutes declared parameters inside the Markdown includes. The platform still passes the same parameters; only the baked recipe path changes from `/recipes/<role>.yaml` to `/recipes/<role>/recipe.yaml`.

## Recipe contracts

These are initial image-level interfaces, not a completed artifact-service API or Argo manifest. They implement the agreed separation of roles; they do not adopt the comparison handoff's plan classifier, approval gate, PR writer or PR linting.

| Role | Required parameters | Artifact | `/tmp/status` |
|---|---|---|---|
| planner | `issue_file`, `output_dir` | `plan.md` — approach, files, acceptance criteria, checks, risks or clarification question | `planned`, `needs_clarification`, `blocked` |
| coder | `plan_file`, `branch`, `output_dir` | `coder-notes.md` — changes, check results, commits, push result, remaining problems | `done`, `blocked` |
| reviewer | `plan_file`, `base_ref`, `checks_file`, `output_dir` | `review.md` — verdict, findings, required changes, verification limits | `approved`, `changes`, `blocked` |

- Coder optionally accepts `feedback_file`, default empty. This supports rework input without settling the platform's open session-resume decision.
- Each `*_file` parameter is an absolute path to platform-staged input, passed as a **string**. Goose does not automatically inline these files; the recipe instructs the agent to read them.
- The caller prepares a writable checkout, sets it as the process working directory, and supplies a fresh writable `output_dir` outside that checkout for each step/attempt. Artifacts are create-only; they must not be committed into the target repository.
- The caller creates and checks out the unique `agent/` coding branch before running coder, configures its remote, agent identity, signing key and Git authentication, and makes the review base commit available. Images do not provision these.
- `checks_file` carries deterministic check evidence staged by the caller. No new checks service or checks image is implemented here. The coder can run repository checks, but `done` means the coding pass finished and pushed; it does not mean QA green.
- The recipes ask the model to write its artifact, then one status word and a newline to `/tmp/status`. An exit code of zero is insufficient. The platform must validate that both outputs exist and the status is valid before routing the run. A crash or turn limit can leave either absent; no wrapper fabricates success.
- Reviewer uses `changes` to match the platform's existing example workflow, rather than the comparison handoff's `changes_requested`. The example's `/tmp/verdict` path must be wired to `/tmp/status` when integrating these recipes; the example is not a ready-to-run manifest.
- Planner records clarification questions locally. Posting a clarification and ending/restarting a run are platform integration work; this image does not introduce the comparison handoff's issue-comment behavior.
- Reviews are staged locally for platform upload. The platform's documented reviewer GitHub permissions (`contents: read`, `pull requests: write`) are unchanged. Posting comments on an existing PR is not implemented by this recipe; intermediate reviews stay out of GitHub.

Example invocation, after preparing inputs, checkout and runtime authentication:

```sh
goose run --recipe /recipes/planner/recipe.yaml \
  --params issue_file=/run/agent-inputs/issue.md \
  --params output_dir=/run/agent-outputs/planner

goose run --recipe /recipes/coder/recipe.yaml \
  --params plan_file=/run/agent-inputs/plan.md \
  --params branch=agent/task-123-run-456 \
  --params output_dir=/run/agent-outputs/coder

goose run --recipe /recipes/reviewer/recipe.yaml \
  --params plan_file=/run/agent-inputs/plan.md \
  --params base_ref=BASE_COMMIT_SHA \
  --params checks_file=/run/agent-inputs/checks.log \
  --params output_dir=/run/agent-outputs/reviewer
```

Run each command in its corresponding image and pod; they are not commands for one shared agent session. The paths are examples of mounted/staged files, not supplied directories in the images. The platform reads `/tmp/status`, uploads artifacts and controls retries, deadlines, escalation and final PR creation.

## Behavior and permissions

- Recipes provide role-specific instructions and enable the same built-in `developer` extension. They do not spawn sub-agents or install extra coding harnesses.
- The default turn limits are planner 30, coder 80 and reviewer 40. These are initial implementation defaults, not calibrated cost ceilings; the platform still needs pass limits and pod deadlines.
- Provider/model settings are absent from every recipe. Model selection remains runtime-only; no particular model or model family is selected here.
- Instructions about planning without editing, create-only artifacts, headless operation and untrusted input are behavioral controls. They are not isolation or authorization boundaries.
- Platform permissions determine access. Shared tools do not imply shared credentials. Role images do not fetch tokens, implement the token broker, configure signing or grant cloud/Kubernetes access.
- Shared skills remain inherited from the base. Repository-supplied skills may still affect Goose discovery; the platform's [skills ADR](https://github.com/julie-ng/ai-native-sdlc/blob/main/architecture/decisions/013-skills-distribution.md) tracks that open constraint.

## Offline verification

Go/no-go: all four images build for AMD64; inherited tool/user/workspace checks pass; each role contains only its own role recipe plus the smoke recipe; recipes validate; runtime provider/model selection and recipe parameter rendering reach a loopback mock with a synthetic key. These checks do not establish task completion or validate the platform integration.

```sh
docker run --rm --network none --platform linux/amd64 \
  agent-base:dev sh /usr/local/bin/agent-image-smoke-test
for role in planner coder reviewer; do
  docker run --rm --network none --platform linux/amd64 \
    "agent-$role:dev" sh /usr/local/bin/agent-image-smoke-test "$role"
done

docker run --rm -i --network none --platform linux/amd64 \
  agent-base:dev python3 - < scripts/check-runtime-config.py

docker run --rm -i --network none --platform linux/amd64 \
  agent-planner:dev python3 - \
  --recipe /recipes/planner/recipe.yaml \
  --params 'issue_file=/tmp/issue fixture.md' \
  --params 'output_dir=/tmp/planner output' \
  --expect-prompt 'You are the planner' \
  --expect-prompt 'Missing artifacts or status are not success.' \
  --expect-prompt '/tmp/issue fixture.md' \
  --expect-prompt '/tmp/planner output/plan.md' \
  < scripts/check-runtime-config.py

docker run --rm -i --network none --platform linux/amd64 \
  agent-coder:dev python3 - \
  --recipe /recipes/coder/recipe.yaml \
  --params 'plan_file=/tmp/plan fixture.md' \
  --params branch=agent/offline-fixture \
  --params 'output_dir=/tmp/coder output' \
  --params 'feedback_file=/tmp/feedback fixture.md' \
  --expect-prompt 'You are the coder' \
  --expect-prompt 'Do not review or approve your own work.' \
  --expect-prompt '/tmp/plan fixture.md' \
  --expect-prompt 'agent/offline-fixture' \
  --expect-prompt '/tmp/feedback fixture.md' \
  --expect-prompt '/tmp/coder output/coder-notes.md' \
  < scripts/check-runtime-config.py

docker run --rm -i --network none --platform linux/amd64 \
  agent-reviewer:dev python3 - \
  --recipe /recipes/reviewer/recipe.yaml \
  --params 'plan_file=/tmp/plan fixture.md' \
  --params base_ref=0123456789012345678901234567890123456789 \
  --params 'checks_file=/tmp/checks fixture.log' \
  --params 'output_dir=/tmp/reviewer output' \
  --expect-prompt 'You are the reviewer' \
  --expect-prompt 'do not start another pass.' \
  --expect-prompt '/tmp/plan fixture.md' \
  --expect-prompt '0123456789012345678901234567890123456789' \
  --expect-prompt '/tmp/checks fixture.log' \
  --expect-prompt '/tmp/reviewer output/review.md' \
  < scripts/check-runtime-config.py
```

The mock returns a canned response. It checks that Goose loads the recipe and renders its inputs, without executing tools, reading the example input files or writing role artifacts. It does not test planner/coder/reviewer judgment, Git operations or status emission.

Verified 2026-10-22 under AMD64 emulation on an ARM64 host:

- All four images built and passed the toolchain, non-root, workspace and recipe-presence/validation checks above.
- The base routing check and all three recipe-rendering checks passed using only a loopback mock and synthetic key, including paths containing spaces.
- After splitting the Markdown files, rebuilds and all offline checks passed again. The mock verified included instructions and substituted task prompts reached the model request. Extracted Markdown preserves the original wording, with paragraphs reflowed for review.
- Image inspection confirmed exact inherited base layers, user, working directory, command, entrypoint and environment. Each role history adds only its recipe/Markdown copy and labels; no task-supplied credentials or provider/model defaults were added. Upstream layers were not independently audited.
- Each role adds one filesystem layer to the exact shared base. No registry-transfer or startup measurement was performed.

Real-model task behavior, artifact/status emission, Git operations in the images, Kubernetes execution, artifact upload, broker integration and runtime signing remain unverified. No images were published.

Primary Goose references: [v1.48.0 include loader and renderer](https://github.com/aaif-goose/goose/blob/v1.48.0/crates/goose/src/recipe/template_recipe.rs), [v1.48.0 recipe schema](https://github.com/aaif-goose/goose/blob/v1.48.0/crates/goose/src/recipe/mod.rs), [recipe reference](https://goose-docs.ai/docs/guides/recipes/recipe-reference/). The installed pinned binary's validation and offline execution are the compatibility checks for these recipes.

## Decision log

| Date/context | Decision and reasoning |
|---|---|
| 2026-10-22 architect approval | Group each image with its recipe under `images/<role>/`; keep shared scripts and a root build context. |
| 2026-10-22 role packaging | Build separate planner, coder and reviewer images now, even with identical skills, to version and test each role's prompt with its image. |
| 2026-10-22 recipe defaults | Stage artifacts locally pending the platform API; use explicit required inputs, fixed status words and bounded recipe turns. These defaults need real-model and platform verification. |
| 2026-10-22 base references | Retain a local `agent-base:dev` default for unpublished builds; require a digest-qualified base for release builds rather than inventing a registry. |
| 2026-10-22 offline verification | AMD64 builds, role-aware toolchain checks, model routing, recipe rendering and inherited image configuration/layers passed. Keep real-model completion and platform integration explicitly unverified. |
| 2026-10-22 reviewability | Split role instructions and task prompts into adjacent Markdown files using native Goose includes. Keep YAML focused on configuration; no custom assembly step or prompt changes. |
