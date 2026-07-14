import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// Reusable pill chip with optional icon.
/// Selected: bg color+20, border color, Lato 700
/// Unselected: bg t.card, border t.border, t.muted
class ChipButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;
  final AppTokens t;
  final Widget Function({required Color c, double s})? iconBuilder;

  const ChipButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.color,
    required this.t,
    this.iconBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width - 56,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.2) : t.card,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: selected ? color : t.border, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconBuilder != null) ...[
              iconBuilder!(c: selected ? color : t.muted, s: 16),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                style: selected
                    ? AppTypography.lato700(13, color)
                    : AppTypography.lato400(13, t.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Themed card container — bg, border, shadow, borderRadius 18
class AppCard extends StatelessWidget {
  final AppTokens t;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BoxDecoration? decoration;
  final EdgeInsetsGeometry? margin;

  const AppCard({
    super.key,
    required this.t,
    required this.child,
    this.padding,
    this.decoration,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 14),
      padding: padding ?? const EdgeInsets.all(18),
      decoration:
          decoration ??
          BoxDecoration(
            color: t.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: t.border),
            boxShadow: t.cardShadow,
          ),
      child: child,
    );
  }
}

/// Section card with accent bar + icon + UPPERCASE label header
class SectionCard extends StatelessWidget {
  final String title;
  final Color accentColor;
  final Widget? icon;
  final AppTokens t;
  final Widget child;
  final int delayMs;

  const SectionCard({
    super.key,
    required this.title,
    required this.accentColor,
    this.icon,
    required this.t,
    required this.child,
    this.delayMs = 0,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      t: t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              if (icon != null) ...[icon!, const SizedBox(width: 8)],
              Text(
                title.toUpperCase(),
                style: AppTypography.sectionLabel(t.muted),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

/// Full-width CTA button — Playfair Display 700 17px
class CTAButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool disabled;
  final AppTokens t;
  final Widget? icon;
  final bool loading;

  const CTAButton({
    super.key,
    required this.label,
    this.onTap,
    this.disabled = false,
    required this.t,
    this.icon,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = disabled || loading;
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        margin: const EdgeInsets.only(top: 24),
        decoration: BoxDecoration(
          color: isDisabled ? t.border : t.accent,
          borderRadius: BorderRadius.circular(14),
          boxShadow:
              isDisabled
                  ? null
                  : [
                    BoxShadow(
                      color: t.accent.withValues(alpha: 0.27),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null && !loading) ...[icon!, const SizedBox(width: 10)],
            Text(
              loading ? 'Chamomile is thinking…' : label,
              style: AppTypography.playfair(
                17,
                isDisabled ? t.muted : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small solid circle button — e.g. 36px accent bg, white icon
class SolidButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget icon;
  final double size;
  final Color color;
  final Color? pressedColor;

  const SolidButton({
    super.key,
    required this.onTap,
    required this.icon,
    this.size = 36,
    required this.color,
    this.pressedColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.27),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(child: icon),
      ),
    );
  }
}
