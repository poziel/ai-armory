# AI Armory

Reusable skills, instruction templates, sub-agents, MCP servers, and scripts for AI-assisted development.

## Structure

| Directory | Contents |
| --- | --- |
| [skills/](skills/) | Reusable skills with instructions and supporting resources. |
| [instructions/](instructions/) | Project instruction templates, such as `AGENTS.md`, `CLAUDE.md`, and `GEMINI.md`. |
| [agents/](agents/) | Sub-agent definitions for specialized roles and workflows. |
| [mcp-servers/](mcp-servers/) | Custom Model Context Protocol servers, when needed. |
| [scripts/](scripts/) | Utilities for managing, validating, or installing these assets. |

## Conventions

- Use lowercase, hyphen-separated names for folders and files, except filenames required by a tool, such as `SKILL.md` or `AGENTS.md`.
- Keep each asset self-contained and document its purpose, supported tools, setup, and usage.
- Keep tool-specific formats explicit. Skills, instruction files, and agent definitions may need different formats for different tools.
- Use `{{PLACEHOLDER_NAME}}` for template values and document how to replace them.
- Keep secrets, machine-specific paths, and generated files out of version control.

Start with the guide in the relevant directory. Add dependencies and automation only when an asset needs them.