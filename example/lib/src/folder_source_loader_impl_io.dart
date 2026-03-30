import 'dart:io';

import 'package:searchlight/searchlight.dart';
import 'package:searchlight_highlight_example/src/folder_source_loader.dart';
import 'package:searchlight_highlight_example/src/parsedoc_record_loader.dart';
import 'package:searchlight_highlight_example/src/validation_issue.dart';
import 'package:searchlight_parsedoc/searchlight_parsedoc.dart';

FolderSourceLoader createFolderSourceLoader() => _IoFolderSourceLoader();

final class _IoFolderSourceLoader implements FolderSourceLoader {
  _IoFolderSourceLoader() : _loader = const ParsedocRecordLoader();

  final ParsedocRecordLoader _loader;

  @override
  Future<FolderLoadResult> load(String rootPath) async {
    final root = Directory(rootPath);
    if (!root.existsSync()) {
      throw FileSystemException('Selected folder does not exist.', rootPath);
    }

    final supportedFiles = <File>[];
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is! File) {
        continue;
      }

      final normalized = entity.path.toLowerCase();
      if (normalized.endsWith('.md') || normalized.endsWith('.html')) {
        supportedFiles.add(entity);
      }
    }
    supportedFiles.sort((a, b) => a.path.compareTo(b.path));

    final db = Searchlight.create(
      schema: Schema({
        for (final entry in defaultHtmlSchema.entries)
          entry.key: TypedField(
            switch (entry.value) {
              'string' => SchemaType.string,
              _ => throw ArgumentError.value(
                  entry.value,
                  'entry.value',
                  'Unsupported schema type in defaultHtmlSchema.',
                ),
            },
          ),
      }),
    );

    final issues = <ValidationIssue>[];
    final records = <dynamic>[];

    for (final file in supportedFiles) {
      try {
        final fileRecords = await _loader.loadSupportedFile(
          filePath: file.path,
          rootPath: root.path,
          db: db,
        );
        records.addAll(fileRecords);
      } on Object catch (error) {
        issues.add(ValidationIssue(path: file.path, message: error.toString()));
      }
    }

    return FolderLoadResult(
      db: db,
      rootPath: root.path,
      discoveredSupportedFiles: supportedFiles.length,
      records: List.unmodifiable(records.cast()),
      issues: issues,
    );
  }
}
