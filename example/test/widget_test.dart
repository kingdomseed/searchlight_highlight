import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:searchlight/searchlight.dart';
import 'package:searchlight_highlight_example/main.dart';
import 'package:searchlight_highlight_example/src/folder_source_loader.dart';
import 'package:searchlight_highlight_example/src/parsedoc_record.dart';
import 'package:searchlight_highlight_example/src/validation_issue.dart';

void main() {
  testWidgets('standalone mode renders all four highlight output sections', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 3000));
    await tester.pumpWidget(
      HighlightValidationApp(
        supportsDesktopFolderSource: true,
        pickDirectory: () async => null,
        folderSourceLoader: _FakeFolderSourceLoader([]),
      ),
    );

    expect(find.text('TextSpan preview'), findsOneWidget);
    expect(find.text('Rendered HTML preview'), findsOneWidget);
    expect(find.text('Raw HTML string'), findsOneWidget);
    expect(find.text('Trim(18)'), findsOneWidget);
    expect(
      find.textContaining('<mark class="searchlight-highlight">'),
      findsWidgets,
    );
  });

  testWidgets(
    'standalone mode wires the case-sensitive toggle into Highlight',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 3000));
      await tester.pumpWidget(
        HighlightValidationApp(
          supportsDesktopFolderSource: true,
          pickDirectory: () async => null,
          folderSourceLoader: _FakeFolderSourceLoader([]),
        ),
      );

      await tester.enterText(
        find.byKey(const ValueKey('standalone-query')),
        'ALICE',
      );
      await tester.pumpAndSettle();

      // Case-insensitive (default): "ALICE" matches "Alice" at position 0.
      expect(find.textContaining('Positions: [0-4'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('case-sensitive-toggle')));
      await tester.pumpAndSettle();

      // Case-sensitive: "ALICE" does not match "Alice".
      expect(find.textContaining('Positions: []'), findsOneWidget);
    },
  );

  testWidgets('parsedoc mode loads records and shows highlighted output', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 1000));
    await tester.pumpWidget(
      HighlightValidationApp(
        supportsDesktopFolderSource: true,
        pickDirectory: () async => '/fixtures',
        folderSourceLoader: _FakeFolderSourceLoader([
          _parsedocRecord(
            id: 'ember-md',
            title: 'Ember Lance',
            content: 'Ember Lance',
            displayBody: '# Ember Lance\n\nA focused lance of heat.',
            pathLabel: 'spells/ember-lance.md',
            parsedPath: 'root[0].h1[0]',
            type: 'h1',
            format: 'markdown',
            sourcePath: '/fixtures/spells/ember-lance.md',
          ),
        ]),
      ),
    );

    await tester.tap(find.text('Parsedoc + highlight'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('choose-folder')));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Indexed 1 extracted records from 1 supported files'),
      findsOneWidget,
    );
    expect(find.text('Ember Lance'), findsWidgets);

    await tester.enterText(
      find.byKey(const ValueKey('parsedoc-query')),
      'ember',
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('<mark class="searchlight-highlight">Ember</mark>'),
      findsWidgets,
    );
  });

  testWidgets('parsedoc mode shows raw HTML source previews for html records', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 1000));
    await tester.pumpWidget(
      HighlightValidationApp(
        supportsDesktopFolderSource: true,
        pickDirectory: () async => '/fixtures',
        folderSourceLoader: _FakeFolderSourceLoader([
          _parsedocRecord(
            id: 'ember-html',
            title: 'Ember Bolt',
            content: 'Ember Bolt',
            displayBody: '<h1>Ember Bolt</h1><p>Arc flash.</p>',
            pathLabel: 'spells/ember-bolt.html',
            parsedPath: 'root[0].h1[0]',
            type: 'h1',
            format: 'html',
            sourcePath: '/fixtures/spells/ember-bolt.html',
          ),
        ]),
      ),
    );

    await tester.tap(find.text('Parsedoc + highlight'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('choose-folder')));
    await tester.pumpAndSettle();

    expect(find.text('Format: html'), findsOneWidget);
    expect(
      find.textContaining('Shown as raw HTML source text.'),
      findsOneWidget,
    );
    expect(find.text('<h1>Ember Bolt</h1><p>Arc flash.</p>'), findsOneWidget);
  });
}

final class _FakeFolderSourceLoader implements FolderSourceLoader {
  _FakeFolderSourceLoader(this.records);

  final List<ParsedocRecord> records;

  @override
  Future<FolderLoadResult> load(String rootPath) async {
    final db = Searchlight.create(
      schema: Schema({
        'type': const TypedField(SchemaType.string),
        'content': const TypedField(SchemaType.string),
        'path': const TypedField(SchemaType.string),
      }),
    );

    final hydratedRecords = <ParsedocRecord>[];
    for (final record in records) {
      final id = db.insert({
        'type': record.type,
        'content': record.content,
        'path': record.pathLabel,
      });
      hydratedRecords.add(
        ParsedocRecord(
          id: id,
          title: record.title,
          content: record.content,
          displayBody: record.displayBody,
          pathLabel: record.pathLabel,
          parsedPath: record.parsedPath,
          group: record.group,
          type: record.type,
          format: record.format,
          sourcePath: record.sourcePath,
        ),
      );
    }

    return FolderLoadResult(
      db: db,
      rootPath: rootPath,
      discoveredSupportedFiles: hydratedRecords.length,
      records: hydratedRecords,
      issues: const <ValidationIssue>[],
    );
  }
}

ParsedocRecord _parsedocRecord({
  required String id,
  required String title,
  required String content,
  required String displayBody,
  required String pathLabel,
  required String parsedPath,
  required String type,
  required String format,
  required String sourcePath,
}) {
  return ParsedocRecord(
    id: id,
    title: title,
    content: content,
    displayBody: displayBody,
    pathLabel: pathLabel,
    parsedPath: parsedPath,
    group: 'spells',
    type: type,
    format: format,
    sourcePath: sourcePath,
  );
}
