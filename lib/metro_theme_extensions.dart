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
    covariant ThemeExtension<MetroTitleTextTheme>? other,
    double t,
  ) {
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

  final Color? captionColor;
  final TextStyle? captionStyle;

  const MetroAppBarTheme({
    this.captionColor,
    this.captionStyle,
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

  MetroAppBarTheme merge(MetroAppBarTheme other) => copyWith(
    backgroundColor: other.backgroundColor,
    expandedBackgroundColor: other.expandedBackgroundColor,
    buttonColor: other.buttonColor,
    buttonIconColor: other.buttonIconColor,
    disabledButtonIconColor: other.disabledButtonIconColor,
    pressedButtonIconColor: other.pressedButtonIconColor,
    menuItemColor: other.menuItemColor,
    disabledMenuItemColor: other.disabledMenuItemColor,
    expandCurve: other.expandCurve,
    collapseCurve: other.collapseCurve,
    expandDuration: other.expandDuration,
    collapseDuration: other.collapseDuration,
    captionColor: other.captionColor,
    captionStyle: other.captionStyle,
  );

  @override
  MetroAppBarTheme copyWith({
    Color? captionColor,
    TextStyle? captionStyle,
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
      captionColor: captionColor ?? this.captionColor,
      captionStyle: captionStyle ?? this.captionStyle,
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
    covariant ThemeExtension<MetroAppBarTheme>? other,
    double t,
  ) {
    if (other is! MetroAppBarTheme) return this;
    return MetroAppBarTheme(
      captionColor: Color.lerp(captionColor, other.captionColor, t),
      captionStyle: TextStyle.lerp(captionStyle, other.captionStyle, t),
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t),
      expandedBackgroundColor: Color.lerp(
        expandedBackgroundColor,
        other.expandedBackgroundColor,
        t,
      ),
      buttonColor: Color.lerp(buttonColor, other.buttonColor, t),
      buttonIconColor: Color.lerp(buttonIconColor, other.buttonIconColor, t),
      disabledButtonIconColor: Color.lerp(
        disabledButtonIconColor,
        other.disabledButtonIconColor,
        t,
      ),
      pressedButtonIconColor: Color.lerp(
        pressedButtonIconColor,
        other.pressedButtonIconColor,
        t,
      ),
      menuItemColor: Color.lerp(menuItemColor, other.menuItemColor, t),
      disabledMenuItemColor: Color.lerp(
        disabledMenuItemColor,
        other.disabledMenuItemColor,
        t,
      ),
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

  MetroButtonThemeData merge(MetroButtonThemeData other) => copyWith(
    normalBorderColor: other.normalBorderColor,
    pressedBackgroundColor: other.pressedBackgroundColor,
    pressedTextColor: other.pressedTextColor,
    disabledBorderColor: other.disabledBorderColor,
    disabledTextColor: other.disabledTextColor,
  );

  @override
  MetroButtonThemeData copyWith({
    Color? normalBorderColor,
    Color? pressedBackgroundColor,
    Color? pressedTextColor,
    Color? disabledBorderColor,
    Color? disabledTextColor,
  }) {
    return MetroButtonThemeData(
      normalBorderColor: normalBorderColor ?? this.normalBorderColor,
      pressedBackgroundColor:
          pressedBackgroundColor ?? this.pressedBackgroundColor,
      pressedTextColor: pressedTextColor ?? this.pressedTextColor,
      disabledBorderColor: disabledBorderColor ?? this.disabledBorderColor,
      disabledTextColor: disabledTextColor ?? this.disabledTextColor,
    );
  }

  @override
  ThemeExtension<MetroButtonThemeData> lerp(
    covariant ThemeExtension<MetroButtonThemeData>? other,
    double t,
  ) {
    if (other is! MetroButtonThemeData) return this;
    return MetroButtonThemeData(
      normalBorderColor: Color.lerp(
        normalBorderColor,
        other.normalBorderColor,
        t,
      ),
      pressedBackgroundColor: Color.lerp(
        pressedBackgroundColor,
        other.pressedBackgroundColor,
        t,
      ),
      pressedTextColor: Color.lerp(pressedTextColor, other.pressedTextColor, t),
      disabledBorderColor: Color.lerp(
        disabledBorderColor,
        other.disabledBorderColor,
        t,
      ),
      disabledTextColor: Color.lerp(
        disabledTextColor,
        other.disabledTextColor,
        t,
      ),
    );
  }
}

/// Panorama 专用主题扩展
class MetroPanoramaThemeData extends ThemeExtension<MetroPanoramaThemeData> {
  final PanoramaConfig config;

  const MetroPanoramaThemeData({this.config = const PanoramaConfig()});

  @override
  ThemeExtension<MetroPanoramaThemeData> copyWith({PanoramaConfig? config}) {
    return MetroPanoramaThemeData(config: config ?? this.config);
  }

  @override
  ThemeExtension<MetroPanoramaThemeData> lerp(
    covariant ThemeExtension<MetroPanoramaThemeData>? other,
    double t,
  ) {
    if (other is! MetroPanoramaThemeData) return this;
    return MetroPanoramaThemeData(config: t < 0.5 ? config : other.config);
  }
}

/// Version behavior is discrete; colors remain in ThemeData/colorScheme.
/// Widgets can read this extension without introducing their own version flags.
class MetroSystemThemeData extends ThemeExtension<MetroSystemThemeData> {
  const MetroSystemThemeData({
    this.version = MetroDesignVersion.wp8,
    this.highContrast = false,
  });
  static MetroSystemThemeData of(BuildContext context) =>
      Theme.of(context).extension<MetroSystemThemeData>() ??
      const MetroSystemThemeData();

  final MetroDesignVersion version;
  final bool highContrast;
  bool get continuousApplicationBar => version == MetroDesignVersion.wp7;
  @override
  MetroSystemThemeData copyWith({
    MetroDesignVersion? version,
    bool? highContrast,
  }) => MetroSystemThemeData(
    version: version ?? this.version,
    highContrast: highContrast ?? this.highContrast,
  );
  @override
  MetroSystemThemeData lerp(covariant MetroSystemThemeData? other, double t) =>
      other ?? this; // Never interpolate operating-system behavior.
}

/// UIX Turnstile defaults. WP8.1 depth follows the explicit 100 dp × .8 assumption.
class MetroPageThemeData extends ThemeExtension<MetroPageThemeData> {
  const MetroPageThemeData({
    this.inDuration = const Duration(milliseconds: 350),
    this.outDuration = const Duration(milliseconds: 167),
    this.pivotDepth = 0,
    this.alternatePivot = false,
    this.outAlphaHold = const Duration(milliseconds: 166),
  });
  factory MetroPageThemeData.forVersion(MetroDesignVersion version) =>
      version == MetroDesignVersion.wp81
      ? const MetroPageThemeData(
          inDuration: Duration(milliseconds: 300),
          outDuration: Duration(milliseconds: 128),
          pivotDepth: 80,
          alternatePivot: true,
          outAlphaHold: Duration(milliseconds: 126),
        )
      : const MetroPageThemeData();
  final Duration inDuration, outDuration, outAlphaHold;
  final double pivotDepth;
  final bool alternatePivot;
  @override
  MetroPageThemeData copyWith({
    Duration? inDuration,
    Duration? outDuration,
    Duration? outAlphaHold,
    double? pivotDepth,
    bool? alternatePivot,
  }) => MetroPageThemeData(
    inDuration: inDuration ?? this.inDuration,
    outDuration: outDuration ?? this.outDuration,
    outAlphaHold: outAlphaHold ?? this.outAlphaHold,
    pivotDepth: pivotDepth ?? this.pivotDepth,
    alternatePivot: alternatePivot ?? this.alternatePivot,
  );
  @override
  MetroPageThemeData lerp(covariant MetroPageThemeData? other, double t) =>
      other ?? this;
}

/// ContextMenu 专用主题扩展
class MetroContextMenuThemeData
    extends ThemeExtension<MetroContextMenuThemeData> {
  final Color? backgroundColor;
  final Color? lineColor;
  final Duration? pushBackDuration;
  final Duration? restoreDuration;
  final Duration? lineAnimationDuration;
  final Duration? menuAnimationDuration;
  final TextStyle? itemTextStyle;
  final double? itemHeight;

  const MetroContextMenuThemeData({
    this.backgroundColor,
    this.lineColor,
    this.pushBackDuration,
    this.restoreDuration,
    this.lineAnimationDuration,
    this.menuAnimationDuration,
    this.itemTextStyle,
    this.itemHeight,
  });

  MetroContextMenuThemeData merge(MetroContextMenuThemeData other) => copyWith(
    backgroundColor: other.backgroundColor,
    lineColor: other.lineColor,
    pushBackDuration: other.pushBackDuration,
    restoreDuration: other.restoreDuration,
    lineAnimationDuration: other.lineAnimationDuration,
    menuAnimationDuration: other.menuAnimationDuration,
    itemTextStyle: other.itemTextStyle,
    itemHeight: other.itemHeight,
  );

  @override
  MetroContextMenuThemeData copyWith({
    Color? backgroundColor,
    Color? lineColor,
    Duration? pushBackDuration,
    Duration? restoreDuration,
    Duration? lineAnimationDuration,
    Duration? menuAnimationDuration,
    TextStyle? itemTextStyle,
    double? itemHeight,
  }) {
    return MetroContextMenuThemeData(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      lineColor: lineColor ?? this.lineColor,
      pushBackDuration: pushBackDuration ?? this.pushBackDuration,
      restoreDuration: restoreDuration ?? this.restoreDuration,
      lineAnimationDuration:
          lineAnimationDuration ?? this.lineAnimationDuration,
      menuAnimationDuration:
          menuAnimationDuration ?? this.menuAnimationDuration,
      itemTextStyle: itemTextStyle ?? this.itemTextStyle,
      itemHeight: itemHeight ?? this.itemHeight,
    );
  }

  @override
  ThemeExtension<MetroContextMenuThemeData> lerp(
    covariant ThemeExtension<MetroContextMenuThemeData>? other,
    double t,
  ) {
    if (other is! MetroContextMenuThemeData) return this;
    return MetroContextMenuThemeData(
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t),
      lineColor: Color.lerp(lineColor, other.lineColor, t),
      pushBackDuration: t < 0.5 ? pushBackDuration : other.pushBackDuration,
      restoreDuration: t < 0.5 ? restoreDuration : other.restoreDuration,
      lineAnimationDuration: t < 0.5
          ? lineAnimationDuration
          : other.lineAnimationDuration,
      menuAnimationDuration: t < 0.5
          ? menuAnimationDuration
          : other.menuAnimationDuration,
      itemTextStyle: TextStyle.lerp(itemTextStyle, other.itemTextStyle, t),
      itemHeight: t < 0.5 ? itemHeight : other.itemHeight,
    );
  }
}

/// The track, thumb, outline and labels of a toggle switch.
class MetroToggleSwitchTheme extends ThemeExtension<MetroToggleSwitchTheme> {
  const MetroToggleSwitchTheme({
    this.activeColor,
    this.inactiveColor,
    this.thumbColor,
    this.borderColor,
    this.disabledColor,
    this.labelColor,
    this.statusColor,
    this.disabledOpacity,
  });
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? thumbColor;
  final Color? borderColor;
  final Color? disabledColor;
  final Color? labelColor;
  final Color? statusColor;
  final double? disabledOpacity;

  @override
  MetroToggleSwitchTheme copyWith({
    Color? activeColor,
    Color? inactiveColor,
    Color? thumbColor,
    Color? borderColor,
    Color? disabledColor,
    Color? labelColor,
    Color? statusColor,
    double? disabledOpacity,
  }) => MetroToggleSwitchTheme(
    activeColor: activeColor ?? this.activeColor,
    inactiveColor: inactiveColor ?? this.inactiveColor,
    thumbColor: thumbColor ?? this.thumbColor,
    borderColor: borderColor ?? this.borderColor,
    disabledColor: disabledColor ?? this.disabledColor,
    labelColor: labelColor ?? this.labelColor,
    statusColor: statusColor ?? this.statusColor,
    disabledOpacity: disabledOpacity ?? this.disabledOpacity,
  );

  @override
  MetroToggleSwitchTheme lerp(
    covariant MetroToggleSwitchTheme? other,
    double t,
  ) {
    if (other == null) return this;
    return MetroToggleSwitchTheme(
      activeColor: Color.lerp(activeColor, other.activeColor, t),
      inactiveColor: Color.lerp(inactiveColor, other.inactiveColor, t),
      thumbColor: Color.lerp(thumbColor, other.thumbColor, t),
      borderColor: Color.lerp(borderColor, other.borderColor, t),
      disabledColor: Color.lerp(disabledColor, other.disabledColor, t),
      labelColor: Color.lerp(labelColor, other.labelColor, t),
      statusColor: Color.lerp(statusColor, other.statusColor, t),
      disabledOpacity: t < .5 ? disabledOpacity : other.disabledOpacity,
    );
  }
}

/// Shared colors for linear and circular progress indicators.
class MetroProgressTheme extends ThemeExtension<MetroProgressTheme> {
  const MetroProgressTheme({this.barColor, this.trackColor, this.ringColor});
  final Color? barColor;
  final Color? trackColor;
  final Color? ringColor;

  @override
  MetroProgressTheme copyWith({
    Color? barColor,
    Color? trackColor,
    Color? ringColor,
  }) => MetroProgressTheme(
    barColor: barColor ?? this.barColor,
    trackColor: trackColor ?? this.trackColor,
    ringColor: ringColor ?? this.ringColor,
  );

  @override
  MetroProgressTheme lerp(covariant MetroProgressTheme? other, double t) {
    if (other == null) return this;
    return MetroProgressTheme(
      barColor: Color.lerp(barColor, other.barColor, t),
      trackColor: Color.lerp(trackColor, other.trackColor, t),
      ringColor: Color.lerp(ringColor, other.ringColor, t),
    );
  }
}

/// EditBox colors and borders for idle, focused and disabled states.
class MetroEditBoxTheme extends ThemeExtension<MetroEditBoxTheme> {
  const MetroEditBoxTheme({
    this.textColor,
    this.hintColor,
    this.selectionColor,
    this.idleFill,
    this.focusedFill,
    this.disabledFill,
    this.idleBorder,
    this.focusedBorder,
    this.disabledBorder,
  });
  final Color? textColor;
  final Color? hintColor;
  final Color? selectionColor;
  final Color? idleFill;
  final Color? focusedFill;
  final Color? disabledFill;
  final BorderSide? idleBorder;
  final BorderSide? focusedBorder;
  final BorderSide? disabledBorder;

  @override
  MetroEditBoxTheme copyWith({
    Color? textColor,
    Color? hintColor,
    Color? selectionColor,
    Color? idleFill,
    Color? focusedFill,
    Color? disabledFill,
    BorderSide? idleBorder,
    BorderSide? focusedBorder,
    BorderSide? disabledBorder,
  }) => MetroEditBoxTheme(
    textColor: textColor ?? this.textColor,
    hintColor: hintColor ?? this.hintColor,
    selectionColor: selectionColor ?? this.selectionColor,
    idleFill: idleFill ?? this.idleFill,
    focusedFill: focusedFill ?? this.focusedFill,
    disabledFill: disabledFill ?? this.disabledFill,
    idleBorder: idleBorder ?? this.idleBorder,
    focusedBorder: focusedBorder ?? this.focusedBorder,
    disabledBorder: disabledBorder ?? this.disabledBorder,
  );

  @override
  MetroEditBoxTheme lerp(covariant MetroEditBoxTheme? other, double t) {
    if (other == null) return this;
    return MetroEditBoxTheme(
      textColor: Color.lerp(textColor, other.textColor, t),
      hintColor: Color.lerp(hintColor, other.hintColor, t),
      selectionColor: Color.lerp(selectionColor, other.selectionColor, t),
      idleFill: Color.lerp(idleFill, other.idleFill, t),
      focusedFill: Color.lerp(focusedFill, other.focusedFill, t),
      disabledFill: Color.lerp(disabledFill, other.disabledFill, t),
      idleBorder: t < .5 ? idleBorder : other.idleBorder,
      focusedBorder: t < .5 ? focusedBorder : other.focusedBorder,
      disabledBorder: t < .5 ? disabledBorder : other.disabledBorder,
    );
  }
}

/// Visual overrides for a ListPicker.
class MetroListPickerTheme extends ThemeExtension<MetroListPickerTheme> {
  const MetroListPickerTheme({
    this.foreground,
    this.disabledForeground,
    this.placeholderColor,
    this.accentColor,
    this.focusedForeground,
    this.focusedFill,
    this.borderWidth,
    this.textStyle,
  });
  final Color? foreground;
  final Color? disabledForeground;
  final Color? placeholderColor;
  final Color? accentColor;
  final Color? focusedForeground;
  final Color? focusedFill;
  final double? borderWidth;
  final TextStyle? textStyle;

  @override
  MetroListPickerTheme copyWith({
    Color? foreground,
    Color? disabledForeground,
    Color? placeholderColor,
    Color? accentColor,
    Color? focusedForeground,
    Color? focusedFill,
    double? borderWidth,
    TextStyle? textStyle,
  }) => MetroListPickerTheme(
    foreground: foreground ?? this.foreground,
    disabledForeground: disabledForeground ?? this.disabledForeground,
    placeholderColor: placeholderColor ?? this.placeholderColor,
    accentColor: accentColor ?? this.accentColor,
    focusedForeground: focusedForeground ?? this.focusedForeground,
    focusedFill: focusedFill ?? this.focusedFill,
    borderWidth: borderWidth ?? this.borderWidth,
    textStyle: textStyle ?? this.textStyle,
  );

  @override
  MetroListPickerTheme lerp(covariant MetroListPickerTheme? other, double t) {
    if (other == null) return this;
    return MetroListPickerTheme(
      foreground: Color.lerp(foreground, other.foreground, t),
      disabledForeground: Color.lerp(
        disabledForeground,
        other.disabledForeground,
        t,
      ),
      placeholderColor: Color.lerp(placeholderColor, other.placeholderColor, t),
      accentColor: Color.lerp(accentColor, other.accentColor, t),
      focusedForeground: Color.lerp(
        focusedForeground,
        other.focusedForeground,
        t,
      ),
      focusedFill: Color.lerp(focusedFill, other.focusedFill, t),
      borderWidth: t < .5 ? borderWidth : other.borderWidth,
      textStyle: TextStyle.lerp(textStyle, other.textStyle, t),
    );
  }
}

/// Visual overrides for one- and two-line list rows.
class MetroListItemTheme extends ThemeExtension<MetroListItemTheme> {
  const MetroListItemTheme({
    this.headerStyle,
    this.subHeaderStyle,
    this.disabledColor,
  });
  final TextStyle? headerStyle;
  final TextStyle? subHeaderStyle;
  final Color? disabledColor;

  @override
  MetroListItemTheme copyWith({
    TextStyle? headerStyle,
    TextStyle? subHeaderStyle,
    Color? disabledColor,
  }) => MetroListItemTheme(
    headerStyle: headerStyle ?? this.headerStyle,
    subHeaderStyle: subHeaderStyle ?? this.subHeaderStyle,
    disabledColor: disabledColor ?? this.disabledColor,
  );

  @override
  MetroListItemTheme lerp(covariant MetroListItemTheme? other, double t) {
    if (other == null) return this;
    return MetroListItemTheme(
      headerStyle: TextStyle.lerp(headerStyle, other.headerStyle, t),
      subHeaderStyle: TextStyle.lerp(subHeaderStyle, other.subHeaderStyle, t),
      disabledColor: Color.lerp(disabledColor, other.disabledColor, t),
    );
  }
}

/// Visual overrides for page and Pivot headings.
class MetroHeadingTheme extends ThemeExtension<MetroHeadingTheme> {
  const MetroHeadingTheme({
    this.pageTitleStyle,
    this.singlePivotHeaderStyle,
    this.pivotSelectedStyle,
    this.pivotIdleStyle,
  });
  final TextStyle? pageTitleStyle;
  final TextStyle? singlePivotHeaderStyle;
  final TextStyle? pivotSelectedStyle;
  final TextStyle? pivotIdleStyle;

  @override
  MetroHeadingTheme copyWith({
    TextStyle? pageTitleStyle,
    TextStyle? singlePivotHeaderStyle,
    TextStyle? pivotSelectedStyle,
    TextStyle? pivotIdleStyle,
  }) => MetroHeadingTheme(
    pageTitleStyle: pageTitleStyle ?? this.pageTitleStyle,
    singlePivotHeaderStyle:
        singlePivotHeaderStyle ?? this.singlePivotHeaderStyle,
    pivotSelectedStyle: pivotSelectedStyle ?? this.pivotSelectedStyle,
    pivotIdleStyle: pivotIdleStyle ?? this.pivotIdleStyle,
  );

  @override
  MetroHeadingTheme lerp(covariant MetroHeadingTheme? other, double t) {
    if (other == null) return this;
    return MetroHeadingTheme(
      pageTitleStyle: TextStyle.lerp(pageTitleStyle, other.pageTitleStyle, t),
      singlePivotHeaderStyle: TextStyle.lerp(
        singlePivotHeaderStyle,
        other.singlePivotHeaderStyle,
        t,
      ),
      pivotSelectedStyle: TextStyle.lerp(
        pivotSelectedStyle,
        other.pivotSelectedStyle,
        t,
      ),
      pivotIdleStyle: TextStyle.lerp(pivotIdleStyle, other.pivotIdleStyle, t),
    );
  }
}
