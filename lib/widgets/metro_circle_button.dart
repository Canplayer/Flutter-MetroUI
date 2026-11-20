import 'package:flutter/material.dart';
import 'package:metro_ui/application_bar.dart';
import 'package:metro_ui/metro_theme_extensions.dart';
import 'package:metro_ui/widgets/tile.dart';

/// Appearance of the shared circular button frame.
enum MetroCircleFrameStyle {
  /// Resolution-independent ring and fill.
  vector,

  /// WP8 Shell PNGs, with the red pressed fill mapped to the accent color.
  classicBitmap,
}

/// Builds a frame behind the foreground icon.
typedef MetroCircleBackgroundBuilder = Widget Function(
  BuildContext context,
  bool pressed,
  Color foreground,
);

/// Windows Phone 风格的圆形图标按钮（圆环）。
///
/// 对应 WP 原版 ApplicationBarIconButton 的圆环外观：一个带边框的圆形，
/// 中间放置图标，按下时填充主题色。独立成组件，可在任意位置复用。
///
/// 示例：
/// ```dart
/// MetroCircleButton(
///   icon: Icon(Icons.add),
///   borderColor: Colors.white,
///   onPressed: () { ... },
/// )
/// ```
///
/// 纯图标模式（不响应触摸、不受禁用影响）：
/// ```dart
/// MetroCircleButton(
///   icon: Icon(Icons.add),
///   iconMode: true,
/// )
/// ```
///
/// 受控按下（点击其他控件时联动高亮）：
/// ```dart
/// MetroCircleButton(
///   icon: Icon(Icons.add),
///   pressed: isPressed, // 由外部状态驱动
/// )
/// ```
class MetroCircleButton extends StatefulWidget {
  const MetroCircleButton({
    super.key,
    required this.icon,
    this.borderColor,
    this.themeColor,
    this.iconColor,
    this.onPressed,
    this.semanticLabel,
    this.size,
    this.borderWidth,
    this.frameStyle = MetroCircleFrameStyle.vector,
    this.backgroundBuilder,
    this.iconSize = 24,
    this.iconMode = false,
    this.pressed,
  });

  /// 按钮图标，建议使用 [Icon] 组件。
  final Widget icon;

  /// 圆环边框颜色，为 null 时使用 [MetroAppBarTheme.buttonColor]，
  /// 仍未提供则使用主题前景色。
  final Color? borderColor;

  /// 主题色（按下时圆环的填充色），为 null 时使用 [ColorScheme.primary]。
  final Color? themeColor;

  /// 图标颜色，为 null 时使用 [MetroAppBarTheme.buttonIconColor]，
  /// 仍未提供则使用主题前景色。
  final Color? iconColor;

  /// 点击回调，为 null 时显示为禁用状态。
  final VoidCallback? onPressed;

  /// 无障碍标签，为 null 时不包裹 [Semantics]。
  final String? semanticLabel;

  /// 圆环尺寸（直径，含边框），默认与 WP AppBar 按钮一致（48.125 * 0.8）。
  final double? size;

  /// 边框宽度，默认与 WP AppBar 按钮一致（5 * 0.625 * 0.8）。
  ///
  /// 未显式传入时，会随 [size] 等比缩放（以默认尺寸为基准），
  /// 以保持不同尺寸下的视觉比例一致；显式传入则直接使用该值。
  final double? borderWidth;

  /// The default is [MetroCircleFrameStyle.vector].
  final MetroCircleFrameStyle frameStyle;

  /// A custom frame takes precedence over [frameStyle].
  final MetroCircleBackgroundBuilder? backgroundBuilder;

  /// 图标尺寸，默认 24。
  final double iconSize;

  /// 纯图标模式。
  ///
  /// 为 true 时仅渲染圆环图标：不嵌套 [Tile]、不响应触摸，
  /// 且不受 [onPressed] 为 null 时的禁用半透明影响。
  final bool iconMode;

  /// 外部强制按下状态。
  ///
  /// 非 null 时由外部全权控制按下状态（按下时圆环填充主题色），
  /// 例如点击其他控件时联动高亮该按钮；为 null 时由内部触摸状态决定。
  final bool? pressed;

  @override
  State<MetroCircleButton> createState() => _MetroCircleButtonState();
}

class _MetroCircleButtonState extends State<MetroCircleButton> {
  bool _isTouch = false;

  // 圆环子树使用 GlobalKey：当 Tile 包裹与否切换时，子树（如传入的
  // icon，可能含内部状态/动画）会被 reparent 复用而不是销毁重建。
  final GlobalKey _contentKey = GlobalKey();

  /// 实际按下状态：外部 [MetroCircleButton.pressed] 优先；
  /// iconMode 下自动跟随父级 [MetroPressDetector] 的按压状态（[MetroPressScope]）；
  /// 否则取内部触摸状态。
  bool get _isPressed {
    if (widget.pressed != null) return widget.pressed!;
    if (widget.iconMode) {
      return MetroPressScope.maybeOf(context) ?? false;
    }
    return _isTouch;
  }

  Widget _buildFrame(
    BuildContext context, {
    required double size,
    required double borderWidth,
    required bool pressed,
    required Color border,
    required Color accent,
  }) {
    final custom = widget.backgroundBuilder;
    if (custom != null) return custom(context, pressed, border);
    if (widget.frameStyle == MetroCircleFrameStyle.classicBitmap) {
      final light = Theme.of(context).brightness == Brightness.light;
      final name = pressed ? (light ? 'light_down' : 'dark_down') : 'rest';
      final image = Image.asset(
        'assets/appbar/appbar_circle_$name.png',
        package: 'metro_ui',
        width: size,
        height: size,
        fit: BoxFit.fill,
        color: pressed ? null : border,
        excludeFromSemantics: true,
      );
      if (!pressed) return image;

      // The source PNG uses pure red for the fill, and blends toward black
      // (light theme) or white (dark theme) in the rim. Preserve its alpha.
      List<double> channel(double component) => [
        light ? component : 0,
        light ? 0 : 1 - component,
        0,
        0,
        light ? 0 : component * 255,
      ];
      return ColorFiltered(
        colorFilter: ColorFilter.matrix([
          ...channel(accent.r),
          ...channel(accent.g),
          ...channel(accent.b),
          0,
          0,
          0,
          1,
          0,
        ]),
        child: image,
      );
    }

    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: pressed ? accent : null,
        border: Border.all(color: border, width: borderWidth),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 默认尺寸与默认边框（WP AppBar 按钮基准，保留 *0.8）
    const double defaultSize = 48.125 * 0.8;
    const double defaultBorderWidth = 5 * 0.625 * 0.8;

    final double size = widget.size ?? defaultSize;
    // 未显式传入 borderWidth 时，随 size 等比缩放（保持视觉比例一致）
    final double borderWidth =
        widget.borderWidth ?? defaultBorderWidth * (size / defaultSize);

    // iconMode：纯图标模式，不嵌套 Tile、不响应触摸、不受禁用影响
    final bool useTile = !widget.iconMode && widget.onPressed != null;
    final bool disabled = !widget.iconMode && widget.onPressed == null;

    final theme = Theme.of(context);
    final barTheme = theme.extension<MetroAppBarTheme>();
    final pressed = _isPressed;
    final border =
        widget.borderColor ??
        barTheme?.buttonColor ??
        theme.colorScheme.onSurface;
    final accent = widget.themeColor ?? theme.colorScheme.primary;
    final iconColor = pressed
        ? barTheme?.pressedButtonIconColor ?? Colors.white
        : widget.iconColor ??
              barTheme?.buttonIconColor ??
              theme.colorScheme.onSurface;

    // 圆环内容（固定结构，避免随包裹方式变化而重建）
    final Widget content = KeyedSubtree(
      key: _contentKey,
      child: SizedBox(
        height: size,
        width: size,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            _buildFrame(
              context,
              size: size,
              borderWidth: borderWidth,
              pressed: pressed,
              border: border,
              accent: accent,
            ),
            // 图标层：独占完整的直径，负责渲染 Icon
            SizedBox(
              height: size,
              width: size,
              child: ColorFiltered(
                // 使用 srcIn 滤镜控制图标颜色（而非 IconTheme.color）：
                // 即使传入的 icon 内部自带颜色，也能被强制统一覆盖。
                // 按下时（背景填充主题色）图标切换为 pressedButtonIconColor
                // （未配置则纯白），保证与高亮背景的对比度。
                colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                child: IconTheme(
                  data: IconThemeData(size: widget.iconSize),
                  child: widget.icon,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    Widget result = content;
    if (useTile) {
      result = Tile(
        onTap: widget.onPressed,
        onTouch: (isTouch) {
          setState(() {
            _isTouch = isTouch;
          });
        },
        child: content,
      );
    }

    // 禁用状态：50% 半透明滤镜，且不再被 Tile 嵌套
    if (disabled) {
      result = Opacity(opacity: 0.5, child: result);
    }

    final String? label = widget.semanticLabel;
    if (label == null) return result;
    return Semantics(label: label, button: true, child: result);
  }
}
