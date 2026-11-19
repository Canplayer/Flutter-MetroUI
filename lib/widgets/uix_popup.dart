import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../animations.dart';

/// UIXMobile!PopupControl default, using the Swivel show and hide tracks.
class UixPopupRoute<T> extends RawDialogRoute<T> {
  UixPopupRoute({required Brightness brightness, required super.pageBuilder})
    : super(
        barrierDismissible: false,
        barrierColor: brightness == Brightness.dark
            ? const Color(0xaa000000)
            : const Color(0xaaffffff),
        transitionDuration: const Duration(milliseconds: 300),
        transitionBuilder: _animatePanel,
      );

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 200);

  static Widget _animatePanel(
    BuildContext context,
    Animation<double> transition,
    Animation<double> secondary,
    Widget child,
  ) {
    final reversing = transition.status == AnimationStatus.reverse;
    final t = reversing ? 1 - transition.value : transition.value;
    // Swivel's axis is X and the Y pivot is the middle of the popup.
    final rotation = reversing
        ? const UixExp(150).transform(t) * math.pi / 3
        : (const UixLog(200).transform(t) - 1) * math.pi / 4;
    final alpha = reversing
        ? ((1 - t) * 200).clamp(0.0, 1.0)
        : (t * 30).clamp(0.0, 1.0);
    return Align(
      alignment: Alignment.topCenter,
      child: IgnorePointer(
        ignoring: reversing || t < 1,
        child: Opacity(
          opacity: alpha,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()..rotateX(rotation),
            child: child,
          ),
        ),
      ),
    );
  }
}
