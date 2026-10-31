---
name: git-branch
description: Name and create git branches following the Conventional Branch spec with personal conventions and optional work item IDs. Use whenever creating, naming, renaming or validating a branch, starting work on an issue, or before pushing a new branch.
argument-hint: "[optional work item id] [type] [short description]"
license: MIT
compatibility: Codex SKILL.md with YAML frontmatter. Requires Git and repository read access; branch creation or renaming requires repository write access, and fetching requires remote access. Optional - an issue tracker connector or CLI to read work item titles when an ID is supplied without a title.
metadata:
  author: "Pøziel"
  version: "1.0.0"
  category: git
  tags:
    - git
    - branch
    - conventional-branch
    - work-item
  spec: https://conventionalbranch.org
---

# Git branch

Arguments: `$ARGUMENTS`

Follows [Conventional Branch 1.1.0](https://conventionalbranch.org), with these personal conventions:

1. **Include a work item number when the work is linked to one.** Work without an issue uses a descriptive name without a number.
2. **Never prefix a branch with an AI name.** Use the work type as the prefix; authorship and validation remain the user's responsibility.

Companion skill: `git-commit` (commit messages). No issue tracker is required for work without an issue.

## Format

```text
<type>/<work-item-id>-<description>
<type>/<description>
```

| Part | Rule | Example |
|---|---|---|
| `type` | one of the types below | `feature` |
| `work-item-id` | optional, digits only, the issue or work item the branch implements | `48213` |
| `description` | kebab-case, lowercase, 2-5 words, from the task or issue title | `add-supplier-quote-export` |

Valid: `feature/48213-add-supplier-quote-export`, `bugfix/48390-prevent-empty-order-notes`, `hotfix/48411-fix-invoice-total`, `chore/48500-update-npm-dependencies`, `feature/add-export`, `chore/update-dependencies`.

### Types

Use the **full names only**, not the `feat/` and `fix/` aliases, for consistency (confirmed).

| Type | Use for | Matching commit type (`git-commit`) |
|---|---|---|
| `feature/` | new functionality or enhancement of a User Story | `feat`, plus `test`, `docs`, `refactor` that belong to it |
| `bugfix/` | fixing a Bug | `fix` |
| `hotfix/` | urgent production fix | `fix` |
| `chore/` | non-feature work: dependencies, tooling, docs, config, pipelines | `build`, `ops`, `docs`, `chore` |
| `release/` | release preparation (see below) | `chore`, `build` |

Choosing: a bug → `bugfix` (or `hotfix` when it is an urgent production fix, ask if unsure). New functionality → `feature`. Maintenance work → `chore`. When the type is unclear, ask; don't default silently. The type reflects the task, not the commit types inside the branch.

Trunk branches `main`, `master` and `develop` have no prefix. Never create a branch with a trunk name; branch off it.

### Release branches

`release/v1.2.0`: the version replaces the description, and dots are allowed there (and only there). Release branches do **not** carry a work item number. They are rare (none seen so far), so don't build a flow around them; if one is needed, follow this format and don't invent a number.

## Which work item number?

- Use the issue or work item the branch implements when one is supplied. Do not require a particular tracker, parent/child hierarchy, or workflow state.
- In a multi-repo workspace, each repo gets its own branch. Use the relevant supplied issue ID for each; do not invent separate work items.
- **If there is no work item, don't make up a number.** Use `<type>/<description>` without creating an issue or asking for an unnecessary ID.
- Don't call a tracker just to name a branch if the user gave the ID and title. When only an ID is given, read its title with an available authorized connector or CLI, or ask for the title if no tracker is available.

## Naming rules (strict)

- Lowercase letters `a-z`, digits `0-9`, hyphens `-`; one `/` after the type. Dots only in `release/` versions.
- No uppercase, underscores, spaces, accents or special characters. Strip accents from French titles (`é` → `e`), drop punctuation and quotes.
- No consecutive hyphens, no leading or trailing hyphen in the description. No hyphen/dot adjacency.
- When present, the work item number comes first after the `/`, followed by `-`.
- The description summarizes the task or issue title in 2-5 words (about 50 characters for the whole name). Specific beats vague: `prevent-empty-order-notes`, not `fix-bug`. Drop filler words (`the`, `a`, `for`...) when it keeps meaning.
- **No person names** (author, assignee, reporter) and no personal markers (`wip-`, `test-`, initials).
- **No AI names**, anywhere: not as the prefix, not inside the description (`claude-`, `copilot-`, `ai-`).

Validation regexes (match the applicable format):

```text
^(feature|bugfix|hotfix|chore)/([0-9]+-)?[a-z0-9]+(-[a-z0-9]+)*$
^release/v[0-9]+(\.[0-9]+)*$
^(main|master|develop)$
```

### Wrong → right

| Wrong | Why | Right |
|---|---|---|
| `claude/add-supplier-export` | AI prefix | `feature/add-supplier-export` |
| `ai/48213-add-supplier-export` | AI prefix | `feature/48213-add-supplier-export` |
| `Feature/48213-Add-Supplier-Export` | uppercase | `feature/48213-add-supplier-export` |
| `feature/48213_add_supplier_export` | underscores | `feature/48213-add-supplier-export` |
| `fix/48390-empty-note` | alias, vague | `bugfix/48390-prevent-empty-order-notes` |
| `feature/48213--add-export-` | double and trailing hyphen | `feature/48213-add-export` |
| `bugfix/48390-john-fix` | person name, vague | `bugfix/48390-prevent-empty-order-notes` |

## Workflow: create a branch

1. **Work out the inputs**: type, description, and optional work item number (see above). Take them from the arguments when given, in any order and loosely worded (`48213 feature add supplier export`: the number is the work item, a type word is the type, the rest is the description). Ask only for essential missing information, in one short question. Derive the description from the task or issue title; show the final name.
2. **Validate the name** against the rules and applicable regex. Fix mechanical issues silently (case, spaces, underscores, accents, double hyphens). Never guess a work item number; remove an AI prefix in favor of the work type.
3. **Go to the right repo.** In a multi-repo workspace, run git inside the specific repo folder, never a workspace root without its own repository.
4. **Check for local changes**: `git status --porcelain`. If the tree is dirty, stop and tell the user; don't stash, reset or carry changes over without being asked.
5. **Detect the base branch**: the remote default branch, normally `main`.
   ```bash
   git fetch origin
   git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||'
   ```
   If that returns nothing, use the first of `main`, `master`, `develop` that exists on `origin`.
6. **Create from the up-to-date remote base**, without tracking it (so a later push doesn't target the base branch):
   ```bash
   git switch -c <branch-name> --no-track origin/<base>
   ```
7. **Confirm**: the branch name, the base it came from, and the repo. Remind that `git push -u origin <branch-name>` publishes it. **Don't push** unless asked.

## Workflow: check or fix an existing branch name

- Read `git branch --show-current`, check against the rules and regexes, and list what is wrong.
- **Branches an AI tool named for you** (e.g. a worktree or agent created `claude/...`): rename before the first push. If not pushed: `git branch -m <new-name>`. If already pushed, tell the user: renaming needs a new remote branch and deleting the old one, which is the user's call (and updates any open PR). Don't do it unprompted.
- Never rename or delete someone else's branch or a protected one.

## Relationship with other conventions

- **Commits**: scopes in commit messages are never work item ids (see `git-commit`); an associated id lives in the branch name. Commit subjects never carry the id either; a commit with a body gets a `Refs #<id>` footer when an id is known (see `git-commit`).
- **PRs**: link the same issue or work item when one exists. Branch creation does not authorize publishing a branch or creating a PR.

## Self-check before answering

- [ ] Type is `feature`, `bugfix`, `hotfix`, `chore` or `release`, full name.
- [ ] Work item number, when supplied, is digits right after the `/`; work without an issue has no invented ID.
- [ ] Lowercase kebab-case, 2-5 words, no person or AI names, no underscores or accents.
- [ ] No `ai/`, `claude/`, `codex/`, `copilot/` or `cursor/` anywhere.
- [ ] Created in the right repo, from the up-to-date remote base, tree was clean.
- [ ] Nothing was pushed.
