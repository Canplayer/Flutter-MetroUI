import 'package:flutter/material.dart';

import '../metro_theme_extensions.dart';
import '../uix_metrics.dart';
import '../uix_typography.dart';
import 'uix_tight_text.dart';

/// The TitleHost and optional SinglePivotHeader in UIXMobile!PageHeader.
///
/// A [Text] in either slot inherits the page style and uses UIX tight text
/// bounds. A Pivot supplies its own pane headers in the page body.
class MetroPageHeader extends StatelessWidget {
  const MetroPageHeader({
    super.key,
    this.title,
    this.singlePivotHeader,
    this.titleStyle,
    this.singlePivotHeaderStyle,
    this.minimumPadding,
    this.titleGap,
    this.singlePivotHeaderBottomGap = 56 * uixScale,
  });

  final Widget? title;
  final Widget? singlePivotHeader;
  final TextStyle? titleStyle;
  final TextStyle? singlePivotHeaderStyle;

  /// Defaults to PageStyle's screen margins for the current orientation.
  final EdgeInsets? minimumPadding;

  /// Distance after the title, in logical pixels. Defaults to 24 design units
  /// before a SinglePivotHeader and 56 before a normal page body.
  final double? titleGap;

  /// Distance from SinglePivotHeader to the page body, in logical pixels.
  final double singlePivotHeaderBottomGap;

  @override
  Widget build(BuildContext context) {
    if (title == null && singlePivotHeader == null) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final heading = theme.extension<MetroHeadingTheme>();
    final color = theme.colorScheme.onSurface;
    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final padding =
        minimumPadding ??
        EdgeInsets.only(
          left: 24 * uixScale,
          top: (landscape ? 32 : 56) * uixScale,
        );

    return SafeArea(
      bottom: false,
      minimum: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title case final child?) ...[
            _heading(
              child,
              TextStyle(
                color: color,
                fontSize: 17 * uixFontScale,
                fontWeight: UixFontWeight.semiBold,
                letterSpacing: 0,
              ).merge(heading?.pageTitleStyle).merge(titleStyle),
            ),
            SizedBox(
              height:
                  titleGap ?? (singlePivotHeader == null ? 56 : 24) * uixScale,
            ),
          ],
          if (singlePivotHeader case final child?) ...[
            _heading(
              child,
              TextStyle(
                    color: color,
                    fontSize: uixPivotHeaderFontSize,
                    fontWeight: UixFontWeight.semiLight,
                    letterSpacing: 0,
                  )
                  .merge(heading?.singlePivotHeaderStyle)
                  .merge(singlePivotHeaderStyle),
            ),
            SizedBox(height: singlePivotHeaderBottomGap),
          ],
        ],
      ),
    );
  }

  Widget _heading(Widget child, TextStyle style) => Semantics(
    header: true,
    child: DefaultTextStyle.merge(
      style: style,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.clip,
      child: child is Text ? UixTightText.fromText(child) : child,
    ),
  );
}
