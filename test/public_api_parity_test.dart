import 'package:searchlight_highlight/searchlight_highlight.dart';
import 'package:test/test.dart';

void main() {
  test('exports the Orama parity surface', () {
    final highlighter = Highlight();
    const options = HighlightOptions();
    const position = Position(start: 1, end: 2);

    expect(highlighter, isA<Highlight>());
    expect(options, isA<HighlightOptions>());
    expect(position.start, equals(1));
    expect(position.end, equals(2));
    expect(
      highlightStrategy.WHOLE_WORD_MATCH,
      equals('wholeWordMatch'),
    );
    expect(
      highlightStrategy.PARTIAL_MATCH,
      equals('partialMatch'),
    );
    expect(
      highlightStrategy.PARTIAL_MATCH_FULL_WORD,
      equals('partialMatchFullWord'),
    );
  });
}
