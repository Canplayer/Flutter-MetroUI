import 'package:flutter/material.dart';
import 'package:metro_ui/application_bar.dart';
import 'package:metro_ui/metro_theme_extensions.dart';
import 'package:metro_ui/widgets/tile.dart';

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
    this.iconSize = 24,
    this.version,
    this.iconMode = false,
    this.pressed,
  });

  /// 按钮图标，建议使用 [Icon] 组件。
  final Widget icon;

  /// 圆环边框颜色，为 null 时使用 [MetroAppBarTheme.buttonColor]，
  /// 仍未提供则回退为白色。
  final Color? borderColor;

  /// 主题色（按下时圆环的填充色），为 null 时使用 [ColorScheme.primary]。
  final Color? themeColor;

  /// 图标颜色，为 null 时使用 [MetroAppBarTheme.buttonIconColor]，
  /// 仍未提供则回退为白色。
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

  /// 图标尺寸，默认 24。
  final double iconSize;

  /// Metro UI 设计版本（WP7 / WP8 / WP8.1）。
  ///
  /// 目前仅保留字段以兼容后续版本差异，尚未实现各版本间的视觉差异。
  final MetroDesignVersion? version;

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

  @override
  Widget build(BuildContext context) {
    // 默认尺寸与默认边框（WP AppBar 按钮基准，保留 *0.8）
    final double defaultSize = 48.125 * 0.8;
    final double defaultBorderWidth = 5 * 0.625 * 0.8;

    final double size = widget.size ?? defaultSize;
    // 未显式传入 borderWidth 时，随 size 等比缩放（保持视觉比例一致）
    final double borderWidth =
        widget.borderWidth ?? defaultBorderWidth * (size / defaultSize);

    // iconMode：纯图标模式，不嵌套 Tile、不响应触摸、不受禁用影响
    final bool useTile = !widget.iconMode && widget.onPressed != null;
    final bool disabled = !widget.iconMode && widget.onPressed == null;

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
            // 圆环主体：在 Stack 中居中
            Container(
              height: size,
              width: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isPressed
                    ? widget.themeColor ?? Theme.of(context).colorScheme.primary
                    : null,
                border: Border.all(
                  color: widget.borderColor ??
                      Theme.of(context)
                          .extension<MetroAppBarTheme>()!
                          .buttonColor ??
                      Colors.white,
                  width: borderWidth,
                ),
              ),
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
                colorFilter: ColorFilter.mode(
                  _isPressed
                      ? Theme.of(context)
                              .extension<MetroAppBarTheme>()!
                              .pressedButtonIconColor ??
                          Colors.white
                      : widget.iconColor ??
                          Theme.of(context)
                              .extension<MetroAppBarTheme>()!
                              .buttonIconColor ??
                          Colors.white,
                  BlendMode.srcIn,
                ),
                child: IconTheme(
                  // IconTheme 仅保留尺寸控制，颜色交给上方滤镜
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
    return Semantics(
      label: label,
      button: true,
      child: result,
    );
  }
}
