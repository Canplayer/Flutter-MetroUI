import 'package:flutter/material.dart';

/// Metro UI 专用的标题文本主题扩展，这允许我们在 ThemeData 之外统一管理特定样式的字体
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

  const MetroAppBarTheme(
      {this.backgroundColor,
      this.expandedBackgroundColor,
      this.buttonColor,
      this.buttonIconColor,
      this.disabledButtonIconColor,
      this.pressedButtonIconColor,
      this.menuItemColor,
      this.disabledMenuItemColor});

  @override
  ThemeExtension<MetroAppBarTheme> copyWith(
      {Color? backgroundColor,
      Color? expandedBackgroundColor,
      Color? buttonColor,
      Color? buttonIconColor,
      Color? disabledButtonIconColor,
      Color? pressedButtonIconColor,
      Color? menuItemColor,
      Color? disabledMenuItemColor}) {
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
    );
  }
}
