import 'package:flutter/material.dart';
import 'package:metro_ui/widgets/panorama.dart';

/// Metro UI Design 版本枚举
enum MetroDesignVersion { wp7, wp8, wp81 }

/// Metro UI 专用的标题文本主题扩展
class MetroTitleTextTheme extends ThemeExtension<MetroTitleTextTheme> {
  final TextStyle? titleTextStyle;

  const MetroTitleTextTheme({this.titleTextStyle});

  @override
  ThemeExtension<MetroTitleTextTheme> copyWith({TextStyle? titleTextStyle}) {
    return MetroTitleTextTheme(
      titleTextStyle: titleTextStyle ?? this.titleTextStyle,
    );
  }

  @override
  ThemeExtension<MetroTitleTextTheme> lerp(
      covariant ThemeExtension<MetroTitleTextTheme>? other, double t) {
    if (other is! MetroTitleTextTheme) return this;
    return MetroTitleTextTheme(
      titleTextStyle: TextStyle.lerp(titleTextStyle, other.titleTextStyle, t),
    );
  }
}

/// AppBar 专用主题扩展
class MetroAppBarTheme extends ThemeExtension<MetroAppBarTheme> {
  /// 未展开状态的背景色
  final Color? backgroundColor;

  /// 展开状态的背景色
  final Color? expandedBackgroundColor;

  /// MetroAppBarButton背景色
  final Color? buttonColor;

  /// MetroAppBarButton图标颜色
  final Color? buttonIconColor;

  /// MetroAppBarButton不可用时的图标文字颜色
  final Color? disabledButtonIconColor;

  /// MetroAppBarButton被按下时的图标文字颜色
  final Color? pressedButtonIconColor;

  /// MetroAppBarMenuItem文字颜色
  final Color? menuItemColor;

  /// MetroAppBarMenuItem不可用时的文字颜色
  final Color? disabledMenuItemColor;

  /// MetroAppBar的展开动画曲线
  final Curve? expandCurve;

  /// MetroAppBar的收缩动画曲线
  final Curve? collapseCurve;

  /// MetroAppBar的展开动画时间
  final Duration? expandDuration;

  /// MetroAppBar的收缩动画时间
  final Duration? collapseDuration;

  const MetroAppBarTheme({
    this.backgroundColor,
    this.expandedBackgroundColor,
    this.buttonColor,
    this.buttonIconColor,
    this.disabledButtonIconColor,
    this.pressedButtonIconColor,
    this.menuItemColor,
    this.disabledMenuItemColor,
    this.expandCurve,
    this.collapseCurve,
    this.expandDuration,
    this.collapseDuration,
  });

  @override
  ThemeExtension<MetroAppBarTheme> copyWith({
    Color? backgroundColor,
    Color? expandedBackgroundColor,
    Color? buttonColor,
    Color? buttonIconColor,
    Color? disabledButtonIconColor,
    Color? pressedButtonIconColor,
    Color? menuItemColor,
    Color? disabledMenuItemColor,
    Curve? expandCurve,
    Curve? collapseCurve,
    Duration? expandDuration,
    Duration? collapseDuration,
  }) {
    return MetroAppBarTheme(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      expandedBackgroundColor:
          expandedBackgroundColor ?? this.expandedBackgroundColor,
      buttonColor: buttonColor ?? this.buttonColor,
      buttonIconColor: buttonIconColor ?? this.buttonIconColor,
      disabledButtonIconColor:
          disabledButtonIconColor ?? this.disabledButtonIconColor,
      pressedButtonIconColor:
          pressedButtonIconColor ?? this.pressedButtonIconColor,
      menuItemColor: menuItemColor ?? this.menuItemColor,
      disabledMenuItemColor:
          disabledMenuItemColor ?? this.disabledMenuItemColor,
      expandCurve: expandCurve ?? this.expandCurve,
      collapseCurve: collapseCurve ?? this.collapseCurve,
      expandDuration: expandDuration ?? this.expandDuration,
      collapseDuration: collapseDuration ?? this.collapseDuration,
    );
  }

  @override
  ThemeExtension<MetroAppBarTheme> lerp(
      covariant ThemeExtension<MetroAppBarTheme>? other, double t) {
    if (other is! MetroAppBarTheme) return this;
    return MetroAppBarTheme(
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t),
      expandedBackgroundColor:
          Color.lerp(expandedBackgroundColor, other.expandedBackgroundColor, t),
      buttonColor: Color.lerp(buttonColor, other.buttonColor, t),
      buttonIconColor: Color.lerp(buttonIconColor, other.buttonIconColor, t),
      disabledButtonIconColor:
          Color.lerp(disabledButtonIconColor, other.disabledButtonIconColor, t),
      pressedButtonIconColor:
          Color.lerp(pressedButtonIconColor, other.pressedButtonIconColor, t),
      menuItemColor: Color.lerp(menuItemColor, other.menuItemColor, t),
      disabledMenuItemColor:
          Color.lerp(disabledMenuItemColor, other.disabledMenuItemColor, t),
      expandCurve: t < 0.5 ? expandCurve : other.expandCurve,
      collapseCurve: t < 0.5 ? collapseCurve : other.collapseCurve,
      expandDuration: t < 0.5 ? expandDuration : other.expandDuration,
      collapseDuration: t < 0.5 ? collapseDuration : other.collapseDuration,
    );
  }
}

/// 按钮 专用主题扩展
class MetroButtonThemeData extends ThemeExtension<MetroButtonThemeData> {
  final Color? normalBorderColor;
  final Color? pressedBackgroundColor;
  final Color? pressedTextColor;
  final Color? disabledBorderColor;
  final Color? disabledTextColor;

  const MetroButtonThemeData({
    this.normalBorderColor,
    this.pressedBackgroundColor,
    this.pressedTextColor,
    this.disabledBorderColor,
    this.disabledTextColor,
  });

  @override
  ThemeExtension<MetroButtonThemeData> copyWith({
    Color? normalBorderColor,
    Color? pressedBackgroundColor,
    Color? pressedTextColor,
    Color? disabledBorderColor,
    Color? disabledTextColor,
  }) {
    return MetroButtonThemeData(
      normalBorderColor: normalBorderColor ?? this.normalBorderColor,
      pressedBackgroundColor: pressedBackgroundColor ?? this.pressedBackgroundColor,
      pressedTextColor: pressedTextColor ?? this.pressedTextColor,
      disabledBorderColor: disabledBorderColor ?? this.disabledBorderColor,
      disabledTextColor: disabledTextColor ?? this.disabledTextColor,
    );
  }

  @override
  ThemeExtension<MetroButtonThemeData> lerp(
      covariant ThemeExtension<MetroButtonThemeData>? other, double t) {
    if (other is! MetroButtonThemeData) return this;
    return MetroButtonThemeData(
      normalBorderColor: Color.lerp(normalBorderColor, other.normalBorderColor, t),
      pressedBackgroundColor: Color.lerp(pressedBackgroundColor, other.pressedBackgroundColor, t),
      pressedTextColor: Color.lerp(pressedTextColor, other.pressedTextColor, t),
      disabledBorderColor: Color.lerp(disabledBorderColor, other.disabledBorderColor, t),
      disabledTextColor: Color.lerp(disabledTextColor, other.disabledTextColor, t),
    );
  }
}

/// Panorama 专用主题扩展
class MetroPanoramaThemeData extends ThemeExtension<MetroPanoramaThemeData> {
  final PanoramaConfig config;

  const MetroPanoramaThemeData({
    this.config = const PanoramaConfig(),
  });

  @override
  ThemeExtension<MetroPanoramaThemeData> copyWith({
    PanoramaConfig? config,
  }) {
    return MetroPanoramaThemeData(
      config: config ?? this.config,
    );
  }

  @override
  ThemeExtension<MetroPanoramaThemeData> lerp(
      covariant ThemeExtension<MetroPanoramaThemeData>? other, double t) {
    if (other is! MetroPanoramaThemeData) return this;
    return MetroPanoramaThemeData(
      config: t < 0.5 ? config : other.config,
    );
  }
}

/// Page 专用主题扩展
class MetroPageThemeData extends ThemeExtension<MetroPageThemeData> {
  const MetroPageThemeData();

  @override
  ThemeExtension<MetroPageThemeData> copyWith() {
    return const MetroPageThemeData();
  }

  @override
  ThemeExtension<MetroPageThemeData> lerp(
      covariant ThemeExtension<MetroPageThemeData>? other, double t) {
    if (other is! MetroPageThemeData) return this;
    return const MetroPageThemeData();
  }
}
