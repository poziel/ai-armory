---
name: git-changelog
description: Create, update, or review CHANGELOG.md and release notes from Git history using Conventional Changelog conventions. Use for release summaries, unreleased entries, changelog formatting, and changelog generation or validation tooling.
argument-hint: "[changelog path] [previous ref..target ref] [version or Unreleased]"
compatibility: Codex SKILL.md with YAML frontmatter; outputs Markdown changelogs and GFM release notes. Requires Git and repository read access; edits require changelog write access. Optional - Node.js and changelog generation or linting packages. Installation requires PowerShell 7.
metadata:
  author: "Pøziel"
  version: "1.0.1"
  category: git
  tags:
    - git
    - changelog
    - release-notes
    - conventional-changelog
---

# Git changelog

Produce a useful release history: explain what changed for users and consumers, make breaking changes actionable, and keep entries traceable to the selected Git range.

## Supported format and setup

This is a Codex skill using YAML-frontmatter `SKILL.md`. Output targets Markdown `CHANGELOG.md` files and GitHub Flavored Markdown release notes. Other agents and renderers require their own compatibility checks. Git and repository read access are required for history-based work; writing requires access to the requested changelog. No credentials or connector are required. Node.js and packages are optional for generation/linting; manual writing works for non-Node projects too.

The source is maintained in [the AI resources](https://github.com/poziel/ai-resources). From the repository root, preview installation with `./scripts/Install-Skills.ps1 -Skill git-changelog -DryRun`, then omit `-DryRun` to create a link in the configured `SKILLS_DIR`. This requires PowerShell 7; see the [installer guide](../../scripts/README.md#install-skills). Creating this folder alone does not activate it.

Invoke with “Use $git-changelog to update the Unreleased section” or “Review the changelog for v2.3.0.” Review/draft requests return findings/text; update requests authorize focused edits. Changelog work does not implicitly authorize installing dependencies, changing release configuration or versions, committing, tagging, pushing, publishing, or running a release pipeline. Honor any authorization already given for those actions.

## Establish the release boundary

1. Read repository instructions, the existing changelog and its current diff, manifests, release scripts/configuration, and relevant CI. Keep manual text and unrelated edits. Use the project's established format and generator rather than switching ecosystems.
2. Identify the app/package, changelog path, previous release ref, target ref, intended version or Unreleased status, and release date. Use the correct package tags and prerelease policy; the newest tag in a monorepo may belong to another package. Check tag ancestry and history completeness. Missing tags/shallow history require investigation, not silently treating the available history as a first release.
3. Inspect the explicit `previous-ref..target-ref` range, including full commit bodies and footers. Start with status, tags, and a bounded log; inspect diffs for unclear claims. Use local metadata before remote services. A manifest version alone does not prove a release or identify the next version. For a first release, explicitly use history through the target ref with no previous release boundary.
4. If the version/date is undecided, draft under `Unreleased` without a fictitious release date or future tag. Ask only when an essential boundary cannot be established. A version recommendation is advisory and must respect repository policies, including pre-1.0 and prerelease behavior.

Uncommitted work is absent from Git-generated notes. Include it only when requested, verified from the diff, and clearly treated as unreleased; do not manufacture commit links for it. Keep separate repositories and independently versioned packages separate. Package path filters are a starting point: shared code/configuration can affect consumers outside that path.

## Write consistent entries

Conventional Commits defines commit syntax; Conventional Changelog presets determine parsing and output. There is no single mandatory Markdown changelog schema. Preserve the repository's convention, including an existing Keep a Changelog layout. For a new changelog, use these local defaults:

- One `# Changelog` title; optional `## Unreleased` first; released versions newest first with the exact version and actual `YYYY-MM-DD` release date. Preserve prerelease identifiers. Use version comparison links when the repository and tag scheme are known.
- Use `###` category headings and bullet entries. Put `### BREAKING CHANGES` first when needed, then Features, Bug Fixes, Performance Improvements, and Reverts as applicable. Omit empty categories. Follow a configured generator's heading levels, labels, and ordering instead when adopting its output.
- Write concise English entries describing the resulting behavior and who benefits or must act. Keep useful scopes as `**scope:**`; use backticks for code identifiers, flags, paths, and scoped package names. Do not paste raw commit prefixes, merge messages, implementation trivia, or vague “various fixes” summaries.
- Include verified commit/PR/issue links where available. Derive host-specific URLs from sanitized repository metadata and existing link conventions; do not assume GitHub paths for Azure DevOps or another host. Never invent issue IDs, hashes, tags, dates, security claims, or migration instructions. Without reliable metadata, use plain text.
- Consolidate commits for one user-visible change without losing distinct fixes, attribution, or traceability. Check merge/squash history to avoid duplicate entries. Preserve separate consumer impacts even when they share a scope.

### Inclusion and breaking changes

Use the configured preset first. Without a project-specific mapping, the `conventionalcommits` preset is the preferred baseline:

| Commit | Default treatment |
| --- | --- |
| `feat` | Features |
| `fix` | Bug Fixes |
| `perf` | Performance Improvements |
| `revert` | Reverts, subject to cancellation checks |
| `docs`, `style`, `chore`, `refactor`, `test`, `build`, `ci` | Hidden unless breaking or explicitly included by project policy |
| Any type with `!`, `BREAKING CHANGE:`, or `BREAKING-CHANGE:` | Surface the breaking impact prominently |

The companion `git-commit` skill also uses `ops` and Git's default `Revert "..."` messages. Inspect these explicitly: custom types and revert detection depend on the installed parser/preset. Do not change historical commits or reclassify dependency changes merely to force generator visibility. If a hidden/nonconventional commit changes shipped behavior, investigate and include the verified impact in curated notes, or report the generation gap for an automated changelog.

For every breaking entry, explain the affected contract, what changed, and the migration action, including supported runtime/platform changes. Inspect implementation/docs when a `!` has no detailed footer. If migration information remains unknown, flag it for completion rather than inventing a replacement API or claiming the release notes are ready.

For reverts, verify the referenced commit and net effect. A fully canceled change and its revert within the same unreleased range should not advertise a feature that will not ship. A revert of an already released change is itself a release-visible change; explain what users lose or regain. Partial reverts still need accurate notes. Check generated results rather than assuming the parser recognizes every revert form.

## Generate efficiently and preserve history

Read [tooling-and-validation.md](references/tooling-and-validation.md) when generating, choosing tools, configuring mappings, or running checks. Prefer an already installed, pinned project tool and a verified preview command. Inspect script definitions before execution: a script named `changelog` may also bump versions or tag releases.

Generate to stdout or a separate scratch file, then review the result before applying it. CLI defaults differ by version, so check local `--version` and `--help`; a bare invocation is not a reliable preview. Use an explicit range and the project's preset/configuration. For a short curated release, directly writing verified entries may be more efficient than introducing tooling.

Update only the requested release/Unreleased section. Preserve the introduction, link definitions, manual migration notes, and previous releases. Before inserting, check for the same version and changes already present; rerunning must not duplicate a release or its entries. Moving Unreleased content into a confirmed release must not leave the same changes in both sections. Full-history regeneration is a distinct operation and must not silently replace curated history.

## Verify and report

- Reconcile entries against the selected range and package: cover every verified release-visible change and breaking marker; exclude canceled, duplicate, unrelated, and already released changes.
- Check headings, version/date, category consistency, useful migration guidance, and correct comparison/commit/issue destinations. Treat a planned tag link as pending until the tag exists. Inspect Markdown formatting with the project's available checker; tooling cannot establish factual completeness by itself.
- Inspect the focused diff, including untracked changelog files; run `git diff --check` for whitespace. Confirm older releases and manual edits remain intact and a repeated update would add nothing. For wholly generated files, compare a reproducible regeneration under the same refs/configuration; normalize only known volatile fields such as generated dates.
- Report the file or draft, range/package, checks actually run, and material gaps briefly. Distinguish source inspection from command execution. If a tool is unavailable, perform content checks and state which automated check was skipped.

## Maintaining this skill

Run the skill-creator `scripts/quick_validate.py` when available (Python with PyYAML), check local links, and exercise the scenarios in [tooling-and-validation.md](references/tooling-and-validation.md#behavioral-checks). Format validation alone does not prove good release notes. The reference also links the upstream skill and official documentation; revisit these when changing tool guidance.
