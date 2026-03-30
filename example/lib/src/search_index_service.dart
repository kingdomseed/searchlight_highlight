import 'package:searchlight_highlight_example/src/loaded_validation_source.dart';
import 'package:searchlight_highlight_example/src/search_result_item.dart';

class SearchIndexService {
  const SearchIndexService();

  List<SearchResultItem> browseAll(LoadedValidationSource source) {
    final sorted = [...source.records]
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return sorted
        .map((record) => SearchResultItem(record: record, score: 0))
        .toList(growable: false);
  }

  List<SearchResultItem> search(LoadedValidationSource source, String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return browseAll(source);
    }

    final result = source.db.search(
      term: trimmed,
      properties: const ['type', 'content', 'path'],
      limit: source.records.length,
    );

    return result.hits
        .map((hit) {
          final record = source.recordsById[hit.id]!;
          return SearchResultItem(record: record, score: hit.score);
        })
        .toList(growable: false);
  }
}
