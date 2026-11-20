import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../src/text/uix_font_catalog.dart';

/// The independent boundary options of WP8 UIX Text.
@immutable
class UixTextBounds {
  const UixTextBounds({
    this.alignToAscender = false,
    this.alignToBaseline = false,
    this.trimLeftSideBearing = false,
  });

  static const full = UixTextBounds();
  static const tight = UixTextBounds(
    alignToAscender: true,
    alignToBaseline: true,
    trimLeftSideBearing: true,
  );

  /// Uses the font's cap-height line as the top layout edge.
  final bool alignToAscender;

  /// Uses the alphabetic baseline as the bottom layout edge.
  final bool alignToBaseline;

  /// Removes the positive left side bearing of the leading glyph.
  final bool trimLeftSideBearing;

  bool get _isFull =>
      !alignToAscender && !alignToBaseline && !trimLeftSideBearing;
}

/// Flutter text measured with the selected UIX layout boundaries.
///
/// Font metrics are taken from static assets declared by the application.
/// Text that cannot be measured with a single, resolved font face keeps its
/// normal Flutter layout. The supplied [Text] still shapes and paints the text.
class UixText extends StatelessWidget {
  const UixText(
    String data, {
    super.key,
    this.boundsType = UixTextBounds.full,
    this.style,
    this.overflow,
    this.maxLines,
    this.softWrap,
  }) : _data = data,
       _span = null,
       _original = null;

  const UixText.rich(
    TextSpan span, {
    super.key,
    this.boundsType = UixTextBounds.full,
    this.style,
    this.overflow,
    this.maxLines,
    this.softWrap,
  }) : _span = span,
       _data = null,
       _original = null;

  /// Applies UIX boundaries while preserving the supplied Text properties.
  const UixText.fromText(
    Text text, {
    super.key,
    this.boundsType = UixTextBounds.full,
  }) : _original = text,
       _data = null,
       _span = null,
       style = null,
       overflow = null,
       maxLines = null,
       softWrap = null;

  final Text? _original;
  final String? _data;
  final TextSpan? _span;
  final UixTextBounds boundsType;
  final TextStyle? style;
  final TextOverflow? overflow;
  final int? maxLines;
  final bool? softWrap;

  /// Loads the metrics before displaying text when initial geometry matters.
  ///
  /// Asset-backed fonts declared in pubspec.yaml are discovered automatically.
  /// Use the same bundle as the target widgets when overriding DefaultAssetBundle.
  static Future<void> preloadFontMetrics(
    String family, {
    AssetBundle? bundle,
  }) async {
    await UixFontCatalog.of(bundle ?? rootBundle).load(family);
  }

  @override
  Widget build(BuildContext context) {
    final text =
        _original ??
        Text.rich(
          _span ?? TextSpan(text: _data),
          style: style,
          maxLines: maxLines,
          softWrap: softWrap,
          overflow: overflow,
        );
    if (boundsType._isFull ||
        text.strutStyle != null ||
        MediaQuery.maybeLineHeightScaleFactorOverrideOf(context) != null) {
      return text;
    }

    final defaults = DefaultTextStyle.of(context);
    var resolved = defaults.style.merge(text.style);
    if (MediaQuery.boldTextOf(context)) {
      resolved = resolved.merge(const TextStyle(fontWeight: FontWeight.bold));
    }
    final span = text.textSpan ?? TextSpan(text: text.data);
    final run = _singleFaceText(span, resolved);
    if (run == null || run.content.trim().isEmpty) return text;
    final faceStyle = run.style;
    final family = faceStyle.fontFamily;
    if (family == null || faceStyle.fontVariations?.isNotEmpty == true) {
      return text;
    }

    // Match the Flutter Text constructor's scaling precedence.
    // ignore: deprecated_member_use
    final scaler = switch ((text.textScaler, text.textScaleFactor)) {
      (final TextScaler scaler, _) => scaler,
      (_, final double factor) => TextScaler.linear(factor),
      _ => MediaQuery.textScalerOf(context),
    };
    final fontSize = scaler.scale(faceStyle.fontSize ?? 14);
    if (fontSize == 0) return text;

    Widget measure(List<UixFontFace> faces) {
      final weight = (faceStyle.fontWeight ?? FontWeight.normal).value;
      final italic = faceStyle.fontStyle == FontStyle.italic;
      for (final face in faces) {
        if (face.weight != weight || face.italic != italic) continue;
        final font = face.metrics;
        if (!run.content.runes.every(font.contains)) return text;
        final capHeight = font.capHeight;
        if (boundsType.alignToAscender && capHeight == null) return text;

        final scale = fontSize / font.unitsPerEm;
        final alignment =
            text.textAlign ?? defaults.textAlign ?? TextAlign.start;
        final direction = text.textDirection ?? Directionality.maybeOf(context);
        // Flutter exposes character clusters, but not the shaped glyph IDs.
        // Use the first character’s hmtx bearing for simple Latin labels.
        final trim =
            boundsType.trimLeftSideBearing &&
                direction == TextDirection.ltr &&
                (alignment == TextAlign.start || alignment == TextAlign.left) &&
                faceStyle.fontFeatures?.isNotEmpty != true &&
                _simpleLeftToRight.hasMatch(run.content)
            ? math.max(0, font.leftSideBearing(run.content.runes.first) ?? 0) *
                  scale
            : 0.0;
        final ascent = boundsType.alignToAscender
            ? capHeight! * scale
            : boundsType.alignToBaseline
            ? (font.ascent + font.lineGap) * scale
            : null;
        return _TextBoundsBox(
          ascent: ascent,
          descent: boundsType.alignToBaseline ? 0 : font.descent * scale,
          leftBearing: trim,
          softWrap: text.softWrap ?? defaults.softWrap,
          child: text,
        );
      }
      return text;
    }

    final catalog = UixFontCatalog.of(DefaultAssetBundle.of(context));
    final faces = catalog.faces(family);
    if (faces != null) return measure(faces);
    return FutureBuilder(
      future: catalog.load(family),
      builder: (context, snapshot) =>
          snapshot.hasData ? measure(snapshot.requireData) : text,
    );
  }
}

final _lineBreak = RegExp(r'[\r\n\v\f\u0085\u2028\u2029]');
// Include spaces after the first glyph and common punctuation. Rich spans
// changing only colour still constitute one layout run for these purposes.
final _simpleLeftToRight = RegExp(r'^[A-Za-z0-9][ -~]*$');

({String content, TextStyle style})? _singleFaceText(
  InlineSpan span,
  TextStyle inherited,
) {
  final content = StringBuffer();
  TextStyle? faceStyle;

  bool collect(InlineSpan span, TextStyle parent) {
    if (span is! TextSpan) return false;
    final style = parent.merge(span.style);
    final text = span.text;
    if (text != null && text.isNotEmpty) {
      if (style.height != null || _lineBreak.hasMatch(text)) return false;
      final face = faceStyle ??= style;
      if (style.fontFamily != face.fontFamily ||
          style.fontWeight != face.fontWeight ||
          style.fontStyle != face.fontStyle ||
          style.fontSize != face.fontSize ||
          !listEquals(style.fontFeatures, face.fontFeatures) ||
          !listEquals(style.fontVariations, face.fontVariations)) {
        return false;
      }
      content.write(text);
    }
    return span.children?.every((child) => collect(child, style)) ?? true;
  }

  if (!collect(span, inherited) || faceStyle == null) return null;
  return (content: content.toString(), style: faceStyle!);
}

class _TextBoundsBox extends SingleChildRenderObjectWidget {
  const _TextBoundsBox({
    required this.ascent,
    required this.descent,
    required this.leftBearing,
    required this.softWrap,
    required super.child,
  });

  final double? ascent;
  final double descent;
  final double leftBearing;
  final bool softWrap;

  @override
  _RenderTextBoundsBox createRenderObject(BuildContext context) =>
      _RenderTextBoundsBox(ascent, descent, leftBearing, softWrap);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderTextBoundsBox renderObject,
  ) {
    renderObject.updateMetrics(ascent, descent, leftBearing, softWrap);
  }
}

class _RenderTextBoundsBox extends RenderShiftedBox {
  _RenderTextBoundsBox(
    this._ascent,
    this._descent,
    this._leftBearing,
    this._softWrap,
  ) : super(null);

  double? _ascent;
  double _descent;
  double _leftBearing;
  bool _softWrap;

  void updateMetrics(
    double? ascent,
    double descent,
    double leftBearing,
    bool softWrap,
  ) {
    if (_ascent == ascent &&
        _descent == descent &&
        _leftBearing == leftBearing &&
        _softWrap == softWrap) {
      return;
    }
    _ascent = ascent;
    _descent = descent;
    _leftBearing = leftBearing;
    _softWrap = softWrap;
    markNeedsLayout();
  }

  bool _fitsOneLine(double width) =>
      !_softWrap ||
      child!.getMaxIntrinsicWidth(double.infinity) <= width + _leftBearing;

  Size _fit(BoxConstraints constraints, Size text, bool tight) {
    final ascent = _ascent;
    return constraints.constrain(
      Size(
        tight ? math.max(0, text.width - _leftBearing) : text.width,
        tight && ascent != null ? ascent + _descent : text.height,
      ),
    );
  }

  BoxConstraints _textConstraints(BoxConstraints constraints, bool tight) {
    final bearing = tight ? _leftBearing : 0;
    return BoxConstraints(
      minWidth: constraints.minWidth + bearing,
      maxWidth: constraints.maxWidth + bearing,
    );
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final tight = _fitsOneLine(constraints.maxWidth);
    final text = child!.getDryLayout(_textConstraints(constraints, tight));
    return _fit(constraints, text, tight);
  }

  @override
  void performLayout() {
    final text = child!;
    final tight = _fitsOneLine(constraints.maxWidth);
    text.layout(_textConstraints(constraints, tight), parentUsesSize: true);
    size = _fit(constraints, text.size, tight);
    final ascent = _ascent;
    final baseline = tight && ascent != null
        ? text.getDistanceToBaseline(TextBaseline.alphabetic)
        : null;
    (text.parentData! as BoxParentData).offset = Offset(
      tight ? -_leftBearing : 0,
      baseline == null ? 0 : ascent! - baseline,
    );
  }

  @override
  double? computeDryBaseline(
    BoxConstraints constraints,
    TextBaseline baseline,
  ) {
    final tight = _fitsOneLine(constraints.maxWidth);
    final inner = _textConstraints(constraints, tight);
    final actual = child!.getDryBaseline(inner, baseline);
    final ascent = _ascent;
    if (!tight || ascent == null || actual == null) return actual;
    final alphabetic = child!.getDryBaseline(inner, TextBaseline.alphabetic);
    return alphabetic == null ? actual : actual + ascent - alphabetic;
  }

  @override
  Rect get paintBounds {
    final text = child!;
    final offset = (text.parentData! as BoxParentData).offset;
    return super.paintBounds.expandToInclude(text.paintBounds.shift(offset));
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    final width = child!.getMinIntrinsicWidth(height);
    return _fitsOneLine(width) ? math.max(0, width - _leftBearing) : width;
  }

  @override
  double computeMaxIntrinsicWidth(double height) =>
      math.max(0, child!.getMaxIntrinsicWidth(height) - _leftBearing);

  @override
  double computeMinIntrinsicHeight(double width) =>
      computeDryLayout(BoxConstraints(maxWidth: width)).height;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      computeMinIntrinsicHeight(width);
}
