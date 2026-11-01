import 'package:flutter/material.dart';
import '../icons/app_icons.dart';
import '../models/gentle_read.dart';
import '../theme/tokens.dart';

/// Home-screen gentle read. The section header stays put.
/// When [reads] has more than one item, the card slides between them.
class GentleReadPost extends StatefulWidget {
  final GentleRead read;
  final AppTokens t;
  final Uri baseUri;
  final ValueChanged<Uri> onOpenLink;
  final bool loading;

  /// Today's three reads. A single [read] is shown when this is empty.
  final List<GentleRead> reads;
  final int pageIndex;
  final ValueChanged<int>? onPageChanged;

  /// Portrait photo, close to an Instagram 4:5 frame.
  static const double portraitAspectRatio = 4 / 5;
  static const int readsPerDay = 3;

  const GentleReadPost({
    super.key,
    required this.read,
    required this.t,
    required this.baseUri,
    required this.onOpenLink,
    this.loading = false,
    this.reads = const [],
    this.pageIndex = 0,
    this.onPageChanged,
  });

  @override
  State<GentleReadPost> createState() => _GentleReadPostState();
}

class _GentleReadPostState extends State<GentleReadPost> {
  PageController? _pages;
  final Map<int, double> _heights = {};
  double _slidePage = 0;
  int? _expandedIndex;
  AppTokens get t => widget.t;

  List<GentleRead> get _reads =>
      widget.reads.isNotEmpty ? widget.reads : [widget.read];

  bool get _canSlide => _reads.length > 1;

  @override
  void initState() {
    super.initState();
    _attachController();
  }

  @override
  void didUpdateWidget(covariant GentleReadPost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reads.length != widget.reads.length) {
      _pages?.removeListener(_onSlide);
      _pages?.dispose();
      _pages = null;
      _heights.clear();
      _attachController();
    }
  }

  void _attachController() {
    if (!_canSlide) return;
    final initial = widget.pageIndex.clamp(0, _reads.length - 1);
    _slidePage = initial.toDouble();
    _pages = PageController(initialPage: initial)..addListener(_onSlide);
  }

  void _onSlide() {
    final page = _pages?.page;
    if (page == null || (page - _slidePage).abs() < 0.001) return;
    setState(() => _slidePage = page);
  }

  @override
  void dispose() {
    _pages?.removeListener(_onSlide);
    _pages?.dispose();
    super.dispose();
  }

  void _selectPage(int index) {
    final controller = _pages;
    if (controller == null || !controller.hasClients) return;
    controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  void _rememberHeight(int index, double height) {
    final previous = _heights[index];
    if (previous != null && (previous - height).abs() < 0.5) return;
    setState(() => _heights[index] = height);
  }

  double get _viewportHeight {
    if (_heights.isEmpty) return 1;
    final last = _reads.length - 1;
    final page = _slidePage.clamp(0, last.toDouble());
    final lower = page.floor().clamp(0, last);
    final upper = page.ceil().clamp(0, last);
    final start = _heights[lower] ?? _heights[upper] ?? 1;
    final end = _heights[upper] ?? start;
    return start + (end - start) * (page - lower);
  }

  @override
  Widget build(BuildContext context) {
    final reads = _reads;
    final index = _canSlide ? _slidePage.round().clamp(0, reads.length - 1) : 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionHeader(),
          const SizedBox(height: 12),
          if (_canSlide) ...[
            _measurers(reads),
            SizedBox(
              height: _viewportHeight,
              child: PageView.builder(
                controller: _pages,
                itemCount: reads.length,
                onPageChanged: widget.onPageChanged,
                itemBuilder: (context, page) => _card(reads[page], page),
              ),
            ),
          ] else
            _card(reads.first, 0),
          if (_canSlide) ...[
            const SizedBox(height: 14),
            _dots(index, reads.length),
            const SizedBox(height: 8),
            Text(
              '${index + 1} of ${reads.length} · tap dots to browse',
              textAlign: TextAlign.center,
              style: AppTypography.lato400(12, t.muted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _measurers(List<GentleRead> reads) {
    return SizedBox(
      height: 0,
      child: OverflowBox(
        alignment: Alignment.topCenter,
        minHeight: 0,
        maxHeight: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < reads.length; i++)
              _ReportHeight(
                onHeight: (height) => _rememberHeight(i, height),
                child: _card(reads[i], i),
              ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader() {
    return Row(
      children: [
        AppIcons.book(c: t.muted, s: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'GENTLE READ',
            style: AppTypography.sectionLabel(t.muted),
          ),
        ),
        if (widget.loading)
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: t.accent),
          ),
      ],
    );
  }

  Widget _dots(int index, int count) {
    final active = t == AppTokens.day ? const Color(0xFFC4615A) : t.accent;
    final idle = t == AppTokens.day ? const Color(0xFFE8D6D0) : t.border;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          GestureDetector(
            key: ValueKey('gentle-read-dot-$i'),
            onTap: () => _selectPage(i),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                width: i == index ? 20 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: i == index ? active : idle,
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _card(GentleRead read, int index) {
    final image = _webUri(read.imageUrl);
    final link = _webUri(read.linkUrl);
    final hasTitle = read.title.trim().isNotEmpty;
    final hasBody = read.body.trim().isNotEmpty;
    final hasCopy = hasTitle || hasBody;
    final day = t == AppTokens.day;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: day ? 0.06 : 0.28),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (image != null) _photo(image, read.imageAlt),
              if (hasCopy || link != null)
                AnimatedOpacity(
                  opacity: widget.loading ? 0.45 : 1,
                  duration: const Duration(milliseconds: 180),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      22,
                      image == null ? 22 : 16,
                      22,
                      20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (image == null && hasBody) ...[
                          Text(
                            _storyKicker(read.body),
                            style: AppTypography.lato700(
                              11,
                              day ? const Color(0xFFC47D72) : t.accent,
                              letterSpacing: 1.25,
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                        if (hasTitle) _title(read.title),
                        if (hasBody)
                          _caption(
                            read.body,
                            index,
                            spacedParagraphs: image == null,
                          ),
                        if (link != null) ...[
                          if (hasCopy) const SizedBox(height: 10),
                          _link(read, link),
                        ],
                        if (hasCopy)
                          Text(
                            'Me Time Club · ${_minutes(read)} min',
                            style: AppTypography.lato400(12, t.muted),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Uri? _webUri(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = Uri.tryParse(value.trim());
    if (parsed == null) return null;
    final resolved = widget.baseUri.resolveUri(parsed);
    if ((resolved.scheme != 'http' && resolved.scheme != 'https') ||
        resolved.host.isEmpty) {
      return null;
    }
    return resolved;
  }

  int _wordCount(String text) {
    return text
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;
  }

  int _minutes(GentleRead read) {
    final words = _wordCount('${read.title} ${read.body}');
    if (words == 0) return 1;
    return (words / 180).ceil().clamp(1, 30);
  }

  /// Text-only reads are labeled by length, as in "100-WORD STORY".
  String _storyKicker(String body) {
    final words = _wordCount(body);
    final rounded =
        words == 0 ? 10 : ((words / 10).round() * 10).clamp(10, 9990);
    return '$rounded-WORD STORY';
  }

  Widget _photo(Uri image, String? alt) {
    return AspectRatio(
      aspectRatio: GentleReadPost.portraitAspectRatio,
      child: Image.network(
        image.toString(),
        fit: BoxFit.cover,
        semanticLabel: alt ?? 'Gentle read image',
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return ColoredBox(
            color: t.bg,
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: t.accent,
                  value:
                      progress.expectedTotalBytes == null
                          ? null
                          : progress.cumulativeBytesLoaded /
                              progress.expectedTotalBytes!,
                ),
              ),
            ),
          );
        },
        errorBuilder:
            (context, error, stack) => ColoredBox(
              color: t.bg,
              child: Center(
                child: Text(
                  'Image unavailable',
                  style: AppTypography.lato400(12, t.muted),
                ),
              ),
            ),
      ),
    );
  }

  Widget _title(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: AppTypography.playfair(17, t.text, height: 1.3),
      ),
    );
  }

  Widget _caption(String body, int index, {bool spacedParagraphs = false}) {
    final style = AppTypography.cormorantItalic(15, t.text, height: 1.65);
    if (spacedParagraphs) {
      final parts =
          body
              .split(RegExp(r'\r?\n+'))
              .map((part) => part.trim())
              .where((part) => part.isNotEmpty)
              .toList();
      if (parts.length > 1) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final part in parts)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(part, style: style),
              ),
          ],
        );
      }
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: body, style: style),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          maxLines: 6,
        )..layout(maxWidth: constraints.maxWidth);
        final overflows = painter.didExceedMaxLines;
        final expanded = _expandedIndex == index;
        painter.dispose();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              body,
              style: style,
              maxLines: expanded ? null : 6,
              overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
            if (overflows)
              TextButton(
                onPressed:
                    widget.loading
                        ? null
                        : () => setState(() {
                          _expandedIndex = expanded ? null : index;
                        }),
                style: TextButton.styleFrom(
                  foregroundColor: t.accent,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  alignment: Alignment.centerLeft,
                ),
                child: Text(expanded ? 'Show less' : 'Read more'),
              ),
            const SizedBox(height: 10),
          ],
        );
      },
    );
  }

  Widget _link(GentleRead read, Uri uri) {
    final label = read.linkLabel?.trim();
    final text = label == null || label.isEmpty ? uri.host : label;
    return GestureDetector(
      onTap: () => widget.onOpenLink(uri),
      child: Text(
        text,
        style: AppTypography.cormorantItalic(
          15,
          t.accent,
          height: 1.65,
        ).copyWith(decoration: TextDecoration.underline),
      ),
    );
  }
}

class _ReportHeight extends StatefulWidget {
  final Widget child;
  final ValueChanged<double> onHeight;

  const _ReportHeight({required this.child, required this.onHeight});

  @override
  State<_ReportHeight> createState() => _ReportHeightState();
}

class _ReportHeightState extends State<_ReportHeight> {
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final height = context.size?.height;
      if (height != null) widget.onHeight(height);
    });
    return widget.child;
  }
}
