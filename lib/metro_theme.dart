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

  ThemeData resolve(BuildContext context, {ThemeData? base}) {
    final ambient = Theme.of(context);
    final inherited = ambient.extension<MetroSystemThemeData>();
    final effectiveBrightness =
        brightness ?? base?.brightness ?? ambient.brightness;
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
      base: base,
      fontFamily: inherited == null
          ? null
          : ambient.textTheme.bodyMedium?.fontFamily,
    );
  }

  ThemeData toThemeData({
    required Brightness brightness,
    bool highContrast = false,
    Color accentColor = const Color(0xff1ba1e2),
    ThemeData? base,
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
        this.accentColor ??
        base?.colorScheme.primary ??
        (highContrast ? foreground : accentColor);
    // High contrast uses explicit solid disabled colors, so
    // compositing against a parent surface cannot change their legibility.
    final disabledColor = highContrast
        ? (useWhiteTheme ? const Color(0xff595959) : const Color(0xffb3b3b3))
        : (base?.colorScheme.onSurface ?? foreground).withValues(alpha: .5);
    final family = fontFamily ?? 'Segoe WP';
    final package = fontFamily == null ? 'metro_ui' : null;
    final source =
        base ??
        ThemeData(
          brightness: brightness,
          colorSchemeSeed: primaryColor,
          fontFamily: family,
          package: package,
        );
    final scheme = source.colorScheme;
    final preset = base == null;
    final textColor = preset
        ? foreground
        : source.textTheme.bodyMedium?.color ?? scheme.onSurface;
    final onSurface = preset ? foreground : scheme.onSurface;
    final List<ThemeExtension<dynamic>> merged = [
      titleDefaults(textColor),
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
        onSurface,
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
    for (final override in [...?base?.extensions.values, ...extensions]) {
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
    final applyAccent = base == null || this.accentColor != null;
    final textTheme = source.textTheme.apply(
      fontFamily: family,
      package: package,
      bodyColor: preset ? foreground : null,
      displayColor: preset ? foreground : null,
      decorationColor: preset ? foreground : null,
    );
    return source.copyWith(
      disabledColor: preset && highContrast
          ? disabledColor
          : source.disabledColor,
      brightness: brightness,
      typography: base == null
          ? uixTypography(source.typography)
          : source.typography,
      colorScheme: scheme.copyWith(
        brightness: brightness,
        primary: primaryColor,
        onPrimary: applyAccent
            ? _contrastForeground(primaryColor)
            : scheme.onPrimary,
        onSurface: onSurface,
        surface: preset ? background : scheme.surface,
        surfaceContainer: preset ? surfaceColor : scheme.surfaceContainer,
        outline: preset && highContrast ? foreground : scheme.outline,
      ),
      primaryColor: applyAccent ? primaryColor : source.primaryColor,
      scaffoldBackgroundColor: preset
          ? background
          : source.scaffoldBackgroundColor,
      textTheme: preset ? uixTextTheme(textTheme) : textTheme,
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
