import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Windows Phone 8.1 XAML ProgressRing, using the phone GENERIC.XBF template.
/// Size constants are scaled from the 480-wide resource by 0.8.
class ProgressRing extends StatefulWidget {
  const ProgressRing({
    super.key,
    this.isActive = false,
    this.size = 46.0,
    this.foreground,
    this.showSixthCircle = true,
    this.semanticLabel,
  });
  final bool isActive;
  final double size;
  final Color? foreground;

  /// The original template hides SixthCircle in its Small state. The native
  /// threshold choosing that state has not yet been verified.
  final bool showSixthCircle;
  final String? semanticLabel;
  @override
  State<ProgressRing> createState() => _ProgressRingState();
}

class _ProgressRingState extends State<ProgressRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock;
  @override
  void initState() {
    super.initState();
    _clock = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4305),
    );
    if (widget.isActive) _clock.repeat();
  }

  @override
  void didUpdateWidget(covariant ProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _clock.repeat();
      } else {
        _clock.stop();
        _clock.value = 0;
      }
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: widget.semanticLabel,
    child: SizedBox.square(
      dimension: widget.size,
      child: widget.isActive
          ? AnimatedBuilder(
              animation: _clock,
              builder: (context, _) => CustomPaint(
                painter: _RingPainter(
                  _clock.value * 4.305,
                  widget.foreground ?? Theme.of(context).colorScheme.onSurface,
                  widget.showSixthCircle,
                ),
              ),
            )
          : null,
    ),
  );
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.time, this.color, this.sixth);
  final double time;
  final Color color;
  final bool sixth;
  static const _times = [0.0, .433, 1.2, 1.617, 2.017, 2.783, 3.217];
  static const _angles = [-110.0, 10.0, 93.0, 205.0, 357.0, 439.0, 585.0];
  // SplineDoubleKeyFrame applies its KeySpline to the segment ending there.
  static const _curves = [
    Curves.linear,
    Cubic(.02, .33, .38, .77),
    Curves.linear,
    Cubic(.57, .17, .95, .75),
    Cubic(0, .19, .07, .72),
    Curves.linear,
    Cubic(0, 0, .95, .37),
  ];
  double _angle(double t, int circle) {
    if (t <= 0) return _angles.first - circle * 6;
    for (var i = 1; i < _times.length; i++) {
      if (t <= _times[i]) {
        final q = ((t - _times[i - 1]) / (_times[i] - _times[i - 1])).clamp(
          0.0,
          1.0,
        );
        double value(int n) =>
            _angles[n] - circle * 6 - (n == 4 && circle >= 4 ? 2 : 0);
        return value(i - 1) +
            (value(i) - value(i - 1)) * _curves[i].transform(q);
      }
    }
    return _angles.last - circle * 6;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 57.5;
    final c = size.center(Offset.zero);
    // Ellipse 6.5 with 7.5 margin, rotated by a center-origin Canvas.
    final origin = Offset(
      (7.5 + 6.5 / 2 - 57.5 / 2) * scale,
      (7.5 + 6.5 / 2 - 57.5 / 2) * scale,
    );
    final paint = Paint()..color = color;
    for (var i = 0; i < (sixth ? 6 : 5); i++) {
      final local = time - i * .167;
      if (local < 0 || local >= 3.22) continue;
      final r = _angle(local, i) * math.pi / 180;
      final pt = Offset(
        origin.dx * math.cos(r) - origin.dy * math.sin(r),
        origin.dx * math.sin(r) + origin.dy * math.cos(r),
      );
      canvas.drawCircle(c + pt, 3.25 * scale, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.time != time || old.color != color || old.sixth != sixth;
}
