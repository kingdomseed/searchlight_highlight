import 'package:searchlight/searchlight.dart';
import 'package:searchlight_highlight_example/src/parsedoc_record.dart';
import 'package:searchlight_highlight_example/src/validation_issue.dart';

import 'folder_source_loader_impl_stub.dart'
    if (dart.library.io) 'folder_source_loader_impl_io.dart'
    as impl;

final class FolderLoadResult {
  const FolderLoadResult({
    required this.db,
    required this.rootPath,
    required this.discoveredSupportedFiles,
    required this.records,
    required this.issues,
  });

  final Searchlight db;
  final String rootPath;
  final int discoveredSupportedFiles;
  final List<ParsedocRecord> records;
  final List<ValidationIssue> issues;
}

abstract class FolderSourceLoader {
  Future<FolderLoadResult> load(String rootPath);
}

FolderSourceLoader createFolderSourceLoader() {
  return impl.createFolderSourceLoader();
}
