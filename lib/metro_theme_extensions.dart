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
