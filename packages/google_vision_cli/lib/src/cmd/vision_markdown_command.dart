import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dio/dio.dart';
import 'package:google_vision/google_vision.dart';

import 'vision_helper_command.dart';

/// Convert the result of `DOCUMENT_TEXT_DETECTION` to a markdown document.
class VisionMarkdownCommand extends VisionHelper {
  @override
  String get name => 'markdown';

  @override
  String get description =>
      'Convert DOCUMENT_TEXT_DETECTION result to markdown.';

  VisionMarkdownCommand() {
    argParser
      ..addOption(
        'image-file',
        mandatory: true,
        valueHelp: 'image or PDF file path',
        help: 'The path to the file that will be processed.',
      )
      ..addOption(
        'output-file',
        abbr: 'o',
        valueHelp: 'markdown file path',
        help:
            'Path to write the markdown output. If omitted, output is written to stdout.',
      )
      ..addOption(
        'pages',
        abbr: 'p',
        valueHelp: 'comma delimited list of pages to process (max 5)',
        help:
            'When set, the file is processed via the file annotation API (PDF/TIFF/GIF).',
      )
      ..addFlag(
        'all-pages',
        defaultsTo: false,
        help:
            'Process all pages in the file. Automatically batches requests in '
            'groups of 5 (the API limit). Mutually exclusive with --pages.',
      )
      ..addFlag(
        'page-headers',
        defaultsTo: false,
        help:
            'Emit a level-1 header (`# Page N`) at the top of each page. '
            'Disabled by default because the heading is generated content '
            'rather than original document text.',
      )
      ..addFlag(
        'image-placeholders',
        defaultsTo: true,
        help: 'Emit a placeholder image link for `BlockType.PICTURE` blocks.',
      )
      ..addFlag(
        'detect-headers',
        defaultsTo: true,
        help: 'Detect headers using a relative symbol-height heuristic.',
      )
      ..addFlag(
        'detect-lists',
        defaultsTo: true,
        help: 'Detect bullet and ordered lists from leading characters.',
      )
      ..addFlag(
        'detect-checkboxes',
        defaultsTo: true,
        help:
            'Detect checkbox glyphs / `[ ]` / `[x]` patterns and emit task-list items.',
      )
      ..addFlag(
        'strip-running-headers',
        defaultsTo: true,
        help:
            'Strip blocks geometrically positioned in the top/bottom band of each page (running headers/footers).',
      )
      ..addFlag(
        'bold-allcaps-labels',
        defaultsTo: true,
        help:
            'Emit short ALL-CAPS lines as bold labels on their own paragraph.',
      )
      ..addFlag(
        'pair-column-markers',
        defaultsTo: false,
        help:
            'Pair stand-alone list-marker paragraphs to body paragraphs when '
            'they form a vertical column in a separate block (cross-column '
            'orphan-marker repair). Off by default — geometric column '
            'detection is more aggressive than the in-stream rule.',
      )
      ..addFlag(
        'promote-text-tables',
        defaultsTo: false,
        help:
            'Promote clusters of narrow TEXT paragraphs that share a '
            'Y-baseline and occupy distinct X positions into a markdown table. '
            'Repairs documents where Vision returns tables as multiple TEXT '
            'blocks rather than a native TABLE block.',
      );
  }

  @override
  void run() async {
    try {
      await initializeGoogleVision();

      final useAllPages = argResults!['all-pages'] as bool;
      final usePages = pages != null;

      if (useAllPages && usePages) {
        throw UsageException(
          'Cannot use both --all-pages and --pages. Choose one.',
          '',
        );
      }

      if (!useAllPages && !usePages) {
        throw UsageException(
          'PDF/TIFF/GIF files require either --pages or --all-pages flag.',
          '',
        );
      }

      final options = MarkdownOptions(
        emitPageHeaders: argResults!['page-headers'] as bool,
        emitImagePlaceholders: argResults!['image-placeholders'] as bool,
        detectHeaders: argResults!['detect-headers'] as bool,
        detectLists: argResults!['detect-lists'] as bool,
        detectCheckboxes: argResults!['detect-checkboxes'] as bool,
        stripRunningHeaders: argResults!['strip-running-headers'] as bool,
        boldAllCapsLabels: argResults!['bold-allcaps-labels'] as bool,
        pairColumnAlignedMarkers: argResults!['pair-column-markers'] as bool,
        promoteTextToTable: argResults!['promote-text-tables'] as bool,
      );

      String markdown;

      if (useAllPages) {
        // Batch process all pages in groups of 5 (API limit)
        final allPages = <Page>[];
        const batchSize = 5;
        int batchStart = 1;
        bool hasMorePages = true;

        while (hasMorePages) {
          final pageList = List.generate(batchSize, (i) => batchStart + i);

          try {
            final fileResponses = await googleVision.file.documentTextDetection(
              InputConfig.fromBuffer(imageBytes.buffer),
              pages: pageList,
            );

            bool receivedAnyContent = false;
            for (final fileResponse in fileResponses) {
              if (fileResponse.error != null) {
                stderr.writeln(
                  'Warning: Error on pages ${pageList.first}-${pageList.last}: ${fileResponse.error?.message}',
                );
                hasMorePages = false;
                break;
              }
              for (final imageResponse in fileResponse.responses ?? const []) {
                final responsePages = imageResponse.fullTextAnnotation?.pages;
                if (responsePages != null && responsePages.isNotEmpty) {
                  receivedAnyContent = true;
                  allPages.addAll(responsePages);
                }
              }
            }

            // If we didn't get any content, we've processed all pages
            if (!receivedAnyContent) {
              hasMorePages = false;
            } else {
              batchStart += batchSize;
            }
          } on DioException catch (err) {
            // 400 error likely means we've exceeded the page count
            if (err.response?.statusCode == 400) {
              stderr.writeln(
                'Reached end of document after processing ${allPages.length} pages',
              );
              hasMorePages = false;
            } else {
              rethrow;
            }
          }
        }

        markdown = MarkdownConverter(options: options).convertPages(allPages);
      } else {
        final fileResponses = await googleVision.file.documentTextDetection(
          InputConfig.fromBuffer(imageBytes.buffer),
          pages: pages!,
        );

        final allPages = <Page>[];
        for (final fileResponse in fileResponses) {
          if (fileResponse.error != null) continue;
          for (final imageResponse in fileResponse.responses ?? const []) {
            final responsePages = imageResponse.fullTextAnnotation?.pages;
            if (responsePages != null) allPages.addAll(responsePages);
          }
        }

        markdown = MarkdownConverter(options: options).convertPages(allPages);
      }

      final outputFile = argResults!['output-file'] as String?;
      if (outputFile != null) {
        File(outputFile).writeAsStringSync(markdown);
      } else {
        stdout.write(markdown);
      }
    } on DioException catch (err) {
      throw UsageException('API usage error:', err.usage);
    }
  }
}
