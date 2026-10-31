# Structure and voice

## Choose the reader’s next action

Keep a recognizable reading order: identity and promise → evidence of value → first success → deeper help. The headings and length can vary; do not force every project into every section.

| Project / reader | Lead toward | Useful proof | Getting started |
| --- | --- | --- | --- |
| Hosted product / end user | Open the application or demo | Screenshot of a real task | Access requirements and first action; link developer setup later |
| Desktop application / end user | Download and launch | Screenshot or short recording | Supported OS, actual download route, first useful task |
| CLI / operator | Install and run a command | Command plus representative output | Real install method, prerequisites, one common workflow |
| Library / developer | Install and integrate | Small executable usage example | Correct package/import and the minimum working example |
| Self-hosted service / operator | Start a usable instance | Real service interaction | Runtime, configuration, persistence, and relevant side effects |
| Multi-project repository / explorer | Find the right component | Short component map with links | Component-specific entry points; no fictitious universal install |
| Internal tool / teammate | Complete the team’s task | A familiar workflow | Required access and actual internal prerequisites; no public-service assumptions |

## Default composition

1. **Identity:** existing logo or banner, textual project name, and a concrete one-sentence promise identifying what it does and whom it helps. Add the primary action and useful badges close by.
2. **Proof:** show a real result early. Choose a screenshot, recording, CLI output, or usage example appropriate to the product. Omit unavailable media rather than adding empty image links.
3. **Highlights:** select a few distinctive benefits grounded in shipped capabilities. Connect each feature to a reader’s task. Combine with proof for a tiny project; avoid repeating the opening.
4. **Get started:** lead to the shortest supported route to a first success. Include prerequisites before commands, working directory when needed, essential configuration, and the expected result. Surface relevant costs, external writes, installs, or data changes before the action.
5. **Essential usage:** only the workflows/options needed to continue. Link the full API, command reference, configuration guide, and troubleshooting material instead of copying them.
6. **Further links:** make documentation, support/community, contribution guide, releases/changelog, and license easy to reach when they exist. Use a compact link row or natural links; do not add redundant sections for dedicated files.

Use a table of contents only when the document is long enough to benefit. Include architecture, a directory tree, a technology explanation, or a comparison only when it helps this audience make a decision or act. A polished README is not required to enumerate every dependency or command.

## Sound like the project’s author

- Open with a recognizable task and outcome. Prefer “Preview database changes before applying them” to “A powerful, seamless solution that revolutionizes database management.”
- Use specific nouns and verbs. Replace “easy,” “fast,” “secure,” or “production-ready” with evidence or remove the claim. Do not manufacture benchmarks, popularity, trust, or guarantees.
- Keep enthusiasm tied to something demonstrable. Preserve distinctive, useful wording from the existing author rather than flattening it into generic marketing copy.
- Avoid stock introductions, rhetorical filler, repetitive summaries, repeated “Why X?” sections, and an emoji on every heading. Use emojis sparingly when they fit the existing voice.
- Speak to the primary reader. Put ordinary installation ahead of contributor builds when those are different routes. Keep critical platform/access limitations close to the promise or first action.
- Keep planned capabilities explicitly labeled and secondary. Never turn a roadmap into a present-tense feature list.
- For narrow edits, retain existing order and voice unless the requested change requires adjustment. For full rewrites, preserve useful manually authored content and check its destination in the diff.
