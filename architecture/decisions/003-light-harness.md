# ADR-003: Keep Goose a light harness around capable models

- **Status:** Accepted
- **Date:** 2026-10-22
- **Context:** Headless agents using model APIs, billed by token usage rather than developer subscriptions.

## Context

**Starting assumption: Codex and Claude are highly capable models in their own right.** The model should do the reasoning and coding; the harness supplies the execution interface.

We will start from that premise and prioritize cost-effectiveness. Additional prompts, tool definitions and model calls need to earn their token cost through better task outcomes.

## Decision

Use Goose as a **light harness — essentially a wrapper around the model**.

- Call models through providers, with provider/model selected at runtime.
- Supply tools, focused instructions and recipes needed for the task.
- Do not add Claude Code, Codex CLI or ACP adapters to the image.
- Keep cross-step orchestration and completion gates in the platform.
- Add harness complexity when measured improvements justify its cost.

## Evidence and limits

HarnessTax reports:

> Harness choice has little effect on task success rate, but can significantly affect the cost on the benchmarks we test. The same model can achieve similar success rates at up to 5x costs.

Supporting findings:

- *What Does a Harness Buy? Tokens, Mostly* reports up to 3× cost differences across tested harnesses, with system prompts and tool schemas contributing to the gap.
- Apple's study finds no advantage for its evaluated elaborate harnesses over a minimal baseline under the same model and time budget on ML-engineering benchmarks.

These studies support testing a lightweight starting point. They do not prove that every model/task needs little scaffolding, or that Goose is the cheapest harness. **Goose's overhead and our cost per completed task remain unmeasured.**

## Consequences

- Favor task completion per API dollar over harness feature count.
- Evaluate changes using task outcomes, token cost, retries and elapsed time.
- Capabilities are a premise to test, not a completion guarantee. Tests and objective completion gates remain necessary.
- Revisit when repeated failures show missing scaffolding, or another configuration improves outcomes enough to justify its cost.

## Sources

Primary research sources:

- [HarnessTax: How Much Does the Harness Matter for Coding Agents?](https://harnesstax.github.io/)
- [What Does a Harness Buy? Tokens, Mostly](https://arxiv.org/abs/2610.04433)
- [How Much of a Harness Does a Strong Agent Need for Autonomous ML Engineering?](https://machinelearning.apple.com/research/harness-autonomous-ml-engineering)
