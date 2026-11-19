import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../animations.dart';

/// Gives UIX popup routes an overlay above the shared Application Bar.
class UixPopupLayer extends InheritedWidget {
  UixPopupLayer({super.key, required Widget child})
    : super(child: Overlay.wrap(child: child));

  @override
  bool updateShouldNotify(UixPopupLayer oldWidget) => false;
}

/// UIXMobile!PopupControl default, using the Swivel show and hide tracks.
class UixPopupRoute<T> extends RawDialogRoute<T> {
  UixPopupRoute({
    required Brightness brightness,
    required super.pageBuilder,
    this.useSafeArea = false,
  }) : super(
         barrierDismissible: false,
         barrierColor: brightness == Brightness.dark
             ? const Color(0xaa000000)
             : const Color(0xaaffffff),
         transitionDuration: const Duration(milliseconds: 300),
       );

  final bool useSafeArea;
  late final _portal = OverlayPortalController()..show();

  bool get _hasPopupLayer =>
      navigator?.context.getInheritedWidgetOfExactType<UixPopupLayer>() != null;

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 200);

  @override
  Widget buildModalBarrier() => _hasPopupLayer
      ? const ModalBarrier(dismissible: false)
      : super.buildModalBarrier();

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> transition,
    Animation<double> secondary,
    Widget child,
  ) {
    final panel = _animatePanel(transition, child);
    if (!_hasPopupLayer || offstage) return panel;

    // The portal keeps the popup in the route's widget tree while painting
    // its scrim and panel above the Navigator and shared Application Bar.
    return OverlayPortal(
      controller: _portal,
      overlayLocation: OverlayChildLocation.rootOverlay,
      overlayChildBuilder: (context) => Stack(
        fit: StackFit.expand,
        children: [super.buildModalBarrier(), panel],
      ),
    );
  }

  Widget _animatePanel(Animation<double> transition, Widget child) {
    final reversing = transition.status == AnimationStatus.reverse;
    final t = reversing ? 1 - transition.value : transition.value;
    // Swivel's axis is X and the Y pivot is the middle of the popup.
    final rotation = reversing
        ? const UixExp(150).transform(t) * math.pi / 3
        : (const UixLog(200).transform(t) - 1) * math.pi / 4;
    final alpha = reversing
        ? ((1 - t) * 200).clamp(0.0, 1.0)
        : (t * 30).clamp(0.0, 1.0);
    final panel = Align(
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
    return useSafeArea ? SafeArea(child: panel) : panel;
  }
}
