# Rust

Source: [the AI resources](https://github.com/poziel/ai-resources).

Use the [Google Rust Style Guide](https://google.github.io/styleguide/rustguide.html) as the baseline for design and implementation. The explicit shared conventions below strengthen its documentation guidance. For remaining details, use the [Rust Style Guide](https://doc.rust-lang.org/style-guide/) and [Rust API Guidelines](https://rust-lang.github.io/api-guidelines/).

## Applying the baseline

Read Google's rules in their stated context. Restrictions marked `[chrome]` or `[Fuchsia]` are specific to those environments; do not impose Chromium's flat crate layout, async restrictions, import machinery, or test framework on a Cargo application. Retain the consuming project's runtime and toolchain. Apply library API rules in context rather than generalizing application code unnecessarily.

Use Google's guidance for module organization, imports, ownership, function contracts, error handling, traits, concurrency, and safe code. Where this guide adds a stronger commenting requirement, follow it explicitly.

## Readable types and behavior

Express state with named structs and enums, and place its behavior in focused inherent `impl` blocks. Use traits for actual shared contracts, not to imitate a class hierarchy. Rust does not need a translation of TypeScript classes or its one-class-per-file rule. Keep a module focused on an understandable responsibility; small supporting types may remain beside their owner.

Prefer code a reader learning Rust can follow. Use descriptive names, visible intermediate steps, and explicit types when inference hides an important domain meaning. When a compact expression or iterator chain obscures validation, mutation, error handling, or ownership, write the steps out and explain them. Comments supplement clear code; they do not justify unnecessarily obscure code.

## Documentation is part of the implementation

Write for a maintainer who knows the application but is still learning Rust. Provide enough context to understand the code directly, without reconstructing its purpose from callers or asking an agent to explain it afterward.

Our default is more explanation than the minimum public-API documentation:

- Document every handwritten struct, enum, trait, type alias, and named constant, including private items. Document fields, enum variants, and associated items so their domain meaning and constraints are visible beside their declarations.
- Document functions, inherent methods, constructors, and private helpers. Explain the operation, meaningful input restrictions, result semantics, state changes, and ownership or cleanup obligations where relevant.
- Start implementation modules with a short explanation of their responsibility and important relationships. Simple re-export-only modules do not need a repetitive overview if their role is already clear from surrounding docs.
- For trait implementations, keep the shared contract on the trait declaration. Explain implementation-specific guarantees, deviations permitted by the trait, resource behavior, or subtle design choices where they occur; do not copy the same trait documentation onto every implementation method.

A straightforward item can have one useful sentence. An obscure type or method needs a short overview and further paragraphs describing its model, invariants, and interactions; add a small example when that makes usage clearer. There is no comment quota or requirement to explain each source line.

This is an intentional extension of Google's public-API emphasis and allowance to omit obvious variant documentation. Private code is also read and learned from. Describe the item's role or invariant rather than repeating its name, and update its documentation in the same change as its behavior. Generated and vendored code are outside this handwritten-documentation requirement.

## Rust documentation syntax

Use Rust's documentation system, following the [rustdoc writing guide](https://doc.rust-lang.org/rustdoc/how-to-write-documentation.html):

- `//!` describes the containing module or crate, usually at the file's start.
- `///` immediately before an item documents that item for editor hovers and generated reference pages. Use it for private items too.
- `//` explains an implementation step, local decision, or internal detail.

Start item documentation with a short summary. Add paragraphs and Markdown sections when needed. Use `# Errors` for meaningful failure conditions, `# Panics` for reachable panic conditions, `# Safety` for unsafe caller requirements, and `# Examples` for useful usage examples. Explain parameters and results in prose or a short list when they need explanation; Rust does not use JSDoc's `@param` and `@returns` tags. Avoid repeating types already in signatures.

Prefer intra-doc links such as ``[`Self::select`]`` when they help navigation. Keep runnable examples self-contained or give them the correct crate imports. Do not add `ignore` merely to avoid fixing an example that should compile.

## Comments inside implementations

Add implementation comments before non-obvious steps and meaningful phases of an algorithm. Explain the goal, the reason for the chosen approach, and any invariant that must survive the step. Include relevant edge cases and ordering requirements. Keep comments close to the code they explain.

Give particular attention to Rust mechanics when they affect this operation:

- Explain why data is borrowed, moved, cloned, or removed with `take` or `mem::take`, and which object owns it afterward when that is not apparent.
- Explain a non-obvious lifetime relationship in domain terms: what must remain alive, what the returned reference points into, and why it is valid.
- Explain why shared ownership or interior mutability is required, who can access the value, and when a guard or mutable borrow ends.
- Explain lock ordering, releasing guards before callbacks or `.await`, task cancellation, and resource cleanup when those choices matter to correctness.
- Explain error conversion or propagation when the boundary changes what a failure means. Explain recoverable paths and why state is still valid.

It is welcome to briefly explain an unfamiliar Rust idiom in the context of this code. For example, explain that `take` leaves `None` so a resource can be moved out before cleanup. Do not turn every borrow or assignment into a generic language lesson. Spend the explanation on choices the reader must understand.

Avoid narration such as `// Increment the counter` beside `counter += 1`. Prefer an explanation of why the counter is updated here or what it measures. Comments must describe actual behavior, not a hoped-for design or a stale implementation. If a comment and code disagree, resolve the discrepancy.

For necessary unsafe operations, document caller requirements under `# Safety` and explain each unsafe block's local proof with `// SAFETY:`. The explanation must identify the actual validity and lifetime guarantees, not just claim that the operation is safe. Prefer a safe implementation when one is available.

## Example: contracts and implementation comments together

This standalone example illustrates documentation style, not an application API. The type overview explains the model; method docs explain the contract; local comments explain validation order and the effect of borrowing.

```rust
//! Maintains a selection within a fixed-length animation.

/// Tracks one selected frame without allowing indices outside the animation.
///
/// Indices are zero-based. This type stores only the frame count and selection;
/// the caller owns the animation data. Recreate the selection if its frame
/// count changes, because the stored bounds are fixed after construction.
pub struct FrameSelection {
    /// Nonzero number of frames available in the owning animation.
    frame_count: usize,
    /// Selected zero-based index, or `None` before a frame has been selected.
    selected: Option<usize>,
}

/// Explains why an animation selection could not be created or changed.
#[derive(Debug, PartialEq, Eq)]
pub enum SelectionError {
    /// An empty animation has no frame that can be selected.
    EmptyAnimation,
    /// The requested zero-based index is outside the stored frame count.
    InvalidFrame,
}

impl FrameSelection {
    /// Creates an unselected range for an animation containing `frame_count` frames.
    ///
    /// # Errors
    ///
    /// Returns [`SelectionError::EmptyAnimation`] when `frame_count` is zero.
    pub fn try_new(frame_count: usize) -> Result<Self, SelectionError> {
        if frame_count == 0 {
            return Err(SelectionError::EmptyAnimation);
        }

        Ok(Self {
            frame_count,
            selected: None,
        })
    }

    /// Selects `index`, preserving the current selection if the request fails.
    ///
    /// # Errors
    ///
    /// Returns [`SelectionError::InvalidFrame`] when `index` is outside the animation.
    pub fn select(&mut self, index: usize) -> Result<(), SelectionError> {
        // Validate before mutating so an invalid request preserves the user's
        // previous selection rather than leaving the object partially updated.
        if index >= self.frame_count {
            return Err(SelectionError::InvalidFrame);
        }

        self.selected = Some(index);
        Ok(())
    }

    /// Returns the selected zero-based index, or `None` if none has been selected.
    pub fn selected(&self) -> Option<usize> {
        // This value is Copy: callers receive an independent index and do not
        // keep a reference into the selection after this borrow ends.
        self.selected
    }
}
```

## Formatting and verification

Use the project's pinned Rust toolchain and `rustfmt`, normally through `cargo fmt`. Rust uses four-space indentation and the standard 100-column layout, rather than the TypeScript/JavaScript two-space and 80-column defaults. Do not apply the TypeScript member-spacing or six-parameter rules to Rust. Use stable formatting options; do not require nightly merely for style.

Run relevant Cargo checks, tests, and documentation examples using the consuming project's documented commands. For Cargo projects, `cargo doc --no-deps --document-private-items` can help review private documentation too. `missing_docs` is useful for public API coverage but does not verify all private comments or the quality of explanations. Review both item contracts and the implementation commentary; formatting alone proves neither.
