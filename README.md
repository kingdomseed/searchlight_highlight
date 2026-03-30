# Searchlight Highlight

[![Pub Version](https://img.shields.io/pub/v/searchlight_highlight)](https://pub.dev/packages/searchlight_highlight)
[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/kingdomseed/searchlight_highlight)
[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Repository](https://img.shields.io/badge/repository-kingdomseed%2Fsearchlight__highlight-24292f)](https://github.com/kingdomseed/searchlight_highlight)
[![Publisher](https://img.shields.io/badge/publisher-jasonholtdigital.com-2b7cff)](https://pub.dev/publishers/jasonholtdigital.com)

Searchlight Highlight is a pure Dart reimplementation of Orama's standalone
highlight package shape for Searchlight, the independent Dart reimplementation
of Orama's in-memory search and indexing model.

Package links:

- `searchlight` on pub.dev: <https://pub.dev/packages/searchlight>
- `searchlight` on GitHub: <https://github.com/kingdomseed/searchlight>
- `searchlight_highlight` on pub.dev:
  <https://pub.dev/packages/searchlight_highlight>
- `searchlight_highlight` on GitHub:
  <https://github.com/kingdomseed/searchlight_highlight>

It exposes the same core helper surface audited from Orama Highlight:

- `Highlight`
- `highlightStrategy`
- `HighlightOptions`
- `Position`

## Status

`searchlight_highlight` matches the audited Orama Highlight source contract:

- stateful `Highlight` class
- `highlight(text, searchTerm)` returns `this`
- inclusive `Position(start, end)` offsets
- `HTML` getter for rendered highlighted markup
- `trim(trimLength, [ellipsis])` behavior that re-highlights the trimmed text
- `highlightStrategy.WHOLE_WORD_MATCH`
- `highlightStrategy.PARTIAL_MATCH`
- `highlightStrategy.PARTIAL_MATCH_FULL_WORD`

Important package-shape note:

- Orama Highlight is a standalone helper package, not a create-time plugin
- `searchlight_highlight` matches that package shape directly
- it does not require the Searchlight extension system

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

`HighlightOptions` mirrors the audited Orama source:

```dart
final highlighter = Highlight(
  const HighlightOptions(
    caseSensitive: false,
    strategy: 'partialMatch',
    HTMLTag: 'mark',
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

## Relationship To `searchlight`

The core `searchlight` package already includes built-in highlighting helpers
for Searchlight search flows.

`searchlight_highlight` exists for a different purpose:

- strict parity with the audited Orama standalone package API
- HTML-markup output via `HTML`
- Orama-style stateful trimming semantics
- use outside of a Searchlight database when you just need text highlighting

## Example

The repository includes a small console example under [`example/`](example/).

Run it with:

```bash
dart run example/searchlight_highlight_example.dart
```

## Additional Information

This package intentionally keeps the audited Orama package boundary narrow.
Potential follow-up helpers such as Flutter `TextSpan` adapters or richer
snippet builders should only be added after strict parity is complete and
explicitly documented as additive behavior.
