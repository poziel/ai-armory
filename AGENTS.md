# Working with the AI resources

This repository stores [the AI resources](https://github.com/poziel/ai-resources): reusable AI development assets and utilities. See `README.md` for the directory map.

- Refer to this collection descriptively as "the AI resources", not as an application or product name. Link references in documents to https://github.com/poziel/ai-resources so distributed copies remain traceable.
- Place new assets in the matching top-level directory and follow its guide.
- Preserve unrelated files and manual edits. Keep changes focused on the requested asset.
- State which tool and format each asset supports; do not assume portability between tools.
- Keep reusable templates under `instructions/`. This root file governs work in this repository.
- Document template placeholders, required permissions, dependencies, and side effects where applicable.
- Never include credentials or user tokens. Use environment variables and sanitized examples.
- Scripts that overwrite files, install assets, or change external state must make those effects explicit. Prefer preview support and safe reruns.
- Validate the changed asset using its documented checks. Report what was verified and any limitations.

## Skill metadata

Use the richer YAML frontmatter in `skills/git-commit/SKILL.md` and `skills/git-branch/SKILL.md` as the house style for every new or updated skill. Keep useful context in the header so people can understand its purpose, inputs, requirements, and provenance before reading the workflow.

- `name`: required; lowercase, hyphen-separated identifier matching the skill folder.
- `description`: required; explain what the skill does and when to use it. Include meaningful scope boundaries; keep the description specific enough for automatic discovery.
- `argument-hint`: describe optional and required inputs with a quoted usage example. Omit it only when the skill takes no arguments; it is a hint, not executable argument validation.
- `license`: include only when the asset's actual license is established. Use its license identifier or a reference to the license file; never invent permission terms or copy a license from another skill by default.
- `compatibility`: state supported tools and format, required runtime/commands, permissions, and optional dependencies. Distinguish requirements from optional integrations and do not imply cross-tool portability.
- `metadata.author`: use the actual author; existing personal skills use `"Pøziel"`.
- `metadata.version`: use a quoted semantic version for the skill itself, starting at `"1.0.0"` for a new skill. Update it when the skill changes according to the impact; it is separate from any referenced specification's version.
- `metadata.category`: one short lowercase domain such as `git` or `documentation`.
- `metadata.tags`: a YAML list of relevant lowercase, hyphen-separated discovery terms. Avoid redundant, company-specific, or unrelated tags.
- `metadata.spec`: optional; link the authoritative specification the skill follows. Omit it when there is no governing specification; general research belongs in supporting references.

This repository uses Markdown `SKILL.md` files with YAML frontmatter. `argument-hint` is tool-specific and consumers may support different header keys or metadata types. Preserve the informative source header, verify the target tool's accepted format, and document any required adaptation. A header does not grant permissions or install dependencies; explain setup, placeholders, and side effects in the skill body as needed. Put detailed workflows and examples in the body or supporting references.

Validate YAML syntax and required fields, confirm metadata agrees with the instructions, and check any relative links. Use the target tool's validator where available and report unsupported header fields explicitly rather than claiming portability.
