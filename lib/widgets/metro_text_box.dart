import 'package:flutter/material.dart';
import 'package:metro_ui/uix_metrics.dart';

/// Windows Phone 8.0 native (UIX) EditBox, scaled by 0.8.
///
/// Padding, font size and margins come from `UIXMobileAssets480x800!Constants`
/// (`EditBoxPadding` 10,4,10,10 -> 8,3.2,8,8; `EditBoxStyleFontSize` 19;
/// `EditBoxMargins` 0,12,0,12 -> 0,9.6,0,9.6).
///
/// Height: `EditBoxStyle.MinimumSize` is `ButtonMinimumSize + AntiAliasingEdgeWidth*2`
/// = (136,48) + (1,1)*2 = 138x50; the 2 AA edges are painted outside the
/// layout box, so the visible frame is 48 design units = 38.4 logical.
class EditBox extends StatefulWidget {
  const EditBox({
    super.key,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.hintText,
    this.enabled = true,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
    this.onSubmitted,
  });
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? hintText;
  final bool enabled;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int? maxLines;

  @override
  State<EditBox> createState() => _EditBoxState();
}

class _EditBoxState extends State<EditBox> {
  FocusNode? _ownedFocusNode;

  FocusNode get _focusNode =>
      widget.focusNode ?? (_ownedFocusNode ??= FocusNode());

  @override
  void dispose() {
    _ownedFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    // `EditBoxStyle.Foreground` = BaseBlackColor, `PlaceholderColor` =
    // BlendWithPageBackground(TextMidColor), `HighlightColor` = accent.
    const foreground = Colors.black;
    final placeholderColor = Colors.black.withValues(alpha: 0.55);
    final accent = theme.colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12 * 0.8),
      child: TextSelectionTheme(
        data: TextSelectionThemeData(
          cursorColor: foreground,
          selectionColor: accent,
          selectionHandleColor: accent,
        ),
        child: ListenableBuilder(
          listenable: _focusNode,
          builder: (context, _) => _EditBoxFrame(
            enabled: widget.enabled,
            focused: _focusNode.hasFocus,
            accent: accent,
            dark: dark,
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              enabled: widget.enabled,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              maxLines: widget.maxLines,
              // UIX line boxes are 1 em; Material's 1.43 leading would overflow
              // the 48-unit frame once the 4/3 font correction is applied.
              style: TextStyle(
                fontSize: uixFontSize(19),
                height: uixLineHeight,
                color: foreground,
              ),
              // The hint uses its own style, otherwise it keeps Material's
              // small default size instead of the UIX font.
              //
              // `InputDecoration.collapsed` is deliberate: with an
              // `OutlineInputBorder` the decorator paints the border around its
              // own *content* height, so a forced 48-unit frame left the top 23 px
              // framed and the rest blank. The frame is drawn by [_EditBoxFrame]
              // instead, exactly like the 9-grid `MediumBorder` bitmap the system
              // paints as a background over the content box.
              decoration: InputDecoration.collapsed(
                hintText: widget.hintText,
                hintStyle: TextStyle(
                  fontSize: uixFontSize(19),
                  height: uixLineHeight,
                  color: placeholderColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The EditBox frame: a 48-unit box with the `MediumBorder` ring and the
/// `EditBoxBackgroundBrush` fill, with the text laid out on top of it.
class _EditBoxFrame extends StatelessWidget {
  const _EditBoxFrame({
    required this.enabled,
    required this.focused,
    required this.accent,
    required this.dark,
    required this.child,
  });

  final bool enabled;
  final bool focused;
  final Color accent;
  final bool dark;
  final Widget child;

  /// `Constants.EditBoxPadding` = 10,4,10,10 design units. The border is drawn
  /// *over* the padding (the system paints it as a background bitmap), so the
  /// text starts 4 units below the top edge of the frame.
  static const EdgeInsets _padding = EdgeInsets.fromLTRB(
    10 * 0.8,
    4 * 0.8,
    10 * 0.8,
    10 * 0.8,
  );

  @override
  Widget build(BuildContext context) {
    // `EditBoxStyle` normal branch:
    //   BackgroundImage        = EditBoxBackgroundImage (9-grid theme bitmap)
    //   FocusedBackgroundImage = MediumBorderAccentWhiteFill
    //   DisabledBackgroundImage= MediumBorderDisabled (ring at alpha 102)
    // The idle bitmap is a flat translucent panel with **no ring at all**; the
    // accent ring only appears once the box has key focus.
    final Color? borderColor = !enabled
        ? Colors.black.withValues(alpha: 102 / 255)
        : focused
        ? accent
        : null;
    final Color? fillColor = !enabled
        ? null
        : focused
        ? Colors.white
        : (dark
              // ui.dark.editbox.background.png: white at alpha 191/255.
              ? Colors.white.withValues(alpha: 191 / 255)
              // ui.light.editbox.background.png: black at alpha 38/255.
              : Colors.black.withValues(alpha: 38 / 255));
    return Container(
      // EditBoxStyle.MinimumSize = ButtonMinimumSize + AA*2 = (138, 50); the
      // two 1-unit anti-aliasing edges are painted outside the layout box, so
      // the frame is 48 design units tall.
      constraints: const BoxConstraints.tightFor(height: 48 * 0.8),
      padding: _padding,
      decoration: BoxDecoration(color: fillColor),
      foregroundDecoration: BoxDecoration(
        border: borderColor == null
            ? null
            : Border.all(color: borderColor, width: 3 * 0.8),
      ),
      // `EditBoxPadding` (4 top / 10 bottom) sits on the horizontal
      // ScrollViewer's content, and a ScrollViewer centres its content on the
      // cross axis. So it is the *padded block* that is centred, not the text:
      // the 4/10 asymmetry is what keeps the glyphs optically centred.
      child: Center(child: child),
    );
  }
}

/// Compatibility alias; appearance and state handling are not yet verified.
typedef MetroTextBox = EditBox;
