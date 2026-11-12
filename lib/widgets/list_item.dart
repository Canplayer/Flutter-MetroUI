import 'package:flutter/material.dart';
import 'package:metro_ui/uix_metrics.dart';
import 'package:metro_ui/widgets/tile.dart';

/// UIX List.uix!SingleLineListItem. Does not add PageMargins: the page owns them.
class SingleLineListItem extends StatelessWidget {
  const SingleLineListItem({
    super.key,
    required this.headerText,
    this.onTap,
    this.enabled = true,
    this.allowHeaderToWrap = false,
  });
  final String headerText;
  final VoidCallback? onTap;
  final bool enabled, allowHeaderToWrap;
  @override
  Widget build(BuildContext context) => _ListItemContent(
    headerText: headerText,
    onTap: onTap,
    enabled: enabled,
    wrap: allowHeaderToWrap,
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
  });
  final String headerText, subHeaderText;
  final VoidCallback? onTap;
  final bool enabled, allowHeaderToWrap;
  @override
  Widget build(BuildContext context) => _ListItemContent(
    headerText: headerText,
    subHeaderText: subHeaderText,
    onTap: onTap,
    enabled: enabled,
    wrap: allowHeaderToWrap,
  );
}

class _ListItemContent extends StatelessWidget {
  const _ListItemContent({
    required this.headerText,
    this.subHeaderText,
    required this.onTap,
    required this.enabled,
    required this.wrap,
  });
  final String headerText;
  final String? subHeaderText;
  final VoidCallback? onTap;
  final bool enabled, wrap;
  @override
  Widget build(BuildContext context) {
    final foreground = Theme.of(context).colorScheme.onSurface;
    return Semantics(
      button: onTap != null,
      enabled: enabled,
      child: Tile(
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.only(
                  top: 10 * uixScale,
                  bottom: subHeaderText == null ? 46 * uixScale : 0,
                ),
                child: Text(
                  headerText,
                  maxLines: wrap ? 2 : 1,
                  softWrap: wrap,
                  overflow: TextOverflow.clip,
                  style: TextStyle(
                    fontSize: uixFontSize(28),
                    fontWeight: FontWeight.w300,
                    color: foreground.withValues(alpha: enabled ? 1 : .2),
                  ),
                ),
              ),
              if (subHeaderText != null)
                Padding(
                  padding: const EdgeInsets.only(
                    top: 12 * uixScale,
                    bottom: 23 * uixScale,
                  ),
                  child: Text(
                    subHeaderText!,
                    softWrap: true,
                    style: TextStyle(
                      fontSize: uixFontSize(15),
                      fontWeight: FontWeight.w400,
                      color: foreground.withValues(alpha: enabled ? .6 : .2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
