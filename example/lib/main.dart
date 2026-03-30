import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:searchlight_highlight/searchlight_highlight.dart';
import 'package:searchlight_highlight_example/src/folder_source_loader.dart';
import 'package:searchlight_highlight_example/src/loaded_validation_source.dart';
import 'package:searchlight_highlight_example/src/parsedoc_record.dart';
import 'package:searchlight_highlight_example/src/search_index_service.dart';
import 'package:searchlight_highlight_example/src/search_result_item.dart';

void main() {
  runApp(const HighlightValidationApp());
}

enum ValidationMode { standalone, parsedoc }

class HighlightValidationApp extends StatelessWidget {
  const HighlightValidationApp({
    super.key,
    this.folderSourceLoader,
    this.supportsDesktopFolderSource,
    this.pickDirectory,
  });

  final FolderSourceLoader? folderSourceLoader;
  final bool? supportsDesktopFolderSource;
  final Future<String?> Function()? pickDirectory;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0E6B52)),
        useMaterial3: true,
      ),
      home: HighlightValidationScreen(
        folderSourceLoader: folderSourceLoader ?? createFolderSourceLoader(),
        supportsDesktopFolderSource:
            supportsDesktopFolderSource ??
            _defaultSupportsDesktopFolderSource(),
        pickDirectory: pickDirectory ?? getDirectoryPath,
      ),
    );
  }

  bool _defaultSupportsDesktopFolderSource() {
    if (kIsWeb) {
      return false;
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.macOS ||
      TargetPlatform.windows ||
      TargetPlatform.linux => true,
      _ => false,
    };
  }
}

class HighlightValidationScreen extends StatefulWidget {
  const HighlightValidationScreen({
    required this.folderSourceLoader,
    required this.supportsDesktopFolderSource,
    required this.pickDirectory,
    super.key,
  });

  final FolderSourceLoader folderSourceLoader;
  final bool supportsDesktopFolderSource;
  final Future<String?> Function() pickDirectory;

  @override
  State<HighlightValidationScreen> createState() =>
      _HighlightValidationScreenState();
}

class _HighlightValidationScreenState extends State<HighlightValidationScreen> {
  static const _standaloneSeedText =
      'Alice was beginning to get very tired of sitting by her sister on '
      'the bank, and of having nothing to do: once or twice she had '
      'peeped into the book her sister was reading, but it had no '
      'pictures or conversations in it, "and what is the use of a book," '
      'thought Alice "without pictures or conversations?"\n\n'
      'So she was considering in her own mind (as well as she could, for '
      'the hot day made her feel very sleepy and stupid), whether the '
      'pleasure of making a daisy-chain would be worth the trouble of '
      'getting up and picking the daisies, when suddenly a White Rabbit '
      'with pink eyes ran close by her.\n\n'
      'There was nothing so very remarkable in that; nor did Alice think '
      'it so very much out of the way to hear the Rabbit say to itself, '
      '"Oh dear! Oh dear! I shall be late!" (when she thought it over '
      'afterwards, it occurred to her that she ought to have wondered at '
      'this, but at the time it all seemed quite natural); but when the '
      'Rabbit actually took a watch out of its waistcoat-pocket, and '
      'looked at it, and then hurried on, Alice started to her feet, for '
      'it flashed across her mind that she had never before seen a rabbit '
      'with either a waistcoat-pocket, or a watch to take out of it, and '
      'burning with curiosity, she ran across the field after it, and '
      'fortunately was just in time to see it pop down a large '
      'rabbit-hole under the hedge.\n\n'
      'In another moment down went Alice after it, never once considering '
      'how in the world she was to get out again.';
  static const _standaloneSeedQuery = 'Alice Rabbit';
  static const _exampleHighlightCssClass = 'searchlight-highlight';

  final TextEditingController _standaloneTextController = TextEditingController(
    text: _standaloneSeedText,
  );
  final TextEditingController _standaloneQueryController =
      TextEditingController(text: _standaloneSeedQuery);
  final TextEditingController _parsedocQueryController =
      TextEditingController();
  final SearchIndexService _searchIndexService = const SearchIndexService();

  ValidationMode _mode = ValidationMode.standalone;
  bool _caseSensitive = false;
  String _strategy = highlightStrategy.PARTIAL_MATCH;

  LoadedValidationSource? _source;
  List<SearchResultItem> _results = const [];
  ParsedocRecord? _selectedRecord;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _parsedocQueryController.addListener(_runParsedocSearch);
    _standaloneTextController.addListener(_refreshStandalone);
    _standaloneQueryController.addListener(_refreshStandalone);
  }

  @override
  void dispose() {
    _standaloneTextController
      ..removeListener(_refreshStandalone)
      ..dispose();
    _standaloneQueryController
      ..removeListener(_refreshStandalone)
      ..dispose();
    _parsedocQueryController
      ..removeListener(_runParsedocSearch)
      ..dispose();
    _source?.dispose();
    super.dispose();
  }

  void _refreshStandalone() {
    if (_mode == ValidationMode.standalone && mounted) {
      setState(() {});
    }
  }

  Future<void> _chooseFolder() async {
    if (!widget.supportsDesktopFolderSource) {
      _showMessage(
        'Desktop folder indexing is only available in desktop builds.',
      );
      return;
    }

    final path = await widget.pickDirectory();
    if (path == null || path.isEmpty) {
      return;
    }

    await _loadFolder(path);
  }

  Future<void> _loadFolder(String rootPath) async {
    setState(() {
      _loading = true;
      _error = null;
      _results = const [];
      _selectedRecord = null;
    });

    final previous = _source;
    _source = null;
    await previous?.dispose();

    try {
      final loadResult = await widget.folderSourceLoader.load(rootPath);
      final recordsById = {
        for (final record in loadResult.records) record.id: record,
      };
      final nextSource = LoadedValidationSource(
        db: loadResult.db,
        records: loadResult.records,
        recordsById: recordsById,
        label: loadResult.rootPath,
        discoveredCount: loadResult.discoveredSupportedFiles,
        issues: loadResult.issues,
      );
      if (!mounted) {
        await nextSource.dispose();
        return;
      }

      setState(() {
        _source = nextSource;
        _loading = false;
        _results = _searchIndexService.browseAll(nextSource);
        _selectedRecord = nextSource.records.isEmpty
            ? null
            : nextSource.records.first;
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  void _runParsedocSearch() {
    final source = _source;
    if (source == null) {
      return;
    }

    setState(() {
      _results = _searchIndexService.search(
        source,
        _parsedocQueryController.text,
      );
      _selectedRecord = _results.isEmpty ? null : _results.first.record;
    });
  }

  void _showMessage(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Searchlight Highlight Validation')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Standalone highlight plus parsedoc-backed integration validation',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SegmentedButton<ValidationMode>(
              segments: const [
                ButtonSegment<ValidationMode>(
                  value: ValidationMode.standalone,
                  label: Text('Standalone highlight'),
                  icon: Icon(Icons.text_fields),
                ),
                ButtonSegment<ValidationMode>(
                  value: ValidationMode.parsedoc,
                  label: Text('Parsedoc + highlight'),
                  icon: Icon(Icons.library_books),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (selection) {
                setState(() {
                  _mode = selection.first;
                });
              },
              showSelectedIcon: false,
              style: ButtonStyle(visualDensity: VisualDensity.compact),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: switch (_mode) {
                ValidationMode.standalone => _buildStandaloneMode(context),
                ValidationMode.parsedoc => _buildParsedocMode(context),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStandaloneMode(BuildContext context) {
    final text = _standaloneTextController.text;
    final query = _standaloneQueryController.text;
    final highlighted = Highlight(
      HighlightOptions(
        caseSensitive: _caseSensitive,
        strategy: _strategy,
        CSSClass: _exampleHighlightCssClass,
      ),
    ).highlight(text, query);

    final controls = ListView(
      children: [
        Text(
          'Standalone highlight',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        TextField(
          key: const ValueKey('standalone-query'),
          controller: _standaloneQueryController,
          decoration: const InputDecoration(
            labelText: 'Query',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('standalone-text'),
          controller: _standaloneTextController,
          minLines: 6,
          maxLines: 10,
          decoration: const InputDecoration(
            labelText: 'Input text',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 560;
            if (narrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStrategyField(),
                  const SizedBox(height: 12),
                  _buildCaseSensitiveToggle(),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildStrategyField()),
                const SizedBox(width: 16),
                Expanded(child: _buildCaseSensitiveToggle()),
              ],
            );
          },
        ),
      ],
    );

    final positions = highlighted.positions;
    final htmlOutput = highlighted.HTML;
    final trimOutput = highlighted.trim(18);

    final details = ListView(
      children: [
        _InfoCard(
          title: 'TextSpan preview',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rendered with RichText/TextSpan from inclusive Position ranges.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              _HighlightedTextPreview(text: text, positions: positions),
              const SizedBox(height: 8),
              Text('Positions: ${_formatPositions(positions)}'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _InfoCard(
          title: 'Rendered HTML preview',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rendered with flutter_html from the highlight HTML output.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Html(data: htmlOutput),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _InfoCard(
          title: 'Raw HTML string',
          child: _CodeBlock(text: htmlOutput),
        ),
        const SizedBox(height: 16),
        _InfoCard(
          title: 'Trim(18)',
          child: _CodeBlock(text: trimOutput),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 960;
        if (narrow) {
          return Column(
            children: [
              Expanded(child: controls),
              const SizedBox(height: 24),
              Expanded(child: details),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: controls),
            const SizedBox(width: 24),
            Expanded(child: details),
          ],
        );
      },
    );
  }

  Widget _buildParsedocMode(BuildContext context) {
    final source = _source;
    final record = _selectedRecord;
    final query = _parsedocQueryController.text;
    final highlightedTitle = record == null
        ? null
        : Highlight(
            const HighlightOptions(CSSClass: _exampleHighlightCssClass),
          ).highlight(record.title, query);
    final highlightedContent = record == null
        ? null
        : Highlight(
            const HighlightOptions(CSSClass: _exampleHighlightCssClass),
          ).highlight(record.content, query);

    final header = LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 760;
        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FilledButton.icon(
                key: const ValueKey('choose-folder'),
                onPressed: _loading ? null : _chooseFolder,
                icon: const Icon(Icons.folder_open),
                label: const Text('Choose Folder'),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('parsedoc-query'),
                controller: _parsedocQueryController,
                decoration: const InputDecoration(
                  hintText: 'Search parsed HTML or Markdown...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          );
        }

        return Row(
          children: [
            FilledButton.icon(
              key: const ValueKey('choose-folder'),
              onPressed: _loading ? null : _chooseFolder,
              icon: const Icon(Icons.folder_open),
              label: const Text('Choose Folder'),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                key: const ValueKey('parsedoc-query'),
                controller: _parsedocQueryController,
                decoration: const InputDecoration(
                  hintText: 'Search parsed HTML or Markdown...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        );
      },
    );

    final resultsPane = _results.isEmpty
        ? const Center(
            child: Text(
              'Choose a folder to validate parsedoc-backed highlighting.',
            ),
          )
        : ListView.separated(
            itemCount: _results.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = _results[index];
              final preview = Highlight(
                const HighlightOptions(CSSClass: _exampleHighlightCssClass),
              ).highlight(item.record.content, query);
              return ListTile(
                title: Text(item.record.title),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.record.pathLabel),
                    const SizedBox(height: 4),
                    _HighlightedTextPreview(
                      text: item.record.content,
                      positions: preview.positions,
                      maxLines: 2,
                    ),
                  ],
                ),
                selected: item.record == _selectedRecord,
                onTap: () {
                  setState(() {
                    _selectedRecord = item.record;
                  });
                },
              );
            },
          );

    final detailsPane = record == null
        ? const Center(child: Text('Select a result to inspect it.'))
        : ListView(
            children: [
              _InfoCard(
                title: 'Highlighted title',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HighlightedTextPreview(
                      text: record.title,
                      positions: highlightedTitle!.positions,
                    ),
                    const SizedBox(height: 8),
                    _CodeBlock(text: highlightedTitle.HTML),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _InfoCard(
                title: 'Highlighted content',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HighlightedTextPreview(
                      text: record.content,
                      positions: highlightedContent!.positions,
                    ),
                    const SizedBox(height: 8),
                    _CodeBlock(text: highlightedContent.HTML),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _InfoCard(
                title: 'Parsed record metadata',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Path: ${record.pathLabel}'),
                    Text('Parsed path: ${record.parsedPath}'),
                    Text('Type: ${record.type}'),
                    Text('Format: ${record.format}'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _InfoCard(
                title: 'Source preview',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.format == 'markdown'
                          ? 'Rendered with flutter_markdown_plus MarkdownBody.'
                          : 'Shown as raw HTML source text.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    record.format == 'markdown'
                        ? MarkdownBody(data: record.displayBody)
                        : SelectableText(record.displayBody),
                  ],
                ),
              ),
            ],
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        const SizedBox(height: 16),
        if (_loading) const LinearProgressIndicator(),
        if (_loading) const SizedBox(height: 16),
        Text(
          source == null
              ? 'No folder loaded yet.'
              : 'Indexed ${source.indexedCount} extracted records from ${source.discoveredCount} supported files in ${source.label}',
        ),
        if (source != null) ...[
          const SizedBox(height: 8),
          Text('Issues: ${source.issues.length}'),
        ],
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 16),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 960;
              if (narrow) {
                return Column(
                  children: [
                    Expanded(child: resultsPane),
                    const SizedBox(height: 24),
                    Expanded(child: detailsPane),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: resultsPane),
                  const SizedBox(width: 24),
                  Expanded(child: detailsPane),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStrategyField() {
    return DropdownButtonFormField<String>(
      key: const ValueKey('standalone-strategy'),
      initialValue: _strategy,
      isExpanded: true,
      items: const [
        DropdownMenuItem(value: 'partialMatch', child: Text('Partial match')),
        DropdownMenuItem(
          value: 'wholeWordMatch',
          child: Text('Whole word match'),
        ),
        DropdownMenuItem(
          value: 'partialMatchFullWord',
          child: Text('Partial match, full word'),
        ),
      ],
      decoration: const InputDecoration(
        labelText: 'Strategy',
        border: OutlineInputBorder(),
      ),
      onChanged: (value) {
        if (value == null) {
          return;
        }
        setState(() {
          _strategy = value;
        });
      },
    );
  }

  Widget _buildCaseSensitiveToggle() {
    return SwitchListTile.adaptive(
      key: const ValueKey('case-sensitive-toggle'),
      contentPadding: EdgeInsets.zero,
      title: const Text('Case sensitive'),
      value: _caseSensitive,
      onChanged: (value) {
        setState(() {
          _caseSensitive = value;
        });
      },
    );
  }

  String _formatPositions(List<Position> positions) {
    if (positions.isEmpty) {
      return '[]';
    }
    return '[${positions.map((p) => '${p.start}-${p.end}').join(', ')}]';
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _HighlightedTextPreview extends StatelessWidget {
  const _HighlightedTextPreview({
    required this.text,
    required this.positions,
    this.maxLines,
  });

  final String text;
  final List<Position> positions;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return RichText(
      maxLines: maxLines,
      overflow: maxLines == null ? TextOverflow.visible : TextOverflow.ellipsis,
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyMedium,
        children: _buildSpans(context),
      ),
    );
  }

  List<InlineSpan> _buildSpans(BuildContext context) {
    if (positions.isEmpty || text.isEmpty) {
      return [TextSpan(text: text)];
    }

    final sorted = [...positions]..sort((a, b) => a.start.compareTo(b.start));
    final spans = <InlineSpan>[];
    var cursor = 0;

    for (final position in sorted) {
      final start = position.start.clamp(0, text.length);
      final endExclusive = (position.end + 1).clamp(0, text.length);
      if (start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, start)));
      }
      if (endExclusive > start) {
        spans.add(
          TextSpan(
            text: text.substring(start, endExclusive),
            style: TextStyle(
              backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
              color: Theme.of(context).colorScheme.onTertiaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      }
      cursor = endExclusive;
    }

    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }

    return spans;
  }
}

class _CodeBlock extends StatelessWidget {
  const _CodeBlock({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SelectableText(
        text,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
      ),
    );
  }
}
