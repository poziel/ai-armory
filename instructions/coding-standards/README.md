# Coding standards

These shared conventions are maintained in [the AI resources](https://github.com/poziel/ai-resources) under `instructions/coding-standards/`. Project copies are ordinary tracked files. Edit the originals in [the AI resources](https://github.com/poziel/ai-resources) and distribute updates with `scripts/Sync-CodingStandards.ps1`; do not customize the copies per project.

## Read only the relevant guides

Read this index before editing source. Read the guides for the languages you will change, rather than loading every standard for every task:

| Files being edited         | Guides to read                                 |
| -------------------------- | ---------------------------------------------- |
| TypeScript or JavaScript   | `typescript.md`                                |
| Vue single-file components | `vue.md`, `typescript.md`, `html.md`, `css.md` |
| HTML                       | `html.md`                                      |
| CSS or SCSS                | `css.md`                                       |
| Rust                       | `rust.md`                                      |
| Markdown or MDX            | `markdown.md`                                  |

Only guides selected for this project are copied. The table describes available standards, not a requirement to read missing or unrelated guides. TypeScript and JavaScript deliberately share one guide. Rust has its own Google baseline, documentation requirements, and formatting conventions in `rust.md`.

## Shared conventions and project responsibilities

Explicit task instructions take precedence over these conventions. Use the linked Google guides as baselines for details not covered here. A formatter's defaults do not override the explicit shared conventions.

Use UTF-8, LF line endings, no trailing whitespace, and a final newline. The TypeScript, JavaScript, Vue, HTML, and CSS guides use two-space indentation and an 80-column layout preference. Rust follows rustfmt's four-space indentation and standard 100-column layout. Preserve meaningful Markdown hard breaks. Do not damage literals, URLs, documentation examples, or readable types to satisfy a line-width target.

Markdown prose has no fixed line length. Do not insert line breaks merely to meet a character count. Group related sentences into paragraphs, with paragraph breaks where the topic or purpose changes. Preserve explicit Markdown hard breaks and structural line breaks; code examples retain their language-specific formatting conventions.

Architecture, framework integration, ownership boundaries, theme-token names, and supported verification commands come from the consuming project's own documentation. Keep those details outside these shared files so language standards remain identical across projects. Follow existing language toolchains for languages without a shared guide.

Formatting does not invent meaningful documentation, split classes, establish ownership, prove accessibility, or verify runtime behavior. Review those concerns and run the checks appropriate to the change separately.
