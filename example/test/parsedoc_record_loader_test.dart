import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:searchlight/searchlight.dart';
import 'package:searchlight_highlight_example/src/parsedoc_record_loader.dart';
import 'package:searchlight_parsedoc/searchlight_parsedoc.dart';

void main() {
  group('ParsedocRecordLoader', () {
    late Directory tempDir;
    late Searchlight db;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp(
        'searchlight_highlight_loader_test_',
      );
      db = Searchlight.create(
        schema: Schema({
          for (final entry in defaultHtmlSchema.entries)
            entry.key: TypedField(switch (entry.value) {
              'string' => SchemaType.string,
              _ => throw ArgumentError.value(
                entry.value,
                'entry.value',
                'Unsupported schema type in defaultHtmlSchema.',
              ),
            }),
        }),
      );
    });

    tearDown(() async {
      await db.dispose();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test(
      'loads markdown files through parsedoc and populates searchlight',
      () async {
        final file = File(p.join(tempDir.path, 'spells', 'ember-lance.md'))
          ..createSync(recursive: true)
          ..writeAsStringSync('# Ember Lance\n\nA focused lance of heat.');

        final records = await const ParsedocRecordLoader().loadSupportedFile(
          filePath: file.path,
          rootPath: tempDir.path,
          db: db,
        );

        expect(records, isNotEmpty);
        expect(records.first.format, 'markdown');
        expect(records.first.pathLabel, 'spells/ember-lance.md');
        expect(records.first.title, 'Ember Lance');

        final result = db.search(term: 'ember', properties: const ['content']);
        expect(result.count, greaterThan(0));
      },
    );

    test(
      'loads html files through parsedoc and preserves raw source preview',
      () async {
        final file = File(p.join(tempDir.path, 'spells', 'ember-bolt.html'))
          ..createSync(recursive: true)
          ..writeAsStringSync('<h1>Ember Bolt</h1><p>Arc flash.</p>');

        final records = await const ParsedocRecordLoader().loadSupportedFile(
          filePath: file.path,
          rootPath: tempDir.path,
          db: db,
        );

        expect(records, isNotEmpty);
        expect(records.first.format, 'html');
        expect(records.first.pathLabel, 'spells/ember-bolt.html');
        expect(
          records.first.displayBody,
          '<h1>Ember Bolt</h1><p>Arc flash.</p>',
        );

        final result = db.search(term: 'bolt', properties: const ['content']);
        expect(result.count, greaterThan(0));
      },
    );
  });
}
