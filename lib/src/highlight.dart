class _HighlightStrategyValues {
  const _HighlightStrategyValues();

  // ignore: non_constant_identifier_names
  String get WHOLE_WORD_MATCH => 'wholeWordMatch';

  // ignore: non_constant_identifier_names
  String get PARTIAL_MATCH => 'partialMatch';

  // ignore: non_constant_identifier_names
  String get PARTIAL_MATCH_FULL_WORD => 'partialMatchFullWord';
}

const highlightStrategy = _HighlightStrategyValues();

typedef HighlightStrategy = String;

class HighlightOptions {
  const HighlightOptions({
    this.caseSensitive = false,
    this.strategy = 'partialMatch',
    // ignore: non_constant_identifier_names
    this.HTMLTag = 'mark',
    // ignore: non_constant_identifier_names
    this.CSSClass = 'orama-highlight',
  });

  final bool caseSensitive;
  final HighlightStrategy strategy;

  // ignore: non_constant_identifier_names
  final String HTMLTag;

  // ignore: non_constant_identifier_names
  final String CSSClass;
}

class Position {
  const Position({
    required this.start,
    required this.end,
  });

  final int start;
  final int end;
}

class Highlight {
  Highlight([HighlightOptions options = const HighlightOptions()])
    : _options = options;

  final HighlightOptions _options;
  final List<Position> _positions = <Position>[];
  String _html = '';

  Highlight highlight(String? text, String? searchTerm) {
    throw UnimplementedError();
  }

  String trim(int trimLength, [bool ellipsis = true]) {
    throw UnimplementedError();
  }

  List<Position> get positions => List<Position>.unmodifiable(_positions);

  // ignore: non_constant_identifier_names
  String get HTML => _html;

  HighlightOptions get options => _options;
}
