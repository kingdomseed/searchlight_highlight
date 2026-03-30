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
