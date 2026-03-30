import 'package:searchlight_highlight/searchlight_highlight.dart';
import 'package:test/test.dart';

void main() {
  group('default configuration', () {
    test('highlight returns the same stateful instance', () {
      final highlighter = Highlight();
      final returned = highlighter.highlight('The quick brown fox', 'fox');

      expect(identical(returned, highlighter), isTrue);
    });

    test('highlights partial matches into HTML', () {
      const text = 'The quick brown fox jumps over the lazy dog';
      const searchTerm = 'fox';
      const expected =
          'The quick brown <mark class="orama-highlight">fox</mark> jumps '
          'over the lazy dog';

      final highlighter = Highlight();

      expect(highlighter.highlight(text, searchTerm).HTML, equals(expected));
    });

    test('returns inclusive positions', () {
      const text = 'The quick brown fox jumps over the lazy dog';
      const searchTerm = 'fox';

      final highlighter = Highlight();

      expect(
        highlighter.highlight(text, searchTerm).positions,
        equals(const <Position>[Position(start: 16, end: 18)]),
      );
    });

    test('returns multiple positions', () {
      const text = 'The quick brown fox jumps over the lazy dog';
      const searchTerm = 'the';

      final highlighter = Highlight();

      expect(
        highlighter.highlight(text, searchTerm).positions,
        equals(const <Position>[
          Position(start: 0, end: 2),
          Position(start: 31, end: 33),
        ]),
      );
    });
  });

  group('custom configuration', () {
    test('supports case sensitive matching', () {
      const text = 'The quick brown fox jumps over the lazy dog';
      const searchTerm = 'Fox';

      final highlighter = Highlight(
        const HighlightOptions(caseSensitive: true),
      );

      expect(highlighter.highlight(text, searchTerm).HTML, equals(text));
    });

    test('supports custom CSS class', () {
      const text = 'The quick brown fox jumps over the lazy dog';
      const searchTerm = 'fox';
      const expected =
          'The quick brown <mark class="custom-class">fox</mark> jumps over '
          'the lazy dog';

      final highlighter = Highlight(
        const HighlightOptions(CSSClass: 'custom-class'),
      );

      expect(highlighter.highlight(text, searchTerm).HTML, equals(expected));
    });

    test('supports custom HTML tag', () {
      const text = 'The quick brown fox jumps over the lazy dog';
      const searchTerm = 'fox';
      const expected =
          'The quick brown <div class="orama-highlight">fox</div> jumps over '
          'the lazy dog';

      final highlighter = Highlight(const HighlightOptions(HTMLTag: 'div'));

      expect(highlighter.highlight(text, searchTerm).HTML, equals(expected));
    });

    test('supports whole word strategy', () {
      const text = 'The quick brown fox jumps over the lazy dog';
      const searchTerm = 'fox jump';
      const expected =
          'The quick brown <mark class="orama-highlight">fox</mark> jumps '
          'over the lazy dog';

      final highlighter = Highlight(
        HighlightOptions(strategy: highlightStrategy.WHOLE_WORD_MATCH),
      );

      expect(highlighter.highlight(text, searchTerm).HTML, equals(expected));
    });

    test('supports partial match full word strategy', () {
      const text = 'The quick brown fox jumps over the lazy dog';
      const searchTerm = 'fo umps ve';
      const expected =
          'The quick brown <mark class="orama-highlight">fox</mark> '
          '<mark class="orama-highlight">jumps</mark> '
          '<mark class="orama-highlight">over</mark> the lazy dog';

      final highlighter = Highlight(
        HighlightOptions(strategy: highlightStrategy.PARTIAL_MATCH_FULL_WORD),
      );

      expect(highlighter.highlight(text, searchTerm).HTML, equals(expected));
    });

    test('returns original text on empty search term', () {
      const text = 'The quick brown fox jumps over the lazy dog';

      final highlighter = Highlight(
        HighlightOptions(strategy: highlightStrategy.PARTIAL_MATCH_FULL_WORD),
      );

      expect(highlighter.highlight(text, '').HTML, equals(text));
    });
  });

  group('trim', () {
    test('trims around the first match using Orama semantics', () {
      const text = 'The quick brown fox jumps over the lazy dog';
      final highlighter = Highlight();

      expect(
        highlighter.highlight(text, 'fox').trim(10),
        equals('...rown <mark class="orama-highlight">fox</mark> j...'),
      );
      expect(
        highlighter.highlight(text, 'fox').trim(5),
        equals('...n <mark class="orama-highlight">fox</mark>...'),
      );
      expect(
        highlighter.highlight(text, 'the').trim(5),
        equals('<mark class="orama-highlight">The</mark> q...'),
      );
      expect(
        highlighter.highlight(text, 'dog').trim(5),
        equals('...y <mark class="orama-highlight">dog</mark>'),
      );
      expect(
        highlighter.highlight(text, 'dog').trim(5, false),
        equals('y <mark class="orama-highlight">dog</mark>'),
      );
      expect(
        highlighter.highlight(text, 'the').trim(5, false),
        equals('<mark class="orama-highlight">The</mark> q'),
      );

      expect(
        highlighter.positions,
        equals(const <Position>[Position(start: 0, end: 2)]),
      );
    });

    test('trims no-match content from the current HTML', () {
      const text = 'The quick brown dog jumps over the lazy dog in a forrest';
      final highlighter = Highlight();

      expect(
        highlighter.highlight(text, 'fox').trim(10),
        equals('The quick ...'),
      );
      expect(
        highlighter.highlight(text, 'fox').trim(10, false),
        equals('The quick '),
      );
    });
  });

  group('special cases', () {
    test('escapes regex characters in the search term', () {
      const text = 'C++ is a hell of a language';
      const expected =
          '<mark class="orama-highlight">C++</mark> is a hell of a language';

      final highlighter = Highlight();

      expect(highlighter.highlight(text, 'C++').HTML, equals(expected));
    });

    test('tolerates null text', () {
      final highlighter = Highlight();

      expect(highlighter.highlight(null, 'C').HTML, equals(''));
    });

    test('tolerates null text and null search term', () {
      final highlighter = Highlight();

      expect(highlighter.highlight(null, null).HTML, equals(''));
    });
  });
}
