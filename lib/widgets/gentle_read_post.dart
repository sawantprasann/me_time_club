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

  const GentleReadPost({
    super.key,
    required this.read,
    required this.t,
    required this.baseUri,
    required this.onOpenLink,
    this.loading = false,
    this.onPrevious,
    this.onNext,
  });

  @override
  State<GentleReadPost> createState() => _GentleReadPostState();
}

class _GentleReadPostState extends State<GentleReadPost> {
  bool _expanded = false;
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
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: t.border),
        boxShadow: t.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              aspectRatio: 1,
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
          if (hasCaption || link != null)
            AnimatedOpacity(
              opacity: widget.loading ? 0.45 : 1,
              duration: const Duration(milliseconds: 180),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  image != null ? 12 : 2,
                  16,
                  16,
                ),
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
                    if (hasCaption && link != null) const SizedBox(height: 12),
                    if (link != null) _link(link),
                  ],
                ),
              ),
            ),
          if (hasNavigation) ...[
            Divider(height: 1, color: t.border),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  if (widget.onPrevious != null)
                    TextButton.icon(
                      onPressed: widget.loading ? null : widget.onPrevious,
                      icon: const Icon(Icons.chevron_left_rounded, size: 18),
                      label: const Text('Previous'),
                      style: TextButton.styleFrom(foregroundColor: t.accent),
                    ),
                  const Spacer(),
                  if (widget.onNext != null)
                    TextButton.icon(
                      onPressed: widget.loading ? null : widget.onNext,
                      icon: const Icon(Icons.chevron_right_rounded, size: 18),
                      iconAlignment: IconAlignment.end,
                      label: const Text('Next'),
                      style: TextButton.styleFrom(foregroundColor: t.accent),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _caption(String body) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final style = AppTypography.lato400(14, t.text, height: 1.6);
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
