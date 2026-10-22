# ADR-002: Use GitHub CLI instead of GitHub MCP

- **Status:** Accepted
- **Date:** 2026-10-22
- **Context:** GitHub operations in the API-funded agent demo.

## Context

Agents need GitHub issues, pull requests and API access. The image already includes `gh`, callable through the existing shell tool.

We prioritize token efficiency and avoid adding a separate GitHub tool catalog when the CLI meets the task's needs.

## Decision

- Use `gh` for GitHub operations and native `git` for repository operations.
- Do not configure a GitHub MCP server for these capabilities.
- Request compact output: select the required JSON fields and limit result sets.
- Supply authentication at runtime; CLI selection does not determine token permissions.

## Evidence and limits

The clifor.ai comparison points to ScaleKit's CLI-versus-MCP benchmark:

- Same model, Claude Sonnet 4; five read-only GitHub tasks; 75 runs across CLI, CLI with skills, and MCP.
- The MCP setup exposed 43 GitHub tool schemas. Reported median token usage was 4–32× higher than plain CLI, depending on the task.
- Schema exposure was a major contributor. This is evidence about that configuration, not an unavoidable property of MCP.

These are externally reported results, not measurements of our agents. They motivate the starting choice; they do not establish our expected savings or guarantee CLI reliability.

## Consequences

- Reuse the shell interface and installed GitHub CLI.
- Agents must construct commands and handle exit codes and output.
- CLI output can still consume substantial context; keep requests narrow.
- Revisit if required capabilities are awkward through `gh`, or equivalent-task measurements favor MCP with selective tool exposure.

## Sources

- [CLI vs MCP](https://www.clifor.ai/compare/cli-vs-mcp) — secondary comparison; starting reference.
- [ScaleKit benchmark](https://www.scalekit.com/blog/mcp-vs-cli-use) — primary benchmark report.
