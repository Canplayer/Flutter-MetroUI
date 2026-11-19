import 'package:flutter/widgets.dart';

import '../animations.dart';
import '../uix_metrics.dart';

/// UIXMobile!Animations.uix SlideUpFadeIn / SlideDownFadeOut.
/// [fromTop] selects the mirrored pair used by SearchBarUI.
class UixPageSlide extends StatefulWidget {
  const UixPageSlide({
    super.key,
    required this.child,
    this.initiallyVisible = true,
    this.fromTop = false,
  });

  static const inDuration = Duration(milliseconds: 350);
  static const outDuration = Duration(milliseconds: 250);
  static const offset = 200 * uixScale;

  final Widget child;
  final bool initiallyVisible;
  final bool fromTop;

  @override
  State<UixPageSlide> createState() => UixPageSlideState();
}

class UixPageSlideState extends State<UixPageSlide>
    with SingleTickerProviderStateMixin {
  late final _timeline = AnimationController(vsync: this, value: 1);
  late bool _showing = widget.initiallyVisible;

  Future<void> show() => _play(true);

  Future<void> hide() => _play(false);

  Future<void> _play(bool showing) async {
    _showing = showing;
    _timeline.duration = showing
        ? UixPageSlide.inDuration
        : UixPageSlide.outDuration;
    try {
      await _timeline.forward(from: 0).orCancel;
    } on TickerCanceled {
      // A newer visibility change or disposal replaced this transition.
    }
  }

  @override
  void dispose() {
    _timeline.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _timeline,
    child: widget.child,
    builder: (context, child) {
      final t = _timeline.value;
      final distance = _showing
          ? 1 - const UixLog(150).transform(t)
          : const UixExp(150).transform(t);
      final milliseconds =
          t *
          (_showing ? UixPageSlide.inDuration : UixPageSlide.outDuration)
              .inMilliseconds;
      final opacity = _showing
          ? (milliseconds / 10).clamp(0.0, 1.0)
          : ((250 - milliseconds) / 10).clamp(0.0, 1.0);
      return IgnorePointer(
        ignoring: t < 1 || !_showing,
        child: Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(
              0,
              UixPageSlide.offset * distance * (widget.fromTop ? -1 : 1),
            ),
            child: child,
          ),
        ),
      );
    },
  );
}
