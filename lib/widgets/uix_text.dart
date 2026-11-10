import 'package:flutter/widgets.dart';
import 'package:metro_ui/uix_metrics.dart';

/// Centres a single-line label optically rather than by its line box.
///
/// Flutter centres the font line box, which for Segoe WP is lopsided (1.0791 em
/// above the baseline, 0.2510 em below), so capitals end up
/// [uixOpticalTextOffset] below the middle. This shifts the label back so the
/// cap box is centred.
///
/// Children that are not a [Text] (icons, custom paint) have no font line box to
/// correct and are passed through untouched.
class UixOpticalText extends StatelessWidget {
  const UixOpticalText({
    super.key,
    required this.fontSize,
    required this.child,
  });

  final double fontSize;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (child is! Text) return child;
    return Transform.translate(
      offset: Offset(0, uixOpticalTextOffset(fontSize)),
      child: child,
    );
  }
}
