# HTML and template markup

Source: [the AI resources](https://github.com/poziel/ai-resources).

Use the [Google HTML/CSS Style Guide](https://google.github.io/styleguide/htmlcssguide.html) as the baseline, with the exceptions below. For Vue templates, also read the Vue component guide when that standard is selected for the project.

Use semantic elements matching the interaction: buttons for actions, links for navigation, labels for inputs, and appropriate landmarks. Prefer native semantics over unnecessary ARIA. Interactive controls need an accessible name, keyboard access, and visible focus. Keep heading levels meaningful.

Use lowercase native tag names and double-quoted attributes. Keep explicit closing tags for non-void HTML elements, even when the HTML specification allows omission. Use `<!doctype html>` in standalone HTML documents and declare UTF-8. Only meaningful identifiers belong in IDs; use classes for styling.

Indent with two spaces, let the formatter wrap long tags, and avoid mixing substantial script or style logic into markup. Formatting must preserve text content, whitespace-sensitive elements, and separation between inline elements. Configure HTML formatters to preserve meaningful inline whitespace.

Do not rewrite URLs, accessibility labels, or rendered text as a formatting change. Accessibility behavior and content correctness still need review; well-formatted markup does not establish either one.
