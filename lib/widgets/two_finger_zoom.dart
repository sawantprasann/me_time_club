import 'package:flutter/material.dart';

/// Pinch with two fingers to enlarge the whole app. One finger still
/// scrolls, taps, and types. Pinch back in to return to normal size.
class TwoFingerZoom extends StatefulWidget {
  final Widget child;

  const TwoFingerZoom({super.key, required this.child});

  @override
  State<TwoFingerZoom> createState() => _TwoFingerZoomState();
}

class _TwoFingerZoomState extends State<TwoFingerZoom> {
  static const double _minScale = 1;
  static const double _maxScale = 2.5;

  /// Close enough to 1× that lifting the fingers should settle back to normal.
  static const double _snapToNormal = 0.02;

  final Map<int, Offset> _points = {};
  double _scale = 1;
  double? _spanAtStart;
  double? _scaleAtStart;

  void _onPointerDown(PointerDownEvent event) {
    _points[event.pointer] = event.localPosition;
    _captureBaseline();
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!_points.containsKey(event.pointer)) return;
    _points[event.pointer] = event.localPosition;
    final spanAtStart = _spanAtStart;
    final scaleAtStart = _scaleAtStart;
    final span = _span();
    if (spanAtStart == null ||
        scaleAtStart == null ||
        span == null ||
        _points.length != 2) {
      return;
    }
    // Ignore a pinch that starts with the fingers almost touching.
    if (spanAtStart < 24) {
      if (span >= 24) _captureBaseline();
      return;
    }
    final next = (scaleAtStart * span / spanAtStart).clamp(
      _minScale,
      _maxScale,
    );
    if ((next - _scale).abs() < 0.005) return;
    setState(() => _scale = next);
  }

  void _onPointerEnd(PointerEvent event) {
    _points.remove(event.pointer);
    if (_points.length == 2) {
      _captureBaseline();
      return;
    }
    _spanAtStart = null;
    _scaleAtStart = null;
    if (_scale != 1 && _scale < 1 + _snapToNormal) {
      setState(() => _scale = 1);
    }
  }

  void _captureBaseline() {
    if (_points.length != 2) {
      _spanAtStart = null;
      _scaleAtStart = null;
      return;
    }
    _spanAtStart = _span();
    _scaleAtStart = _scale;
  }

  double? _span() {
    if (_points.length != 2) return null;
    final points = _points.values.toList(growable: false);
    return (points[0] - points[1]).distance;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerEnd,
      onPointerCancel: _onPointerEnd,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (_scale == 1 ||
              !constraints.hasBoundedWidth ||
              !constraints.hasBoundedHeight) {
            return widget.child;
          }

          final width = constraints.maxWidth / _scale;
          final height = constraints.maxHeight / _scale;
          final mediaQuery = MediaQuery.of(context);
          return ClipRect(
            child: OverflowBox(
              alignment: Alignment.topCenter,
              minWidth: width,
              maxWidth: width,
              minHeight: height,
              maxHeight: height,
              child: Transform.scale(
                scale: _scale,
                alignment: Alignment.topCenter,
                filterQuality: FilterQuality.high,
                child: MediaQuery(
                  data: mediaQuery.copyWith(
                    size: Size(width, height),
                    devicePixelRatio: mediaQuery.devicePixelRatio * _scale,
                    padding: mediaQuery.padding / _scale,
                    viewPadding: mediaQuery.viewPadding / _scale,
                    viewInsets: mediaQuery.viewInsets / _scale,
                    systemGestureInsets:
                        mediaQuery.systemGestureInsets / _scale,
                  ),
                  child: widget.child,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
