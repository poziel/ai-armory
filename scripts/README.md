# Scripts

Shared utilities for managing the assets in this repository, such as listing assets, checking templates, or copying selected files into a project.

- Keep helpers used by only one skill or MCP server alongside that asset.
- Document prerequisites, inputs, usage, and side effects for every shared script.
- Resolve repository paths relative to the script location rather than a machine-specific directory.
- Make reruns safe and avoid overwriting existing user files by default.
- Provide preview support for scripts that install, overwrite, or remove assets.

## Install skills

Requires PowerShell 7. Run from the repository root:

```powershell
./Install.ps1 -DryRun
./Install.ps1
```

The installer creates a Windows directory junction (or a symbolic link on other platforms) for each folder in `skills/` containing `SKILL.md`. The files in [the AI resources](https://github.com/poziel/ai-resources) remain the source; edits are visible through the installed link immediately. Keep the repository at the same path while its links are installed.

The root `Install.ps1` delegates to `scripts/Install-Skills.ps1`. Skills are the only implemented installation step; future installers for agents, instruction composition, MCP servers, and scripts will be connected here when their behavior is defined. Nonblank reserved settings do not activate unimplemented steps.

Destination precedence:

1. `-SkillsPath`.
2. Process environment variable `SKILLS_DIR`.
3. `SKILLS_DIR` in the repository `.env`.

Copy `.env.example` to `.env` on first setup and set `SKILLS_DIR`. Missing or blank destinations produce a configuration error, including in dry runs. Paths must be absolute after expansion; `%VARIABLE%` placeholders can reference environment variables or other `.env` settings. Undefined placeholders produce an error. The parser accepts uppercase `NAME=value` settings, optional quotes, and full-line comments; values are read as data, never executed or exported into the process environment.

| Setting | Purpose | Status |
| --- | --- | --- |
| `SKILLS_DIR` | Directory receiving links to skill folders | Implemented |
| `AGENTS_DIR` | Agent installation destination | Reserved |
| `INSTRUCTIONS_DIR` | Destination for composed instruction files | Reserved |
| `MCP_SERVERS_DIR` | MCP server installation destination | Reserved; client registration and runtime setup are undecided |
| `SCRIPTS_DIR` | Shared script installation destination | Reserved |

Settings describe destinations, independent of the AI tool. For example, a local setting can reference an existing tool variable such as `SKILLS_DIR=%CODEX_HOME%/skills`, or a shared skills folder used by several tools. Use `-EnvFile` to choose another settings file. Only the settings needed by an implemented installer are resolved.

```powershell
# Install one skill or use a different destination.
./scripts/Install-Skills.ps1 -Skill git-commit
./scripts/Install-Skills.ps1 -SkillsPath 'D:/AI/2-skills' -DryRun

# Migrate existing ordinary directories, retaining backups.
./scripts/Install-Skills.ps1 -SkillsPath 'D:/AI/2-skills' -BackupExisting -DryRun
./scripts/Install-Skills.ps1 -SkillsPath 'D:/AI/2-skills' -BackupExisting
```

Reruns leave matching links alone. Conflicting files and links are refused. Existing ordinary directories are refused unless `-BackupExisting` is supplied; it moves them into `<destination>.ai-resources-backups/<timestamp-id>/` beside the installation directory before linking. If link creation fails, the installer attempts to restore that directory. Backups stay outside the skills discovery directory. No files are deleted. Review backups before removing them manually.

Both installers accept `-DryRun` (and PowerShell's `-WhatIf`) to report planned links and backups without creating directories, moving files, or installing anything. Matching links are reported as `UNCHANGED`. Source skill folders may themselves be junctions or symbolic links; reruns compare the final targets of both links, while new links still point through the checkout of [the AI resources](https://github.com/poziel/ai-resources). A dry run still validates configuration and refuses conflicts.

To relocate the repository or remove a skill, remove its installed link and run the installer from the new location if needed. On Windows, use `[IO.Directory]::Delete('<installed-link>')` to remove only a junction; do not recursively delete its contents. Your AI tool may need a refresh or new session to discover newly installed skills.

Run the isolated installer checks with:

```powershell
./scripts/tests/Install-Skills.Tests.ps1
```

## Distribute coding standards

`Sync-CodingStandards.ps1` previews, copies, or checks shared standards in all
configured project checkouts. Requires PowerShell 7 only. The default is preview;
`-Apply` overwrites selected destination files, while `-Check` fails on drift.
The project list is separate from the skill installer and `Install.ps1`.
See the [distribution guide](../instructions/coding-standards-distribution.md)
for setup, language selection, side effects, and tests.
