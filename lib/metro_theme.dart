import 'package:flutter/material.dart';

import 'metro_theme_extensions.dart';
import 'uix_typography.dart';
import 'src/theme/component_defaults.dart';

export 'metro_theme_extensions.dart';

/// A preset that can be applied to a whole app or just a single widget.
@immutable
class MetroThemeData {
  const MetroThemeData.fromPreset({
    this.version = MetroDesignVersion.wp8,
    this.brightness,
    this.highContrast,
    this.accentColor,
    this.extensions = const [],
  });

  final MetroDesignVersion version;
  final Brightness? brightness;
  final bool? highContrast;
  final Color? accentColor;
  final List<ThemeExtension<dynamic>> extensions;

  ThemeData resolve(BuildContext context) {
    final ambient = Theme.of(context);
    final inherited = ambient.extension<MetroSystemThemeData>();
    final effectiveBrightness = brightness ?? ambient.brightness;
    final contrast =
        highContrast ??
        inherited?.highContrast ??
        MediaQuery.maybeHighContrastOf(context) ??
        false;
    final color =
        accentColor ??
        (inherited == null
            ? const Color(0xff1ba1e2)
            : ambient.colorScheme.primary);
    return toThemeData(
      brightness: effectiveBrightness,
      highContrast: contrast,
      accentColor: color,
      fontFamily: inherited == null
          ? null
          : ambient.textTheme.bodyMedium?.fontFamily,
    );
  }

  ThemeData toThemeData({
    required Brightness brightness,
    bool highContrast = false,
    Color accentColor = const Color(0xff1ba1e2),
    String? fontFamily,
  }) {
    highContrast = this.highContrast ?? highContrast;
    brightness = this.brightness ?? brightness;
    final useWhiteTheme = brightness == Brightness.light;
    const whiteColor = Colors.white;
    const blackColor = Colors.black;
    final background = useWhiteTheme ? whiteColor : blackColor;
    final foreground = useWhiteTheme ? blackColor : whiteColor;
    final surfaceColor = highContrast
        ? background
        : useWhiteTheme
        ? const Color(0xffdddddd)
        : const Color(0xff1f1f1f);
    final primaryColor =
        this.accentColor ?? (highContrast ? foreground : accentColor);
    // High contrast uses explicit solid disabled colors, so
    // compositing against a parent surface cannot change their legibility.
    final disabledColor = highContrast
        ? (useWhiteTheme ? const Color(0xff595959) : const Color(0xffb3b3b3))
        : foreground.withValues(alpha: .5);
    final family = fontFamily ?? 'Segoe WP';
    final package = fontFamily == null ? 'metro_ui' : null;
    final source = ThemeData(
      brightness: brightness,
      colorSchemeSeed: primaryColor,
      fontFamily: family,
      package: package,
    );
    final scheme = source.colorScheme;
    final List<ThemeExtension<dynamic>> merged = [
      titleDefaults(foreground),
      appBarDefaults(
        version,
        brightness,
        surfaceColor,
        disabledColor,
        pressedIcon: highContrast
            ? _contrastForeground(primaryColor)
            : whiteColor,
      ),
      buttonDefaults(
        version,
        foreground,
        primaryColor,
        disabledColor,
        pressedText: highContrast
            ? _contrastForeground(primaryColor)
            : whiteColor,
        background: background,
      ),
      panoramaDefaults(version),
      contextMenuDefaults(background, foreground),
      MetroSystemThemeData(version: version, highContrast: highContrast),
      MetroPageThemeData.forVersion(version),
    ];
    for (final override in extensions) {
      final index = merged.indexWhere((value) => value.type == override.type);
      if (index < 0) {
        merged.add(override);
      } else {
        final existing = merged[index];
        if (existing is MetroAppBarTheme && override is MetroAppBarTheme) {
          merged[index] = existing.merge(override);
        } else if (existing is MetroButtonThemeData &&
            override is MetroButtonThemeData) {
          merged[index] = existing.merge(override);
        } else if (existing is MetroContextMenuThemeData &&
            override is MetroContextMenuThemeData) {
          merged[index] = existing.merge(override);
        } else {
          merged[index] = override;
        }
      }
    }
    final textTheme = source.textTheme.apply(
      fontFamily: family,
      package: package,
      bodyColor: foreground,
      displayColor: foreground,
      decorationColor: foreground,
    );
    return source.copyWith(
      disabledColor: highContrast ? disabledColor : source.disabledColor,
      brightness: brightness,
      typography: uixTypography(source.typography),
      colorScheme: scheme.copyWith(
        brightness: brightness,
        primary: primaryColor,
        onPrimary: _contrastForeground(primaryColor),
        onSurface: foreground,
        surface: background,
        surfaceContainer: surfaceColor,
        outline: highContrast ? foreground : scheme.outline,
      ),
      primaryColor: primaryColor,
      scaffoldBackgroundColor: background,
      textTheme: uixTextTheme(textTheme),
      extensions: merged,
    );
  }

  static Color _contrastForeground(Color background) {
    return background.computeLuminance() > .179 ? Colors.black : Colors.white;
  }
}

/// Applies a Metro preset without adding a navigator or changing layout scale.
///
/// Use [MetroThemeData.extensions] to override component defaults.
class MetroTheme extends StatelessWidget {
  const MetroTheme({super.key, required this.data, required this.child});

  final MetroThemeData data;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = data.resolve(context);
    return Theme(
      data: theme,
      child: DefaultTextStyle(
        style: theme.textTheme.bodyMedium ?? const TextStyle(),
        child: child,
      ),
    );
  }
}
