import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Me Time Club Design Tokens
/// Day and Night color palettes with typography and spacing constants.
class AppTokens {
  final Color bg;
  final Color card;
  final Color header;
  final Color accent;
  final Color gold;
  final Color green;
  final Color text;
  final Color muted;
  final Color border;
  final Color cycleRose;
  final Color navBg;

  const AppTokens._({
    required this.bg,
    required this.card,
    required this.header,
    required this.accent,
    required this.gold,
    required this.green,
    required this.text,
    required this.muted,
    required this.border,
    required this.cycleRose,
    required this.navBg,
  });

  static const day = AppTokens._(
    bg: Color(0xFFF5F0E8),
    card: Color(0xFFFFFFFF),
    header: Color(0xFFFFFFFF),
    accent: Color(0xFFB8706A),
    gold: Color(0xFFC4945A),
    green: Color(0xFF7A9E8E),
    text: Color(0xFF2C2825),
    muted: Color(0xFF8A7D76),
    border: Color(0xFFE8DDD5),
    cycleRose: Color(0xFFC4878A),
    navBg: Color(0xFFFFFFFF),
  );

  static const night = AppTokens._(
    bg: Color(0xFF1E1C1A),
    card: Color(0xFF282422),
    header: Color(0xFF141210),
    accent: Color(0xFFC4878A),
    gold: Color(0xFFC4945A),
    green: Color(0xFF7A9E8E),
    text: Color(0xFFF0EBE3),
    muted: Color(0xFF8A8078),
    border: Color(0xFF302C28),
    cycleRose: Color(0xFFC4878A),
    navBg: Color(0xFF1A1816),
  );

  /// Card shadow based on mode
  List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: this == day ? 0.04 : 0.25),
          blurRadius: 16,
          offset: const Offset(0, 2),
        ),
      ];

  /// Header shadow
  List<BoxShadow> get headerShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: this == day ? 0.05 : 0.3),
          blurRadius: 16,
          offset: const Offset(0, 2),
        ),
      ];
}

/// Typography helpers using Google Fonts
class AppTypography {
  /// Playfair Display 700 — Titles, CTAs, user name
  static TextStyle playfair(double size, Color color, {double? height}) =>
      GoogleFonts.playfairDisplay(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color,
        height: height,
      );

  /// Cormorant Garamond Italic 400 — Reflections, quotes, textareas
  static TextStyle cormorantItalic(double size, Color color,
          {double? height}) =>
      GoogleFonts.cormorantGaramond(
        fontSize: size,
        fontWeight: FontWeight.w400,
        fontStyle: FontStyle.italic,
        color: color,
        height: height,
      );

  /// Cormorant Garamond 600 — Section pull quotes
  static TextStyle cormorant600(double size, Color color, {double? height}) =>
      GoogleFonts.cormorantGaramond(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: color,
        height: height,
      );

  /// Lato 300 — Light body labels
  static TextStyle lato300(double size, Color color, {double? height}) =>
      GoogleFonts.lato(
        fontSize: size,
        fontWeight: FontWeight.w300,
        color: color,
        height: height,
      );

  /// Lato 400 — UI labels, dates, navigation
  static TextStyle lato400(double size, Color color, {double? height}) =>
      GoogleFonts.lato(
        fontSize: size,
        fontWeight: FontWeight.w400,
        color: color,
        height: height,
      );

  /// Lato 700 — Section labels (UPPERCASE), chip selected
  static TextStyle lato700(double size, Color color,
          {double letterSpacing = 0, double? height}) =>
      GoogleFonts.lato(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );

  /// DM Serif Display Italic — Opening thought, night reflection
  static TextStyle dmSerifItalic(double size, Color color, {double? height}) =>
      GoogleFonts.dmSerifDisplay(
        fontSize: size,
        fontStyle: FontStyle.italic,
        color: color,
        height: height,
      );

  /// Section label style: Lato 700 · 10px · UPPERCASE · letter-spacing 1.8px
  static TextStyle sectionLabel(Color color) => GoogleFonts.lato(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 1.8,
      );
}

/// Spacing & layout constants
class AppSpacing {
  static const double pagePadding = 18;
  static const double cardRadius = 18;
  static const double smallRadius = 14;
  static const double featureRadius = 20;
  static const double bottomNavHeight = 70;
  static const double headerHeight = 50;
  static const double maxWidth = 430;
}
