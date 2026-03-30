# Searchlight Highlight Validation App

This Flutter app is the canonical integration example for
`searchlight_highlight`.

It validates two distinct paths:

- standalone highlighting with `Highlight`, `Position`, `HTML`,
  and `trim()`
- parsedoc-backed folder indexing where `searchlight_parsedoc` extracts live
  `.md` and `.html` files into records, `searchlight` indexes them, and
  `searchlight_highlight` renders the matched ranges

The app is intentionally an integration harness, not a reusable UI package.

## Package Boundaries

This example depends on three packages with separate responsibilities:

- `searchlight_highlight`
  computes highlight state, `HTML`, and inclusive `Position` offsets
- `searchlight`
  indexes records and executes queries
- `searchlight_parsedoc`
  parses Markdown and HTML into Searchlight-ready records

This split mirrors the upstream package boundaries:

- standalone highlighting is not a create-time plugin
- parsing lives outside core search
- UI rendering stays in the app

Current example-app constraints:

- the parsedoc integration currently depends on `searchlight_parsedoc` from
  GitHub `main`
- live folder indexing in this app is desktop-only

## Run The App

From `example/`:

```bash
flutter pub get
flutter run -d macos
```

## Verify Standalone Highlight

In `Standalone highlight` mode the default sample is an excerpt from
*Alice's Adventures in Wonderland* with the query `Alice Rabbit`.

Confirm the four output cards:

- **TextSpan preview** — Flutter `RichText` / `TextSpan` rendering from
  inclusive `Position` ranges, with the positions listed below the preview
- **Rendered HTML preview** — the highlight HTML rendered by `flutter_html`
- **Raw HTML string** — the literal HTML markup (should contain
  `<mark class="searchlight-highlight">`) shown in a code-style block
- **Trim(18)** — the trimmed highlight output from `highlight.trim(18)`

Also:

- try the three strategy modes; depending on the current sample/query pair,
  some modes may render the same output
- toggle case sensitivity and verify matching changes

## Verify Parsedoc + Highlight

In `Parsedoc + highlight` mode:

1. Click `Choose Folder`.
2. Pick a folder containing `.md` and/or `.html` files.
3. Confirm the app reports the indexed record count and supported file count.
4. Enter a search term that exists in extracted record `content` or `path`.
5. Confirm:
   - the result list filters down to matching records
   - the result list shows content preview highlighting for matching records
   - the selected record details show highlighted title and highlighted content
   - markdown records show `Rendered with flutter_markdown_plus MarkdownBody.`
   - HTML records show `Shown as raw HTML source text.`

Supported live folder formats in this example:

- `.md`
- `.html`

## Flutter Rendering Note

`searchlight_highlight.Position.end` is inclusive.

When converting positions into `TextSpan` ranges, use `end + 1` for the Dart
substring end offset. The example app demonstrates that pattern in
[`main.dart`](lib/main.dart).

The standalone example app uses `searchlight-highlight` as a custom CSS class
for readability in its raw HTML card. The package default remains
`orama-highlight` unless you override `HighlightOptions.CSSClass`.
