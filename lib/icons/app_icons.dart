import 'dart:math';
import 'package:flutter/material.dart';

/// All inline SVG-equivalent icon components for Me Time Club.
/// Each accepts [c] (color) and [s] (size in px). All use stroke style.

class AppIcons {
  // ── Navigation Icons ──────────────────────────────

  /// House outline — bottom nav Home
  static Widget home({required Color c, double s = 20}) => SizedBox(
    width: s,
    height: s,
    child: CustomPaint(painter: _HomePainter(c)),
  );

  /// Calendar grid with dots — bottom nav Calendar
  static Widget calendar({required Color c, double s = 20}) => SizedBox(
    width: s,
    height: s,
    child: CustomPaint(painter: _CalendarPainter(c)),
  );

  /// Heart-pin / location drop — bottom nav Memories
  static Widget memories({required Color c, double s = 20}) => SizedBox(
    width: s,
    height: s,
    child: CustomPaint(painter: _MemoriesPainter(c)),
  );

  /// Notebook outline — bottom nav + Tasks
  static Widget journal({required Color c, double s = 20}) => SizedBox(
    width: s,
    height: s,
    child: CustomPaint(painter: _JournalPainter(c)),
  );

  /// Radial circle — bottom nav Circle
  static Widget circle({required Color c, double s = 20}) => SizedBox(
    width: s,
    height: s,
    child: CustomPaint(painter: _CirclePainter(c)),
  );

  /// Person silhouette — bottom nav Me
  static Widget me({required Color c, double s = 20}) =>
      SizedBox(width: s, height: s, child: CustomPaint(painter: _MePainter(c)));

  // ── Bloom / Brand Icon ───────────────────────────

  /// 6-petal botanical bloom — header logo, mood chip, daily page sections
  static Widget bloom({required Color c, double s = 20, Color? center}) =>
      SizedBox(
        width: s,
        height: s,
        child: CustomPaint(painter: _BloomPainter(c, center ?? c)),
      );

  // ── Mood Icons ────────────────────────────────────

  /// Diagonal leaf with stem — Tender
  static Widget leaf({required Color c, double s = 20}) => SizedBox(
    width: s,
    height: s,
    child: CustomPaint(painter: _LeafPainter(c)),
  );

  /// Sine wave lines — Overwhelmed
  static Widget wave({required Color c, double s = 20}) => SizedBox(
    width: s,
    height: s,
    child: CustomPaint(painter: _WavePainter(c)),
  );

  /// Crescent — Sleep-Deprived
  static Widget moon({required Color c, double s = 20}) => SizedBox(
    width: s,
    height: s,
    child: CustomPaint(painter: _MoonPainter(c)),
  );

  /// Circle + rays — Motivated
  static Widget sun({required Color c, double s = 20}) => SizedBox(
    width: s,
    height: s,
    child: CustomPaint(painter: _SunPainter(c)),
  );

  /// Horizontal flow lines — Anxious
  static Widget wind({required Color c, double s = 20}) => SizedBox(
    width: s,
    height: s,
    child: CustomPaint(painter: _WindPainter(c)),
  );

  /// Flame on cylinder — Lonely
  static Widget candle({required Color c, double s = 20}) => SizedBox(
    width: s,
    height: s,
    child: CustomPaint(painter: _CandlePainter(c)),
  );

  /// Grain stalk — Stable
  static Widget wheat({required Color c, double s = 20}) => SizedBox(
    width: s,
    height: s,
    child: CustomPaint(painter: _WheatPainter(c)),
  );

  /// Cloud outline — Just Here
  static Widget cloud({required Color c, double s = 20}) => SizedBox(
    width: s,
    height: s,
    child: CustomPaint(painter: _CloudPainter(c)),
  );

  // ── UI Icons ──────────────────────────────────────

  /// Heart outline — Emotional Alignment, Circle reactions
  static Widget heart({required Color c, double s = 20}) => SizedBox(
    width: s,
    height: s,
    child: CustomPaint(painter: _HeartPainter(c)),
  );

  /// Person with open arms — Circle reactions
  static Widget hug({required Color c, double s = 20}) => SizedBox(
    width: s,
    height: s,
    child: CustomPaint(painter: _HugPainter(c)),
  );

  /// 5-point star — Insight section
  static Widget star({required Color c, double s = 20}) => SizedBox(
    width: s,
    height: s,
    child: CustomPaint(painter: _StarPainter(c)),
  );

  /// Radial sun/compass — Micro Ritual section
  static Widget ritual({required Color c, double s = 20}) => SizedBox(
    width: s,
    height: s,
    child: CustomPaint(painter: _RitualPainter(c)),
  );

  /// Open book — Gentle Read section
  static Widget book({required Color c, double s = 20}) => SizedBox(
    width: s,
    height: s,
    child: CustomPaint(painter: _BookPainter(c)),
  );

  /// Edit pen — Profile edit, Reflection section
  static Widget pen({required Color c, double s = 20}) => SizedBox(
    width: s,
    height: s,
    child: CustomPaint(painter: _PenPainter(c)),
  );

  /// Tick mark — save confirmation, completed tasks
  static Widget check({required Color c, double s = 20}) => SizedBox(
    width: s,
    height: s,
    child: CustomPaint(painter: _CheckPainter(c)),
  );

  /// Diagonal cross — cancel, delete
  static Widget close({required Color c, double s = 20}) => SizedBox(
    width: s,
    height: s,
    child: CustomPaint(painter: _ClosePainter(c)),
  );

  /// Plus sign — add actions
  static Widget plus({required Color c, double s = 20}) => SizedBox(
    width: s,
    height: s,
    child: CustomPaint(painter: _PlusPainter(c)),
  );

  /// Circular arrow — New check-in
  static Widget refresh({required Color c, double s = 20}) => SizedBox(
    width: s,
    height: s,
    child: CustomPaint(painter: _RefreshPainter(c)),
  );

  /// Single chevron right — list item drill-in
  static Widget chevRight({required Color c, double s = 20}) => SizedBox(
    width: s,
    height: s,
    child: CustomPaint(painter: _ChevRightPainter(c)),
  );

  /// Three-node share icon
  static Widget share({required Color c, double s = 20}) => SizedBox(
    width: s,
    height: s,
    child: CustomPaint(painter: _SharePainter(c)),
  );

  /// Envelope outline — Me tab letter cards
  static Widget letter({required Color c, double s = 20}) => SizedBox(
    width: s,
    height: s,
    child: CustomPaint(painter: _LetterPainter(c)),
  );

  /// Filled crescent — night toggle
  static Widget moon2({required Color c, double s = 15}) => SizedBox(
    width: s,
    height: s,
    child: CustomPaint(painter: _Moon2Painter(c)),
  );

  /// Minimal sun — day toggle
  static Widget sun2({required Color c, double s = 15}) => SizedBox(
    width: s,
    height: s,
    child: CustomPaint(painter: _Sun2Painter(c)),
  );

  /// Microphone — voice input button
  static Widget mic({required Color c, double s = 20}) => SizedBox(
    width: s,
    height: s,
    child: CustomPaint(painter: _MicPainter(c)),
  );

  /// Camera icon — photo picker badge
  static Widget camera({required Color c, double s = 20}) => SizedBox(
    width: s,
    height: s,
    child: CustomPaint(painter: _CameraPainter(c)),
  );
}

// ═══════════════════════════════════════════════════════
// PAINTERS — CustomPaint implementations for each icon
// ═══════════════════════════════════════════════════════

class _HomePainter extends CustomPainter {
  final Color color;
  _HomePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p =
        Paint()
          ..color = color
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
    final s = size.width;
    // Roof
    canvas.drawLine(Offset(s * 0.1, s * 0.45), Offset(s * 0.5, s * 0.12), p);
    canvas.drawLine(Offset(s * 0.5, s * 0.12), Offset(s * 0.9, s * 0.45), p);
    // Walls
    final wall =
        Path()
          ..moveTo(s * 0.2, s * 0.45)
          ..lineTo(s * 0.2, s * 0.85)
          ..lineTo(s * 0.8, s * 0.85)
          ..lineTo(s * 0.8, s * 0.45);
    canvas.drawPath(wall, p);
    // Door
    canvas.drawRect(Rect.fromLTWH(s * 0.38, s * 0.58, s * 0.24, s * 0.27), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CalendarPainter extends CustomPainter {
  final Color color;
  _CalendarPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p =
        Paint()
          ..color = color
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
    final s = size.width;
    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(s * 0.1, s * 0.15, s * 0.8, s * 0.75),
      const Radius.circular(3),
    );
    canvas.drawRRect(r, p);
    canvas.drawLine(Offset(s * 0.1, s * 0.38), Offset(s * 0.9, s * 0.38), p);
    // Calendar pins
    canvas.drawLine(Offset(s * 0.35, s * 0.08), Offset(s * 0.35, s * 0.22), p);
    canvas.drawLine(Offset(s * 0.65, s * 0.08), Offset(s * 0.65, s * 0.22), p);
    // Dots
    final dp =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(s * 0.35, s * 0.55), s * 0.04, dp);
    canvas.drawCircle(Offset(s * 0.55, s * 0.55), s * 0.04, dp);
    canvas.drawCircle(Offset(s * 0.35, s * 0.72), s * 0.04, dp);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MemoriesPainter extends CustomPainter {
  final Color color;
  _MemoriesPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p =
        Paint()
          ..color = color
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
    final s = size.width;
    // Heart shape at top of pin
    final path =
        Path()
          ..moveTo(s * 0.5, s * 0.92)
          ..lineTo(s * 0.25, s * 0.55)
          ..cubicTo(s * 0.05, s * 0.25, s * 0.25, s * 0.05, s * 0.5, s * 0.3)
          ..cubicTo(s * 0.75, s * 0.05, s * 0.95, s * 0.25, s * 0.75, s * 0.55)
          ..close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _JournalPainter extends CustomPainter {
  final Color color;
  _JournalPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p =
        Paint()
          ..color = color
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
    final s = size.width;
    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(s * 0.2, s * 0.08, s * 0.65, s * 0.84),
      const Radius.circular(3),
    );
    canvas.drawRRect(r, p);
    // Spine
    canvas.drawLine(Offset(s * 0.2, s * 0.08), Offset(s * 0.2, s * 0.92), p);
    canvas.drawLine(Offset(s * 0.15, s * 0.08), Offset(s * 0.15, s * 0.92), p);
    // Lines
    canvas.drawLine(Offset(s * 0.35, s * 0.3), Offset(s * 0.7, s * 0.3), p);
    canvas.drawLine(Offset(s * 0.35, s * 0.45), Offset(s * 0.7, s * 0.45), p);
    canvas.drawLine(Offset(s * 0.35, s * 0.6), Offset(s * 0.6, s * 0.6), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CirclePainter extends CustomPainter {
  final Color color;
  _CirclePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p =
        Paint()
          ..color = color
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
    final s = size.width;
    canvas.drawCircle(Offset(s * 0.5, s * 0.5), s * 0.38, p);
    // Inner dots
    final dp =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(s * 0.35, s * 0.5), s * 0.05, dp);
    canvas.drawCircle(Offset(s * 0.5, s * 0.5), s * 0.05, dp);
    canvas.drawCircle(Offset(s * 0.65, s * 0.5), s * 0.05, dp);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MePainter extends CustomPainter {
  final Color color;
  _MePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p =
        Paint()
          ..color = color
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
    final s = size.width;
    // Head
    canvas.drawCircle(Offset(s * 0.5, s * 0.28), s * 0.18, p);
    // Shoulders
    final body =
        Path()
          ..moveTo(s * 0.15, s * 0.92)
          ..quadraticBezierTo(s * 0.15, s * 0.6, s * 0.5, s * 0.58)
          ..quadraticBezierTo(s * 0.85, s * 0.6, s * 0.85, s * 0.92);
    canvas.drawPath(body, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BloomPainter extends CustomPainter {
  final Color petalColor;
  final Color centerColor;
  _BloomPainter(this.petalColor, this.centerColor);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final center = Offset(s * 0.5, s * 0.5);
    final p =
        Paint()
          ..color = petalColor
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke;

    // 6 petals
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60) * pi / 180;
      final petalLength = s * 0.32;
      final petalWidth = s * 0.14;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);
      final petal =
          Path()
            ..moveTo(0, 0)
            ..quadraticBezierTo(petalWidth, -petalLength * 0.5, 0, -petalLength)
            ..quadraticBezierTo(-petalWidth, -petalLength * 0.5, 0, 0);
      canvas.drawPath(petal, p);
      canvas.restore();
    }

    // Centre circle — filled
    final cp =
        Paint()
          ..color = centerColor
          ..style = PaintingStyle.fill;
    canvas.drawCircle(center, s * 0.07, cp);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LeafPainter extends CustomPainter {
  final Color color;
  _LeafPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p =
        Paint()
          ..color = color
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
    final s = size.width;
    final leaf =
        Path()
          ..moveTo(s * 0.2, s * 0.8)
          ..quadraticBezierTo(s * 0.1, s * 0.2, s * 0.8, s * 0.15)
          ..quadraticBezierTo(s * 0.85, s * 0.8, s * 0.2, s * 0.8);
    canvas.drawPath(leaf, p);
    // Stem
    canvas.drawLine(Offset(s * 0.2, s * 0.8), Offset(s * 0.65, s * 0.35), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WavePainter extends CustomPainter {
  final Color color;
  _WavePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p =
        Paint()
          ..color = color
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
    final s = size.width;
    for (double y in [s * 0.3, s * 0.5, s * 0.7]) {
      final wave =
          Path()
            ..moveTo(s * 0.1, y)
            ..cubicTo(s * 0.3, y - s * 0.12, s * 0.5, y + s * 0.12, s * 0.7, y)
            ..cubicTo(
              s * 0.8,
              y - s * 0.06,
              s * 0.85,
              y - s * 0.06,
              s * 0.9,
              y,
            );
      canvas.drawPath(wave, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MoonPainter extends CustomPainter {
  final Color color;
  _MoonPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p =
        Paint()
          ..color = color
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
    final s = size.width;
    final moon =
        Path()..addArc(
          Rect.fromCircle(center: Offset(s * 0.5, s * 0.5), radius: s * 0.35),
          0,
          2 * pi,
        );
    canvas.drawPath(moon, p);
    // Cutout effect with thick stroke matching bg — just draw crescent
    final cut =
        Paint()
          ..color = color
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(s * 0.62, s * 0.42), radius: s * 0.28),
      0.5,
      pi * 1.4,
      false,
      cut,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SunPainter extends CustomPainter {
  final Color color;
  _SunPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p =
        Paint()
          ..color = color
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
    final s = size.width;
    final center = Offset(s * 0.5, s * 0.5);
    canvas.drawCircle(center, s * 0.2, p);
    // 8 rays
    for (int i = 0; i < 8; i++) {
      final angle = (i * 45) * pi / 180;
      canvas.drawLine(
        Offset(
          center.dx + cos(angle) * s * 0.28,
          center.dy + sin(angle) * s * 0.28,
        ),
        Offset(
          center.dx + cos(angle) * s * 0.4,
          center.dy + sin(angle) * s * 0.4,
        ),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WindPainter extends CustomPainter {
  final Color color;
  _WindPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p =
        Paint()
          ..color = color
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
    final s = size.width;
    // Three horizontal flow lines with slight curves
    final w1 =
        Path()
          ..moveTo(s * 0.1, s * 0.3)
          ..quadraticBezierTo(s * 0.5, s * 0.28, s * 0.75, s * 0.22)
          ..quadraticBezierTo(s * 0.88, s * 0.18, s * 0.85, s * 0.28);
    canvas.drawPath(w1, p);
    final w2 =
        Path()
          ..moveTo(s * 0.15, s * 0.5)
          ..lineTo(s * 0.8, s * 0.5)
          ..quadraticBezierTo(s * 0.95, s * 0.5, s * 0.9, s * 0.42);
    canvas.drawPath(w2, p);
    final w3 =
        Path()
          ..moveTo(s * 0.2, s * 0.7)
          ..quadraticBezierTo(s * 0.45, s * 0.72, s * 0.65, s * 0.7)
          ..quadraticBezierTo(s * 0.78, s * 0.68, s * 0.75, s * 0.76);
    canvas.drawPath(w3, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CandlePainter extends CustomPainter {
  final Color color;
  _CandlePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p =
        Paint()
          ..color = color
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
    final s = size.width;
    // Cylinder body
    canvas.drawRect(Rect.fromLTWH(s * 0.32, s * 0.4, s * 0.36, s * 0.52), p);
    // Wick
    canvas.drawLine(Offset(s * 0.5, s * 0.4), Offset(s * 0.5, s * 0.3), p);
    // Flame
    final flame =
        Path()
          ..moveTo(s * 0.5, s * 0.08)
          ..quadraticBezierTo(s * 0.58, s * 0.2, s * 0.5, s * 0.3)
          ..quadraticBezierTo(s * 0.42, s * 0.2, s * 0.5, s * 0.08);
    canvas.drawPath(flame, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WheatPainter extends CustomPainter {
  final Color color;
  _WheatPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p =
        Paint()
          ..color = color
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
    final s = size.width;
    // Main stem
    canvas.drawLine(Offset(s * 0.5, s * 0.9), Offset(s * 0.5, s * 0.15), p);
    // Grain pairs
    for (double t in [0.25, 0.4, 0.55, 0.7]) {
      final y = s * t;
      final grain1 =
          Path()
            ..moveTo(s * 0.5, y)
            ..quadraticBezierTo(s * 0.3, y - s * 0.08, s * 0.35, y - s * 0.14);
      canvas.drawPath(grain1, p);
      final grain2 =
          Path()
            ..moveTo(s * 0.5, y)
            ..quadraticBezierTo(s * 0.7, y - s * 0.08, s * 0.65, y - s * 0.14);
      canvas.drawPath(grain2, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CloudPainter extends CustomPainter {
  final Color color;
  _CloudPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p =
        Paint()
          ..color = color
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
    final s = size.width;
    final cloud =
        Path()
          ..moveTo(s * 0.2, s * 0.65)
          ..quadraticBezierTo(s * 0.05, s * 0.65, s * 0.1, s * 0.5)
          ..quadraticBezierTo(s * 0.12, s * 0.32, s * 0.3, s * 0.35)
          ..quadraticBezierTo(s * 0.35, s * 0.18, s * 0.55, s * 0.22)
          ..quadraticBezierTo(s * 0.75, s * 0.18, s * 0.78, s * 0.38)
          ..quadraticBezierTo(s * 0.95, s * 0.38, s * 0.9, s * 0.55)
          ..quadraticBezierTo(s * 0.88, s * 0.65, s * 0.78, s * 0.65)
          ..close();
    canvas.drawPath(cloud, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HeartPainter extends CustomPainter {
  final Color color;
  _HeartPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p =
        Paint()
          ..color = color
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round;
    final s = size.width;
    final heart =
        Path()
          ..moveTo(s * 0.5, s * 0.85)
          ..cubicTo(s * 0.05, s * 0.55, s * 0.05, s * 0.2, s * 0.5, s * 0.3)
          ..cubicTo(s * 0.95, s * 0.2, s * 0.95, s * 0.55, s * 0.5, s * 0.85);
    canvas.drawPath(heart, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HugPainter extends CustomPainter {
  final Color color;
  _HugPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p =
        Paint()
          ..color = color
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
    final s = size.width;
    // Head
    canvas.drawCircle(Offset(s * 0.5, s * 0.22), s * 0.14, p);
    // Body
    canvas.drawLine(Offset(s * 0.5, s * 0.36), Offset(s * 0.5, s * 0.7), p);
    // Arms reaching out/around
    final leftArm =
        Path()
          ..moveTo(s * 0.5, s * 0.45)
          ..quadraticBezierTo(s * 0.15, s * 0.42, s * 0.2, s * 0.6);
    canvas.drawPath(leftArm, p);
    final rightArm =
        Path()
          ..moveTo(s * 0.5, s * 0.45)
          ..quadraticBezierTo(s * 0.85, s * 0.42, s * 0.8, s * 0.6);
    canvas.drawPath(rightArm, p);
    // Legs
    canvas.drawLine(Offset(s * 0.5, s * 0.7), Offset(s * 0.35, s * 0.9), p);
    canvas.drawLine(Offset(s * 0.5, s * 0.7), Offset(s * 0.65, s * 0.9), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StarPainter extends CustomPainter {
  final Color color;
  _StarPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p =
        Paint()
          ..color = color
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round;
    final s = size.width;
    final center = Offset(s * 0.5, s * 0.5);
    final outer = s * 0.4;
    final inner = s * 0.18;
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final outerAngle = (i * 72 - 90) * pi / 180;
      final innerAngle = ((i * 72) + 36 - 90) * pi / 180;
      final ox = center.dx + cos(outerAngle) * outer;
      final oy = center.dy + sin(outerAngle) * outer;
      final ix = center.dx + cos(innerAngle) * inner;
      final iy = center.dy + sin(innerAngle) * inner;
      if (i == 0) {
        path.moveTo(ox, oy);
      } else {
        path.lineTo(ox, oy);
      }
      path.lineTo(ix, iy);
    }
    path.close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RitualPainter extends CustomPainter {
  final Color color;
  _RitualPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p =
        Paint()
          ..color = color
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
    final s = size.width;
    final center = Offset(s * 0.5, s * 0.5);
    canvas.drawCircle(center, s * 0.12, p);
    canvas.drawCircle(center, s * 0.3, p);
    // 8 rays
    for (int i = 0; i < 8; i++) {
      final angle = (i * 45) * pi / 180;
      canvas.drawLine(
        Offset(
          center.dx + cos(angle) * s * 0.3,
          center.dy + sin(angle) * s * 0.3,
        ),
        Offset(
          center.dx + cos(angle) * s * 0.42,
          center.dy + sin(angle) * s * 0.42,
        ),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BookPainter extends CustomPainter {
  final Color color;
  _BookPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p =
        Paint()
          ..color = color
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
    final s = size.width;
    // Left page
    final left =
        Path()
          ..moveTo(s * 0.5, s * 0.25)
          ..quadraticBezierTo(s * 0.3, s * 0.2, s * 0.1, s * 0.22)
          ..lineTo(s * 0.1, s * 0.78)
          ..quadraticBezierTo(s * 0.3, s * 0.76, s * 0.5, s * 0.8);
    canvas.drawPath(left, p);
    // Right page
    final right =
        Path()
          ..moveTo(s * 0.5, s * 0.25)
          ..quadraticBezierTo(s * 0.7, s * 0.2, s * 0.9, s * 0.22)
          ..lineTo(s * 0.9, s * 0.78)
          ..quadraticBezierTo(s * 0.7, s * 0.76, s * 0.5, s * 0.8);
    canvas.drawPath(right, p);
    // Spine
    canvas.drawLine(Offset(s * 0.5, s * 0.25), Offset(s * 0.5, s * 0.8), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PenPainter extends CustomPainter {
  final Color color;
  _PenPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p =
        Paint()
          ..color = color
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
    final s = size.width;
    // Pen body (diagonal)
    canvas.drawLine(Offset(s * 0.7, s * 0.15), Offset(s * 0.2, s * 0.65), p);
    canvas.drawLine(Offset(s * 0.82, s * 0.28), Offset(s * 0.32, s * 0.78), p);
    // Tip
    canvas.drawLine(Offset(s * 0.2, s * 0.65), Offset(s * 0.15, s * 0.85), p);
    canvas.drawLine(Offset(s * 0.32, s * 0.78), Offset(s * 0.15, s * 0.85), p);
    // Cap line
    canvas.drawLine(Offset(s * 0.7, s * 0.15), Offset(s * 0.82, s * 0.28), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CheckPainter extends CustomPainter {
  final Color color;
  _CheckPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p =
        Paint()
          ..color = color
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
    final s = size.width;
    canvas.drawLine(Offset(s * 0.2, s * 0.5), Offset(s * 0.4, s * 0.72), p);
    canvas.drawLine(Offset(s * 0.4, s * 0.72), Offset(s * 0.8, s * 0.28), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ClosePainter extends CustomPainter {
  final Color color;
  _ClosePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p =
        Paint()
          ..color = color
          ..strokeWidth = 1.8
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
    final s = size.width;
    canvas.drawLine(Offset(s * 0.25, s * 0.25), Offset(s * 0.75, s * 0.75), p);
    canvas.drawLine(Offset(s * 0.75, s * 0.25), Offset(s * 0.25, s * 0.75), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PlusPainter extends CustomPainter {
  final Color color;
  _PlusPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p =
        Paint()
          ..color = color
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
    final s = size.width;
    canvas.drawLine(Offset(s * 0.5, s * 0.2), Offset(s * 0.5, s * 0.8), p);
    canvas.drawLine(Offset(s * 0.2, s * 0.5), Offset(s * 0.8, s * 0.5), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RefreshPainter extends CustomPainter {
  final Color color;
  _RefreshPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p =
        Paint()
          ..color = color
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
    final s = size.width;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(s * 0.5, s * 0.5), radius: s * 0.3),
      -pi / 2,
      pi * 1.5,
      false,
      p,
    );
    // Arrow head
    final arrow =
        Path()
          ..moveTo(s * 0.5, s * 0.15)
          ..lineTo(s * 0.62, s * 0.25)
          ..moveTo(s * 0.5, s * 0.15)
          ..lineTo(s * 0.38, s * 0.25);
    canvas.drawPath(arrow, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ChevRightPainter extends CustomPainter {
  final Color color;
  _ChevRightPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p =
        Paint()
          ..color = color
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
    final s = size.width;
    canvas.drawLine(Offset(s * 0.35, s * 0.2), Offset(s * 0.65, s * 0.5), p);
    canvas.drawLine(Offset(s * 0.65, s * 0.5), Offset(s * 0.35, s * 0.8), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SharePainter extends CustomPainter {
  final Color color;
  _SharePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p =
        Paint()
          ..color = color
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
    final dp =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;
    final s = size.width;
    // Three nodes
    canvas.drawCircle(Offset(s * 0.75, s * 0.2), s * 0.1, p);
    canvas.drawCircle(Offset(s * 0.25, s * 0.5), s * 0.1, p);
    canvas.drawCircle(Offset(s * 0.75, s * 0.8), s * 0.1, p);
    canvas.drawCircle(Offset(s * 0.75, s * 0.2), s * 0.04, dp);
    canvas.drawCircle(Offset(s * 0.25, s * 0.5), s * 0.04, dp);
    canvas.drawCircle(Offset(s * 0.75, s * 0.8), s * 0.04, dp);
    // Lines
    canvas.drawLine(Offset(s * 0.35, s * 0.45), Offset(s * 0.65, s * 0.25), p);
    canvas.drawLine(Offset(s * 0.35, s * 0.55), Offset(s * 0.65, s * 0.75), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LetterPainter extends CustomPainter {
  final Color color;
  _LetterPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p =
        Paint()
          ..color = color
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round;
    final s = size.width;
    // Envelope
    final env = RRect.fromRectAndRadius(
      Rect.fromLTWH(s * 0.1, s * 0.22, s * 0.8, s * 0.56),
      const Radius.circular(3),
    );
    canvas.drawRRect(env, p);
    // Flap
    canvas.drawLine(Offset(s * 0.1, s * 0.22), Offset(s * 0.5, s * 0.52), p);
    canvas.drawLine(Offset(s * 0.9, s * 0.22), Offset(s * 0.5, s * 0.52), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Moon2Painter extends CustomPainter {
  final Color color;
  _Moon2Painter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final p =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;
    final path =
        Path()
          ..addArc(
            Rect.fromCircle(
              center: Offset(s * 0.45, s * 0.5),
              radius: s * 0.35,
            ),
            -pi / 2,
            pi,
          )
          ..arcTo(
            Rect.fromCircle(
              center: Offset(s * 0.55, s * 0.5),
              radius: s * 0.25,
            ),
            pi / 2,
            -pi,
            false,
          );
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Sun2Painter extends CustomPainter {
  final Color color;
  _Sun2Painter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p =
        Paint()
          ..color = color
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
    final s = size.width;
    final center = Offset(s * 0.5, s * 0.5);
    canvas.drawCircle(center, s * 0.18, p);
    for (int i = 0; i < 8; i++) {
      final angle = (i * 45) * pi / 180;
      canvas.drawLine(
        Offset(
          center.dx + cos(angle) * s * 0.26,
          center.dy + sin(angle) * s * 0.26,
        ),
        Offset(
          center.dx + cos(angle) * s * 0.38,
          center.dy + sin(angle) * s * 0.38,
        ),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MicPainter extends CustomPainter {
  final Color color;
  _MicPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p =
        Paint()
          ..color = color
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
    final s = size.width;
    // Mic body
    final mic = RRect.fromRectAndRadius(
      Rect.fromLTWH(s * 0.33, s * 0.1, s * 0.34, s * 0.48),
      Radius.circular(s * 0.17),
    );
    canvas.drawRRect(mic, p);
    // Arc below
    final arc =
        Path()
          ..moveTo(s * 0.22, s * 0.52)
          ..quadraticBezierTo(s * 0.22, s * 0.72, s * 0.5, s * 0.72)
          ..quadraticBezierTo(s * 0.78, s * 0.72, s * 0.78, s * 0.52);
    canvas.drawPath(arc, p);
    // Stand
    canvas.drawLine(Offset(s * 0.5, s * 0.72), Offset(s * 0.5, s * 0.88), p);
    canvas.drawLine(Offset(s * 0.35, s * 0.88), Offset(s * 0.65, s * 0.88), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CameraPainter extends CustomPainter {
  final Color color;
  _CameraPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p =
        Paint()
          ..color = color
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
    final s = size.width;
    // Body
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(s * 0.1, s * 0.3, s * 0.8, s * 0.5),
      const Radius.circular(4),
    );
    canvas.drawRRect(body, p);
    // Lens bump
    final bump =
        Path()
          ..moveTo(s * 0.35, s * 0.3)
          ..lineTo(s * 0.4, s * 0.18)
          ..lineTo(s * 0.6, s * 0.18)
          ..lineTo(s * 0.65, s * 0.3);
    canvas.drawPath(bump, p);
    // Lens circle
    canvas.drawCircle(Offset(s * 0.5, s * 0.55), s * 0.14, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
