import 'package:flutter/material.dart';

/// Material's geometry supplies a fixed line height for every script. Metro
/// instead uses the active font's native line metrics unless a style opts in.
Typography uixTypography(Typography base) => Typography(
  black: _withoutHeight(base.black),
  white: _withoutHeight(base.white),
  englishLike: _withoutHeight(base.englishLike),
  dense: _withoutHeight(base.dense),
  tall: _withoutHeight(base.tall),
);

TextTheme _withoutHeight(TextTheme theme) => TextTheme(
  displayLarge: _nativeLineHeight(theme.displayLarge),
  displayMedium: _nativeLineHeight(theme.displayMedium),
  displaySmall: _nativeLineHeight(theme.displaySmall),
  headlineLarge: _nativeLineHeight(theme.headlineLarge),
  headlineMedium: _nativeLineHeight(theme.headlineMedium),
  headlineSmall: _nativeLineHeight(theme.headlineSmall),
  titleLarge: _nativeLineHeight(theme.titleLarge),
  titleMedium: _nativeLineHeight(theme.titleMedium),
  titleSmall: _nativeLineHeight(theme.titleSmall),
  bodyLarge: _nativeLineHeight(theme.bodyLarge),
  bodyMedium: _nativeLineHeight(theme.bodyMedium),
  bodySmall: _nativeLineHeight(theme.bodySmall),
  labelLarge: _nativeLineHeight(theme.labelLarge),
  labelMedium: _nativeLineHeight(theme.labelMedium),
  labelSmall: _nativeLineHeight(theme.labelSmall),
);

// copyWith(height: null) retains the original height, so reconstruct the style.
TextStyle? _nativeLineHeight(TextStyle? style) => style == null
    ? null
    : TextStyle(
        inherit: style.inherit,
        color: style.color,
        backgroundColor: style.backgroundColor,
        fontSize: style.fontSize,
        fontWeight: style.fontWeight,
        fontStyle: style.fontStyle,
        letterSpacing: style.letterSpacing,
        wordSpacing: style.wordSpacing,
        textBaseline: style.textBaseline,
        leadingDistribution: style.leadingDistribution,
        locale: style.locale,
        foreground: style.foreground,
        background: style.background,
        shadows: style.shadows,
        fontFeatures: style.fontFeatures,
        fontVariations: style.fontVariations,
        decoration: style.decoration,
        decorationColor: style.decorationColor,
        decorationStyle: style.decorationStyle,
        decorationThickness: style.decorationThickness,
        debugLabel: style.debugLabel,
        fontFamily: style.fontFamily,
        fontFamilyFallback: style.fontFamilyFallback,
        overflow: style.overflow,
      );
