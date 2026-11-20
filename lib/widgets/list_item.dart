import 'package:flutter/material.dart';
import 'package:metro_ui/uix_metrics.dart';
import 'package:metro_ui/uix_typography.dart';
import 'package:metro_ui/metro_theme_extensions.dart';
import 'package:metro_ui/widgets/tile.dart';

import 'uix_text.dart';

/// UIX List.uix!SingleLineListItem. Does not add PageMargins: the page owns them.
class SingleLineListItem extends StatelessWidget {
  const SingleLineListItem({
    super.key,
    required this.headerText,
    this.onTap,
    this.enabled = true,
    this.allowHeaderToWrap = false,
    this.headerStyle,
    this.leading,
    this.trailing,
  });
  final String headerText;
  final TextStyle? headerStyle;
  final Widget? leading, trailing;
  final VoidCallback? onTap;
  final bool enabled, allowHeaderToWrap;
  @override
  Widget build(BuildContext context) => _ListItemContent(
    headerText: headerText,
    onTap: onTap,
    enabled: enabled,
    wrap: allowHeaderToWrap,
    headerStyle: headerStyle,
    leading: leading,
    trailing: trailing,
  );
}

/// UIX List.uix!DoubleLineListItem, used by SettingsUI GeneralCPLListItem.
class DoubleLineListItem extends StatelessWidget {
  const DoubleLineListItem({
    super.key,
    required this.headerText,
    required this.subHeaderText,
    this.onTap,
    this.enabled = true,
    this.allowHeaderToWrap = false,
    this.headerStyle,
    this.subHeaderStyle,
    this.leading,
    this.trailing,
  });
  final String headerText, subHeaderText;
  final TextStyle? subHeaderStyle;
  final TextStyle? headerStyle;
  final Widget? leading, trailing;
  final VoidCallback? onTap;
  final bool enabled, allowHeaderToWrap;
  @override
  Widget build(BuildContext context) => _ListItemContent(
    headerText: headerText,
    subHeaderText: subHeaderText,
    subHeaderStyle: subHeaderStyle,
    onTap: onTap,
    enabled: enabled,
    wrap: allowHeaderToWrap,
    headerStyle: headerStyle,
    leading: leading,
    trailing: trailing,
  );
}

class _ListItemContent extends StatelessWidget {
  const _ListItemContent({
    required this.headerText,
    this.subHeaderText,
    required this.onTap,
    required this.enabled,
    required this.wrap,
    this.headerStyle,
    this.subHeaderStyle,
    this.leading,
    this.trailing,
  });
  final String headerText;
  final String? subHeaderText;
  final TextStyle? headerStyle, subHeaderStyle;
  final Widget? leading, trailing;
  final VoidCallback? onTap;
  final bool enabled, wrap;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = theme.colorScheme.onSurface;
    final tokens = theme.extension<MetroListItemTheme>();
    final highContrast = MetroSystemThemeData.of(context).highContrast;
    final disabled =
        tokens?.disabledColor ??
        (highContrast ? theme.disabledColor : foreground.withValues(alpha: .2));
    final secondary = highContrast
        ? foreground
        : foreground.withValues(alpha: .6);
    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.only(
            top: 10 * uixScale,
            bottom: subHeaderText == null ? 46 * uixScale : 0,
          ),
          child: UixText.fromText(
            Text(
              headerText,
              maxLines: wrap ? 2 : 1,
              softWrap: wrap,
              overflow: TextOverflow.clip,
              style: TextStyle(
                fontSize: uixFontSize(28),
                fontWeight: UixFontWeight.semiLight,
                color: enabled ? foreground : disabled,
              ).merge(tokens?.headerStyle).merge(headerStyle),
            ),
            boundsType: UixTextBounds.tight,
          ),
        ),
        if (subHeaderText != null)
          Padding(
            padding: const EdgeInsets.only(
              top: 12 * uixScale,
              bottom: 23 * uixScale,
            ),
            child: UixText.fromText(
              Text(
                subHeaderText!,
                softWrap: true,
                style: TextStyle(
                  fontSize: uixFontSize(15),
                  fontWeight: UixFontWeight.normal,
                  color: enabled ? secondary : disabled,
                ).merge(tokens?.subHeaderStyle).merge(subHeaderStyle),
              ),
              boundsType: UixTextBounds.tight,
            ),
          ),
      ],
    );
    if (leading != null || trailing != null) {
      content = Row(
        children: [
          if (leading != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 12),
              child: leading,
            ),
          Expanded(child: content),
          if (trailing != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 12),
              child: trailing,
            ),
        ],
      );
    }
    return Semantics(
      button: onTap != null,
      enabled: enabled,
      child: Tile(
        onTap: enabled ? onTap : null,
        child: SizedBox(width: double.infinity, child: content),
      ),
    );
  }
}
