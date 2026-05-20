/// Configuration for [MarkdownConverter].
///
/// Controls which structural elements are detected and emitted when converting
/// a `FullTextAnnotation` (the result of `DOCUMENT_TEXT_DETECTION`) into
/// markdown.
class MarkdownOptions {
  /// Emit a level-1 markdown header (`# Page N`) at the start of every page.
  final bool emitPageHeaders;

  /// Emit a horizontal rule (`---`) between consecutive pages.
  final bool emitPageSeparators;

  /// Detect headers using a relative-symbol-height heuristic and emit
  /// `#`, `##` or `###` prefixes.
  final bool detectHeaders;

  /// Detect bullet and ordered lists from leading characters and emit
  /// markdown list syntax.
  final bool detectLists;

  /// Detect checkbox glyphs / `[ ]` / `[x]` patterns and emit GitHub-flavoured
  /// task-list items.
  final bool detectCheckboxes;

  /// Emit a placeholder image link for `BlockType.PICTURE` blocks rather than
  /// silently dropping them.
  final bool emitImagePlaceholders;

  /// Strip blocks whose bounding box lies entirely within the top
  /// [runningHeaderBand] or bottom [runningFooterBand] fraction of the page.
  ///
  /// This is a purely geometric heuristic that removes repeating chrome such
  /// as page-number footers and breadcrumb navigation headers without
  /// relying on the textual content of the document.
  final bool stripRunningHeaders;

  /// Top-of-page fraction used by [stripRunningHeaders]. A block is treated as
  /// a running header when its bounding box fits entirely within
  /// `[0, page.height * runningHeaderBand]`.
  final double runningHeaderBand;

  /// Bottom-of-page fraction used by [stripRunningHeaders]. A block is treated
  /// as a running footer when its bounding box fits entirely within
  /// `[page.height * (1 - runningFooterBand), page.height]`.
  final double runningFooterBand;

  /// When a paragraph contains a short, fully upper-case line (typographic
  /// label), split it from the surrounding text and emit it as `**LABEL**`.
  ///
  /// This is a structural typography rule — it does not match any specific
  /// vocabulary from the source document.
  final bool boldAllCapsLabels;

  /// Maximum character length (after trimming) that a line may have to be
  /// considered an ALL-CAPS label by [boldAllCapsLabels].
  final int allCapsLabelMaxLength;

  /// Merge consecutive paragraphs that are vertically adjacent and where the
  /// previous paragraph does not end in terminal punctuation (`.`, `?`, `!`,
  /// `:`, `;`).
  ///
  /// Repairs paragraph fragmentation introduced when Vision splits a single
  /// visual line at a blank form-field, or when a logical paragraph spans
  /// multiple `Paragraph` blocks. Pure structural rule — no vocabulary.
  final bool mergeFragmentedParagraphs;

  /// Maximum vertical gap, expressed as a multiple of the page median symbol
  /// height, between two paragraphs that may still be considered part of the
  /// same logical paragraph for [mergeFragmentedParagraphs].
  final double paragraphMergeGapRatio;

  /// Absorb stand-alone list-marker paragraphs (e.g. `3.`, `A.`) into the
  /// paragraph that immediately follows them.
  ///
  /// Helps reading-order recovery when Vision returns the marker column and
  /// the body column as separate paragraphs.
  final bool absorbOrphanListMarkers;

  /// Drop digit-only paragraphs whose text length is at most
  /// [digitOnlyNoiseMaxLength] (typically vertical numeral columns produced by
  /// blank form fields).
  final bool dropDigitOnlyNoise;

  /// Maximum character length used by [dropDigitOnlyNoise].
  final int digitOnlyNoiseMaxLength;

  /// Extended Y-band fraction used to identify chrome paragraphs/blocks that
  /// don't fully fit inside [runningHeaderBand]/[runningFooterBand] but still
  /// look like running chrome (very few words near the top/bottom of the
  /// page). Matches a block when its bounding box top is within
  /// `pageHeight * chromeBand` of the top/bottom edge **and** the block has
  /// at most [maxChromeWords] words.
  final double chromeBand;

  /// Maximum word count for the extended-band chrome rule. See [chromeBand].
  final int maxChromeWords;

  /// Maximum paragraph mean symbol height, expressed as a fraction of the
  /// page median symbol height, for a paragraph to be eligible as
  /// extended-band chrome. Page-number footers and breadcrumb headers are
  /// typographically smaller than body text; this typographic gate prevents
  /// short body fragments near the page edges from being misclassified as
  /// chrome. Set to a value `> 1` to disable the gate.
  final double chromeMaxSymbolRatio;

  /// Pair stand-alone list-marker paragraphs to their bodies across
  /// non-adjacent positions in the page-level paragraph stream when the
  /// markers form a vertical column.
  ///
  /// Repairs two-column "marker | body" layouts where Vision emits all
  /// markers in a left strip and all bodies in a right strip rather than
  /// interleaving them. Pure structural rule — no vocabulary.
  ///
  /// Off by default. Enable only after validating against your document
  /// fixtures, since column detection is geometrically more aggressive than
  /// the in-stream [absorbOrphanListMarkers] rule.
  final bool pairColumnAlignedMarkers;

  /// Maximum horizontal spread of a candidate marker column, expressed as a
  /// fraction of page width. Wider strips are not treated as a column and
  /// pairing is skipped. See [pairColumnAlignedMarkers].
  final double markerColumnWidthRatio;

  /// Minimum number of orphan markers that must share a column before
  /// [pairColumnAlignedMarkers] fires. Smaller groups fall back to the
  /// in-stream [absorbOrphanListMarkers] rule.
  final int markerColumnMinSize;

  /// Maximum vertical-centre offset between a column marker and a candidate
  /// body, expressed as a multiple of page median symbol height. Used by
  /// [pairColumnAlignedMarkers].
  final double markerPairYToleranceRatio;

  /// Maximum vertical gap, in units of page median symbol height, between
  /// two consecutive markers that may still be considered part of the same
  /// marker column cluster. Larger gaps split the column into separate
  /// clusters which are paired independently. Used by
  /// [pairColumnAlignedMarkers].
  final double markerColumnMaxGapRatio;

  /// When two consecutive paragraphs are vertically aligned on the same
  /// baseline (their Y centres differ by less than
  /// [sameLineToleranceRatio] times the page median symbol height) and
  /// separated by a clear horizontal gap, merge them and emit
  /// [formFieldPlaceholder] in place of the gap.
  ///
  /// Repairs the typical contract layout where a single visual line is
  /// interrupted by underline-style fill-in fields (e.g. `THIS AGREEMENT
  /// made and entered into this ___ day of ___, 20___ by and between …`),
  /// preserving the blank as a visible placeholder rather than dropping it.
  final bool preserveFormFieldGaps;

  /// Markdown rendered into a same-line gap when [preserveFormFieldGaps]
  /// triggers. Defaults to a short underline-style placeholder. Backslash-
  /// escapes the underscores so markdown viewers do not interpret them as
  /// emphasis.
  final String formFieldPlaceholder;

  /// Minimum horizontal gap (in units of page median symbol height) between
  /// two same-baseline paragraphs that qualifies them for
  /// [preserveFormFieldGaps] merging. Smaller gaps are treated as ordinary
  /// inter-word spacing.
  final double formFieldGapRatio;

  /// Maximum vertical-centre offset, expressed as a multiple of page median
  /// symbol height, for two paragraphs to be considered on the same visual
  /// line by [preserveFormFieldGaps].
  final double sameLineToleranceRatio;

  /// Symbol-height ratio (paragraph mean / page median) at or above which a
  /// paragraph is treated as a level-1 header.
  final double headerH1Ratio;

  /// Symbol-height ratio at or above which a paragraph is treated as a level-2
  /// header (and below [headerH1Ratio]).
  final double headerH2Ratio;

  /// Symbol-height ratio at or above which a paragraph is treated as a level-3
  /// header (and below [headerH2Ratio]).
  final double headerH3Ratio;

  /// Promote clusters of narrow TEXT paragraphs that share a Y-baseline
  /// and occupy distinct X positions into a markdown table.
  ///
  /// Repairs the common Vision artefact where a visual table is returned as
  /// multiple `BlockType.TEXT` blocks (one per cell or column) rather than a
  /// native `BlockType.TABLE`. Pure geometric rule — no vocabulary.
  ///
  /// Off by default. Enable together with [pairColumnAlignedMarkers] for
  /// documents that contain both two-column lists and inline tables.
  final bool promoteTextToTable;

  /// Maximum bbox width, expressed as a fraction of page width, for a
  /// paragraph to be considered a table-cell candidate by
  /// [promoteTextToTable]. Paragraphs wider than this are treated as body
  /// text. Default 0.4 (40% of page width).
  final double tableCellMaxWidthRatio;

  /// Maximum Y-top difference, expressed as a multiple of page median symbol
  /// height, for two paragraphs to be considered on the same table row by
  /// [promoteTextToTable].
  final double tableRowYToleranceRatio;

  /// Minimum number of distinct X-position columns required to form a table
  /// row. Default 2.
  final int tableMinColumns;

  /// Maximum number of words in a single paragraph for it to be considered a
  /// table-cell candidate. Paragraphs with more words are excluded from table
  /// promotion. Default 15.
  final int tableCellMaxWords;

  const MarkdownOptions({
    this.emitPageHeaders = false,
    this.emitPageSeparators = true,
    this.detectHeaders = true,
    this.detectLists = true,
    this.detectCheckboxes = true,
    this.emitImagePlaceholders = true,
    this.stripRunningHeaders = true,
    this.runningHeaderBand = 0.08,
    this.runningFooterBand = 0.08,
    this.boldAllCapsLabels = true,
    this.allCapsLabelMaxLength = 40,
    this.mergeFragmentedParagraphs = true,
    this.paragraphMergeGapRatio = 1.5,
    this.absorbOrphanListMarkers = true,
    this.dropDigitOnlyNoise = true,
    this.digitOnlyNoiseMaxLength = 6,
    this.chromeBand = 0.10,
    this.maxChromeWords = 3,
    this.chromeMaxSymbolRatio = 0.85,
    this.pairColumnAlignedMarkers = false,
    this.markerColumnWidthRatio = 0.05,
    this.markerColumnMinSize = 2,
    this.markerPairYToleranceRatio = 0.7,
    this.markerColumnMaxGapRatio = 5.0,
    this.preserveFormFieldGaps = true,
    this.formFieldPlaceholder = r'\_\_\_\_\_',
    this.formFieldGapRatio = 1.0,
    this.sameLineToleranceRatio = 0.5,
    this.headerH1Ratio = 1.6,
    this.headerH2Ratio = 1.3,
    this.headerH3Ratio = 1.1,
    this.promoteTextToTable = false,
    this.tableCellMaxWidthRatio = 0.4,
    this.tableRowYToleranceRatio = 0.8,
    this.tableMinColumns = 2,
    this.tableCellMaxWords = 4,
  });
}
