import 'package:flutter/material.dart' show Theme;
import 'package:flutter/widgets.dart';

import '../metro_theme_extensions.dart';
import '../uix_metrics.dart';
import '../uix_typography.dart';
import 'tile.dart';
import 'uix_popup.dart';
import 'uix_tight_text.dart';

/// The standard two-button UIXMobile MessageBox (portrait, 480×800 resources).
class MetroMessageBox extends StatelessWidget {
  const MetroMessageBox({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
  });

  final String title, message, confirmLabel, cancelLabel;

  /// Opens the modal with the panel inset to the device's safe area.
  Future<bool?> show(BuildContext context) {
    final theme = Theme.of(context);
    return Navigator.of(context).push(
      UixPopupRoute<bool>(
        brightness: theme.brightness,
        useSafeArea: true,
        pageBuilder: (_, _, _) => Theme(
          data: theme,
          child: DefaultTextStyle(
            style: theme.textTheme.bodyMedium ?? const TextStyle(),
            child: this,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // MessageBoxBodyStyle uses ChromeColor; its title is ExtraLarge/SemiBold
    // and its body is LargeHigh. MessageBoxHeaderAndBodyMargins is (24,54,24,0).
    return ColoredBox(
      color: scheme.surfaceContainer,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 252 * uixScale),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            24 * uixScale,
            54 * uixScale,
            24 * uixScale,
            12 * uixScale,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              UixTightText.fromText(
                Text(
                  title,
                  style: TextStyle(
                    fontSize: uixFontSize(24),
                    fontWeight: UixFontWeight.semiBold,
                    color: scheme.onSurface,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              const SizedBox(height: 40 * uixScale),
              UixTightText.fromText(
                Text(
                  message,
                  style: TextStyle(
                    fontSize: uixFontSize(17),
                    fontWeight: UixFontWeight.normal,
                    color: scheme.onSurface,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              const SizedBox(height: 36 * uixScale),
              Row(
                children: [
                  Expanded(
                    child: MetroTextCommand._dialog(
                      label: confirmLabel,
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ),
                  const SizedBox(width: 24 * uixScale),
                  Expanded(
                    child: MetroTextCommand._dialog(
                      label: cancelLabel,
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Flat text command used by UIX dialogs and the text Application Bar.
class MetroTextCommand extends StatefulWidget {
  const MetroTextCommand({super.key, required this.label, this.onPressed})
    : _isDialogButton = false;

  const MetroTextCommand._dialog({required this.label, this.onPressed})
    : _isDialogButton = true;

  final bool _isDialogButton;

  final String label;
  final VoidCallback? onPressed;

  @override
  State<MetroTextCommand> createState() => _MetroTextCommandState();
}

class _MetroTextCommandState extends State<MetroTextCommand> {
  bool _down = false;

  void _setDown(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = widget.onPressed != null;
    final contrast = MetroSystemThemeData.of(context).highContrast;
    final onSurface = enabled
        ? scheme.onSurface
        : scheme.onSurface.withValues(alpha: .4);
    final label = Text(
      widget.label,
      style: TextStyle(
        fontSize: uixFontSize(17),
        fontWeight: UixFontWeight.semiBold,
        color: _down
            ? contrast
                  ? scheme.surface
                  : const Color(0xffffffff)
            : onSurface,
        decoration: TextDecoration.none,
      ),
    );
    final face = Container(
      height: 48 * uixScale,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _down ? scheme.primary : null,
        border: Border.all(width: 3 * uixScale, color: onSurface),
      ),
      child: widget._isDialogButton ? UixTightText.fromText(label) : label,
    );
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: widget._isDialogButton
          ? Tile(
              // UIX MessageBoxButton inherits Button → ButtonBase → TiltBase.
              localTiltProjection: true,
              onTap: widget.onPressed,
              onTouch: enabled ? _setDown : null,
              child: face,
            )
          : GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onPressed,
              onTapDown: enabled ? (_) => _setDown(true) : null,
              onTapUp: enabled ? (_) => _setDown(false) : null,
              onTapCancel: enabled ? () => _setDown(false) : null,
              child: face,
            ),
    );
  }
}
