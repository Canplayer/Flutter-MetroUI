import 'package:flutter/material.dart';

import '../../animations.dart' show UixEaseIn, UixLog;
import '../../metro_theme_extensions.dart';
import '../../uix_metrics.dart';
import '../../uix_typography.dart';
import '../../widgets/panorama.dart';

MetroTitleTextTheme titleDefaults(Color textColor) => MetroTitleTextTheme(
  titleTextStyle: TextStyle(
    fontSize: uixFontSize(128),
    fontWeight: UixFontWeight.light,
    letterSpacing: -6 * .8,
    color: textColor,
  ),
);

MetroAppBarTheme appBarDefaults(
  MetroDesignVersion version,
  Brightness brightness,
  Color surface,
  Color disabled, {
  required Color pressedIcon,
}) {
  final light = brightness == Brightness.light;
  final foreground = light ? Colors.black : Colors.white;
  final curve = version == MetroDesignVersion.wp7
      ? const UixEaseIn(10, .5)
      : const UixLog(150);
  return MetroAppBarTheme(
    backgroundColor: surface,
    expandedBackgroundColor: surface,
    buttonColor: foreground,
    buttonIconColor: light ? const Color(0xff1d1d1d) : Colors.white,
    disabledButtonIconColor: disabled,
    pressedButtonIconColor: pressedIcon,
    captionColor: foreground,
    menuItemColor: foreground,
    disabledMenuItemColor: disabled,
    expandCurve: curve,
    collapseCurve: curve,
    expandDuration: const Duration(milliseconds: 400),
    collapseDuration: const Duration(milliseconds: 200),
  );
}

MetroButtonThemeData buttonDefaults(
  MetroDesignVersion version,
  Color foreground,
  Color accent,
  Color disabled, {
  required Color pressedText,
  required Color background,
}) {
  final wp7 = version == MetroDesignVersion.wp7;
  return MetroButtonThemeData(
    normalBorderColor: foreground,
    pressedBackgroundColor: wp7 ? foreground : accent,
    pressedTextColor: wp7 ? background : pressedText,
    disabledBorderColor: disabled,
    disabledTextColor: disabled,
  );
}

MetroPanoramaThemeData panoramaDefaults(MetroDesignVersion version) {
  final wp7 = version == MetroDesignVersion.wp7;
  return MetroPanoramaThemeData(
    config: PanoramaConfig(
      titleEntryTranslate: wp7 ? 2600 : 2000 * .8,
      backgroundEntryTranslate: wp7 ? 1400 : 1200 * .8,
      contentEntryTranslate: 1500 * .8,
      rotationDuration: Duration(milliseconds: wp7 ? 750 : 500),
    ),
  );
}

MetroContextMenuThemeData contextMenuDefaults(
  Color background,
  Color foreground,
) => MetroContextMenuThemeData(
  backgroundColor: foreground,
  lineColor: foreground,
  pushBackDuration: const Duration(milliseconds: 500),
  restoreDuration: const Duration(milliseconds: 350),
  lineAnimationDuration: const Duration(milliseconds: 500),
  menuAnimationDuration: const Duration(milliseconds: 400),
  itemHeight: 70,
  itemTextStyle: TextStyle(
    fontSize: 24,
    fontWeight: UixFontWeight.light,
    color: background,
  ),
);
