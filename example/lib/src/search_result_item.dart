import 'package:searchlight_highlight_example/src/parsedoc_record.dart';

final class SearchResultItem {
  const SearchResultItem({
    required this.record,
    required this.score,
  });

  final ParsedocRecord record;
  final double score;
}
