import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../uix_metrics.dart';
import '../uix_typography.dart';

/// Phone!Keypad_Content.uix!Keypad_Content on the WP8 480-wide resource grid.
///
/// The reference cell is 154×106, spacing is 6 in each direction, and the
/// panel has 3 units of padding. The owner supplies the phone color roles.
class PhoneKeypad extends StatelessWidget {
  const PhoneKeypad({
    super.key,
    required this.background,
    required this.pressedBackground,
    required this.foreground,
    required this.secondaryForeground,
    required this.pressedForeground,
    required this.onKey,
    this.onHoldOne,
    this.highContrast = false,
    this.inCall = false,
  });

  static const double referenceWidth = 480 * uixScale;
  static const double referenceHeight = (4 * 106 + 3 * 6 + 2 * 3) * uixScale;

  final Color background;
  final Color pressedBackground;
  final Color foreground;
  final Color secondaryForeground;
  final Color pressedForeground;
  final ValueChanged<String> onKey;
  final VoidCallback? onHoldOne;
  final bool highContrast, inCall;

  static const _digits = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '*',
    '0',
    '#',
  ];
  // PhoneRes EN-US: IDS_KEYPADBUTTON*_SECONDARY (10001–10034).
  static const _secondary = [
    '',
    'ABC',
    'DEF',
    'GHI',
    'JKL',
    'MNO',
    'PQRS',
    'TUV',
    'WXYZ',
    '',
    '+',
    '',
  ];

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      // PhoneShellUI!Keypad_Content uses 156×72 cells, 4-unit gaps,
      // and 2-unit outer inset. Phone!Dialer uses a distinct template.
      final layoutHeight = inCall ? 304 * uixScale : referenceHeight;
      final scale = math.min(
        1.0,
        math.min(
          constraints.maxWidth / referenceWidth,
          constraints.maxHeight / layoutHeight,
        ),
      );
      final gap = (inCall ? 4 : 6) * uixScale;
      if (scale <= 0) return const SizedBox.shrink();
      return Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 1,
        child: SizedBox(
          width: referenceWidth * scale,
          height: layoutHeight * scale,
          child: Padding(
            padding: EdgeInsets.all((inCall ? 2 : 3) * uixScale * scale),
            child: Column(
              children: [
                for (var row = 0; row < 4; row++) ...[
                  if (row > 0) SizedBox(height: gap * scale),
                  Expanded(
                    child: Row(
                      children: [
                        for (var col = 0; col < 3; col++) ...[
                          if (col > 0) SizedBox(width: gap * scale),
                          Expanded(child: _key(row * 3 + col, scale)),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );

  Widget _key(int index, double scale) {
    final digit = _digits[index];
    return _Key(
      key: ValueKey('phone-key-$digit'),
      digit: digit,
      secondary: inCall && digit == '0' ? '' : _secondary[index],
      scale: scale,
      inCall: inCall,
      background: background,
      pressedBackground: pressedBackground,
      foreground: foreground,
      secondaryForeground: secondaryForeground,
      pressedForeground: pressedForeground,
      highContrast: highContrast,
      onTap: () => onKey(digit),
      onHold: inCall
          ? null
          : digit == '0'
          ? () => onKey('+')
          : digit == '1'
          ? onHoldOne
          : null,
    );
  }
}

class _Key extends StatefulWidget {
  const _Key({
    super.key,
    required this.digit,
    required this.secondary,
    required this.scale,
    required this.inCall,
    required this.background,
    required this.pressedBackground,
    required this.foreground,
    required this.secondaryForeground,
    required this.pressedForeground,
    required this.highContrast,
    required this.onTap,
    this.onHold,
  });

  final String digit;
  final String secondary;
  final double scale;
  final Color background,
      pressedBackground,
      foreground,
      secondaryForeground,
      pressedForeground;
  final bool highContrast, inCall;
  final VoidCallback onTap;
  final VoidCallback? onHold;

  @override
  State<_Key> createState() => _KeyState();
}

class _KeyState extends State<_Key> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final symbol = widget.digit == '*' || widget.digit == '#';
    final isStar = widget.digit == '*';
    final callMargins = isStar
        ? const EdgeInsetsDirectional.only(
            start: -3 * uixScale,
            top: -15 * uixScale,
          )
        : EdgeInsetsDirectional.only(
            end: (symbol ? 8 : 16) * uixScale,
            bottom: 4 * uixScale,
          );
    final margins =
        (widget.inCall
                ? callMargins
                : isStar
                ? const EdgeInsetsDirectional.only(top: 5 * uixScale)
                : symbol
                ? const EdgeInsetsDirectional.only(top: -uixScale)
                : const EdgeInsetsDirectional.only(
                    end: 7 * uixScale,
                    bottom: 4 * uixScale,
                  ))
            .resolve(Directionality.of(context)) *
        widget.scale;
    final size = widget.inCall
        ? (isStar ? 66.0 : 32.0)
        : isStar
        ? 68.0
        : symbol
        ? 36.0
        : 43.0;
    final digit = _digit(size, isStar);
    final primary = Transform.translate(
      offset: Offset(
        (margins.left - margins.right) / (symbol ? 2 : 1),
        (margins.top - margins.bottom) / 2,
      ),
      child: digit,
    );
    final secondarySize = widget.digit == '0' ? 21.0 : 14.0;

    return Semantics(
      button: true,
      label: widget.digit,
      onTap: widget.onTap,
      onLongPress: widget.onHold,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onLongPressStart: widget.onHold == null
            ? null
            : (_) {
                _setPressed(true);
                widget.onHold!();
              },
        onLongPressEnd: widget.onHold == null
            ? null
            : (_) => _setPressed(false),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _pressed ? widget.pressedBackground : widget.background,
            border: widget.highContrast && !_pressed
                ? Border.all(color: widget.foreground, width: 3 * uixScale)
                : null,
          ),
          child: symbol
              ? Center(child: primary)
              : Row(
                  children: [
                    // The two-column text grid carries the digit and its suffix
                    // in distinct nodes (CommsAppsShared!PhoneControls).
                    Expanded(
                      child: Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: primary,
                      ),
                    ),
                    Expanded(
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          widget.secondary,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: uixFontSize(secondarySize) * widget.scale,
                            fontWeight: UixFontWeight.normal,
                            color: _pressed
                                ? widget.pressedForeground
                                : widget.secondaryForeground,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _digit(double size, bool light) => Text(
    widget.digit,
    maxLines: 1,
    style: TextStyle(
      fontSize: uixFontSize(size) * widget.scale,
      fontWeight: light ? UixFontWeight.light : UixFontWeight.normal,
      color: _pressed ? widget.pressedForeground : widget.foreground,
    ),
  );
}
