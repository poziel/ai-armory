# Headers and badges

## Artwork and alignment

- Prefer the existing product logo or an approved banner as the first visual element. A standalone symbol with no wordmark is centered. Center the textual project name under centered artwork.
- A product icon paired with its name may use a left-aligned treatment. Keep alignment coherent across the header; the body remains conventionally left-aligned.
- Use GitHub-supported HTML such as `<p align="center">` for images/badges and `<h1 align="center">` for the name where needed. Close HTML blocks and leave blank lines before ordinary Markdown. Do not rely on custom CSS, scripts, or `target="_blank"` surviving GitHub sanitization; readers control opening a link in another tab.
- Use a real relative image path, meaningful alt text, and reasonable dimensions. Keep one textual top-level project heading. Check readability in light/dark contexts and at narrow widths when a rendered preview is available; report if only source checks were possible.
- A banner containing the name still needs a textual heading for accessibility. No asset means a clean text header, not an invented image path or an unsolicited brand redesign.

## Choose badges for this project

Start with roughly three to five useful badges, without imposing a quota or hard cap. A small project can use fewer; a multi-project repository can justify more. A badge should communicate relevant status, identify a component, or take readers somewhere useful. Ask for optional preferences when they matter, but proceed with supported choices when the project makes them clear.

| Badge | Selection rule | Click destination |
| --- | --- | --- |
| License | Strong default when the repository has a known license. Prefer GitHub’s detected-license badge; verify it agrees with the file. | Actual license file, or verified GitHub license view |
| Open in editor | Strong default for a GitHub repository whose readers benefit from exploring code. Use `github.dev` for browser editing. | `https://github.dev/{{OWNER}}/{{REPO}}` |
| Release version | Only for an actual released version. Software need not have a hosted deployment to have a release. Prefer the distribution channel readers will use. | Releases page or relevant package |
| Deployment status | Only for an existing deployment signal. Specify environment/workflow/branch as appropriate. Passing tests do not establish a live deployment or uptime. | Deployment run or provider status page |
| CI/tests | When build/test health helps the reader. Identify the actual workflow and intended branch. | Relevant workflow runs |
| Sub-projects | Useful when readers choose among components. Give each a meaningful name and link; use verified versions/statuses only when available. | Component directory, repository, or documentation |
| Discord/community | When that community is a real support or coordination channel. Use a dynamic Discord badge only with a known server ID and working public widget; otherwise use a static invitation badge. | Existing verified invitation or community page |
| Stars | Optional community signal for public repositories; do not present it as evidence of quality. | Repository stargazers |
| Downloads, coverage, platform support | When meaningful to this audience and backed by current evidence. Static platform badges must reflect actual support. | Package, report, or compatibility documentation |
| Comments | Do not choose by default: the intended metric is unclear. Ask which discussion/issue/count is meant if explicitly requested. | The specific verified conversation or metric |

Prefer one Shields.io style, `flat` by default; retain a coherent existing style or the user’s choice. Do not create an entire stack-badge wall. Static badges for editor/community/component links are useful even when no release or deployment exists. Do not fabricate a release just to fill a badge row.

## Link the image explicitly

The badge image URL supplies the image and metadata, not the README’s click destination. Use `[![Meaningful label](IMAGE_URL)](DESTINATION)` or a compact `<a href="DESTINATION"><img ...></a>` inside a centered HTML row. Shields’ `link=` parameter does not supply a click target for a Markdown image.

These are construction examples, not finished project values:

```markdown
[![License](https://img.shields.io/github/license/{{OWNER}}/{{REPO}}?style=flat)]({{LICENSE_PATH}})
[![Open in editor](https://img.shields.io/badge/Open_in-editor-007ACC?style=flat)](https://github.dev/{{OWNER}}/{{REPO}})
[![Release](https://img.shields.io/github/v/release/{{OWNER}}/{{REPO}}?style=flat)](https://github.com/{{OWNER}}/{{REPO}}/releases)
[![Tests](https://img.shields.io/github/actions/workflow/status/{{OWNER}}/{{REPO}}/{{WORKFLOW_FILE}}?branch={{BRANCH}}&label=tests&style=flat)](https://github.com/{{OWNER}}/{{REPO}}/actions/workflows/{{WORKFLOW_FILE}})
[![Discord](https://img.shields.io/badge/Discord-Join-5865F2?style=flat)]({{DISCORD_INVITE_URL}})
```

Replace `{{OWNER}}` and `{{REPO}}` with the verified GitHub identity; `{{LICENSE_PATH}}` with the real relative license path; `{{WORKFLOW_FILE}}` with the workflow filename; `{{BRANCH}}` with the intended branch; and `{{DISCORD_INVITE_URL}}` with the existing invitation. URL-encode substituted path/query values as required. Remove inapplicable examples and leave no construction markers in the finished README. For sub-project badges, use a descriptive static label linking to each real component, or a verified component-specific status/version.

`github.dev` is browser editing without compute or an integrated terminal. Do not label it “Run demo.” Codespaces is a separate compute-backed development environment with quota/billing considerations; use it when relevant, without presenting it as an automatically configured or free runtime. Local VS Code deep links require an appropriate installed application/extension and should only be offered when supported.

Public badge services may not resolve private repositories. Unknown license, inaccessible data, an unsupported host, or a failed dynamic endpoint calls for a direct link or verified static badge, not credentials in an image URL. Never add tokens to public Markdown. Do not authorize badge applications or enable Discord widgets as part of README writing.

## Technical references

- [Shields GitHub license](https://shields.io/badges/git-hub-license)
- [Shields GitHub Actions workflow status](https://shields.io/badges/git-hub-actions-workflow-status)
- [Shields Discord badge](https://shields.io/badges/discord)
- [GitHub web editor and Codespaces comparison](https://docs.github.com/en/codespaces/the-githubdev-web-based-editor)

Check the provider’s current documentation before constructing an unfamiliar dynamic badge; do not guess its endpoint or prerequisites.
