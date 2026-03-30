# Orama Highlight Source Audit

Date: 2026-03-30

Primary source:

- `src/index.ts` from the Orama Highlight repository
- `src/index.test.ts`
- `README.md`
- `package.json`

## Audited Package Shape

Orama ships Highlight as the standalone package `@orama/highlight`.

The audited package exports:

- `highlightStrategy`
- `HighlightStrategy`
- `HighlightOptions`
- `Position`
- `Highlight`

## Plugin-System Finding

The audited package is **not** a create-time Orama plugin and does **not**
integrate with Orama's core plugin system.

Strict parity for Searchlight Highlight therefore means matching the standalone
helper-package contract first.

## Public Contract Findings

### `highlightStrategy`

Audited shape:

- `WHOLE_WORD_MATCH = 'wholeWordMatch'`
- `PARTIAL_MATCH = 'partialMatch'`
- `PARTIAL_MATCH_FULL_WORD = 'partialMatchFullWord'`

### `HighlightOptions`

Audited options:

- `caseSensitive?: boolean`
- `strategy?: HighlightStrategy`
- `HTMLTag?: string`
- `CSSClass?: string`

Audited defaults:

- `caseSensitive: false`
- `strategy: highlightStrategy.PARTIAL_MATCH`
- `HTMLTag: 'mark'`
- `CSSClass: 'orama-highlight'`

### `Position`

Audited shape:

- `start: number`
- `end: number`

Important:

- `end` is inclusive, not exclusive

### `Highlight`

Audited stateful class behavior:

- constructor accepts `HighlightOptions`
- `highlight(text, searchTerm)` mutates internal state and returns `this`
- `positions` getter exposes current match positions
- `HTML` getter exposes the current highlighted HTML string
- `trim(trimLength, ellipsis = true)` trims around the first match and mutates
  the current state again by re-running `highlight(...)` on the trimmed content

### Matching Behavior

Audited implementation details:

- null text/search input is tolerated and treated as an empty string result
- empty search term or empty text clears positions and sets `HTML` to the
  original text
- search term is escaped before regex construction
- multiple search tokens are created by whitespace splitting and joined with `|`
- default strategy is partial substring matching
- whole-word strategy uses `\\bterm\\b`
- partial-match-full-word strategy highlights the entire containing word when a
  token matches inside it
- rendered HTML always wraps the matched text with
  `<HTMLTag class="CSSClass">...</HTMLTag>`

### `trim(...)`

Audited behavior:

- if no matches exist, return the first `trimLength` characters of the current
  HTML and append `...` when `ellipsis` is true
- if the original text length is already `<= trimLength`, return the current
  HTML unchanged
- otherwise center the excerpt around the first match start, not around the
  midpoint of all matches
- when trimming a matched string, `trim(...)` re-invokes `highlight(...)` on
  the trimmed excerpt so returned positions are relative to the trimmed text

## Parity Status Against Searchlight Core

The current `searchlight` core package is **not** a strict parity match for
`@orama/highlight`.

Key differences:

- core exports `Highlighter`, not `Highlight`
- core returns a detached result object, not a stateful class instance
- core uses exclusive end offsets
- core exposes `wholeWords` instead of strategy constants
- core does not expose `HTML`, `HTMLTag`, or `CSSClass`
- core `trim(...)` behavior differs from Orama's stateful trim flow

This is acceptable for the core package because the Orama highlighter is a
separate package. Strict parity work belongs in `searchlight_highlight`.

## Reserved Questions

These stay reserved until explicitly implemented and documented:

- whether `searchlight_highlight` should later expose adapters for Flutter
  `TextSpan`s or range mapping
- whether the core `searchlight` package should later align its built-in
  highlighter API with the strict parity package
