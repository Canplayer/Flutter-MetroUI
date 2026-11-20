import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../uix_metrics.dart';
import '../uix_typography.dart';
import 'uix_text.dart';

/// The text part of Phone!Controls.uix!DoubleLinePushItem.
///
/// Phone!Styles.uix!PushIn/PopOut animate opacity and uniform XY scale on the
/// text panel. The separately docked image button stays in place.
class PushableDoubleLineListItem extends StatefulWidget {
  const PushableDoubleLineListItem({
    super.key,
    required this.header,
    required this.subHeader,
    required this.headerColor,
    required this.subHeaderColor,
    this.leading,
    this.onPressed,
    this.highlightQuery,
    this.highlightColor,
    this.enabled = true,
  });

  final String header;
  final String subHeader;
  final Color headerColor;
  final Color subHeaderColor;
  final Widget? leading;
  final VoidCallback? onPressed;
  final String? highlightQuery;
  final Color? highlightColor;
  final bool enabled;

  @override
  State<PushableDoubleLineListItem> createState() =>
      _PushableDoubleLineListItemState();
}

class _PushableDoubleLineListItemState extends State<PushableDoubleLineListItem>
    with SingleTickerProviderStateMixin {
  late final _push = AnimationController(vsync: this);

  bool _pressed = false;

  void _setPressed(bool pressed) {
    if (_pressed == pressed) return;
    _pressed = pressed;
    _push.animateTo(
      pressed ? 1 : 0,
      duration: Duration(milliseconds: pressed ? 100 : 300),
    );
  }

  @override
  void dispose() {
    _push.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          // UIXMobileAssets.Constants::ProgressBarDoubleLineListItemHeaderMargins
          padding: const EdgeInsets.only(
            top: 10 * uixScale,
            bottom: 4 * uixScale,
          ),
          child: UixText.rich(
            _headerText(),
            overflow: TextOverflow.fade,
            style: TextStyle(
              fontSize: uixFontSize(28),
              fontWeight: UixFontWeight.semiLight,
              color: widget.headerColor,
            ),
            boundsType: UixTextBounds.tight,
            maxLines: 1,
            softWrap: false,
          ),
        ),
        Padding(
          // ProgressBarDoubleLineListItemSubHeaderMargins
          padding: const EdgeInsets.only(top: 8 * uixScale),
          child: UixText(
            widget.subHeader,
            overflow: TextOverflow.fade,
            style: TextStyle(
              fontSize: uixFontSize(15),
              fontWeight: UixFontWeight.normal,
              color: widget.subHeaderColor,
            ),
            boundsType: UixTextBounds.tight,
            maxLines: 1,
            softWrap: false,
          ),
        ),
      ],
    );
    return ConstrainedBox(
      // PhoneRes Constants::PushableDoubleLineListBackgroundMinimumsize
      constraints: const BoxConstraints(minHeight: 82 * uixScale),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: uixScale),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.leading != null) widget.leading!,
            Expanded(
              child: RawGestureDetector(
                behavior: HitTestBehavior.opaque,
                gestures: {
                  if (widget.enabled)
                    _PushClicker:
                        GestureRecognizerFactoryWithHandlers<_PushClicker>(
                          _PushClicker.new,
                          (clicker) => clicker
                            ..onTap = widget.onPressed ?? () {}
                            ..onPressChanged = _setPressed,
                        ),
                },
                child: AnimatedBuilder(
                  animation: _push,
                  child: content,
                  builder: (context, child) => Transform.scale(
                    scale: 1 - (1 - 0.975) * _push.value,
                    child: Opacity(
                      opacity: widget.enabled ? 1 - 0.5 * _push.value : 0.5,
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextSpan _headerText() {
    final query = widget.highlightQuery;
    final header = widget.header;
    if (query == null || query.isEmpty) return TextSpan(text: header);

    final matches = RegExp(
      RegExp.escape(query),
      caseSensitive: false,
    ).allMatches(header);
    final spans = <TextSpan>[];
    var offset = 0;
    for (final match in matches) {
      spans.add(TextSpan(text: header.substring(offset, match.start)));
      spans.add(
        TextSpan(
          text: match[0],
          style: TextStyle(color: widget.highlightColor),
        ),
      );
      offset = match.end;
    }
    spans.add(TextSpan(text: header.substring(offset)));
    return TextSpan(children: spans);
  }
}

class _PushClicker extends TapGestureRecognizer {
  ValueChanged<bool>? onPressChanged;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    if (primaryPointer == event.pointer) onPressChanged?.call(true);
  }

  @override
  void handlePrimaryPointer(PointerEvent event) {
    if (event is PointerUpEvent || event is PointerCancelEvent) {
      onPressChanged?.call(false);
    }
    super.handlePrimaryPointer(event);
  }

  @override
  void rejectGesture(int pointer) {
    if (primaryPointer == pointer) onPressChanged?.call(false);
    super.rejectGesture(pointer);
  }
}
