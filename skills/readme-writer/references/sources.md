# Sources and design rationale

This skill combines the user’s README preferences with original guidance informed by the following sources. These are references, not runtime dependencies or instructions to install upstream skills. User preferences govern when source advice conflicts: existing dedicated documents are linked, artwork alignment is explicit, and badges adapt to the project.

- [Debbie O’Brien: README wizard workflow](https://debbie.codes/blog/built-agent-skill-readme-wizard/) — informed the separation of workflow, optional supporting guidance, and observable quality checks. Mechanical scanning can be extracted into a script if real usage demonstrates a need; this version uses repository inspection and has no scanner dependency.
- [GitHub Awesome Copilot: create-readme](https://github.com/github/awesome-copilot/blob/main/skills/create-readme/SKILL.md) — informed concise GFM output, reuse of existing artwork, and avoiding redundant dedicated-file sections.
- [Bane Sullivan: How to write a good README](https://github.com/banesullivan/README) — informed approachable highlights, demonstrations, user-oriented installation, and links to deeper documentation.
- [Akash: A Beginners Guide to writing a Kickass README](https://meakaakka.medium.com/a-beginners-guide-to-writing-a-kickass-readme-7ac01da88ab3) — informed the emphasis on an inviting first impression and enough concrete information to begin.
- [rokokol/create-readme-skill](https://github.com/rokokol/create-readme-skill) — user-selected reference, but unavailable during initial research on 2026-10-14. Its contents were not used; inspect it before attributing rules to it or incorporating its implementation.

Provider documentation for badges and the editor is linked from [headers-and-badges.md](headers-and-badges.md). Verify changing provider behavior there when extending supported badge types.
