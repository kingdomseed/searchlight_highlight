import 'package:searchlight_highlight_example/src/folder_source_loader.dart';

FolderSourceLoader createFolderSourceLoader() => _StubFolderSourceLoader();

final class _StubFolderSourceLoader implements FolderSourceLoader {
  @override
  Future<FolderLoadResult> load(String rootPath) {
    throw UnsupportedError(
      'Folder indexing is not supported on this platform.',
    );
  }
}
