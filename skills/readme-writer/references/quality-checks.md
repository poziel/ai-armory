# Quality checks

## Before returning a README

- **Reader journey:** Can the intended reader identify what this does, why it helps, and the next action from the opening? Does the proof demonstrate a real capability?
- **Evidence:** Trace feature claims, supported platforms, prerequisites, package/version references, and commands to project files or verified authoritative sources. Resolve contradictions; omit unsupported optional claims and flag facts required to proceed.
- **First success:** Confirm package manager, command names, working directory, configuration names, and expected result. Inspect definitions before executing commands. Do not execute installers, migrations, deployment, or external writes just to validate prose without appropriate authorization. Report inspected versus executed commands separately.
- **Links and media:** Resolve local relative links from the README’s directory, respecting case for GitHub/Linux. Check heading anchors, image existence, alt text, and badge click targets. Inspect external destinations when available; say when remote rendering/data could not be checked. A URL returning successfully alone does not prove the right content or correct badge data.
- **Header:** One textual project heading, coherent artwork/name alignment, readable sizing, and closed HTML blocks. Check a rendered GitHub-compatible preview where available; source review alone is not visual verification.
- **Badges:** Each selected badge has a purpose, known metadata, and a meaningful destination. Verify workflow/branch/environment labels. No release badges for unreleased manifests, no invented Discord links, no credentials in URLs, and no generic CI badge masquerading as deployment health.
- **Content ownership:** Dedicated files are linked rather than copied. No redundant license/changelog/contribution sections when those files exist. No removed manual content outside scope.
- **Finish:** Remove unresolved construction placeholders, dead scaffold sections, repeated explanations, unsupported superlatives, and fake examples presented as actual results. Run `git diff --check` when Git is available and inspect the focused diff, including new files.

## Behavioral scenarios for skill changes

Exercise representative scenarios when revising the skill. Use an isolated fixture or a user-authorized project; do not rewrite this repository’s README as an implicit test. Judge observable usefulness and accuracy rather than exact wording. Record which scenarios were actually exercised.

| Scenario | Expected behavior |
| --- | --- |
| Tiny unreleased utility with LICENSE and a GitHub remote | Concise README; license/editor badges where supported; no invented release or deployment; one real workflow |
| Hosted product with CI and a separate production deployment | Leads to product use; distinct test/deployment signals; accurate environment; contributor setup stays secondary |
| Repository linking three components, coordinated on Discord | Named component links/badges and known community invitation; no invented server ID or universal install |
| Existing README with manual content; request changes badges only | Focused header/badge edit; body and unrelated manual changes preserved |
| Conflicting lockfiles or absent installation instructions | Investigates configuration; asks when essential ambiguity remains; does not silently invent runnable setup |
| Private repository, no usable dynamic badge data or logo | Honest text header and direct links/static badges when useful; no broken images, guessed license, or exposed tokens |
| Library with a released package and no deployment | Release badge is valid; no deployment requirement added; example uses the real package/import |

Skill-format checks and link checks are structural validation. Real project trials and rendered previews establish different evidence; report their limits separately.
