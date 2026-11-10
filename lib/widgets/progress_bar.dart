import 'package:flutter/material.dart';
import 'package:metro_ui/animations.dart';

/// Windows Phone 8.0 native (UIX) ProgressBar, decoded from
/// `UIXMobile!ProgressBar.uix` and `UIXMobile!Styles.uix!ProgressBarStyle`.
///
/// The 480-wide design units are scaled by 0.8: 4 -> 3.2 logical pixels.
/// A null [value] selects the indeterminate state with five 3.2x3.2 squares.
class ProgressBar extends StatefulWidget {
  const ProgressBar({
    super.key,
    this.value,
    this.foreground,
    this.background,
    this.height = 3.2,
    this.minWidth = 3.2,
    this.semanticLabel,
  });

  /// 0..1 for the determinate state. Null renders the indeterminate animation.
  final double? value;

  /// Indicator color. Defaults to the theme accent color.
  final Color? foreground;

  /// Track color. Defaults to the accent color at 10% opacity.
  final Color? background;

  /// Bar height, and the edge length of each indeterminate square.
  final double height;

  /// `Constants.ProgressBarMinimumWidth` (4 * 0.8).
  final double minWidth;

  final String? semanticLabel;

  @override
  State<ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<ProgressBar>
    with TickerProviderStateMixin {
  late final AnimationController _indeterminate = AnimationController(
    vsync: this,
    duration: ProgressBarTimeline.cycle,
  );
  late final AnimationController _determinate = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 150),
  );
  late double _from = widget.value ?? 0;
  late double _to = widget.value ?? 0;

  @override
  void initState() {
    super.initState();
    if (widget.value == null) {
      _indeterminate.repeat();
    } else {
      _determinate.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant ProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasIndeterminate = oldWidget.value == null;
    if (widget.value == null) {
      if (!wasIndeterminate) _indeterminate.repeat();
      return;
    }
    _indeterminate.stop();
    if (wasIndeterminate) {
      _from = widget.value!;
      _to = widget.value!;
      _determinate.value = 1;
    } else if (widget.value != oldWidget.value) {
      _from = _displayedValue;
      _to = widget.value!;
      _determinate.forward(from: 0);
    }
  }

  double get _displayedValue => _from + (_to - _from) * _determinate.value;

  @override
  void dispose() {
    _indeterminate.dispose();
    _determinate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.foreground ?? Theme.of(context).colorScheme.primary;
    final track = widget.background ?? color.withValues(alpha: 0.1);
    return Semantics(
      label: widget.semanticLabel,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: widget.minWidth),
        child: ClipRect(
          child: SizedBox(
            height: widget.height,
            width: double.infinity,
            child: RepaintBoundary(
              child: widget.value == null
                  ? AnimatedBuilder(
                      animation: _indeterminate,
                      builder: (context, _) => CustomPaint(
                        painter: _ProgressBarPainter(
                          color: color,
                          track: track,
                          height: widget.height,
                          seconds:
                              _indeterminate.value *
                              ProgressBarTimeline.cycle.inMicroseconds /
                              Duration.microsecondsPerSecond,
                        ),
                      ),
                    )
                  : AnimatedBuilder(
                      animation: _determinate,
                      builder: (context, _) => CustomPaint(
                        painter: _ProgressBarPainter(
                          color: color,
                          track: track,
                          height: widget.height,
                          value: _displayedValue.clamp(0.0, 1.0),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The loop decoded from `StaticResources` in `ProgressBar.uix`.
///
/// Each square shares one keyframe animation and is staggered by
/// `Index * 0.2s`; `Extend` pads every track to the same 4.4 s loop, so all
/// five restart together. Translation values are multiples of the container
/// width (`TransformByAttributeAnimation`, `Attribute=Width`, `Magnitude=1`).
abstract final class ProgressBarTimeline {
  static const Duration cycle = Duration(milliseconds: 4400);
  static const List<double> delays = [0, 0.2, 0.4, 0.6, 0.8];
  static const List<double> keyTimes = [0, 0.5, 2.0, 2.6, 3.6];
  static const List<double> keyValues = [0, 0.4, 0.65, 1.4, 1.4];

  /// Interpolation attached to the keyframe that starts each segment
  /// (`Log(10.0)` before 0.5 s, `Exp(10.0)` before 2.6 s).
  static const List<Curve> segmentCurves = [
    UixLog(10),
    Curves.linear,
    UixExp(10),
    Curves.linear,
  ];

  /// Translation of square [index] at loop time [seconds], in container widths.
  static double offsetFraction(double seconds, int index) {
    var t = (seconds - delays[index]) % _cycleSeconds;
    if (t < 0) t += _cycleSeconds;
    for (var i = 1; i < keyTimes.length; i++) {
      if (t <= keyTimes[i]) {
        final span = keyTimes[i] - keyTimes[i - 1];
        final q = ((t - keyTimes[i - 1]) / span).clamp(0.0, 1.0);
        final eased = segmentCurves[i - 1].transform(q);
        return keyValues[i - 1] + (keyValues[i] - keyValues[i - 1]) * eased;
      }
    }
    return keyValues.last;
  }

  static const double _cycleSeconds = 4.4;
}

class _ProgressBarPainter extends CustomPainter {
  _ProgressBarPainter({
    required this.color,
    required this.track,
    required this.height,
    this.seconds,
    this.value,
  });

  final Color color;
  final Color track;
  final double height;

  /// Loop time for the indeterminate state; null for determinate.
  final double? seconds;
  final double? value;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = track);
    final paint = Paint()..color = color;
    final t = seconds;
    if (t == null) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width * (value ?? 0), size.height),
        paint,
      );
      return;
    }
    // Square i sits at Margin.Left = i * spacing - MinimumWidth, with
    // spacing == MinimumWidth == the square size.
    for (var i = 0; i < ProgressBarTimeline.delays.length; i++) {
      final x =
          (i - 1) * height +
          ProgressBarTimeline.offsetFraction(t, i) * size.width;
      canvas.drawRect(Rect.fromLTWH(x, 0, height, height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressBarPainter old) =>
      old.seconds != seconds ||
      old.value != value ||
      old.color != color ||
      old.track != track ||
      old.height != height;
}
