# Skills

Store each skill in its own folder:

```text
skills/
  skill-name/
    SKILL.md
    scripts/      # Optional helpers
    references/   # Optional supporting documentation
    assets/       # Optional templates or other resources
```

Use the target tool's required `SKILL.md` format. Explain when the skill applies, what it does, how to use it, and any prerequisites. Add supporting folders only when needed.

Document installation steps and supported tools with each skill. Keep this directory as source material; adding a skill here does not install or activate it.

## Available skills

| Skill | Purpose |
| --- | --- |
| [git-branch](git-branch/SKILL.md) | Name and create Conventional Branch names with optional work item IDs. |
| [git-commit](git-commit/SKILL.md) | Write Conventional Commit messages with personal writing conventions. |
| [git-changelog](git-changelog/SKILL.md) | Create and review Conventional Changelog release notes with verified ranges, migration guidance, and safe generation checks. |
| [git-review-branch](git-review-branch/SKILL.md) | Summarize branch/worktree changes and optionally open VS Code. |
| [readme-writer](readme-writer/SKILL.md) | Create, improve, or review audience-focused GitHub READMEs with branding, useful badges, and verified setup. |

Follow the [skill metadata instructions](../AGENTS.md#skill-metadata) when creating or updating skills. Install them using [Install-Skills.ps1](../scripts/README.md#install-skills) or the root `Install.ps1`; installation links to these folders rather than copying them. Choose the destination used by your AI tools in `.env`.
