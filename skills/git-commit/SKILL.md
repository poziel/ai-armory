---
name: git-commit
description: Write, suggest or review a git commit message following Conventional Commits 1.0.0 with personal conventions (lowercase imperative subject, fixed type list, no issue ids in scopes). Use whenever asked for a commit message, to commit changes, to summarize a diff as a commit, to fix or reword a commit message, or when about to run `git commit`.
argument-hint: "[optional hint about the change]"
compatibility: Codex SKILL.md with YAML frontmatter. Requires Git and repository read access; committing requires explicit authorization and repository write access.
metadata:
  author: "Pøziel"
  version: "1.0.0"
  category: git
  tags:
    - git
    - commit
    - conventional-commits
  spec: https://www.conventionalcommits.org/en/v1.0.0/
---

# Commit message

Arguments: `$ARGUMENTS`

Follows the [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/) specification, tightened by the personal conventions below. Where this skill and the spec differ, **this skill wins** (differences are listed at the end).

## Workflow

1. **Look at the change**, from the right repository.
   - Run `git status` and `git diff --staged`. If nothing is staged, use `git diff` and say that the message covers the unstaged changes. Read `git log -5 --oneline` to match the repo's recent style and scopes.
   - In a workspace with multiple repositories, run the commands inside the relevant repo folder and write one message per repo. Never describe multiple repos in one message.
2. **Check the change is one logical change.** If the diff mixes unrelated things (a fix plus a refactor, source plus unrelated formatting), say so and propose splitting into several commits, each with its own message, instead of writing one vague message or picking a single type for all of it.
3. **Pick the type, then the scope, then write the description** using the rules below.
4. **Add a body and/or footer only when they carry information** the subject can't.
5. **Output** the message in a `text` code block, ready to copy. Add one short line only if something needs the user's decision (e.g. the split above, or an uncertain type).
6. **Do not run `git commit`, `git push` or `git commit --amend` unless the user explicitly asks.** Asking "write a commit message" means write it, not commit it.

## Format

```text
<type>(<optional scope>): <description>

<optional body>

<optional footer(s)>
```

- A colon and one space always follow the type/scope (and the `!` if present).
- One blank line between subject and body, and one between body and footers.
- Everything is in English.

## Types

Pick the one that best describes **what the commit changes**, not how much work it was.

| Type | Use for |
|---|---|
| `feat` | add, adjust or remove an API/UI feature (user- or consumer-visible behavior) |
| `fix` | fix an API/UI bug |
| `refactor` | restructure code without changing API/UI behavior |
| `perf` | improve performance without changing behavior |
| `style` | formatting or code-style-only changes (whitespace, semicolons, no logic) |
| `test` | add or correct tests |
| `docs` | documentation-only changes (README, AGENTS/CLAUDE files, comments, skills) |
| `build` | build tooling, dependencies, project files, versioning |
| `ops` | infrastructure, deployment scripts, CI/CD, monitoring, backups, recovery procedures |
| `chore` | repository maintenance such as `.gitignore` or initial setup |

Choosing between close types:
- Behavior changes for users or API consumers: `feat` (new/adjusted/removed) or `fix` (it was wrong). Not sure? If the old behavior was a defect, it's `fix`.
- Behavior doesn't change: `refactor` (structure), `perf` (speed), `style` (formatting only).
- A bug fix that includes its test is one `fix` commit; a test added alone is `test`.
- Dependency bump: `build`. Pipeline YAML, Dockerfile, k8s manifests, deploy scripts: `ops`.
- `chore` is the last resort, for housekeeping that fits nothing else. Don't use it to avoid thinking about the type.
- Only these types. Don't invent new ones (`wip`, `update`, `misc`...): tools that read the spec ignore unknown types.

## Scope (optional)

- A noun for the part of the codebase affected, in parentheses: `fix(quotes): ...`.
- Examples used here: `api`, `quotes`, `orders`, `suppliers`, `users`, `behavior-tests`, `integration-tests`, `build`. Reuse a scope already seen in `git log` before inventing one.
- **Never an issue or work item identifier** as the scope (`fix(1234): ...` is wrong).
- Omit the scope when the change is cross-cutting or no single noun fits. One scope only; don't write `fix(api,ui):`.

## Description (the subject)

- **Imperative present tense**: `add`, not `added` or `adds`. It should complete "if applied, this commit will ...".
- **Lowercase first letter** (and no capitalized sentence style).
- **No period** at the end.
- One sentence, concise, focused on the change: say *what* it does, not *how* or *why* (that's for the body).
- Specific over vague: `fix(quotes): prevent submitting empty quote notes`, not `fix: fix bug` or `fix: update quotes`.
- Aim for the whole first line to stay around 72 characters or less.
- Don't repeat the type or scope in the description (`feat(orders): add orders export`, not `feat(orders): orders: add export`).

## Body (optional)

- Only when useful: the motivation, contrast with the previous behavior, or a non-obvious decision. Never restate the diff.
- Starts after one blank line. Free-form, any number of paragraphs.
- Wrap lines reasonably (about 72-100 characters); no hard limit.

## Footers (optional)

- One blank line after the body (or after the subject if there is no body).
- Format: `Token: value` or `Token #value`. Tokens use `-` instead of spaces (`Reviewed-by`, `Refs`, `Closes`), except `BREAKING CHANGE`.
- Use footers for issue references (`Closes #123`, `Fixes JIRA-456`, `Refs #123`) and for breaking-change details.
- A footer value may span several lines; it ends when the next `Token: value` line starts.
- Trailers the tooling or the user asks for (e.g. `Co-Authored-By:`) go **last** in the footer.
- The work item number lives in the **branch name** (see `git-branch`). Never put it in the subject: no `#id` prefix and not as the scope, so a one-line commit carries no id. When the commit has a body, add a `Refs #<id>` footer with the id from the branch name (or the one the user gives). Don't guess one when the branch name has none.

## Breaking changes

A commit that breaks API or UI consumers is marked in one or both ways:

1. `!` right before the colon: `feat(api)!: remove legacy supplier endpoint`
2. A footer starting with **`BREAKING CHANGE:`** (uppercase, space) followed by a description. `BREAKING-CHANGE:` is a synonym.

Use the `!` always for a breaking change; add the `BREAKING CHANGE:` footer unless the subject already fully explains the break. Describe who is affected and what they must do instead. Any type can be breaking, not only `feat`.

Examples of what is breaking here: removing or renaming an API endpoint, request/response property or enum value; changing a Pact contract in a way consumers must adapt to; a database change that is not backward compatible with the deployed version.

## Special commits

- **Merge commits**: keep Git's default message, don't rewrite it: `Merge branch '<branch name>'`.
- **Revert commits**: keep Git's default message: `Revert "<reverted commit subject line>"`. (The spec suggests a `revert` type with a footer listing the SHAs; this skill keeps Git's default.)
- Fixup or squash commits that will be rebased away may use Git's `fixup!`/`squash!` form.

## SemVer relationship (for context)

`fix` → PATCH, `feat` → MINOR, any breaking change → MAJOR. Other types don't trigger a release on their own. This is why `fix` vs `feat` and the breaking marker matter even when nobody reads the history by hand.

## Examples

```text
docs: add agent guidance for local development
```

```text
fix(quotes): prevent submitting empty quote notes
```

```text
test(behavior-tests): cover supplier quote creation
```

```text
fix(api): prevent empty supplier order notes
```

```text
test(integration-tests): cover supplier order note updates
```

```text
build: update package dependencies
```

```text
refactor(orders): simplify invoice event creation
```

With body and footer:

```text
fix(orders): keep invoice total when a part is removed

The total was recomputed from the remaining parts only, so credits on
the removed part were dropped. Recompute from all lines including credits.

Closes #123
```

Breaking:

```text
feat(api)!: remove legacy supplier endpoint

BREAKING CHANGE: supplier clients must use the new supplier lookup endpoint.
```

### Wrong → right

| Wrong | Why | Right |
|---|---|---|
| `Fixed the bug.` | no type, past tense, capital, period, vague | `fix(orders): prevent duplicate invoice events` |
| `feat: Added supplier export` | capital, past tense | `feat(suppliers): add supplier export` |
| `fix(1234): empty note` | issue id as scope, vague | `fix(quotes): prevent submitting empty quote notes` |
| `fix: #48213 prevent empty quote notes` | work item id in the subject | `fix(quotes): prevent empty quote notes`; the id goes in a `Refs #48213` footer, and only when the commit has a body |
| `chore: update code` | vague, `chore` as a dumping ground | `refactor(orders): extract invoice total calculation` |
| `feat(api): remove status endpoint` | breaking change not marked | `feat(api)!: remove status endpoint` |
| `fix: fix tests and add feature` | two changes in one commit | split into `test: ...` and `feat: ...` |

## Differences from the Conventional Commits spec

- The spec allows any casing and any type; this skill requires lowercase and the fixed type list above.
- The spec says `feat` is for *adding* a feature; here `feat` also covers adjusting or removing one.
- The spec suggests a `revert` type; this skill keeps Git's default revert message.
- Imperative mood, no trailing period and the ~72-character first line are this skill's writing conventions, not part of the spec.

## Self-check before answering

- [ ] Type is one of the ten above, lowercase.
- [ ] Scope (if any) is a noun, not an issue id.
- [ ] `: ` after the prefix, subject starts lowercase, imperative, no period.
- [ ] Breaking change has `!` (and a `BREAKING CHANGE:` footer when needed).
- [ ] Blank line before the body and before the footers.
- [ ] No work item id in the subject; a commit with a body has a `Refs #<id>` footer when the branch name gives the id.
- [ ] One logical change, one repo.
- [ ] Nothing was committed.
