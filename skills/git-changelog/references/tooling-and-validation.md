# Tooling and validation

Read this when generation or automated checks are useful. Use the repository's installed version, configuration, package manager, and documented workflow. These commands are examples, not instructions to add dependencies to every application.

## Choose the smallest useful tool

| Tool | What it establishes | Limits and side effects |
| --- | --- | --- |
| `conventional-changelog` with a matching preset | Parses Git history and produces grouped Markdown with links | Generates content; does not lint an existing changelog or prove completeness. Can write files by default. |
| `markdownlint-cli2` | Markdown style and structure under configured rules | Does not verify release facts or links. Configuration may enable fixes or additional globs. |
| `@commitlint/cli` with repository rules | Commit-message conformity for the selected range | Does not validate changelog Markdown or factual release coverage. Historical violations do not authorize rewriting history. |
| `conventional-recommended-bump` | Version-bump advice using the configured preset | A recommendation, not authorization to change a version; inspect installed CLI/API documentation. |
| `commit-and-tag-version`, `semantic-release`, existing release automation | Coordinates broader release work | May change versions/files, create commits/tags, or publish. Use only when that broader work is authorized. |

Conventional Changelog and Keep a Changelog are different conventions. Do not run a validator for one against the other and call the result universal changelog validation.

## Dependencies and safe execution

Prefer the local executable in `node_modules/.bin/` (`.cmd` on Windows) or the project's equivalent installation. Inspect configured scripts first. Avoid bare `npx`/`npm exec` as an assumed local-only runner: they can download and execute packages and write caches. An old global CLI can behave differently from current documentation.

If the user requests adding generation tooling to a Node project, a typical npm setup is:

```sh
npm install --save-dev conventional-changelog conventional-changelog-conventionalcommits
```

This downloads dependencies, changes the manifest/lockfile, and may execute install scripts. Use the project's package manager and compatible package versions; do not mix lockfiles. Check package `engines` for the installed Node version. Older documentation may name `conventional-changelog-cli` as a separate package; inspect the installed binary rather than blindly migrating it. Optional Markdown and commit checks need their own packages/configuration. No network or token is required for local generation from complete Git history.

## Inspect the inputs

Replace all `{{PLACEHOLDERS}}` below before execution. `{{PREVIOUS_REF}}` is the previous release tag/SHA for this app/package; `{{TARGET_REF}}` is the included target ref, usually `HEAD`. The range excludes the previous ref and includes the target. `{{TAG_PREFIX}}` is the verified package/version prefix (for example `v` or `app@`); `{{PACKAGE_PATH}}` is its repository-relative path. Do not type placeholder braces literally.

```sh
git status --short
git diff -- CHANGELOG.md
git diff --cached -- CHANGELOG.md
git tag --merged {{TARGET_REF}} --sort=-version:refname
git merge-base --is-ancestor {{PREVIOUS_REF}} {{TARGET_REF}}
git log --format=fuller {{PREVIOUS_REF}}..{{TARGET_REF}}
```

An ancestry check exits nonzero for an unsuitable base; investigate before generating. Tag sorting is only a discovery aid, not proof of the correct release boundary. Check `git rev-parse --is-shallow-repository` if history seems incomplete. A requested first release needs a deliberate all-history scope; do not invent a previous ref.

## Preview with the installed CLI

PowerShell examples from the application repository root, assuming a local binary exists:

```powershell
./node_modules/.bin/conventional-changelog.cmd --version
./node_modules/.bin/conventional-changelog.cmd --help
```

With a version whose help lists `--stdout`, `--from`, `--to`, and `--output-unreleased`:

```powershell
./node_modules/.bin/conventional-changelog.cmd -p conventionalcommits --stdout --output-unreleased --from '{{PREVIOUS_REF}}' --to '{{TARGET_REF}}'
```

For a confirmed version already correctly represented in the project's release metadata, omit `--output-unreleased` after verifying the resulting heading. If the manifest still holds an already released version, keep the draft Unreleased or use the installed tool's supported context options for the confirmed target. Do not bump the manifest just to obtain a heading.

On POSIX, use `./node_modules/.bin/conventional-changelog` without `.cmd`. For a package, use the supported `--tag-prefix`, `--lerna-package`, `--commit-path`, and `--pkg` options as appropriate; inspect their help and the actual package tags first. Add only options needed by that project. An explicit range alone does not fix incorrect package metadata or comparison links.

If the project uses a custom config, replace `-p conventionalcommits` with its verified `--config` invocation. Executable configuration runs JavaScript; inspect it before loading it. Preserve its parsing, filters, templates, and host-specific links.

Current upstream documents stdout as the explicit preview and file writing as the default. Older CLI releases commonly used stdout by default and `-s/--same-file` for writes; they may lack the newer range flags. Never assume these flag sets are interchangeable. If the installed version cannot safely preview the intended range, use its documented API/configuration or curate the section from the explicit Git log; report the limitation without quietly upgrading dependencies.

Stdout may include the existing infile as well as generated content, depending on version/options. Inspect output boundaries before inserting it; do not paste a complete preview into an existing changelog. To save a scratch preview, use a distinct new path, preserve UTF-8, and check the command exit code before using the output. Never redirect into the source `CHANGELOG.md`, which can truncate it before the process reads it.

`--release-count 0` / `--first-release` regenerates all history and can overwrite output. It is not an incremental update or a formatting check. Use full regeneration only when requested, review in a separate file first, and retain manual content deliberately. Direct write/append options likewise require checking their actual installed semantics.

## Customize only when needed

The upstream commit-message skill is useful for release-impact reasoning, public contract changes, scopes, and local commitlint checks. It does not replace this repository's `git-commit` rules: for example, that skill classifies dependency work as `build`, uses `ops`, and preserves Git's default revert messages.

When automated output misses required notes, inspect the installed parser/preset and report the mismatch. If configuration work is authorized, test changes with representative commits before applying them. Mapping a type to a visible section is not automatically the same as changing version-bump policy.

Preset APIs vary by version. Current upstream uses `effect: 'bump' | 'changelog' | 'hidden'` in type entries; older releases use `hidden` fields. Configuring `types` can replace the entire defaults list. Inspect the installed API and preserve all required types rather than pasting a partial mapping that drops features or breaking changes. Keep reusable changelog templates under `instructions/` in [the AI resources](https://github.com/poziel/ai-resources) if separately requested; this skill needs no copied template.

## Validate in layers

Before running Markdown lint, inspect its configuration: `fix: true` can mutate files even without `--fix`, and configured globs can expand the scope. Run the Markdown command below only after verifying a non-fixing, file-scoped configuration. Otherwise use an isolated configuration supported by the installed version, or skip the automated check and report that limitation. PowerShell examples, conditional on those checks and the tools/configuration being available:

```powershell
./node_modules/.bin/markdownlint-cli2.cmd "CHANGELOG.md"
./node_modules/.bin/commitlint.cmd --from '{{PREVIOUS_REF}}' --to '{{TARGET_REF}}' --verbose
git diff --check
git diff -- CHANGELOG.md
```

Generated changelogs commonly repeat category headings and may contain extra blank lines, conflicting with default Markdown rules. Respect the repository's intentional settings; do not globally disable lint rules or rewrite old releases merely to make a default configuration pass.

Commitlint requires suitable rules/configuration and complete history. A pass proves only those rules. Manual release-content checks still cover breaking changes, omitted custom types, net reverts, version/date correctness, duplicates, and migration information. Inspect local reference targets and host-specific link structure; report remote link checks separately if access is unavailable. For a curated changelog, compare meaning with generated output rather than requiring byte-for-byte equality. For generated-only files, a same-input regeneration can detect drift, but cannot prove omitted changes are unimportant.

## Behavioral checks

When maintaining this skill, exercise realistic scenarios in an isolated fixture or authorized project. Assess observable decisions, not matching phrases. Record which checks actually ran.

| Scenario | Expected behavior |
| --- | --- |
| Manifest still says released 1.4.0; next version/date undecided | Unreleased draft; no duplicate 1.4.0, fictitious date, version mutation, or tag creation |
| `refactor(api)!` without a migration footer | Breaking entry despite hidden type; inspect code/docs and flag any missing migration facts |
| Feature and its complete Git-default revert are both after the base | Omit canceled feature; verify SHA/body and net effect instead of trusting type-only filtering |
| Revert targets a feature released before the base | Explain release-visible removal/restoration; do not cancel it against an out-of-range commit |
| Monorepo has newer tags for another package and shared code changes | Use package boundary and verified refs; account for shared impact |
| Manually curated history; user requests only latest release | Focused edit; previous text retained; second run adds no duplicates |
| Old global CLI; no local generator or Markdown linter | Inspect help/semantics; use safe manual fallback, no implicit install, disclose skipped checks |
| Automated changelog omits a release-visible `build` or `ops` change | Explain parser/policy gap; no history rewrite or unsolicited release-config changes |

## Sources

Reviewed against official sources on 2026-10-14. Verify installed-version documentation when commands or APIs differ.

- [Conventional Changelog repository](https://github.com/conventional-changelog/conventional-changelog) and its [conventional-commit-message skill](https://github.com/conventional-changelog/conventional-changelog/blob/master/skills/conventional-commit-message/SKILL.md): release-aware commit guidance; upstream currently supplies a commit-message skill, not a dedicated changelog skill.
- [Official website](https://conventional-changelog.js.org/), [CLI options and examples](https://conventional-changelog.js.org/conventional-changelog/cli/), and [CLI implementation](https://github.com/conventional-changelog/conventional-changelog/blob/master/packages/conventional-changelog/src/cli/cli.ts): preview, ranges, file writes, and regeneration behavior.
- [Conventional Commits preset](https://conventional-changelog.js.org/presets/conventional-commits/) and [preset options](https://conventional-changelog.js.org/presets/conventional-commits/options/): categories, hidden types, breaking notes, and customization.
- [markdownlint-cli2](https://github.com/DavidAnson/markdownlint-cli2#command-line): Markdown checks, configuration, and fix behavior.
- [commitlint CLI](https://commitlint.js.org/reference/cli.html): commit-range validation, distinct from changelog validation.
