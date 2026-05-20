import '../model/block.dart';
import '../model/bounding_poly.dart';
import '../model/detected_break.dart';
import '../model/full_text_annotation.dart';
import '../model/page.dart';
import '../model/paragraph.dart';
import '../model/symbol.dart' as gv;
import '../model/word.dart';
import 'markdown_options.dart';

/// Converts a [FullTextAnnotation] (result of `DOCUMENT_TEXT_DETECTION`) into
/// well-formatted markdown.
///
/// The converter walks the Google Vision document hierarchy
/// `Page → Block → Paragraph → Word → Symbol` and emits markdown using:
///
/// * native [BlockType] (`TABLE`, `PICTURE`, `RULER`, `BARCODE`, `TEXT`),
/// * the per-word [DetectedBreak] (`SPACE`, `EOL_SURE_SPACE`, `LINE_BREAK`,
///   `HYPHEN`),
/// * a relative symbol-height heuristic for header detection,
/// * leading-character pattern matching for lists and checkboxes.
///
/// See [MarkdownOptions] for tuning.
class MarkdownConverter {
  /// Conversion options.
  final MarkdownOptions options;

  const MarkdownConverter({this.options = const MarkdownOptions()});

  /// Convert a complete [FullTextAnnotation] to markdown.
  String convert(FullTextAnnotation annotation) =>
      convertPages(annotation.pages);

  /// Convert an arbitrary collection of [Page] objects to markdown.
  ///
  /// Useful when assembling output from a multi-response file annotation
  /// (e.g. iterating `BatchAnnotateFilesResponse.responses`).
  String convertPages(Iterable<Page> pages) {
    final pageList = pages.toList();
    final buffer = StringBuffer();

    for (var i = 0; i < pageList.length; i++) {
      if (i > 0 && options.emitPageSeparators) {
        buffer.writeln();
        buffer.writeln('---');
        buffer.writeln();
      }
      _writePage(buffer, pageList[i], i + 1);
    }

    return buffer.toString().trimRight() + (pageList.isEmpty ? '' : '\n');
  }

  // ---------------------------------------------------------------------------
  // Page rendering
  // ---------------------------------------------------------------------------

  void _writePage(StringBuffer buffer, Page page, int pageNumber) {
    if (options.emitPageHeaders) {
      buffer.writeln('# Page $pageNumber');
      buffer.writeln();
    }

    final medianHeight = _pageMedianSymbolHeight(page);

    final blocks = page.blocks ?? const <Block>[];
    final renderedBlocks = <String>[];

    // Pool consecutive TEXT/UNKNOWN blocks so paragraph coalescing (orphan-
    // marker absorption, vertical merge, same-line-with-gap merge) operates
    // across block boundaries. Non-TEXT blocks flush the pool to keep
    // tables/pictures/rulers in their original position.
    var pendingText = <_LogicalParagraph>[];

    void flushText() {
      if (pendingText.isEmpty) return;
      final rendered = _renderLogicalParagraphs(
        pendingText,
        medianHeight,
        page,
      );
      if (rendered.isNotEmpty) renderedBlocks.add(rendered);
      pendingText = <_LogicalParagraph>[];
    }

    for (final block in blocks) {
      if (options.stripRunningHeaders &&
          _isBlockChrome(block, page, medianHeight)) {
        continue;
      }

      switch (block.blockType) {
        case BlockType.TEXT:
        case BlockType.UNKNOWN:
          pendingText.addAll(_collectTextParagraphs(block, page, medianHeight));
          break;
        case BlockType.TABLE:
        case BlockType.PICTURE:
        case BlockType.RULER:
        case BlockType.BARCODE:
          flushText();
          final rendered = _renderBlock(block, medianHeight, page);
          if (rendered.isNotEmpty) renderedBlocks.add(rendered);
          break;
      }
    }
    flushText();

    for (var i = 0; i < renderedBlocks.length; i++) {
      buffer.writeln(renderedBlocks[i]);
      if (i != renderedBlocks.length - 1) buffer.writeln();
    }
  }

  String _renderBlock(Block block, double medianHeight, Page page) {
    switch (block.blockType) {
      case BlockType.TABLE:
        return _renderTable(block, page);
      case BlockType.PICTURE:
        return options.emitImagePlaceholders ? _renderPicture(block) : '';
      case BlockType.RULER:
        return '---';
      case BlockType.BARCODE:
        return '`[barcode placeholder]`';
      case BlockType.TEXT:
      case BlockType.UNKNOWN:
        // Single-block fallback used when callers invoke _renderBlock
        // directly. Page-level pooling in [_writePage] is preferred so that
        // coalescing can cross block boundaries.
        return _renderLogicalParagraphs(
          _collectTextParagraphs(block, page, medianHeight),
          medianHeight,
          page,
        );
    }
  }

  // ---------------------------------------------------------------------------
  // TEXT block rendering (headers / lists / checkboxes / paragraphs)
  // ---------------------------------------------------------------------------

  /// Collect non-chrome paragraphs from [block] and convert each into a
  /// [_LogicalParagraph] (Vision paragraph + rendered lines).
  List<_LogicalParagraph> _collectTextParagraphs(
    Block block,
    Page page,
    double medianHeight,
  ) {
    final out = <_LogicalParagraph>[];
    for (final paragraph in block.paragraphs ?? const <Paragraph>[]) {
      if (options.stripRunningHeaders &&
          _isParagraphChrome(paragraph, page, medianHeight)) {
        continue;
      }
      final lines = _buildParagraphLines(paragraph, page);
      if (lines.isEmpty) continue;
      out.add(_LogicalParagraph(paragraph, lines));
    }
    return out;
  }

  /// Apply coalescing rules and render a logical-paragraph stream as
  /// markdown.
  String _renderLogicalParagraphs(
    List<_LogicalParagraph> initial,
    double medianHeight,
    Page page,
  ) {
    if (initial.isEmpty) return '';

    // Cross-block / cross-column orphan-marker pairing (rule E pre-pass).
    // Repairs two-column "marker | body" layouts where Vision emits the
    // markers as a left strip and the bodies as a right strip rather than
    // interleaving them. Off by default; gated by [pairColumnAlignedMarkers].
    final prepaired = _pairColumnAlignedMarkers(initial, medianHeight, page);

    // Sort paragraphs by vertical position so that in-stream orphan
    // absorption in [_coalesceParagraphs] correctly associates markers
    // with adjacent bodies even when Vision returns blocks out of visual
    // reading order (a common occurrence with section-level markers).
    final sorted = _sortByYPosition(prepaired, page);

    // Table promotion: detect clusters of narrow TEXT paragraphs that form
    // table rows (same Y, distinct X) and replace them with a synthetic
    // rendered-table paragraph BEFORE coalescing can merge them into
    // adjacent body text. Gated by [promoteTextToTable].
    final withTables = options.promoteTextToTable
        ? _promoteTextTables(sorted, medianHeight, page)
        : sorted;

    // Orphan-marker absorption (B), digit-noise drop, vertical-adjacency
    // merge (A) and same-line-with-gap form-field merge.
    final logical = _coalesceParagraphs(withTables, medianHeight, page);

    final out = <String>[];
    for (final lp in logical) {
      for (final segment in _segmentLines(lp.lines)) {
        final text = segment.text.trim();
        if (text.isEmpty) continue;

        if (segment.isAllCapsLabel && options.boldAllCapsLabels) {
          out.add('**$text**');
          continue;
        }

        final checkbox = options.detectCheckboxes ? _matchCheckbox(text) : null;
        if (checkbox != null) {
          out.add(checkbox);
          continue;
        }

        final list = options.detectLists ? _matchList(text) : null;
        if (list != null) {
          out.add(list);
          continue;
        }

        if (options.detectHeaders && medianHeight > 0) {
          final paragraphHeight = _paragraphMeanSymbolHeight(lp.source, page);
          final ratio = paragraphHeight / medianHeight;
          if (ratio >= options.headerH1Ratio) {
            out.add('# $text');
            continue;
          }
          if (ratio >= options.headerH2Ratio) {
            out.add('## $text');
            continue;
          }
          if (ratio >= options.headerH3Ratio) {
            out.add('### $text');
            continue;
          }
        }

        out.add(text);
      }
    }

    return out.join('\n\n');
  }

  /// Apply orphan-marker absorption, digit-noise removal, and adjacent-
  /// paragraph merging on the in-block paragraph stream.
  ///
  /// All three rules are structural: typography for orphan/digit detection,
  /// punctuation for "open clause" detection, and pure geometry for the
  /// merge proximity test.
  List<_LogicalParagraph> _coalesceParagraphs(
    List<_LogicalParagraph> input,
    double medianHeight,
    Page page,
  ) {
    final result = <_LogicalParagraph>[];
    String? pendingMarker;

    for (final lp in input) {
      final text = lp.lines.join(' ').trim();

      // Drop digit-only noise (e.g. vertical numeral columns from form fields).
      if (options.dropDigitOnlyNoise && _isDigitOnlyNoise(text)) {
        continue;
      }

      // Buffer stand-alone list markers so they can be prepended to the next
      // body paragraph.
      if (options.absorbOrphanListMarkers && _isOrphanListMarker(text)) {
        if (pendingMarker != null) {
          // Two consecutive orphan markers. Before dropping the first,
          // try to split the previous result paragraph if it contains a
          // merged list body that should be attributed to pendingMarker.
          if (!_trySplitMergedListBody(result, pendingMarker)) {
            // Split failed — drop the pending marker (likely OCR noise).
          }
          pendingMarker = null;
        }
        pendingMarker = text;
        continue;
      }

      // Prepend any buffered marker to this paragraph's first line, unless
      // the paragraph already starts with its own list marker (which can
      // happen when an earlier pre-pass paired a column-aligned marker to
      // this body — re-prepending would produce double markers like
      // "7. 1. Labor ..."). In that case, flush the buffered marker as
      // plain text instead.
      if (pendingMarker != null) {
        final firstLine = lp.lines.isEmpty ? '' : lp.lines[0];
        if (_leadingListMarker.hasMatch(firstLine)) {
          // Body already starts with its own list marker — the pending
          // orphan is likely OCR noise. Drop it rather than emitting
          // a standalone orphan line.
          pendingMarker = null;
        } else if (lp.lines.isEmpty) {
          lp.lines.add(pendingMarker);
        } else {
          lp.lines[0] = '$pendingMarker ${lp.lines[0]}';
        }
        pendingMarker = null;
      }

      // Same-baseline horizontal-gap merge (form-field placeholders): the
      // current paragraph sits to the right of the previous one on the same
      // visual line, separated by a blank fill-in field. Inject the
      // configured placeholder between them so the gap remains visible
      // (rule for inline `___` underline form fields).
      if (options.preserveFormFieldGaps &&
          result.isNotEmpty &&
          _shouldMergeSameLineWithGap(result.last, lp, medianHeight, page)) {
        if (result.last.lines.isNotEmpty) {
          final lastIdx = result.last.lines.length - 1;
          result.last.lines[lastIdx] =
              '${result.last.lines[lastIdx]} ${options.formFieldPlaceholder}';
        }
        result.last.lastMergedSource = lp.source;
        result.last.lines.addAll(lp.lines);
        continue;
      }

      // Same-baseline / vertical-adjacency merge with previous result.
      if (options.mergeFragmentedParagraphs &&
          result.isNotEmpty &&
          _shouldMergeWithPrev(result.last, lp, medianHeight, page)) {
        result.last.lastMergedSource = lp.source;
        result.last.lines.addAll(lp.lines);
        continue;
      }

      result.add(lp);
    }

    // Trailing marker with no body → emit as plain text rather than dropping.
    if (pendingMarker != null) {
      result.add(_LogicalParagraph.synthetic(<String>[pendingMarker]));
    }

    return result;
  }

  /// Cross-block / cross-column pairing of orphan list markers to their
  /// bodies. Off by default ([MarkdownOptions.pairColumnAlignedMarkers]).
  ///
  /// This is a *pre-pass* that runs before [_coalesceParagraphs] to repair
  /// two-column "marker | body" layouts where Vision emits all markers in a
  /// left strip first and all bodies in a right strip second. The in-stream
  /// [absorbOrphanListMarkers] rule cannot reach across that re-ordering.
  ///
  /// Supports **multiple marker columns** per page. Vision may return both
  /// section-level markers (e.g. "3.", "4." at the left margin) and nested
  /// sub-list markers (e.g. invoice items "1."–"7." at a deeper indent) on
  /// the same page. Each X-aligned cluster is identified and paired
  /// independently.
  ///
  /// Geometric guards (all must hold for a pair to be created):
  ///  * marker text matches [_orphanListMarkerPattern]
  ///  * markers form a column (≥ [markerColumnMinSize] markers whose
  ///    xCenter falls within ±½·[markerColumnWidthRatio] × pageWidth of
  ///    each other)
  ///  * column markers are monotonically increasing in yCenter
  ///  * candidate body's left edge is strictly to the right of every column
  ///    marker's right edge (no underlapping bodies)
  ///  * candidate body's top edge falls inside the cluster's Y window
  ///    expanded by [markerPairYToleranceRatio] × pageMedianSymbolHeight
  ///  * |yKey(body) − yCenter(marker)| ≤ [markerPairYToleranceRatio] ×
  ///    pageMedianSymbolHeight (per-pair)
  ///  * **ordered** assignment: the k-th column marker (in increasing
  ///    yCenter) pairs with the k-th candidate body (also in increasing
  ///    yCenter). This preserves list-item order and avoids the cross-link
  ///    failures of greedy-by-closest-Y matching when body Y centres do not
  ///    perfectly align with marker Y centres.
  List<_LogicalParagraph> _pairColumnAlignedMarkers(
    List<_LogicalParagraph> input,
    double medianHeight,
    Page page,
  ) {
    if (!options.pairColumnAlignedMarkers) return input;
    if (medianHeight <= 0) return input;
    final pageWidth = page.width.toDouble();
    if (pageWidth <= 0) return input;

    // Index orphan markers and candidate bodies (keep indices into input
    // so we can remove paired markers afterwards).
    final markerIdx = <int>[];
    final bodyIdx = <int>[];
    for (var i = 0; i < input.length; i++) {
      final lp = input[i];
      final text = lp.lines.join(' ').trim();
      if (lp.source?.boundingBox == null) continue;
      if (_orphanListMarkerPattern.hasMatch(text)) {
        markerIdx.add(i);
      } else if (!_leadingListMarker.hasMatch(text)) {
        bodyIdx.add(i);
      }
    }
    if (markerIdx.length < options.markerColumnMinSize) return input;

    // Compute X centres for all orphan markers.
    final xCenters = <double>[];
    for (final i in markerIdx) {
      final cx = _xCenter(input[i].source!.boundingBox, page);
      if (cx == null) return input;
      xCenters.add(cx);
    }

    // Cluster markers into X-aligned columns. Markers whose xCenters are
    // within [markerColumnWidthRatio * pageWidth] of each other belong to
    // the same column.
    final xColumns = _clusterMarkersByX(
      markerIdx,
      xCenters,
      pageWidth,
      input,
      page,
    );

    final paired = <int>{};
    final claimedBodies = <int>{};

    for (final column in xColumns) {
      if (column.length < options.markerColumnMinSize) continue;

      // Verify monotonic Y; skip this column if markers are out of order
      // (probably not a real list column).
      final colY = <double>[];
      var yMonotonic = true;
      for (final i in column) {
        final yc = _yCenter(input[i].source!.boundingBox, page);
        if (yc == null) {
          yMonotonic = false;
          break;
        }
        colY.add(yc);
      }
      if (!yMonotonic) continue;
      for (var k = 1; k < colY.length; k++) {
        if (colY[k] <= colY[k - 1]) {
          yMonotonic = false;
          break;
        }
      }
      if (!yMonotonic) continue;

      // Split this column into Y clusters separated by large gaps.
      final yTol = options.markerPairYToleranceRatio * medianHeight;
      final maxGap = options.markerColumnMaxGapRatio * medianHeight;
      final clusters = <List<int>>[];
      var current = <int>[0];
      for (var k = 1; k < column.length; k++) {
        if (colY[k] - colY[k - 1] > maxGap) {
          clusters.add(current);
          current = <int>[k];
        } else {
          current.add(k);
        }
      }
      clusters.add(current);

      // Fallback: if splitting left no cluster large enough to meet
      // minSize, treat the whole column as one cluster. This handles
      // short columns (e.g. 2 section markers "3.", "4.") where the
      // inter-marker gap is large but the column as a whole is valid.
      final hasValidCluster = clusters.any(
        (c) => c.length >= options.markerColumnMinSize,
      );
      final effectiveClusters = hasValidCluster
          ? clusters
          : [List.generate(column.length, (i) => i)];

      for (final cluster in effectiveClusters) {
        if (cluster.length < options.markerColumnMinSize) continue;
        _pairOrderedClusterInto(
          input: input,
          page: page,
          inColumn: column,
          colY: colY,
          cluster: cluster,
          bodyIdx: bodyIdx,
          yTol: yTol,
          paired: paired,
          claimedBodies: claimedBodies,
        );
      }
    }

    if (paired.isEmpty) return input;

    final out = <_LogicalParagraph>[];
    for (var i = 0; i < input.length; i++) {
      if (paired.contains(i)) continue;
      out.add(input[i]);
    }
    return out;
  }

  /// Cluster [markerIdx] into groups of markers that share a similar
  /// X centre (within [MarkdownOptions.markerColumnWidthRatio] × pageWidth).
  /// Returns a list of columns, each being a list of input indices.
  List<List<int>> _clusterMarkersByX(
    List<int> markerIdx,
    List<double> xCenters,
    double pageWidth,
    List<_LogicalParagraph> input,
    Page page,
  ) {
    // Sort markers by X centre.
    final order = List.generate(markerIdx.length, (i) => i);
    order.sort((a, b) => xCenters[a].compareTo(xCenters[b]));

    final maxSpread = options.markerColumnWidthRatio * pageWidth;
    final columns = <List<int>>[];
    var col = <int>[markerIdx[order[0]]];
    var colXMin = xCenters[order[0]];

    for (var k = 1; k < order.length; k++) {
      final x = xCenters[order[k]];
      if (x - colXMin <= maxSpread) {
        col.add(markerIdx[order[k]]);
      } else {
        columns.add(col);
        col = <int>[markerIdx[order[k]]];
        colXMin = x;
      }
    }
    columns.add(col);

    // Within each column, sort by Y centre for subsequent processing.
    for (final c in columns) {
      c.sort((a, b) {
        final ya = _yCenter(input[a].source!.boundingBox, page);
        final yb = _yCenter(input[b].source!.boundingBox, page);
        if (ya == null || yb == null) return 0;
        return ya.compareTo(yb);
      });
    }

    return columns;
  }

  /// Performs ordered k-th to k-th pairing for one cluster of column-aligned
  /// markers. Mutates [paired] and [claimedBodies] in place.
  void _pairOrderedClusterInto({
    required List<_LogicalParagraph> input,
    required Page page,
    required List<int> inColumn,
    required List<double> colY,
    required List<int> cluster,
    required List<int> bodyIdx,
    required double yTol,
    required Set<int> paired,
    required Set<int> claimedBodies,
  }) {
    // Compute this cluster's right edge (max marker right) and Y window.
    var columnRight = double.negativeInfinity;
    for (final k in cluster) {
      final r = _bboxRight(input[inColumn[k]].source!.boundingBox, page);
      if (r != null && r > columnRight) columnRight = r;
    }
    if (columnRight == double.negativeInfinity) return;
    final colYTop = colY[cluster.first] - yTol;
    final colYBottom = colY[cluster.last] + yTol;

    // Build the ordered candidate-body list for this cluster: bodies whose
    // left edge is to the right of the cluster's marker-column, whose
    // **top edge** falls inside the cluster's Y window, sorted by top edge
    // ascending. We use the body's top (not its yCenter) because list
    // bodies are often multi-line — their visual marker aligns with the
    // first line, not the paragraph midpoint. Skip bodies already claimed
    // by an earlier cluster.
    final candidates = <_BodyCandidate>[];
    for (final bi in bodyIdx) {
      if (claimedBodies.contains(bi)) continue;
      final bBox = input[bi].source?.boundingBox;
      if (bBox == null) continue;
      final bTop = _bboxTop(bBox, page);
      final bLeft = _bboxLeft(bBox, page);
      if (bTop == null || bLeft == null) continue;
      if (bLeft <= columnRight) continue; // strict-left rule
      if (bTop < colYTop || bTop > colYBottom) continue; // cluster window
      candidates.add(_BodyCandidate(bi, bTop));
    }
    candidates.sort((a, b) => a.yKey.compareTo(b.yKey));

    // Ordered pairing: k-th cluster marker ↔ k-th candidate body. Per-pair
    // Y tolerance still enforced; on failure, skip this pair (marker stays
    // orphan, body remains unclaimed) and continue with k+1 ↔ k+1.
    final pairCount = cluster.length < candidates.length
        ? cluster.length
        : candidates.length;
    for (var k = 0; k < pairCount; k++) {
      final mi = inColumn[cluster[k]];
      final mY = colY[cluster[k]];
      final cand = candidates[k];
      if ((cand.yKey - mY).abs() > yTol) continue;
      paired.add(mi);
      claimedBodies.add(cand.index);
      final markerText = input[mi].lines.join(' ').trim();
      final body = input[cand.index];
      if (body.lines.isEmpty) {
        body.lines.add(markerText);
      } else {
        body.lines[0] = '$markerText ${body.lines[0]}';
      }
    }
  }

  // ---------------------------------------------------------------------------
  // TEXT → Table promotion (pre-coalescing pass)
  // ---------------------------------------------------------------------------

  /// Detect clusters of narrow TEXT paragraphs that form table rows and
  /// replace them with a synthetic rendered-table paragraph.
  ///
  /// The pass runs before [_coalesceParagraphs] to prevent table-cell
  /// paragraphs from being merged into adjacent body text.
  ///
  /// Algorithm:
  ///  1. Identify "narrow" paragraphs (bbox width < [tableCellMaxWidthRatio]
  ///     × pageWidth AND word count ≤ [tableCellMaxWords]).
  ///  2. Group consecutive narrow paragraphs by Y-baseline proximity.
  ///  3. Within each Y-group, verify distinct X positions (≥ [tableMinColumns]).
  ///  4. If a valid table cluster is found, also check if the preceding body
  ///     paragraph's trailing word(s) align with the first table row and should
  ///     be split off as an additional column.
  ///  5. Render the cluster as a markdown table and replace in-stream.
  List<_LogicalParagraph> _promoteTextTables(
    List<_LogicalParagraph> input,
    double medianHeight,
    Page page,
  ) {
    if (medianHeight <= 0) return input;
    final pageWidth = page.width.toDouble();
    if (pageWidth <= 0) return input;

    // Phase 1: Tag each paragraph as table-candidate or not.
    final isCand = List<bool>.filled(input.length, false);
    for (var i = 0; i < input.length; i++) {
      final lp = input[i];
      if (lp.source == null) continue;
      final box = lp.source!.boundingBox;
      if (box == null) continue;
      final left = _bboxLeft(box, page);
      final right = _bboxRight(box, page);
      if (left == null || right == null) continue;
      final width = right - left;
      final widthRatio = width / pageWidth;
      if (widthRatio >= options.tableCellMaxWidthRatio) continue;
      final wordCount = lp.source!.words?.length ?? 0;
      // Very narrow paragraphs (< 20% page width) qualify regardless of word
      // count — they represent multi-row column cells. Wider paragraphs must
      // also be short to avoid promoting form-field fragments.
      final isVeryNarrow = widthRatio < 0.2;
      if (!isVeryNarrow && wordCount > options.tableCellMaxWords) continue;
      // Don't promote orphan list markers (they're handled separately).
      final text = lp.lines.join(' ').trim();
      if (_orphanListMarkerPattern.hasMatch(text)) continue;
      isCand[i] = true;
    }

    // Phase 2: Find runs of consecutive candidates and group by Y-row.
    final yTol = options.tableRowYToleranceRatio * medianHeight;
    final tableRanges = <_TableRange>[];
    var i = 0;
    while (i < input.length) {
      if (!isCand[i]) {
        i++;
        continue;
      }
      // Start of a candidate run.
      final start = i;
      while (i < input.length && isCand[i]) {
        i++;
      }
      final end = i; // exclusive
      if (end - start < options.tableMinColumns) continue;

      // Group into Y-rows.
      final rows = _groupCandidatesIntoRows(input, start, end, yTol, page);
      if (rows.isEmpty) continue;

      // Verify at least one row has enough distinct X-columns.
      final validRows = rows
          .where(
            (r) => _distinctXColumns(input, r, page) >= options.tableMinColumns,
          )
          .toList();
      if (validRows.isEmpty) continue;

      tableRanges.add(_TableRange(start, end, validRows));
    }

    if (tableRanges.isEmpty) return input;

    // Phase 3: Build output, replacing table ranges with rendered tables.
    final out = <_LogicalParagraph>[];
    var cursor = 0;
    for (final range in tableRanges) {
      // Copy non-table paragraphs up to this range.
      while (cursor < range.start) {
        out.add(input[cursor]);
        cursor++;
      }

      // Check if the preceding paragraph has trailing words that form
      // an additional table-header column.
      String? splitHeader;
      if (out.isNotEmpty) {
        splitHeader = _trySplitTrailingTableHeader(
          out.last,
          input,
          range,
          page,
          yTol,
        );
      }

      // Render the table.
      final tableMarkdown = _renderPromotedTable(
        input,
        range,
        page,
        splitHeader,
      );
      out.add(_LogicalParagraph.synthetic(<String>[tableMarkdown]));
      cursor = range.end;
    }
    // Copy remaining paragraphs.
    while (cursor < input.length) {
      out.add(input[cursor]);
      cursor++;
    }
    return out;
  }

  /// Group paragraph indices [start, end) into Y-rows by baseline proximity.
  List<List<int>> _groupCandidatesIntoRows(
    List<_LogicalParagraph> input,
    int start,
    int end,
    double yTol,
    Page page,
  ) {
    final rows = <List<int>>[];
    List<int>? currentRow;
    double? currentY;
    for (var i = start; i < end; i++) {
      final yTop = _bboxTop(input[i].source?.boundingBox, page);
      if (yTop == null) continue;
      if (currentY == null || (yTop - currentY).abs() > yTol) {
        if (currentRow != null && currentRow.isNotEmpty) rows.add(currentRow);
        currentRow = <int>[i];
        currentY = yTop;
      } else {
        currentRow!.add(i);
      }
    }
    if (currentRow != null && currentRow.isNotEmpty) rows.add(currentRow);
    return rows;
  }

  /// Count distinct X-position columns among paragraphs in [row].
  int _distinctXColumns(
    List<_LogicalParagraph> input,
    List<int> row,
    Page page,
  ) {
    final xCenters = <double>[];
    for (final idx in row) {
      final cx = _xCenter(input[idx].source?.boundingBox, page);
      if (cx != null) xCenters.add(cx);
    }
    if (xCenters.length < 2) return xCenters.length;
    xCenters.sort();
    // Count distinct positions separated by at least 5% of page width.
    final pageWidth = page.width.toDouble();
    final minSep = pageWidth * 0.05;
    var columns = 1;
    for (var i = 1; i < xCenters.length; i++) {
      if (xCenters[i] - xCenters[i - 1] > minSep) columns++;
    }
    return columns;
  }

  /// If the preceding paragraph's last word aligns with the first table row's
  /// Y-baseline, split it off and return the word text. Mutates the
  /// preceding paragraph's lines.
  String? _trySplitTrailingTableHeader(
    _LogicalParagraph prev,
    List<_LogicalParagraph> input,
    _TableRange range,
    Page page,
    double yTol,
  ) {
    if (prev.source == null) return null;
    final words = prev.source!.words;
    if (words == null || words.isEmpty) return null;

    // Get the Y-top of the first table row.
    double? tableRowY;
    for (final row in range.rows) {
      if (row.isEmpty) continue;
      tableRowY = _bboxTop(input[row.first].source?.boundingBox, page);
      break;
    }
    if (tableRowY == null) return null;

    // Check trailing word(s) of prev for same-Y alignment.
    // Walk backwards from last word to find where the table-aligned
    // trailing segment starts.
    var splitIdx = words.length; // exclusive — no split by default
    for (var w = words.length - 1; w >= 0; w--) {
      final wTop = _bboxTop(words[w].boundingBox, page);
      if (wTop == null) break;
      if ((wTop - tableRowY).abs() <= yTol) {
        splitIdx = w;
      } else {
        break;
      }
    }
    if (splitIdx >= words.length) return null; // no trailing words align

    // Ensure what's being split is short (≤ 3 words) — table header cells
    // are typically short column labels.
    final tailWords = words.length - splitIdx;
    if (tailWords > 3) return null;

    // Build the trailing word text.
    final buffer = StringBuffer();
    for (var w = splitIdx; w < words.length; w++) {
      if (w > splitIdx) buffer.write(' ');
      final syms = words[w].symbols;
      if (syms != null) {
        for (final s in syms) {
          buffer.write(s.text ?? '');
        }
      }
    }
    final headerText = buffer.toString().trim();
    if (headerText.isEmpty) return null;

    // Trim the trailing word(s) from prev's lines.
    final fullText = prev.lines.join(' ').trimRight();
    if (fullText.endsWith(headerText)) {
      final trimmed = fullText
          .substring(0, fullText.length - headerText.length)
          .trimRight();
      prev.lines
        ..clear()
        ..add(trimmed);
      return headerText;
    }
    return null;
  }

  /// Render the promoted table as a markdown pipe-table string.
  String _renderPromotedTable(
    List<_LogicalParagraph> input,
    _TableRange range,
    Page page,
    String? extraHeaderCell,
  ) {
    // Build column positions from all rows.
    final allXCenters = <double>[];
    for (final row in range.rows) {
      for (final idx in row) {
        final cx = _xCenter(input[idx].source?.boundingBox, page);
        if (cx != null) allXCenters.add(cx);
      }
    }
    allXCenters.sort();

    // Cluster X centres into distinct columns.
    final pageWidth = page.width.toDouble();
    final minSep = pageWidth * 0.05;
    final colPositions = <double>[allXCenters.first];
    for (var i = 1; i < allXCenters.length; i++) {
      if (allXCenters[i] - colPositions.last > minSep) {
        colPositions.add(allXCenters[i]);
      }
    }

    // If there's a split header cell, prepend a column position for it.
    if (extraHeaderCell != null && colPositions.isNotEmpty) {
      colPositions.insert(0, 0); // leftmost column
    }
    final numCols = colPositions.length;

    // Build table rows. Each input paragraph maps to one column position
    // based on its X-centre. Multi-line paragraphs produce additional rows.
    final tableRows = <List<String>>[];

    for (final row in range.rows) {
      // Map each paragraph in this Y-row to a column index.
      final headerRow = List<String>.filled(numCols, '');
      final extraRows = <List<String>>[];

      // Place the extra header cell in column 0 of the first row only.
      if (extraHeaderCell != null && tableRows.isEmpty) {
        headerRow[0] = extraHeaderCell;
      }

      for (final idx in row) {
        final cx = _xCenter(input[idx].source?.boundingBox, page);
        if (cx == null) continue;
        // Find nearest column.
        var colIdx = 0;
        var minDist = double.infinity;
        final startCol = extraHeaderCell != null ? 1 : 0;
        for (var c = startCol; c < colPositions.length; c++) {
          final dist = (cx - colPositions[c]).abs();
          if (dist < minDist) {
            minDist = dist;
            colIdx = c;
          }
        }

        // Split the paragraph's content into visual lines using word
        // Y-positions (Vision often uses EOL_SURE_SPACE instead of
        // LINE_BREAK within narrow column cells, so lp.lines won't
        // distinguish visual rows).
        final visualLines = _splitParagraphByWordY(input[idx], page);
        if (visualLines.isEmpty) continue;
        // First visual line goes into the header row at this column.
        headerRow[colIdx] = visualLines.first.trim();
        // Additional visual lines become extra rows (same column).
        for (var li = 1; li < visualLines.length; li++) {
          final extraRow = List<String>.filled(numCols, '');
          extraRow[colIdx] = visualLines[li].trim();
          extraRows.add(extraRow);
        }
      }
      tableRows.add(headerRow);
      tableRows.addAll(extraRows);
    }

    if (tableRows.isEmpty) return '';

    // Render as markdown pipe-table.
    final buffer = StringBuffer();
    buffer.writeln('| ${tableRows.first.map(_escapeCell).join(' | ')} |');
    buffer.writeln('| ${List.filled(numCols, '---').join(' | ')} |');
    for (var r = 1; r < tableRows.length; r++) {
      buffer.writeln('| ${tableRows[r].map(_escapeCell).join(' | ')} |');
    }
    return buffer.toString().trimRight();
  }

  /// Split a table-candidate paragraph into visual lines by clustering its
  /// words by Y-top position. Vision often uses `EOL_SURE_SPACE` rather than
  /// `LINE_BREAK` within narrow column cells, so [_buildParagraphLines] may
  /// produce a single line even when the content visually spans multiple rows.
  List<String> _splitParagraphByWordY(_LogicalParagraph lp, Page page) {
    final words = lp.source?.words;
    if (words == null || words.isEmpty) return lp.lines;

    final medH = _pageMedianSymbolHeight(page);
    final yTol = medH > 0 ? medH * 0.5 : 0.0;

    // Build (yTop, text) for each word.
    final wordData = <_WordYData>[];
    for (final word in words) {
      final text = _wordText(word).trim();
      if (text.isEmpty) continue;
      final yTop = _bboxTop(word.boundingBox, page);
      wordData.add(_WordYData(yTop ?? 0, text));
    }
    if (wordData.isEmpty) return lp.lines;

    // Group into Y-rows.
    final lines = <String>[];
    var currentLine = StringBuffer(wordData.first.text);
    var currentY = wordData.first.yTop;
    for (var i = 1; i < wordData.length; i++) {
      final wd = wordData[i];
      if ((wd.yTop - currentY).abs() > yTol) {
        lines.add(currentLine.toString());
        currentLine = StringBuffer(wd.text);
        currentY = wd.yTop;
      } else {
        currentLine.write(' ${wd.text}');
      }
    }
    lines.add(currentLine.toString());
    return lines;
  }

  static final RegExp _orphanListMarkerPattern = RegExp(
    r'^[\dA-Za-z]{1,3}[.)]\s*$',
  );
  static final RegExp _digitOnlyPattern = RegExp(r'^\d+$');
  static final RegExp _terminalPunctuation = RegExp(r'[\.\?\!:;]\s*$');
  static final RegExp _leadingListMarker = RegExp(
    r'^\s*[\dA-Za-z]{1,3}[.)]\s+',
  );

  bool _isOrphanListMarker(String text) =>
      _orphanListMarkerPattern.hasMatch(text);

  /// Attempt to split the last entry in [result] into two list items when
  /// it appears to contain a merged body that should be attributed to
  /// [orphanMarker]. Returns `true` if the split was performed.
  ///
  /// This handles the common Vision OCR artifact where consecutive list items
  /// are returned as a single paragraph (e.g., items 5 and 6 merged into one
  /// paragraph) while their individual markers remain separate.
  bool _trySplitMergedListBody(
    List<_LogicalParagraph> result,
    String orphanMarker,
  ) {
    if (result.isEmpty) return false;

    final prev = result.last;
    final prevText = prev.lines.join(' ').trim();

    // The previous result must start with a list marker.
    final prevMarkerMatch = _leadingListMarker.firstMatch(prevText);
    if (prevMarkerMatch == null) return false;

    // The orphan marker must be sequential to the previous marker.
    final prevMarkerStr = prevText.substring(0, prevMarkerMatch.end).trim();
    if (!_isSequentialMarker(prevMarkerStr, orphanMarker.trim())) return false;

    // Look for a split point: ";" followed by whitespace then a capital
    // letter. This pattern is common in enumerated lists where items end
    // with semicolons.
    final bodyText = prevText.substring(prevMarkerMatch.end);
    final splitMatch = _listItemSplitPattern.firstMatch(bodyText);
    if (splitMatch == null) return false;

    // Ensure both parts are substantial (avoid trivial splits).
    final firstPart = bodyText.substring(0, splitMatch.start + 1); // incl ";"
    final secondPart = bodyText.substring(splitMatch.end);
    if (firstPart.length < 15 || secondPart.length < 15) return false;

    // Perform the split: update the last result and add a new entry.
    prev.lines
      ..clear()
      ..add('$prevMarkerStr $firstPart'.trim());
    result.add(
      _LogicalParagraph.synthetic(<String>[
        '${orphanMarker.trim()} $secondPart',
      ]),
    );
    return true;
  }

  static final RegExp _listItemSplitPattern = RegExp(r';\s+(?=[A-Z])');

  /// Check if [nextMarker] is the sequential successor of [prevMarker].
  /// Handles numeric markers like "5." → "6." and alphabetic like "a)" → "b)".
  bool _isSequentialMarker(String prevMarker, String nextMarker) {
    final prevMatch = RegExp(
      r'^([\dA-Za-z]+)([.)]\s*)$',
    ).firstMatch(prevMarker);
    final nextMatch = RegExp(
      r'^([\dA-Za-z]+)([.)]\s*)$',
    ).firstMatch(nextMarker);
    if (prevMatch == null || nextMatch == null) return false;

    final prevVal = prevMatch.group(1)!;
    final nextVal = nextMatch.group(1)!;
    final prevPunc = prevMatch.group(2)!.trim();
    final nextPunc = nextMatch.group(2)!.trim();

    // Punctuation must match (both "." or both ")").
    if (prevPunc != nextPunc) return false;

    // Try numeric comparison.
    final prevNum = int.tryParse(prevVal);
    final nextNum = int.tryParse(nextVal);
    if (prevNum != null && nextNum != null) return nextNum == prevNum + 1;

    // Try single-letter alphabetic comparison.
    if (prevVal.length == 1 && nextVal.length == 1) {
      return nextVal.codeUnitAt(0) == prevVal.codeUnitAt(0) + 1;
    }

    return false;
  }

  bool _isDigitOnlyNoise(String text) {
    if (!_digitOnlyPattern.hasMatch(text)) return false;
    return text.length <= options.digitOnlyNoiseMaxLength;
  }

  bool _shouldMergeWithPrev(
    _LogicalParagraph prev,
    _LogicalParagraph cur,
    double medianHeight,
    Page page,
  ) {
    if (medianHeight <= 0) return false;

    final prevText = prev.lines.join(' ').trimRight();
    if (prevText.isEmpty) return false;

    // Don't merge across a terminated sentence/clause.
    if (_terminalPunctuation.hasMatch(prevText)) return false;

    final curText = cur.lines.join(' ').trimLeft();
    // Don't pull a fresh list item into a continuation.
    if (_leadingListMarker.hasMatch(curText)) return false;
    // Don't pull an ALL-CAPS label into a continuation.
    if (_isAllCapsShortLabel(curText)) return false;

    final prevBox = prev.source?.boundingBox;
    final curBox = cur.source?.boundingBox;
    if (prevBox == null || curBox == null) return false;

    final prevBottom = _bboxBottom(prevBox, page);
    final curTop = _bboxTop(curBox, page);
    if (prevBottom == null || curTop == null) return false;

    // Vertical gap between the two bboxes. Negative when the boxes overlap
    // (which happens for same-baseline fragments).
    final gap = curTop - prevBottom;
    return gap <= options.paragraphMergeGapRatio * medianHeight;
  }

  /// Returns `true` when [cur] sits on the same visual baseline as [prev]
  /// but to the right of it, separated by a clear horizontal gap. This is
  /// the geometric signature of an inline form-field blank.
  ///
  /// Uses word-level bounding-box coordinates for [cur] (first word) so that
  /// multi-line blocks are evaluated by the line they actually start on,
  /// rather than by the block's aggregate bounding-box midpoint.

  /// Returns the Y-centre of the last non-empty word in [para], or `null` if
  /// no word bounding-boxes are available.
  double? _lastWordYCenter(Paragraph? para, Page page) {
    if (para == null) return null;
    final words = para.words ?? const [];
    for (var i = words.length - 1; i >= 0; i--) {
      final yc = _yCenter(words[i].boundingBox, page);
      if (yc != null) return yc;
    }
    return null;
  }

  /// Returns the right edge of the last non-empty word in [para], or `null`
  /// if no word bounding-boxes are available.
  double? _lastWordRight(Paragraph? para, Page page) {
    if (para == null) return null;
    final words = para.words ?? const [];
    for (var i = words.length - 1; i >= 0; i--) {
      final r = _bboxRight(words[i].boundingBox, page);
      if (r != null) return r;
    }
    return null;
  }

  /// Returns the minimum left x of all words in [words], or `null` if no
  /// bounding-boxes are available. Used as the paragraph's baseline left margin
  /// for intra-block form-field indent detection.
  double? _paragraphMinLeft(List<Word> words, Page page) {
    double? minLeft;
    for (final w in words) {
      final l = _bboxLeft(w.boundingBox, page);
      if (l != null) {
        minLeft = minLeft == null ? l : (l < minLeft ? l : minLeft);
      }
    }
    return minLeft;
  }

  bool _shouldMergeSameLineWithGap(
    _LogicalParagraph prev,
    _LogicalParagraph cur,
    double medianHeight,
    Page page,
  ) {
    if (medianHeight <= 0) return false;

    final prevText = prev.lines.join(' ').trimRight();
    if (prevText.isEmpty) return false;

    // Treat a sentence-terminating prev as closed, even if a same-line tail
    // happens to follow (rare for true form-field layouts).
    if (_terminalPunctuation.hasMatch(prevText)) return false;

    final curText = cur.lines.join(' ').trimLeft();
    if (curText.isEmpty) return false;
    if (_leadingListMarker.hasMatch(curText)) return false;
    if (_isAllCapsShortLabel(curText)) return false;

    final prevBox = prev.source?.boundingBox;
    final curBox = cur.source?.boundingBox;
    if (prevBox == null || curBox == null) return false;

    // Use the first word's Y-centre for cur so that multi-line blocks
    // (where the block bbox spans several visual rows) are judged by the
    // line they actually start on.
    final curWords = cur.source?.words;
    double? curYCenter;
    if (curWords != null && curWords.isNotEmpty) {
      curYCenter = _yCenter(curWords.first.boundingBox, page);
    }
    curYCenter ??= _yCenter(curBox, page);

    // When previous form-field merges have extended prev across several
    // blocks, use the Y-centre of the last visual line (from the
    // most-recently merged source's last word) rather than the original
    // source's block bbox — the original may be several lines above.
    final lastSrc = prev.lastMergedSource ?? prev.source;
    final prevYCenter =
        _lastWordYCenter(lastSrc, page) ?? _yCenter(prevBox, page);
    if (prevYCenter == null || curYCenter == null) return false;

    // Vertical-centre offset must be small (same visual line).
    final dy = (curYCenter - prevYCenter).abs();
    if (dy > options.sameLineToleranceRatio * medianHeight) return false;

    final prevRight =
        _lastWordRight(lastSrc, page) ?? _bboxRight(prevBox, page);

    // Use the first word's left edge for cur to avoid multi-line block bbox
    // giving the wrong X position (e.g. block starts at the left margin
    // across several lines, but its first word is mid-line to the right).
    double? curLeft;
    if (curWords != null && curWords.isNotEmpty) {
      curLeft = _bboxLeft(curWords.first.boundingBox, page);
    }
    curLeft ??= _bboxLeft(curBox, page);

    if (prevRight == null || curLeft == null) return false;

    // cur must be to the right of prev with a non-trivial horizontal gap.
    final gap = curLeft - prevRight;
    return gap >= options.formFieldGapRatio * medianHeight;
  }

  /// Split paragraph lines into segments, isolating short ALL-CAPS lines as
  /// their own segment so they can be styled independently.
  List<_LineSegment> _segmentLines(List<String> lines) {
    final segments = <_LineSegment>[];
    final buffer = <String>[];

    void flushBuffer() {
      if (buffer.isEmpty) return;
      segments.add(_LineSegment(buffer.join(' '), isAllCapsLabel: false));
      buffer.clear();
    }

    for (final line in lines) {
      // Whole-line ALL-CAPS short label.
      if (options.boldAllCapsLabels && _isAllCapsShortLabel(line)) {
        flushBuffer();
        segments.add(_LineSegment(line.trim(), isAllCapsLabel: true));
        continue;
      }

      // Trailing ALL-CAPS label glued onto the end of the line after a
      // sentence terminator, e.g. `... madam? COUNTESS`. Purely a typographic
      // pattern: it does not match any specific vocabulary.
      if (options.boldAllCapsLabels) {
        final match = _trailingAllCapsLabel.firstMatch(line);
        if (match != null) {
          final body = match.group(1)!;
          final label = match.group(2)!.trim();
          if (_isAllCapsShortLabel(label)) {
            buffer.add(body);
            flushBuffer();
            segments.add(_LineSegment(label, isAllCapsLabel: true));
            continue;
          }
        }
      }

      buffer.add(line);
    }
    flushBuffer();

    return segments;
  }

  bool _isAllCapsShortLabel(String line) {
    final trimmed = line.trim();
    if (trimmed.length < 2 || trimmed.length > options.allCapsLabelMaxLength) {
      return false;
    }
    var hasUpper = false;
    for (final code in trimmed.codeUnits) {
      if (code >= 0x61 && code <= 0x7A) return false; // any lower-case ascii
      if (code >= 0x41 && code <= 0x5A) hasUpper = true; // upper-case ascii
    }
    return hasUpper;
  }

  /// Matches `<sentence ending in . ? !> <ALL_CAPS_TAIL>` so the tail can be
  /// peeled off as a separate segment (typographic rule, not vocabulary).
  static final RegExp _trailingAllCapsLabel = RegExp(
    r"^(.+[\.\?\!])\s+([A-Z][A-Z' ]{1,40})\s*$",
  );

  // ---------------------------------------------------------------------------
  // Native TABLE block rendering
  // ---------------------------------------------------------------------------

  String _renderTable(Block block, Page page) {
    final paragraphs = block.paragraphs ?? const <Paragraph>[];
    if (paragraphs.isEmpty) return '';

    // Each paragraph is a row; group its words into cells by clustering on the
    // X-centre of each word's bounding box.
    final rows = <List<String>>[];
    var maxCols = 0;
    for (final paragraph in paragraphs) {
      final cells = _splitParagraphIntoCells(paragraph, page);
      if (cells.isEmpty) continue;
      rows.add(cells);
      if (cells.length > maxCols) maxCols = cells.length;
    }

    if (rows.isEmpty || maxCols == 0) return '';

    // Pad short rows with empty cells.
    for (final row in rows) {
      while (row.length < maxCols) {
        row.add('');
      }
    }

    final buffer = StringBuffer();
    buffer.writeln('| ${rows.first.map(_escapeCell).join(' | ')} |');
    buffer.writeln('| ${List.filled(maxCols, '---').join(' | ')} |');
    for (var i = 1; i < rows.length; i++) {
      buffer.writeln('| ${rows[i].map(_escapeCell).join(' | ')} |');
    }
    return buffer.toString().trimRight();
  }

  List<String> _splitParagraphIntoCells(Paragraph paragraph, Page page) {
    final words = paragraph.words ?? const <Word>[];
    if (words.isEmpty) return const [];

    final wordTexts = <String>[];
    final wordCenters = <double>[];

    for (final word in words) {
      final text = _wordText(word).trim();
      if (text.isEmpty) continue;
      final cx = _xCenter(word.boundingBox, page);
      if (cx == null) {
        // No bounding box → treat the whole paragraph as a single cell.
        return [words.map(_wordText).join(' ').trim()];
      }
      wordTexts.add(text);
      wordCenters.add(cx);
    }

    if (wordTexts.isEmpty) return const [];

    // Cluster words by X-gap. A new cell starts when the gap between
    // consecutive word centres exceeds 1.8× the median inter-word gap.
    final gaps = <double>[];
    for (var i = 1; i < wordCenters.length; i++) {
      gaps.add(wordCenters[i] - wordCenters[i - 1]);
    }
    if (gaps.isEmpty) return [wordTexts.first];

    final medianGap = _median(gaps);
    final threshold = medianGap * 1.8;

    final cells = <String>[wordTexts.first];
    for (var i = 1; i < wordTexts.length; i++) {
      final gap = wordCenters[i] - wordCenters[i - 1];
      if (gap > threshold && gap > 0) {
        cells.add(wordTexts[i]);
      } else {
        cells[cells.length - 1] = '${cells.last} ${wordTexts[i]}';
      }
    }

    return cells.length < 2 ? [cells.join(' ')] : cells;
  }

  String _escapeCell(String value) =>
      value.replaceAll('|', r'\|').replaceAll('\n', ' ').trim();

  // ---------------------------------------------------------------------------
  // PICTURE block rendering
  // ---------------------------------------------------------------------------

  String _renderPicture(Block block) {
    final box = block.boundingBox;
    final coords = _bboxCoords(box);
    if (coords == null) {
      return '![picture placeholder](#)';
    }
    return '![picture placeholder](#bbox=${coords.join(',')})';
  }

  // ---------------------------------------------------------------------------
  // Paragraph → lines (handles DetectedBreak)
  // ---------------------------------------------------------------------------

  List<String> _buildParagraphLines(Paragraph paragraph, [Page? page]) {
    final words = paragraph.words ?? const <Word>[];
    final lines = <String>[];
    final current = StringBuffer();

    // When Vision provides no break metadata (common for PDF files), detect
    // line changes from word Y-positions and inject form-field placeholders
    // at indented line transitions.
    final hasBreaks = words.any((w) => _wordBreak(w) != null);
    double? currentLineY;
    // Compute paragraph minimum-left for intra-block form-field detection
    // at LINE_BREAK transitions (and Y-geometry fallback).
    final double? paraMinLeft = (options.preserveFormFieldGaps && page != null)
        ? _paragraphMinLeft(words, page)
        : null;

    for (var i = 0; i < words.length; i++) {
      final word = words[i];
      final isLast = i == words.length - 1;
      final detectedBreak = _wordBreak(word);
      final breakType = detectedBreak?.type;
      final isPrefix = detectedBreak?.isPrefix ?? false;

      // Y-geometry fallback: when Vision provides no break metadata,
      // detect line changes from word Y-positions.
      if (!hasBreaks && page != null) {
        final wordY = _bboxTop(word.boundingBox, page);
        if (wordY != null) {
          if (currentLineY != null &&
              (wordY - currentLineY).abs() >
                  options.sameLineToleranceRatio *
                      _pageMedianSymbolHeight(page)) {
            if (current.isNotEmpty) {
              final lineText = current.toString().trimRight();
              lines.add(lineText);
              current.clear();
              // Intra-block indent check on Y-line transition: if the new
              // line starts significantly to the right of the paragraph's
              // left margin AND the previous line ended near the right
              // edge of the page, a form-field blank preceded this line.
              if (options.preserveFormFieldGaps &&
                  paraMinLeft != null &&
                  i > 0) {
                final nextLeft = _bboxLeft(word.boundingBox, page);
                if (nextLeft != null) {
                  final indent = nextLeft - paraMinLeft;
                  final medH = _pageMedianSymbolHeight(page);
                  if (indent > options.formFieldGapRatio * medH) {
                    final prevRight = _bboxRight(
                      words[i - 1].boundingBox,
                      page,
                    );
                    final pageW = page.width.toDouble();
                    if (prevRight != null && (prevRight / pageW) > 0.85) {
                      lines.add(options.formFieldPlaceholder);
                    }
                  }
                }
              }
            }
            currentLineY = wordY;
          }
          currentLineY ??= wordY;
        }
      }

      if (isPrefix && breakType == BreakType.LINE_BREAK) {
        if (current.isNotEmpty) {
          lines.add(current.toString().trimRight());
          current.clear();
        }
      }

      var text = _wordText(word);

      if (breakType == BreakType.HYPHEN && !isLast) {
        // Strip a trailing hyphen and join with the next word.
        if (text.endsWith('-')) {
          text = text.substring(0, text.length - 1);
        }
        current.write(text);
        continue;
      }

      current.write(text);

      if (!isPrefix) {
        switch (breakType) {
          case BreakType.SPACE:
            current.write(' ');
            break;
          case BreakType.EOL_SURE_SPACE:
            // EOL_SURE_SPACE marks a visual line end. Check if
            // the geometry indicates a form-field gap.
            if (paraMinLeft != null && page != null && !isLast) {
              final nxWord = words[i + 1];
              final nxLeft = _bboxLeft(nxWord.boundingBox, page);
              final crRight = _bboxRight(word.boundingBox, page);
              final pgW = page.width.toDouble();
              if (nxLeft != null &&
                  crRight != null &&
                  (crRight / pgW) > 0.85 &&
                  (nxLeft - paraMinLeft) >
                      options.formFieldGapRatio *
                          _pageMedianSymbolHeight(page)) {
                lines.add(current.toString().trimRight());
                current.clear();
                lines.add(options.formFieldPlaceholder);
              } else {
                current.write(' ');
              }
            } else {
              current.write(' ');
            }
            break;
          case BreakType.LINE_BREAK:
            lines.add(current.toString().trimRight());
            current.clear();
            // Intra-block form-field gap: if the next word starts
            // significantly right of the paragraph left margin and
            // this word ended near the page right edge, inject placeholder.
            if (paraMinLeft != null && page != null && !isLast) {
              final nextWord = words[i + 1];
              final nextLeft = _bboxLeft(nextWord.boundingBox, page);
              if (nextLeft != null) {
                final indent = nextLeft - paraMinLeft;
                final medH = _pageMedianSymbolHeight(page);
                if (indent > options.formFieldGapRatio * medH) {
                  final curRight = _bboxRight(word.boundingBox, page);
                  final pageW = page.width.toDouble();
                  if (curRight != null && (curRight / pageW) > 0.85) {
                    lines.add(options.formFieldPlaceholder);
                  }
                }
              }
            }
            break;
          case BreakType.HYPHEN:
          case BreakType.UNKNOWN:
          case null:
            // No break info — add a space between words (common for PDFs).
            if (!isLast) current.write(' ');
            break;
        }
      }
    }

    if (current.isNotEmpty) {
      lines.add(current.toString().trimRight());
    }

    return lines.where((l) => l.isNotEmpty).map(_collapsePunctSpaces).toList();
  }

  /// Collapse spurious spaces around punctuation produced when Vision
  /// emits punctuation marks as standalone "words" with SPACE breaks.
  static final _preSpacePunct = RegExp(r' ([,\.;:!?\)\]/])');
  static final _postSpacePunct = RegExp(r'([\(\[/]) ');
  String _collapsePunctSpaces(String s) {
    s = s.replaceAllMapped(_preSpacePunct, (m) => m.group(1)!);
    s = s.replaceAllMapped(_postSpacePunct, (m) => '${m.group(1)}');
    return s;
  }

  String _wordText(Word word) {
    final symbols = word.symbols ?? const <gv.Symbol>[];
    final buffer = StringBuffer();
    for (final symbol in symbols) {
      buffer.write(symbol.text ?? '');
    }
    return buffer.toString();
  }

  // ---------------------------------------------------------------------------
  // Heuristics: list / checkbox / header
  // ---------------------------------------------------------------------------

  static final RegExp _bulletPattern = RegExp(
    r'^\s*([\u2022\u2023\u2043\u25E6\u00B7\u25CF\u2010\u2012\u2013\u2014\-\*])\s+(.*)$',
  );
  static final RegExp _orderedPattern = RegExp(
    r'^\s*(\d+|[a-zA-Z])[\.\)]\s+(.*)$',
  );
  static final RegExp _checkboxOpen = RegExp(r'^\s*(?:\u2610|\[\s?\])\s*(.*)$');
  static final RegExp _checkboxClosed = RegExp(
    r'^\s*(?:\u2611|\u2612|\[\s*[xX\u2713]\s*\])\s*(.*)$',
  );

  String? _matchCheckbox(String text) {
    final closed = _checkboxClosed.firstMatch(text);
    if (closed != null) return '- [x] ${closed.group(1)!.trim()}';
    final open = _checkboxOpen.firstMatch(text);
    if (open != null) return '- [ ] ${open.group(1)!.trim()}';
    return null;
  }

  String? _matchList(String text) {
    final bullet = _bulletPattern.firstMatch(text);
    if (bullet != null) return '- ${bullet.group(2)!.trim()}';
    final ordered = _orderedPattern.firstMatch(text);
    if (ordered != null) {
      final marker = ordered.group(1)!;
      final body = ordered.group(2)!.trim();
      // Preserve the original marker. Numeric markers will be re-rendered as
      // an ordered list by Markdown viewers; alphabetic markers fall back to
      // plain text since CommonMark has no native lettered-list syntax.
      return '$marker. $body';
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Geometry helpers
  // ---------------------------------------------------------------------------

  /// Sort logical paragraphs by their vertical top position on the page.
  /// Paragraphs on the same visual line (Y within half a median symbol
  /// height) are sub-sorted by the X position of their first word for
  /// correct reading order — this avoids the ambiguity of multi-line
  /// paragraph bounding boxes whose left edge reflects a later wrap line.
  /// Paragraphs without a bounding box retain their relative order at the end.
  List<_LogicalParagraph> _sortByYPosition(
    List<_LogicalParagraph> input,
    Page page,
  ) {
    final medH = _pageMedianSymbolHeight(page);
    // Compute a stable (index, yTop, xLeft) for each paragraph.
    final indexed = <_IndexedY>[];
    for (var i = 0; i < input.length; i++) {
      final lp = input[i];
      final yTop = _bboxTop(lp.source?.boundingBox, page);
      // Prefer the first word's left edge for X positioning — more reliable
      // than the paragraph bbox for multi-line paragraphs.
      double? xLeft;
      final words = lp.source?.words;
      if (words != null && words.isNotEmpty) {
        xLeft = _bboxLeft(words.first.boundingBox, page);
      }
      xLeft ??= _bboxLeft(lp.source?.boundingBox, page);
      indexed.add(_IndexedY(i, yTop ?? double.infinity, xLeft ?? 0));
    }
    // Stable sort: primary by yTop, secondary by xLeft for same-line items.
    final yTolerance = medH > 0 ? medH * 0.5 : 0.0;
    indexed.sort((a, b) {
      final dy = a.yTop - b.yTop;
      // If on the same visual line, sort left-to-right.
      if (dy.abs() <= yTolerance) {
        final cx = a.xLeft.compareTo(b.xLeft);
        if (cx != 0) return cx;
        return a.index.compareTo(b.index);
      }
      final cmp = a.yTop.compareTo(b.yTop);
      if (cmp != 0) return cmp;
      return a.index.compareTo(b.index);
    });
    return indexed.map((e) => input[e.index]).toList();
  }

  double _pageMedianSymbolHeight(Page page) {
    final heights = <double>[];
    for (final block in page.blocks ?? const <Block>[]) {
      if (block.blockType != BlockType.TEXT &&
          block.blockType != BlockType.UNKNOWN) {
        continue;
      }
      for (final paragraph in block.paragraphs ?? const <Paragraph>[]) {
        for (final word in paragraph.words ?? const <Word>[]) {
          // Symbol-level bounding boxes are typically null in Vision's PDF
          // file-annotation responses, so fall back to the word bbox when
          // necessary.
          var added = false;
          for (final symbol in word.symbols ?? const <gv.Symbol>[]) {
            final h = _bboxHeight(symbol.boundingBox, page);
            if (h != null && h > 0) {
              heights.add(h);
              added = true;
            }
          }
          if (!added) {
            final h = _bboxHeight(word.boundingBox, page);
            if (h != null && h > 0) heights.add(h);
          }
        }
      }
    }
    return heights.isEmpty ? 0 : _median(heights);
  }

  double _paragraphMeanSymbolHeight(Paragraph? paragraph, Page page) {
    if (paragraph == null) return 0;
    final heights = <double>[];
    for (final word in paragraph.words ?? const <Word>[]) {
      var added = false;
      for (final symbol in word.symbols ?? const <gv.Symbol>[]) {
        final h = _bboxHeight(symbol.boundingBox, page);
        if (h != null && h > 0) {
          heights.add(h);
          added = true;
        }
      }
      if (!added) {
        final h = _bboxHeight(word.boundingBox, page);
        if (h != null && h > 0) heights.add(h);
      }
    }
    if (heights.isEmpty) return 0;
    final sum = heights.reduce((a, b) => a + b);
    return sum / heights.length;
  }

  double _blockMeanSymbolHeight(Block block, Page page) {
    final heights = <double>[];
    for (final paragraph in block.paragraphs ?? const <Paragraph>[]) {
      final h = _paragraphMeanSymbolHeight(paragraph, page);
      if (h > 0) heights.add(h);
    }
    if (heights.isEmpty) return 0;
    final sum = heights.reduce((a, b) => a + b);
    return sum / heights.length;
  }

  double? _bboxHeight(BoundingPoly? box, Page page) {
    final top = _bboxTop(box, page);
    final bottom = _bboxBottom(box, page);
    if (top == null || bottom == null) return null;
    final h = (bottom - top).abs();
    return h > 0 ? h : null;
  }

  double? _xCenter(BoundingPoly? box, Page page) {
    final left = _bboxLeft(box, page);
    final right = _bboxRight(box, page);
    if (left == null || right == null) return null;
    return (left + right) / 2.0;
  }

  List<int>? _bboxCoords(BoundingPoly? box) {
    if (box == null) return null;
    if (box.vertices.length >= 4) {
      final v = box.vertices;
      return [v[0].x, v[0].y, v[2].x, v[2].y];
    }
    return null;
  }

  double _median(List<double> values) {
    final sorted = [...values]..sort();
    final n = sorted.length;
    if (n == 0) return 0;
    if (n.isOdd) return sorted[n ~/ 2];
    return (sorted[n ~/ 2 - 1] + sorted[n ~/ 2]) / 2.0;
  }

  /// Returns the [DetectedBreak] associated with [word], falling back to the
  /// trailing symbol when [Word.property] does not carry one.
  ///
  /// Vision typically attaches the break to the **last [gv.Symbol]** of a
  /// word rather than to the word itself, so reading only `word.property` (as
  /// the original implementation did) caused every word to be concatenated
  /// without separators.
  DetectedBreak? _wordBreak(Word word) {
    final fromWord = word.property?.detectedBreak;
    if (fromWord != null) return fromWord;
    final symbols = word.symbols;
    if (symbols == null || symbols.isEmpty) return null;
    return symbols.last.property?.detectedBreak;
  }

  /// Returns `true` when [block] is geometrically positioned in the running
  /// header or footer band of [page].
  ///
  /// Two regions are considered chrome:
  ///
  ///  * the strict band defined by [MarkdownOptions.runningHeaderBand] /
  ///    [MarkdownOptions.runningFooterBand] — anything in here is chrome
  ///    regardless of size,
  ///  * the extended [MarkdownOptions.chromeBand] band — only treated as
  ///    chrome when the block is short (≤ [MarkdownOptions.maxChromeWords]
  ///    words). This catches page numbers / running titles that Vision
  ///    sometimes places just outside the strict band (rule D).
  ///
  /// All checks are coordinate- and word-count-based; no text matching.
  bool _isBlockChrome(Block block, Page page, double medianHeight) {
    if (_bboxInBand(
      block.boundingBox,
      page,
      options.runningHeaderBand,
      options.runningFooterBand,
    )) {
      return true;
    }
    if (_bboxInBand(
      block.boundingBox,
      page,
      options.chromeBand,
      options.chromeBand,
    )) {
      if (_blockWordCount(block) > options.maxChromeWords) return false;
      // Typographic gate: extended-band chrome must also be smaller than
      // body text. Skipped when median height is unknown.
      if (medianHeight > 0) {
        final h = _blockMeanSymbolHeight(block, page);
        if (h > 0 && h > options.chromeMaxSymbolRatio * medianHeight) {
          return false;
        }
      }
      return true;
    }
    return false;
  }

  /// Paragraph-level variant of [_isBlockChrome] used when Vision has grouped
  /// a chrome paragraph into a larger content block.
  bool _isParagraphChrome(Paragraph paragraph, Page page, double medianHeight) {
    if (_bboxInBand(
      paragraph.boundingBox,
      page,
      options.runningHeaderBand,
      options.runningFooterBand,
    )) {
      return true;
    }
    if (_bboxInBand(
      paragraph.boundingBox,
      page,
      options.chromeBand,
      options.chromeBand,
    )) {
      if (_paragraphWordCount(paragraph) > options.maxChromeWords) return false;
      // Typographic gate: page-number footers / breadcrumb headers are
      // typographically smaller than body text.
      if (medianHeight > 0) {
        final h = _paragraphMeanSymbolHeight(paragraph, page);
        if (h > 0 && h > options.chromeMaxSymbolRatio * medianHeight) {
          return false;
        }
      }
      return true;
    }
    return false;
  }

  bool _bboxInBand(
    BoundingPoly? box,
    Page page,
    double headerBand,
    double footerBand,
  ) {
    final pageHeight = page.height.toDouble();
    if (pageHeight <= 0) return false;
    final top = _bboxTop(box, page);
    final bottom = _bboxBottom(box, page);
    if (top == null || bottom == null) return false;

    final headerLimit = pageHeight * headerBand;
    if (bottom <= headerLimit) return true;

    final footerLimit = pageHeight * (1.0 - footerBand);
    if (top >= footerLimit) return true;

    return false;
  }

  int _blockWordCount(Block block) {
    var count = 0;
    for (final paragraph in block.paragraphs ?? const <Paragraph>[]) {
      count += _paragraphWordCount(paragraph);
    }
    return count;
  }

  int _paragraphWordCount(Paragraph paragraph) {
    final words = paragraph.words ?? const <Word>[];
    var count = 0;
    for (final word in words) {
      if (_wordText(word).trim().isNotEmpty) count++;
    }
    return count;
  }

  // The Vision PDF file-annotation responses populate only
  // `normalizedVertices` (vertices is empty), while image annotation responses
  // populate pixel `vertices`. The bbox helpers below transparently support
  // both representations and scale normalized coordinates by the page
  // dimensions so all downstream geometry is in pixels.

  double? _bboxTop(BoundingPoly? box, Page page) {
    if (box == null) return null;
    if (box.vertices.length >= 4 &&
        box.vertices.any((v) => v.x != 0 || v.y != 0)) {
      final ys = box.vertices.map((v) => v.y.toDouble()).toList();
      return ys.reduce((a, b) => a < b ? a : b);
    }
    if (box.normalizedVertices.length >= 4) {
      final h = page.height.toDouble();
      if (h <= 0) return null;
      final ys = box.normalizedVertices.map((v) => v.y * h).toList();
      return ys.reduce((a, b) => a < b ? a : b);
    }
    return null;
  }

  double? _bboxBottom(BoundingPoly? box, Page page) {
    if (box == null) return null;
    if (box.vertices.length >= 4 &&
        box.vertices.any((v) => v.x != 0 || v.y != 0)) {
      final ys = box.vertices.map((v) => v.y.toDouble()).toList();
      return ys.reduce((a, b) => a > b ? a : b);
    }
    if (box.normalizedVertices.length >= 4) {
      final h = page.height.toDouble();
      if (h <= 0) return null;
      final ys = box.normalizedVertices.map((v) => v.y * h).toList();
      return ys.reduce((a, b) => a > b ? a : b);
    }
    return null;
  }

  double? _bboxLeft(BoundingPoly? box, Page page) {
    if (box == null) return null;
    if (box.vertices.length >= 4 &&
        box.vertices.any((v) => v.x != 0 || v.y != 0)) {
      final xs = box.vertices.map((v) => v.x.toDouble()).toList();
      return xs.reduce((a, b) => a < b ? a : b);
    }
    if (box.normalizedVertices.length >= 4) {
      final w = page.width.toDouble();
      if (w <= 0) return null;
      final xs = box.normalizedVertices.map((v) => v.x * w).toList();
      return xs.reduce((a, b) => a < b ? a : b);
    }
    return null;
  }

  double? _bboxRight(BoundingPoly? box, Page page) {
    if (box == null) return null;
    if (box.vertices.length >= 4 &&
        box.vertices.any((v) => v.x != 0 || v.y != 0)) {
      final xs = box.vertices.map((v) => v.x.toDouble()).toList();
      return xs.reduce((a, b) => a > b ? a : b);
    }
    if (box.normalizedVertices.length >= 4) {
      final w = page.width.toDouble();
      if (w <= 0) return null;
      final xs = box.normalizedVertices.map((v) => v.x * w).toList();
      return xs.reduce((a, b) => a > b ? a : b);
    }
    return null;
  }

  double? _yCenter(BoundingPoly? box, Page page) {
    final top = _bboxTop(box, page);
    final bottom = _bboxBottom(box, page);
    if (top == null || bottom == null) return null;
    return (top + bottom) / 2.0;
  }
}

/// Internal record describing one renderable segment of paragraph text.
class _LineSegment {
  final String text;
  final bool isAllCapsLabel;
  const _LineSegment(this.text, {required this.isAllCapsLabel});
}

/// Internal record bundling a Vision [Paragraph] with the rendered lines
/// produced from it. The [source] may be null for synthetic paragraphs that
/// the converter creates while coalescing fragments.
class _LogicalParagraph {
  final Paragraph? source;
  final List<String> lines;

  /// Source whose last-word bounding-box Y-centre approximates the effective
  /// Y-centre of the last visual line, updated after form-field merges so
  /// subsequent same-line gap checks reflect the merged extent.
  Paragraph? lastMergedSource;

  _LogicalParagraph(this.source, List<String> lines) : lines = List.of(lines);

  factory _LogicalParagraph.synthetic(List<String> lines) =>
      _LogicalParagraph(null, lines);
}

/// Internal record used by [MarkdownConverter._pairColumnAlignedMarkers] to
/// keep a candidate body's input index alongside its sort-key Y (the body's
/// top edge, used for ordered pairing — see method docs) so candidates can
/// be sorted by Y without re-computing geometry.
class _BodyCandidate {
  final int index;
  final double yKey;
  const _BodyCandidate(this.index, this.yKey);
}

/// Internal record used by [MarkdownConverter._sortByYPosition] to associate
/// an original index with its Y-top and X-left coordinates for stable sorting.
class _IndexedY {
  final int index;
  final double yTop;
  final double xLeft;
  const _IndexedY(this.index, this.yTop, this.xLeft);
}

/// Internal record pairing a word's Y-top coordinate with its text, used by
/// [MarkdownConverter._splitParagraphByWordY].
class _WordYData {
  final double yTop;
  final String text;
  const _WordYData(this.yTop, this.text);
}

/// Internal record used by [MarkdownConverter._promoteTextTables] to track
/// a contiguous range of table-candidate paragraphs and the Y-rows within.
class _TableRange {
  final int start;
  final int end; // exclusive
  final List<List<int>> rows;
  const _TableRange(this.start, this.end, this.rows);
}

/// Convenience extension that produces markdown directly from a
/// [FullTextAnnotation].
extension FullTextAnnotationMarkdown on FullTextAnnotation {
  /// Render this annotation as markdown using [MarkdownConverter].
  String toMarkdown({MarkdownOptions options = const MarkdownOptions()}) =>
      MarkdownConverter(options: options).convert(this);
}
