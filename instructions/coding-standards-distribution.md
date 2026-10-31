# Distribute coding standards

The source Markdown is maintained in [the AI resources](https://github.com/poziel/ai-resources) in `instructions/coding-standards/`. Every selected project receives exact file copies, suitable for committing to Git. Updating a standard and applying the distributor updates every configured project in one run. No agent instructions are composed or changed.

## Setup

Requires PowerShell 7. No modules, network connection, Bun, or Git executable are needed. Run from a checkout of [the AI resources](https://github.com/poziel/ai-resources), or invoke the script by its full path from any directory.

```powershell
# First setup only. Preserve an existing project list.
Copy-Item coding-standards.projects.example.json coding-standards.projects.json
# Edit coding-standards.projects.json to list your real project checkouts.

# Preview every configured project; this is also the default behavior.
./scripts/Sync-CodingStandards.ps1 -DryRun

# Explicitly replace the selected standard files in every configured project.
./scripts/Sync-CodingStandards.ps1 -Apply

# Check for missing or changed copies without writing; fails on drift.
./scripts/Sync-CodingStandards.ps1 -Check

# Limit the operation or use a different project list.
./scripts/Sync-CodingStandards.ps1 -Project pixen,frame -Apply
./scripts/Sync-CodingStandards.ps1 -Config ./team-projects.json -Check
```

`coding-standards.projects.json` is a local, ignored setting because project locations vary between machines. The tracked example shows the schema. A custom configuration path is resolved from the caller's current directory; project paths inside it are resolved relative to that configuration file. Absolute project paths are also supported. No environment-variable interpolation occurs.

Each project requires `name`, `path`, `destination`, and `languages`. Names are unique lowercase identifiers. The checkout must already exist; the relative destination folder is created on apply. Unknown fields and languages are errors, so a typo cannot silently select different files.

```json
{
  "version": 1,
  "projects": [
    {
      "name": "pixen",
      "path": "../pixen",
      "destination": "docs/contributing/coding-standards",
      "languages": ["vue", "rust"]
    }
  ]
}
```

## Languages and identical files

The source `catalog.json` maps language identifiers to Markdown filenames:

| Selection | Files in addition to README.md and markdown.md |
| --- | --- |
| `typescript` or `javascript` | typescript.md |
| `vue` | vue.md, typescript.md, html.md, css.md |
| `html` | html.md |
| `css` or `scss` | css.md |
| `rust` | rust.md |
| `markdown` or `mdx` | No additional files; markdown.md is always included |

README.md, markdown.md, and a `.gitattributes` file are always copied. The attributes file keeps shared Markdown in LF form across Git checkouts, avoiding drift caused by automatic Windows line-ending conversion. JavaScript and TypeScript share one guide; Vue automatically includes its referenced language guides. Duplicated selections copy a file only once. Select `rust` for projects with handwritten Rust sources; its guide follows Google's Rust baseline and adds the shared preference for explanatory documentation and implementation comments. A documentation-only project can select `markdown` or `mdx` without copying application-language guides.

Add future standards by adding source Markdown and a catalog entry, then selecting the language in project lists. The source catalog stays in [the AI resources](https://github.com/poziel/ai-resources); it is not copied into projects. Language-specific instructions remain available for agents to read on demand; distributing a file does not automatically load it into an agent's context. Existing project agent instructions can refer to the local index, but this distributor never edits those instructions.

## Update behavior

Review the preview, then apply. **Apply overwrites the selected files with the originals from [the AI resources](https://github.com/poziel/ai-resources), including local edits.** Edit shared rules in [the AI resources](https://github.com/poziel/ai-resources) first. The preview reports COPY, UPDATE, or UNCHANGED for every selected file. Matching files are not rewritten, preserving timestamps. File contents are copied as bytes, with no project-specific substitutions, headers, or line-ending changes.

Only selected filenames inside each configured destination are written. Unrelated files are preserved. No files are deleted, including guides left by removing a language from a project list. Remove obsolete copies deliberately if needed. Commit or review each project's resulting diff through its normal Git workflow; the script does not commit, push, or publish.

All selected projects and source files are validated before any writes. Missing checkouts or sources, invalid filenames, traversal, links/junctions, and overlapping destinations are refused. `-WhatIf` also prevents writes. Validation prevents predictable partial updates, but filesystem or permission errors during writing can still leave some projects updated; resolve the error and rerun. Concurrent edits or concurrent distributor runs are not supported.

Keep project architecture, framework-specific theme names, and actual formatter commands in project documentation outside the copied folder. Copying standards does not install or configure formatting tools. In Frame, the existing formatter workflow is preserved in `docs/contributing/formatting.md`.

Run the isolated distributor integration checks with:

```powershell
./scripts/tests/Sync-CodingStandards.Tests.ps1
```

Tests use temporary projects and verify previews, exact copies, updates, language selection, preflight errors, and junction rejection. They do not change your configured projects. Windows must permit junction creation for that test case.
