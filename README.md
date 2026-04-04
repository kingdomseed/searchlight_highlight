# Searchlight Highlight

[![Pub Version](https://img.shields.io/pub/v/searchlight_highlight)](https://pub.dev/packages/searchlight_highlight)
[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/kingdomseed/searchlight_highlight)
[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Repository](https://img.shields.io/badge/repository-kingdomseed%2Fsearchlight__highlight-24292f)](https://github.com/kingdomseed/searchlight_highlight)
[![Publisher](https://img.shields.io/badge/publisher-jasonholtdigital.com-2b7cff)](https://pub.dev/publishers/jasonholtdigital.com)

Searchlight Highlight is a pure Dart highlighting package for the Searchlight
ecosystem.

Companion core package:

- [`searchlight`](https://pub.dev/packages/searchlight) provides indexing,
  querying, and persistence for the content you highlight here.

It exposes this focused helper surface:

- `Highlight`
- `highlightStrategy`
- `HighlightOptions`
- `HighlightStrategy`
- `Position`

## Status

`searchlight_highlight` currently provides:

- stateful `Highlight` class
- `highlight(text, searchTerm)` returns `this`
- inclusive `Position(start, end)` offsets
- `HTML` getter for rendered highlighted markup
- `trim(trimLength, [ellipsis])` behavior that re-highlights the trimmed text
- `highlightStrategy.WHOLE_WORD_MATCH`
- `highlightStrategy.PARTIAL_MATCH`
- `highlightStrategy.PARTIAL_MATCH_FULL_WORD`

Important package-shape note:

- `searchlight_highlight` is a standalone helper package, not a create-time
  plugin
- it does not require the Searchlight extension system
- it is the canonical highlight package for the Searchlight ecosystem

## Platform Support

`searchlight_highlight` is a pure Dart package:

- no Flutter dependency
- no `dart:io` requirement
- works anywhere plain Dart strings work, including Flutter apps

## Installation

```bash
dart pub add searchlight_highlight

# or from a Flutter app
flutter pub add searchlight_highlight
```

## Quick Start

```dart
import 'package:searchlight_highlight/searchlight_highlight.dart';

void main() {
  final highlighted = Highlight().highlight(
    'The quick brown fox jumps over the lazy dog',
    'brown fox',
  );

  print(highlighted.positions);
  print(highlighted.HTML);
  // trim() re-highlights the trimmed excerpt on the same stateful instance.
  print(highlighted.trim(18));
}
```

Output:

```text
[Position(start: 10, end: 14), Position(start: 16, end: 18)]
The quick <mark class="orama-highlight">brown</mark> <mark class="orama-highlight">fox</mark> jumps over the lazy dog
...he quick <mark class="orama-highlight">brown</mark> <mark class="orama-highlight">fox</mark>...
```

## Configuration

`HighlightOptions` supports:

```dart
final highlighter = Highlight(
  const HighlightOptions(
    caseSensitive: false,
    strategy: 'partialMatch',
    HTMLTag: 'mark',
    // This is the package default.
    CSSClass: 'orama-highlight',
  ),
);
```

The supported strategy constants are:

- `highlightStrategy.WHOLE_WORD_MATCH`
- `highlightStrategy.PARTIAL_MATCH`
- `highlightStrategy.PARTIAL_MATCH_FULL_WORD`

Example with a full-word partial strategy:

```dart
import 'package:searchlight_highlight/searchlight_highlight.dart';

void main() {
  final highlighted = Highlight(
    HighlightOptions(
      strategy: highlightStrategy.PARTIAL_MATCH_FULL_WORD,
    ),
  ).highlight(
    'The quick brown fox jumps over the lazy dog',
    'fo umps ve',
  );

  print(highlighted.HTML);
}
```

## Relationship To Searchlight Packages

Choose dependencies based on the job:

- only text highlighting: install `searchlight_highlight`
- Searchlight search plus post-search excerpts/highlights: install
  `searchlight` and `searchlight_highlight`
- Markdown or HTML extraction plus Searchlight search plus highlights: install
  `searchlight_parsedoc`, `searchlight`, and `searchlight_highlight`

`searchlight_highlight` owns:

- a narrow standalone highlight helper contract
- inclusive `Position` offsets
- HTML-markup output via `HTML`
- stateful trimming semantics

`searchlight` owns:

- index creation
- document storage
- query execution
- persistence

`searchlight_parsedoc` owns:

- Markdown and HTML extraction into Searchlight-ready records
- folder-based document ingestion helpers for supported VM targets

This package does not own:

- index creation
- document parsing
- Flutter widgets

Flutter apps typically use `Position` ranges to build `TextSpan` trees or
highlighted preview widgets.

`HTML` safety note:

- `HTML` is a convenience string built from the original source text plus the
  configured wrapper tag
- it does not escape or sanitize the underlying text for you
- if you render that output in an HTML context, sanitize according to your app
  requirements

Important offset rule:

- `Position.end` is inclusive
- Flutter substring logic should therefore use `end + 1`

## Flutter Rendering Pattern

`searchlight_highlight` stays pure Dart, but Flutter rendering is
straightforward because the package returns plain strings plus `Position`
ranges.

For highlighted inline text, build `TextSpan` ranges from `positions`:

```dart
import 'package:flutter/material.dart';
import 'package:searchlight_highlight/searchlight_highlight.dart';

List<InlineSpan> buildHighlightSpans(
  BuildContext context,
  String text,
  List<Position> positions,
) {
  if (positions.isEmpty) {
    return [TextSpan(text: text)];
  }

  final spans = <InlineSpan>[];
  var cursor = 0;

  for (final position in positions) {
    final start = position.start;
    final endExclusive = position.end + 1;

    if (start > cursor) {
      spans.add(TextSpan(text: text.substring(cursor, start)));
    }

    spans.add(
      TextSpan(
        text: text.substring(start, endExclusive),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
    cursor = endExclusive;
  }

  if (cursor < text.length) {
    spans.add(TextSpan(text: text.substring(cursor)));
  }

  return spans;
}
```

For body/source rendering, keep responsibilities separate:

- use `searchlight_highlight` for the match positions or HTML output
- use `flutter_markdown_plus` when you want rendered Markdown source bodies

```dart
MarkdownBody(data: record.displayBody);
```

The Flutter validation app under [`example/`](example/) shows both patterns in
one place.

## Example

The repository includes:

- a console sample under [`example/searchlight_highlight_example.dart`](example/searchlight_highlight_example.dart)
- a Flutter validation app under [`example/`](example/)

The Flutter app proves two paths:

- standalone `searchlight_highlight` usage
- `searchlight_parsedoc` + `searchlight` + `searchlight_highlight` working
  together over live `.md` and `.html` folders

Current example-app constraints:

- the live folder-ingestion flow is desktop-only in the current app
- the example app overrides the HTML class to `searchlight-highlight`; the
  package default remains `orama-highlight`

Run it with:

```bash
dart run example/searchlight_highlight_example.dart
```

For the Flutter app:

```bash
cd example
flutter pub get
flutter run -d macos
```

Inside the app:

- use `Standalone highlight` to inspect `positions`, `HTML`, and `trim()`
- use `Parsedoc + highlight` to choose a local folder and verify parsed
  Markdown or HTML records are searchable and highlight correctly

## Additional Information

This package intentionally keeps the helper boundary narrow.
Potential follow-up helpers such as Flutter `TextSpan` adapters or richer
snippet builders should only be added after the current helper contract is
stable and explicitly documented as additive behavior.

## License And Attribution

Searchlight Highlight is an independent pure Dart package for the Searchlight
ecosystem. It credits Orama Highlight for inspiration and package-shape audit
work, but it is not affiliated with or endorsed by the Orama project.
