---
name: git-review-branch
description: Review what changed on the current branch or worktree (a git worktree started from main or from another branch) so I can stay close to AI-generated code. Finds the real base (the branch the worktree was started from, else main), gives a global summary of what is new, removed and modified (the big changes, not a line-by-line review), then opens VS Code on the repo(s) unless a window is already open. Handles worktrees with several repos (opens each, or the root) and folders with no usable git history (opens each affected project in its own window to compare by hand). Use when asked to review the code, see what changed, summarize the branch or worktree, or "show me what the AI did".
argument-hint: "[repo folder or story folder] [--base <branch>] [--no-open]"
compatibility: Codex SKILL.md with YAML frontmatter. Requires Git, PowerShell, and repository read access. Optional - the VS Code `code` command on PATH and permission to open windows; use --no-open for a summary only.
metadata:
  author: "Pøziel"
  version: "1.0.0"
  category: git
  tags:
    - git
    - review
    - worktree
    - diff
    - vscode
---

# Review branch changes

Arguments: `$ARGUMENTS`

Goal: after a back-and-forth with the AI in a worktree, give me the **big picture** of what changed, then put the changes in front of me in VS Code. Read-only on git: never commit, stage, stash, reset, switch, fetch with pruning or push. The only side effect is opening VS Code windows.

## 1. Find the repos to review

- Target = the folder in `$ARGUMENTS`, else the current working directory.
- A **repo** is a folder with a `.git` entry (a directory, or a **file** for a worktree). Check the target itself, then its direct sub-folders (a story folder such as `.worktree\<id>-<title>\` holds one worktree per repo; a workspace root holds several repos). Skip `node_modules`, `.worktree` contents unless the target is inside one, and folders without `.git`.
- If the target is a workspace root with no argument, don't review every repo: only keep those with changes against their base (step 2), and say which were skipped.
- No repo found, or `git rev-parse` fails, or no base can be found: use the **no-history** path (step 5) for that folder.

Run git per repo (`git -C <repo> ...`), never combined across repos.

## 2. Find the base to compare against

Per repo, in this order, stop at the first that works:

1. `--base <branch>` given by the user. Use it.
2. **Where the branch was started from**: the first reflog entry of the branch.
   ```bash
   git -C <repo> reflog show --format=%gs <branch> | tail -1    # "branch: Created from origin/main"
   ```
   If it says `Created from <ref>` and `<ref>` is a branch name (not `HEAD` or a sha), use it. Worktree scripts create branches from `origin/<default>` (or a requested base), so this normally names the real parent.
3. **Remote default branch**: `git symbolic-ref --short refs/remotes/origin/HEAD`, else the first of `origin/main`, `origin/master`, `origin/develop` that exists.
4. **Closest branch** when the reflog is gone (the branch was pushed, cloned or re-created): among `origin/main`, `origin/master`, `origin/develop` and the other local branches, take the one with the fewest commits in `<candidate>..HEAD` (`git rev-list --count`). Say it is a guess.

Then the comparison point is the **merge base**: `git merge-base <base> HEAD`. Compare the **current state** (committed + uncommitted) against it:

```bash
git -C <repo> diff --stat -M <merge-base>            # files and size, includes working tree changes
git -C <repo> diff --name-status -M <merge-base>     # A/M/D/R per file
git -C <repo> ls-files --others --exclude-standard   # new untracked files: also "new"
git -C <repo> log --oneline <merge-base>..HEAD       # commits since the base (may be none)
```

Use the local state of the base if the remote ref is missing, and say so. Don't `git fetch` to refresh unless asked: a stale `origin/main` is reported as "base as of the last fetch".

Say plainly which base was used and why (e.g. "base `origin/main`, branch created from it, merge-base `abc1234`"). If the base is not main, say so: it changes what "new" means.

## 3. Global summary

Per repo, concise, the **big changes** first. Read the diff as needed (use sub-agents for large repos, in parallel, each given the repo path, the merge-base and the rules here; they return a compact brief). Don't list every file when there are many: group by area.

- **Header**: repo, branch, base used, number of commits, files changed (+ lines / - lines), uncommitted work yes/no.
- **New**: files, components, endpoints, classes, tests, migrations, config added. One line each, grouped.
- **Modified**: what changed in behavior in existing code, and where. Say *what it does now*, not the diff mechanics.
- **Removed**: files, functions, tests, config deleted. Flag removed tests or disabled assertions explicitly.
- **Renamed/moved**: only when it matters.
- **Worth a closer look**: the 3-6 places where a human should read the code, with `file:line` links: risky logic, contract or schema changes, data or migration impact, security-relevant code, changes outside the stated scope, generated or very large files, dependency or build changes. This is a pointer, not a review verdict; don't invent problems.
- If the work item or the plan is known (branch name carries the id), add one line: does the change set look like what was asked, and what looks extra.

Several repos: one section per repo, then a short cross-repo note (API contract change vs. the UI consuming it) when relevant. Keep the whole answer scannable; no walls of code.

Never copy sensitive data seen in the diff (names, emails, tokens, connection strings); refer to it generically.

## 4. Open VS Code

Skip with `--no-open` or when the user asked only for a summary.

Which folders:

| Situation | Open |
|---|---|
| One repo | That repo folder. |
| Several repos in a story folder or workspace | **Each repo that has changes**, one window each. Alternatively the common root, if the user prefers one window (ask once only if unclear; default to one window per changed repo). |
| No-history folders (step 5) | Each affected project, one window each. |

Resolve `<skill-directory>` to the directory containing this `SKILL.md`, then run the bundled `scripts/Open-VSCodeFolders.ps1` helper (it checks first whether a window is already open on the folder and does nothing if so):

```powershell
& "<skill-directory>\scripts\Open-VSCodeFolders.ps1" -Path '<repo 1>','<repo 2>'      # add -DryRun to preview
```

Report per folder: `OPEN` (already open, untouched), `OPENED`, `MISSING`, `NO-CODE-CLI`. The open check relies on VS Code's state file and can lag a few seconds; if it says `weak match`, tell the user it may be wrong. In VS Code the user sees the changes in the Source Control view (it already lists the working-tree changes); for the committed ones suggest the Git Graph or "Compare with..." on the base only if they ask: don't change their VS Code settings.

## 5. No usable git history

When a folder is not a git repo, has no commits, or no base can be found:

- Say so, and don't fabricate a diff.
- If a main checkout of the same project exists (for a worktree path `...\.worktree\<story>\<repo>`, that is the workspace `<repo>` folder), mention it as the natural comparison, but **never read or edit it as if it were the branch's code** and never touch it.
- Summarize from what exists: the folder's file listing by recent modification time (`Get-ChildItem -Recurse` sorted by `LastWriteTime`, excluding `node_modules`, `bin`, `obj`, `.git`) as a hint of what was touched, clearly labeled as a guess.
- Open each affected project in its own window (step 4) so the user can compare by hand.

## Self-check

- [ ] Base is stated with the reason (reflog, default branch, guess), and a non-main base is called out.
- [ ] Diff is against the merge base and includes uncommitted and untracked files.
- [ ] Summary has New / Modified / Removed, the big changes first, plus a short "worth a closer look" list with `file:line` links.
- [ ] Nothing was committed, staged, stashed, switched, fetched-with-prune or pushed; no main checkout was touched.
- [ ] VS Code windows already open were left alone; each report line matches the script output.
- [ ] No sensitive data copied from the diff.
