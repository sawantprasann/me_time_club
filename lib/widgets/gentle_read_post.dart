import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../icons/app_icons.dart';
import '../models/gentle_read.dart';
import '../theme/tokens.dart';

/// Home-screen read, laid out like a little editorial card.
class GentleReadPost extends StatefulWidget {
  final GentleRead read;
  final AppTokens t;
  final Uri baseUri;
  final ValueChanged<Uri> onOpenLink;
  final bool loading;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  /// Swipes still available today. Null hides the daily note.
  final int? swipesRemaining;

  /// Portrait photo, close to an Instagram 4:5 frame.
  static const double portraitAspectRatio = 4 / 5;

  const GentleReadPost({
    super.key,
    required this.read,
    required this.t,
    required this.baseUri,
    required this.onOpenLink,
    this.loading = false,
    this.onPrevious,
    this.onNext,
    this.swipesRemaining,
  });

  @override
  State<GentleReadPost> createState() => _GentleReadPostState();
}

class _GentleReadPostState extends State<GentleReadPost> {
  bool _expanded = false;
  double _dragDx = 0;
  AppTokens get t => widget.t;

  @override
  void didUpdateWidget(covariant GentleReadPost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.read.id != widget.read.id ||
        oldWidget.read.body != widget.read.body) {
      _expanded = false;
    }
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

  @override
  Widget build(BuildContext context) {
    final read = widget.read;
    final image = _webUri(read.imageUrl);
    final link = _webUri(read.linkUrl);
    final hasTitle = read.title.trim().isNotEmpty;
    final hasBody = read.body.trim().isNotEmpty;
    final hasCopy = hasTitle || hasBody;
    final hasNavigation = widget.onPrevious != null || widget.onNext != null;
    final day = t == AppTokens.day;
    final sage = day ? const Color(0xFF7E8B72) : t.green;
    final tagline = day ? const Color(0xFFB7A89A) : t.muted;
    final bodyColor = day ? const Color(0xFF5E564F) : t.text;
    final kicker = day ? const Color(0xFFC47D72) : t.accent;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(sage, tagline),
          const SizedBox(height: 12),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragUpdate: (details) => _dragDx += details.delta.dx,
            onHorizontalDragEnd: _onSwipeEnd,
            onHorizontalDragCancel: () => _dragDx = 0,
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
                                  style: GoogleFonts.lato(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.25,
                                    color: kicker,
                                  ),
                                ),
                                const SizedBox(height: 6),
                              ],
                              if (hasTitle) _title(read.title),
                              if (hasTitle && hasBody)
                                SizedBox(height: image == null ? 16 : 8),
                              if (hasBody)
                                _caption(
                                  read.body,
                                  bodyColor,
                                  spacedParagraphs: image == null,
                                ),
                              if (link != null) ...[
                                if (hasCopy) const SizedBox(height: 12),
                                _link(link),
                              ],
                              if (hasCopy) ...[
                                const SizedBox(height: 18),
                                Text(
                                  'Me Time Club · ${_minutes(read)} min',
                                  style: AppTypography.lato400(12, t.muted),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (hasNavigation || widget.swipesRemaining != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  _swipeButton(
                    icon: Icons.chevron_left_rounded,
                    tooltip: 'Previous',
                    onPressed: widget.onPrevious,
                  ),
                  Expanded(
                    child: Text(
                      _swipeNote(),
                      textAlign: TextAlign.center,
                      style: AppTypography.lato400(12, t.muted),
                    ),
                  ),
                  _swipeButton(
                    icon: Icons.chevron_right_rounded,
                    tooltip: 'Next',
                    onPressed: widget.onNext,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _header(Color sage, Color tagline) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: sage.withValues(alpha: 0.7)),
          ),
          child: AppIcons.book(c: sage, s: 12),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'LITTLE READS',
                  style: GoogleFonts.lato(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                    color: sage,
                  ),
                ),
                TextSpan(
                  text: '  for mummas exploring beyond motherhood',
                  style: AppTypography.cormorantItalic(15, tagline, height: 1),
                ),
              ],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (widget.loading) ...[
          const SizedBox(width: 8),
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: t.accent),
          ),
        ],
      ],
    );
  }

  Widget _photo(Uri image, String? alt) {
    return AspectRatio(
      aspectRatio: GentleReadPost.portraitAspectRatio,
      child: Image.network(
        image.toString(),
        fit: BoxFit.cover,
        semanticLabel: alt ?? 'Little read image',
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
    return Text(
      title,
      style: GoogleFonts.cormorantGaramond(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        height: 1.15,
        color: t.text,
      ),
    );
  }

  Widget _caption(String body, Color color, {bool spacedParagraphs = false}) {
    final style = AppTypography.cormorantItalic(17, color, height: 1.5);
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
            for (var i = 0; i < parts.length; i++) ...[
              if (i > 0) const SizedBox(height: 14),
              Text(parts[i], style: style),
            ],
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
        painter.dispose();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              body,
              style: style,
              maxLines: _expanded ? null : 6,
              overflow:
                  _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
            if (overflows)
              TextButton(
                onPressed:
                    widget.loading
                        ? null
                        : () => setState(() => _expanded = !_expanded),
                style: TextButton.styleFrom(
                  foregroundColor: t.accent,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  alignment: Alignment.centerLeft,
                ),
                child: Text(_expanded ? 'Show less' : 'Read more'),
              ),
          ],
        );
      },
    );
  }

  Widget _link(Uri uri) {
    final label = widget.read.linkLabel?.trim();
    final text = label == null || label.isEmpty ? uri.host : label;
    return GestureDetector(
      onTap: () => widget.onOpenLink(uri),
      child: Text(
        text,
        style: AppTypography.cormorantItalic(
          16,
          t.accent,
          height: 1.3,
        ).copyWith(decoration: TextDecoration.underline),
      ),
    );
  }

  Widget _swipeButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    return IconButton(
      onPressed: widget.loading ? null : onPressed,
      icon: Icon(icon),
      color: onPressed == null ? Colors.transparent : t.accent,
      disabledColor: Colors.transparent,
      tooltip: onPressed == null ? null : tooltip,
      visualDensity: VisualDensity.compact,
    );
  }

  void _onSwipeEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final dx = _dragDx;
    _dragDx = 0;
    if (widget.loading) return;
    if (dx <= -56 || velocity <= -280) {
      widget.onNext?.call();
    } else if (dx >= 56 || velocity >= 280) {
      widget.onPrevious?.call();
    }
  }

  String _swipeNote() {
    final left = widget.swipesRemaining;
    if (left == null) return '';
    if (left <= 0) return "That's your three for today";
    if (left == 1) return '1 swipe left today';
    return '$left swipes left today';
  }
}
