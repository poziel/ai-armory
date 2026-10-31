# AI resources

Reusable skills, instruction templates, sub-agents, MCP servers, and scripts for AI-assisted development. Find [the AI resources on GitHub](https://github.com/poziel/ai-resources).

## Structure

| Directory | Contents |
| --- | --- |
| [skills/](skills/) | Reusable skills with instructions and supporting resources. |
| [instructions/](instructions/) | Reusable instruction fragments and templates for `AGENTS.md`, `CLAUDE.md`, and `GEMINI.md`. |
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

## Install

Requires PowerShell 7:

```powershell
Copy-Item .env.example .env # First setup only; preserve an existing .env.
# Set SKILLS_DIR in .env to the directory used by your AI tools.
./Install.ps1 -DryRun
./Install.ps1
```

The root installer currently installs skills. Skills are linked to this checkout, so edits take effect through the installed links. Set `SKILLS_DIR` explicitly in `.env` or your environment; no AI tool or destination is assumed. To link skills into several tools' directories, run the skill installer once per destination using `-SkillsPath`.

Settings also reserve destinations for agents, instructions, MCP servers, and scripts. Their installation behavior will be defined later. Instruction fragments will eventually be assembled into the files each tool expects. See the [installer guide](scripts/README.md#install-skills) for configuration and safe migration.

## Coding standards

Shared language guides live in `instructions/coding-standards/`. Configure a
project list, then preview or update all selected checkouts with
`scripts/Sync-CodingStandards.ps1`. This copies ordinary files suitable for Git;
it does not generate agent instructions. See the
[distribution guide](instructions/coding-standards-distribution.md).
