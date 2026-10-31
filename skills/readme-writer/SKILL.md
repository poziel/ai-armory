---
name: readme-writer
description: Create, improve, or review project READMEs with an audience-focused opening, consistent structure, existing branding, useful Shields.io badges, and verified setup instructions. Use for project README writing and polish, including header and badge selection.
argument-hint: "[README path or project folder] [audience] [writing or review goal]"
compatibility: Codex SKILL.md with YAML frontmatter; outputs GitHub Flavored Markdown with GitHub-supported HTML. Requires project read access; edits require README write access. Optional - Git metadata and browsing. No packages or credentials required. Installation requires PowerShell 7.
metadata:
  author: "Pøziel"
  version: "1.0.1"
  category: documentation
  tags:
    - readme
    - documentation
    - github
    - markdown
---

# README writer

Write a README that helps its intended reader recognize the value, see the project working, and take the next step. Keep the author’s voice and make claims traceable to the project.

## Supported format and setup

This is a Codex skill using YAML-frontmatter `SKILL.md`; its output targets GitHub Flavored Markdown (GFM), including GitHub-supported header HTML. Other tools and renderers require their own compatibility checks. No scripts, packages, credentials, or connector are required. The agent needs access to project files; Git metadata and browsing are useful when available.

The source is maintained in [the AI resources](https://github.com/poziel/ai-resources); storing it there does not activate it. From the repository root, preview installation with `./scripts/Install-Skills.ps1 -Skill readme-writer -DryRun`, then omit `-DryRun` to install into the configured `SKILLS_DIR`. The installer requires PowerShell 7 and creates a link to this folder. See the [installer guide](../../scripts/README.md#install-skills).

Invoke with a request such as “Use $readme-writer to improve this project’s README for first-time users.” Review-only requests produce findings without edits. Writing requests authorize focused README edits, not installation, deployment, commits, publishing, changes to project behavior, or creation of community services. Explain any proposed additional asset files before creating them; preserve existing branding.

## Work from evidence

1. Read repository instructions, the existing README, and its current diff. Preserve unrelated/manual edits and limit narrow requests to their requested sections.
2. Identify the primary reader and desired next action from the user’s request and project context. Ask only when a missing answer materially changes the README. Otherwise state the assumption briefly and proceed.
3. Inspect the relevant manifests, lockfiles, executable entry points, setup scripts, CI/deployment configuration, documentation, license, artwork, screenshots, and known community links. Read implementation where necessary to confirm behavior. Skip generated/dependency trees and secret files. Use Git remotes as evidence for repository identity, stripping embedded credentials; do not guess owner, branch, package name, support URL, or Discord invite.
4. Distinguish shipped behavior, released packages, deployed services, and planned work. A manifest version alone does not establish a public release. Conflicting package-manager files or unclear installation instructions require investigation rather than guessing.

## Compose for the reader

Read [structure-and-voice.md](references/structure-and-voice.md) when creating or substantially revising content. Follow its reading order while adapting section depth to the project and audience.

Read [headers-and-badges.md](references/headers-and-badges.md) whenever selecting artwork, building a header, or changing badges. Honor supplied badge preferences, infer useful additions from the project, and include relevant badges when supported by evidence. License and open-editor badges are strong defaults for suitable GitHub repositories; they are not reasons to invent missing metadata.

Link to existing license, changelog, and contribution files where readers can find them. Do not repeat their contents or add redundant sections for them. If a dedicated file does not exist, include only essential confirmed information; never invent license terms or contribution policy.

Use real screenshots/examples when available. Do not generate a logo, invent a screenshot, or insert a placeholder as if it were a finished asset. Keep the project’s name available as text even when artwork includes it. A missing asset need not block a useful text header.

## Check and report

Apply [quality-checks.md](references/quality-checks.md) before completing a draft or review. Check local links and assets, placeholder removal, badge destinations, heading structure, and commands against their actual definitions. Execute setup commands only when appropriate to existing authorization and side effects; otherwise distinguish inspected commands from tested commands.

For writing requests, save the focused changes and inspect the diff. Report the audience served, material changes, checks performed, and unresolved facts briefly. For review requests, prioritize actionable findings with file/line references. Do not claim that commands ran, remote badges rendered, or GitHub layout was inspected unless actually verified.

## Maintaining this skill

Validate frontmatter with the skill-creator `scripts/quick_validate.py` when available, then check relative links and exercise the scenarios in [quality-checks.md](references/quality-checks.md). Syntax validation alone does not establish writing quality. Read [sources.md](references/sources.md) when revisiting the rationale or upstream guidance; normal use does not require fetching every source.
