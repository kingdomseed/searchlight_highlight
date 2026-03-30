// ignore_for_file: non_constant_identifier_names

import 'dart:math' as math;

final class _HighlightStrategyValues {
  const _HighlightStrategyValues();

  String get WHOLE_WORD_MATCH => 'wholeWordMatch';

  String get PARTIAL_MATCH => 'partialMatch';

  String get PARTIAL_MATCH_FULL_WORD => 'partialMatchFullWord';
}

const highlightStrategy = _HighlightStrategyValues();

typedef HighlightStrategy = String;

final class HighlightOptions {
  const HighlightOptions({
    this.caseSensitive = false,
    this.strategy = 'partialMatch',
    this.HTMLTag = 'mark',
    this.CSSClass = 'orama-highlight',
  });

  final bool caseSensitive;
  final HighlightStrategy strategy;

  final String HTMLTag;

  final String CSSClass;
}

final class Position {
  const Position({required this.start, required this.end});

  final int start;
  final int end;

  @override
  bool operator ==(Object other) {
    return other is Position && other.start == start && other.end == end;
  }

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'Position(start: $start, end: $end)';
}

final class Highlight {
  Highlight([HighlightOptions options = const HighlightOptions()])
    : _options = options;

  final HighlightOptions _options;
  List<Position> _positions = <Position>[];
  String _html = '';
  String _searchTerm = '';
  String _originalText = '';

  Highlight highlight(String? text, String? searchTerm) {
    _searchTerm = searchTerm ?? '';
    _originalText = text ?? '';

    if (_searchTerm.isEmpty || _originalText.isEmpty) {
      _positions = const <Position>[];
      _html = _originalText;
      return this;
    }

    final normalizedSearchTerms = _escapeRegExp(
      _options.caseSensitive ? _searchTerm : _searchTerm.toLowerCase(),
    ).trim().split(RegExp(r'\s+')).join('|');

    if (normalizedSearchTerms.isEmpty) {
      _positions = const <Position>[];
      _html = _originalText;
      return this;
    }

    final regex = _buildRegex(normalizedSearchTerms);
    final positions = <Position>[];
    final highlightedParts = <String>[];

    var lastEnd = 0;
    for (final match in regex.allMatches(_originalText)) {
      final start = match.start;
      final end = match.end - 1;

      positions.add(Position(start: start, end: end));
      highlightedParts.add(_originalText.substring(lastEnd, start));
      highlightedParts.add(
        '<${_options.HTMLTag} class="${_options.CSSClass}">'
        '${match[0]}'
        '</${_options.HTMLTag}>',
      );
      lastEnd = end + 1;
    }

    highlightedParts.add(_originalText.substring(lastEnd));

    _positions = positions;
    _html = highlightedParts.join();
    return this;
  }

  String trim(int trimLength, [bool ellipsis = true]) {
    if (_positions.isEmpty) {
      final end = math.min(trimLength, _html.length);
      return '${_html.substring(0, end)}${ellipsis ? '...' : ''}';
    }

    if (_originalText.length <= trimLength) {
      return _html;
    }

    final firstMatch = _positions.first.start;
    final start = math.max(firstMatch - (trimLength ~/ 2), 0);
    final end = math.min(start + trimLength, _originalText.length);
    final trimmedContent =
        '${start == 0 || !ellipsis ? '' : '...'}'
        '${_originalText.substring(start, end)}'
        '${end < _originalText.length && ellipsis ? '...' : ''}';

    highlight(trimmedContent, _searchTerm);
    return _html;
  }

  List<Position> get positions => _positions;

  String get HTML => _html;

  RegExp _buildRegex(String searchTerms) {
    final strategy = _options.strategy;
    if (strategy == highlightStrategy.WHOLE_WORD_MATCH) {
      return RegExp(
        '\\b$searchTerms\\b',
        caseSensitive: _options.caseSensitive,
      );
    }
    if (strategy == highlightStrategy.PARTIAL_MATCH) {
      return RegExp(searchTerms, caseSensitive: _options.caseSensitive);
    }
    if (strategy == highlightStrategy.PARTIAL_MATCH_FULL_WORD) {
      return RegExp(
        '\\b[^\\s]*($searchTerms)[^\\s]*\\b',
        caseSensitive: _options.caseSensitive,
      );
    }
    throw StateError('Invalid highlighter strategy');
  }

  String _escapeRegExp(String string) {
    return string.replaceAllMapped(
      RegExp(r'[.*+?^${}()|[\]\\]'),
      (match) => '\\${match[0]}',
    );
  }
}
