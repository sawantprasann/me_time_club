import 'package:flutter/material.dart';
import '../icons/app_icons.dart';
import '../models/gentle_read.dart';
import '../theme/tokens.dart';

/// A read-only post. Image, caption, and link are independent optional content.
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

  /// Instagram portrait posts are 4:5.
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

  @override
  Widget build(BuildContext context) {
    final read = widget.read;
    final image = _webUri(read.imageUrl);
    final link = _webUri(read.linkUrl);
    final hasCaption =
        read.title.trim().isNotEmpty || read.body.trim().isNotEmpty;
    final hasNavigation = widget.onPrevious != null || widget.onNext != null;

    return Container(
      margin: const EdgeInsets.only(top: 14),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: t.card, boxShadow: t.cardShadow),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragUpdate: (details) => _dragDx += details.delta.dx,
        onHorizontalDragEnd: _onSwipeEnd,
        onHorizontalDragCancel: () => _dragDx = 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(
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
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: t.accent,
                      ),
                    ),
                ],
              ),
            ),
            if (image != null)
              AspectRatio(
                aspectRatio: GentleReadPost.portraitAspectRatio,
                child: Image.network(
                  image.toString(),
                  fit: BoxFit.cover,
                  semanticLabel: read.imageAlt ?? 'Gentle Read image',
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
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.image_not_supported_outlined,
                                color: t.muted,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Image unavailable',
                                style: AppTypography.lato400(12, t.muted),
                              ),
                            ],
                          ),
                        ),
                      ),
                ),
              ),
            if (image == null && hasCaption) _portraitText(read),
            if (image != null && (hasCaption || link != null))
              AnimatedOpacity(
                opacity: widget.loading ? 0.45 : 1,
                duration: const Duration(milliseconds: 180),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (read.title.trim().isNotEmpty)
                        Text(
                          read.title,
                          style: AppTypography.lato700(14, t.text, height: 1.3),
                        ),
                      if (read.title.trim().isNotEmpty &&
                          read.body.trim().isNotEmpty)
                        const SizedBox(height: 4),
                      if (read.body.trim().isNotEmpty) _caption(read.body),
                      if (hasCaption && link != null)
                        const SizedBox(height: 12),
                      if (link != null) _link(link),
                    ],
                  ),
                ),
              ),
            if (image == null && link != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                child: _link(link),
              ),
            if (hasNavigation || widget.swipesRemaining != null) ...[
              Divider(height: 1, color: t.border),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                child: Row(
                  children: [
                    if (widget.onPrevious != null)
                      IconButton(
                        onPressed: widget.loading ? null : widget.onPrevious,
                        icon: const Icon(Icons.chevron_left_rounded),
                        color: t.accent,
                        tooltip: 'Previous',
                      )
                    else
                      const SizedBox(width: 48),
                    Expanded(
                      child: Text(
                        _swipeNote(),
                        textAlign: TextAlign.center,
                        style: AppTypography.lato400(12, t.muted),
                      ),
                    ),
                    if (widget.onNext != null)
                      IconButton(
                        onPressed: widget.loading ? null : widget.onNext,
                        icon: const Icon(Icons.chevron_right_rounded),
                        color: t.accent,
                        tooltip: 'Next',
                      )
                    else
                      const SizedBox(width: 48),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
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

  /// A text-only read fills the same portrait frame as a photo.
  Widget _portraitText(GentleRead read) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height =
            constraints.maxWidth / GentleReadPost.portraitAspectRatio;
        final quote = Padding(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (read.title.trim().isNotEmpty)
                Text(
                  read.title,
                  textAlign: TextAlign.center,
                  style: AppTypography.cormorant600(26, t.text, height: 1.2),
                ),
              if (read.title.trim().isNotEmpty && read.body.trim().isNotEmpty)
                const SizedBox(height: 14),
              if (read.body.trim().isNotEmpty)
                _caption(
                  read.body,
                  collapsedLines: read.title.trim().isNotEmpty ? 6 : 8,
                  centered: true,
                ),
            ],
          ),
        );
        if (_expanded) return quote;
        return SizedBox(height: height, child: Center(child: quote));
      },
    );
  }

  Widget _caption(
    String body, {
    int collapsedLines = 6,
    bool centered = false,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final style =
            centered
                ? AppTypography.cormorantItalic(22, t.text, height: 1.45)
                : AppTypography.lato400(15, t.text, height: 1.6);
        final painter = TextPainter(
          text: TextSpan(text: body, style: style),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          maxLines: collapsedLines,
          textAlign: centered ? TextAlign.center : TextAlign.start,
        )..layout(maxWidth: constraints.maxWidth);
        final overflows = painter.didExceedMaxLines;
        painter.dispose();
        return Column(
          crossAxisAlignment:
              centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: [
            Text(
              body,
              textAlign: centered ? TextAlign.center : TextAlign.start,
              style: style,
              maxLines: _expanded ? null : collapsedLines,
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
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
    return Material(
      color: t.bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => widget.onOpenLink(uri),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.link_rounded, color: t.accent, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label == null || label.isEmpty ? uri.host : label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.lato700(12, t.text),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.open_in_new_rounded, color: t.muted, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
