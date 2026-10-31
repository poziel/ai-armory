# Instruction fragments and templates

Store reusable instruction segments here, grouped by purpose, such as code review, Git conventions, or project setup. Segments should contain focused Markdown that can be shared across applications. Complete instruction templates can live here too.

- Give fragments descriptive names. Complete templates use the filenames expected by the target tool.
- Use `{{PLACEHOLDER_NAME}}` for values that must be customized.
- Include a companion `README.md` explaining the intended project, supported tool, placeholders, and destination path.
- Review and replace placeholders when assembling instructions for a project.

Files here are templates. The repository's own working instructions live in the root `AGENTS.md`.

A future installer will compose selected fragments into project instruction files such as `AGENTS.md`, `CLAUDE.md`, and `GEMINI.md`. Fragment selection, ordering, and preservation of manual content still need to be defined. `INSTRUCTIONS_DIR` reserves the destination setting; no instruction files are generated yet.

## Shared coding standards

The guides in [coding-standards/](coding-standards/README.md) are canonical
language conventions, rather than instruction templates. Project copies must
stay identical to these sources. The distributor copies selected guides without
assembling or changing any `AGENTS.md` file. See
[coding standards distribution](coding-standards-distribution.md).
