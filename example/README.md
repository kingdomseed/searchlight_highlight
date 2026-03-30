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

This split mirrors Orama's package boundaries:

- standalone highlighting is not a create-time plugin
- parsing lives outside core search
- UI rendering stays in the app

## Run The App

From `example/`:

```bash
flutter pub get
flutter run -d macos
```

## Verify Standalone Highlight

In `Standalone highlight` mode:

- confirm the default sample text highlights `brown` and `fox`
- confirm the position output is `[10-14, 16-18]`
- confirm the HTML output contains `<mark class="searchlight-highlight">`
- confirm the `TextSpan preview` card is the Flutter `RichText` / `TextSpan`
  rendering path driven by `Position` ranges
- confirm the HTML output is shown as literal markup inside a code-style block
- switch between the three strategy modes and verify the preview changes
- toggle case sensitivity and verify matching changes

## Verify Parsedoc + Highlight

In `Parsedoc + highlight` mode:

1. Click `Choose Folder`.
2. Pick a folder containing `.md` and/or `.html` files.
3. Confirm the app reports the indexed record count and supported file count.
4. Enter a search term that exists in one of the parsed records.
5. Confirm:
   - the result list filters down to matching records
   - title and content previews highlight the matched ranges
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
