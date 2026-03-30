import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:searchlight/searchlight.dart';
import 'package:searchlight_highlight_example/src/parsedoc_record.dart';
import 'package:searchlight_parsedoc/searchlight_parsedoc.dart';

class ParsedocRecordLoader {
  const ParsedocRecordLoader();

  Future<List<ParsedocRecord>> loadSupportedFile({
    required String filePath,
    required String rootPath,
    required Searchlight db,
  }) async {
    final bytes = await File(filePath).readAsBytes();
    final raw = await File(filePath).readAsString();
    final fileType = _fileTypeFor(filePath);
    final records = await parseFile(
      bytes,
      fileType,
      options: PopulateOptions(basePath: '$filePath/'),
    );
    final ids = await populate(
      db,
      bytes,
      fileType,
      options: PopulateOptions(basePath: '$filePath/'),
    );
    final relativePath = p.posix.normalize(
      p.relative(filePath, from: rootPath).replaceAll(r'\', '/'),
    );

    return [
      for (final (index, record) in records.indexed)
        ParsedocRecord(
          id: ids[index],
          title: _titleFor(
            record['type'] as String? ?? 'node',
            record['content'] as String? ?? '',
            relativePath,
          ),
          content: record['content'] as String? ?? '',
          displayBody: raw.trim(),
          pathLabel: relativePath,
          parsedPath: record['path'] as String? ?? '',
          group: _groupFor(relativePath),
          type: record['type'] as String? ?? _typeFor(relativePath),
          format: fileType == 'md' ? 'markdown' : 'html',
          sourcePath: filePath,
        ),
    ];
  }

  String _titleFor(String type, String content, String relativePath) {
    final normalizedContent = content.trim();
    if (type == 'h1' && normalizedContent.isNotEmpty) {
      return normalizedContent;
    }

    if (normalizedContent.isNotEmpty) {
      return normalizedContent.length <= 48
          ? normalizedContent
          : '${normalizedContent.substring(0, 45)}...';
    }

    return '${type.toUpperCase()} ${p.basenameWithoutExtension(relativePath)}';
  }

  String _groupFor(String relativePath) {
    final segments = p.posix.split(relativePath);
    return segments.isEmpty ? 'root' : segments.first;
  }

  String _typeFor(String relativePath) {
    final normalized = relativePath.toLowerCase();
    if (normalized.contains('/spells') || normalized.startsWith('spells/')) {
      return 'spell';
    }
    if (normalized.contains('/creatures') || normalized.contains('/monsters')) {
      return 'monster';
    }
    if (normalized.contains('/rules') || normalized.contains('/system/')) {
      return 'rule';
    }
    return 'reference';
  }

  String _fileTypeFor(String filePath) {
    final extension = p.extension(filePath).toLowerCase();
    return switch (extension) {
      '.md' => 'md',
      '.html' => 'html',
      _ => throw UnsupportedParsedocFileTypeError(filePath),
    };
  }
}
