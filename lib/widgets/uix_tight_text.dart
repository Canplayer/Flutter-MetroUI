import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../src/text/segoe_wp_ink_bounds.dart';

/// UIX label text with vertical bounds fitted to the glyphs on a single line.
///
/// UIX `BoundsType=7` (`Tight`) can use a smaller layout box than a normal
/// Flutter paragraph. The bundled ASCII Segoe WP glyph outlines supply the
/// vertical metrics; Flutter still shapes and paints the text. Other scripts,
/// explicitly supplied line heights, custom fonts and wrapped paragraphs use
/// normal text layout.
class UixTightText extends StatelessWidget {
  const UixTightText(this._text, {super.key, this.style, this.overflow})
    : _span = null,
      _original = null;

  const UixTightText.rich(TextSpan span, {super.key, this.style, this.overflow})
    : _span = span,
      _text = null,
      _original = null;

  /// Applies UIX label bounds while preserving the supplied Text properties.
  const UixTightText.fromText(Text text, {super.key})
    : _original = text,
      _text = null,
      _span = null,
      style = null,
      overflow = null;

  final Text? _original;
  final String? _text;
  final TextSpan? _span;
  final TextStyle? style;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final text =
        _original ??
        Text.rich(
          _span ?? TextSpan(text: _text),
          style: style,
          maxLines: 1,
          softWrap: false,
          overflow: overflow,
        );
    final span = text.textSpan ?? TextSpan(text: text.data);
    if (span is! TextSpan || text.strutStyle != null) return text;
    final defaults = DefaultTextStyle.of(context);
    var resolved = defaults.style.merge(text.style);
    if (MediaQuery.boldTextOf(context)) {
      resolved = resolved.merge(const TextStyle(fontWeight: FontWeight.bold));
    }
    // ignore: deprecated_member_use
    final scaleFactor = text.textScaleFactor;
    final scaler =
        text.textScaler ??
        (scaleFactor == null
            ? MediaQuery.textScalerOf(context)
            : TextScaler.linear(scaleFactor));
    final bounds = _verticalBounds(span, resolved, scaler);
    if (bounds == null) return text;
    return _TightTextBox(
      ascent: bounds.$1,
      descent: bounds.$2,
      softWrap: text.softWrap ?? defaults.softWrap,
      child: text,
    );
  }
}

(double, double)? _verticalBounds(
  TextSpan root,
  TextStyle inherited,
  TextScaler scaler,
) {
  double? ymin;
  double? ymax;

  bool collect(TextSpan span, TextStyle parent) {
    final style = parent.merge(span.style);
    final text = span.text;
    if (text != null && text.isNotEmpty) {
      final family = style.fontFamily;
      final metrics = segoeWpVerticalBounds[style.fontWeight?.value ?? 400];
      if ((family != 'packages/metro_ui/Segoe WP' && family != 'Segoe WP') ||
          metrics == null ||
          style.height != null ||
          style.fontStyle == FontStyle.italic) {
        return false;
      }
      final scale = scaler.scale(style.fontSize ?? 14) / segoeWpUnitsPerEm;
      for (final code in text.codeUnits) {
        if (code == 32) continue;
        if (code < 32 || code > 126) return false;
        final index = 2 * (code - 32);
        final low = metrics[index] * scale;
        final high = metrics[index + 1] * scale;
        ymin = math.min(ymin ?? low, low);
        ymax = math.max(ymax ?? high, high);
      }
    }
    return span.children?.every(
          (child) => child is TextSpan && collect(child, style),
        ) ??
        true;
  }

  if (!collect(root, inherited) || ymin == null || ymax == null) return null;
  return (ymax!, -ymin!);
}

class _TightTextBox extends SingleChildRenderObjectWidget {
  const _TightTextBox({
    required this.ascent,
    required this.descent,
    required this.softWrap,
    super.child,
  });

  final double ascent;
  final double descent;
  final bool softWrap;

  @override
  _RenderTightTextBox createRenderObject(BuildContext context) =>
      _RenderTightTextBox(ascent, descent, softWrap);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderTightTextBox renderObject,
  ) {
    renderObject.updateMetrics(ascent, descent, softWrap);
  }
}

class _RenderTightTextBox extends RenderShiftedBox {
  _RenderTightTextBox(this._ascent, this._descent, this._softWrap)
    : super(null);

  double _ascent;
  double _descent;
  bool _softWrap;

  void updateMetrics(double ascent, double descent, bool softWrap) {
    if (_ascent == ascent && _descent == descent && _softWrap == softWrap) {
      return;
    }
    _ascent = ascent;
    _descent = descent;
    _softWrap = softWrap;
    markNeedsLayout();
  }

  bool _fitsOneLine(double width) =>
      !_softWrap || child!.getMaxIntrinsicWidth(double.infinity) <= width;

  Size _fit(BoxConstraints constraints, Size text, bool tight) => constraints
      .constrain(Size(text.width, tight ? _ascent + _descent : text.height));

  BoxConstraints _textConstraints(BoxConstraints constraints) => BoxConstraints(
    minWidth: constraints.minWidth,
    maxWidth: constraints.maxWidth,
  );

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final text = child!.getDryLayout(_textConstraints(constraints));
    return _fit(constraints, text, _fitsOneLine(constraints.maxWidth));
  }

  @override
  void performLayout() {
    final text = child!;
    text.layout(_textConstraints(constraints), parentUsesSize: true);
    final tight = _fitsOneLine(constraints.maxWidth);
    size = _fit(constraints, text.size, tight);
    final baseline = tight
        ? text.getDistanceToBaseline(TextBaseline.alphabetic)
        : null;
    (text.parentData! as BoxParentData).offset = baseline == null
        ? Offset.zero
        : Offset(0, _ascent - baseline);
  }

  @override
  double? computeDryBaseline(
    BoxConstraints constraints,
    TextBaseline baseline,
  ) => _fitsOneLine(constraints.maxWidth)
      ? _ascent
      : child!.getDryBaseline(_textConstraints(constraints), baseline);

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) =>
      _fitsOneLine(constraints.maxWidth)
      ? _ascent
      : super.computeDistanceToActualBaseline(baseline);

  @override
  double computeMinIntrinsicHeight(double width) => _fitsOneLine(width)
      ? _ascent + _descent
      : child!.getMinIntrinsicHeight(width);

  @override
  double computeMaxIntrinsicHeight(double width) => _fitsOneLine(width)
      ? _ascent + _descent
      : child!.getMaxIntrinsicHeight(width);
}
