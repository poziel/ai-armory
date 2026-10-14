# Working in AI Armory

This repository stores reusable AI development assets and utilities. See `README.md` for the directory map.

- Place new assets in the matching top-level directory and follow its guide.
- Preserve unrelated files and manual edits. Keep changes focused on the requested asset.
- State which tool and format each asset supports; do not assume portability between tools.
- Keep reusable templates under `instructions/`. This root file governs work in this repository.
- Document template placeholders, required permissions, dependencies, and side effects where applicable.
- Never include credentials or user tokens. Use environment variables and sanitized examples.
- Scripts that overwrite files, install assets, or change external state must make those effects explicit. Prefer preview support and safe reruns.
- Validate the changed asset using its documented checks. Report what was verified and any limitations.
