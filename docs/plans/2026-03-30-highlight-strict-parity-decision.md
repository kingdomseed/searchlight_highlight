# Highlight Strict Parity Decision

Date: 2026-03-30

## Decision

`searchlight_highlight` will target strict parity with Orama Highlight before
any Searchlight-specific improvements.

That means:

- match the audited standalone helper-package contract first
- do not force this package into Searchlight's plugin system because the Orama
  source is not plugin-shaped
- preserve Orama's public names and behavior where the implementation is clear
- treat any additive Flutter or Searchlight ergonomics as follow-up work only
  after parity is complete and documented

## Audited Orama Package Shape

Audit result from the Orama Highlight source:

- Orama Highlight is published as `@orama/highlight`
- the audited package exports a stateful `Highlight` class plus helper types and
  constants
- the audited package is **not** a create-time plugin and does **not** register
  hooks or components with Orama core

Strict parity therefore requires:

- a standalone Dart package
- a `Highlight` class with Orama-compatible getters and methods
- `highlightStrategy`, `HighlightOptions`, and `Position` parity surface

## Implementation Rule

Until parity is reached:

- do not describe the package as "close enough" to Orama
- do not rename public API pieces into more idiomatic Dart names when that
  would hide Orama parity
- do not add excerpt builders, `TextSpan` adapters, or Searchlight wrappers
  ahead of the audited public contract

## Documentation Rule

All planning and implementation work for `searchlight_highlight` should assume
this order:

1. Match Orama exactly where the public implementation is clear.
2. Leave unclear areas reserved rather than guessed.
3. Add improvements only after parity is complete and explicitly documented.
