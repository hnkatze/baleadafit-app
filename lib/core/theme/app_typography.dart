import 'package:flutter/material.dart';

/// Type scale of the app.
///
/// **Plus Jakarta Sans** at the sizes and weights the mobile mockups use
/// (`odd/designs/mobile/`). The family ships in `assets/fonts/` and is declared
/// in `pubspec.yaml`, so it renders offline, in tests and on the device alike.
///
/// Material roles are mapped to the design levels:
/// display→display-lg-mobile, headline*→headline-*, title*→title-*, body*→body-*,
/// label*→label-*/label-lg.
abstract final class AppTypography {
  /// Registered family name, as declared in `pubspec.yaml`.
  static const String family = 'PlusJakartaSans';

  /// Monospaced family for figures that must not shift: times, doses, macros.
  static const String monoFamily = 'JetBrainsMono';

  /// Type scale for `ThemeData.textTheme`.
  static TextTheme get textTheme => const TextTheme(
    displayLarge: TextStyle(
      fontSize: 36,
      height: 1.22,
      fontWeight: FontWeight.w800,
      letterSpacing: -1.08,
    ),
    displayMedium: TextStyle(
      fontSize: 32,
      height: 1.25,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.88,
    ),
    displaySmall: TextStyle(
      fontSize: 28,
      height: 1.29,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.56,
    ),
    headlineLarge: TextStyle(
      fontSize: 30,
      height: 1.27,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.6,
    ),
    headlineMedium: TextStyle(
      fontSize: 24,
      height: 1.33,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.36,
    ),
    headlineSmall: TextStyle(
      fontSize: 20,
      height: 1.4,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
    ),
    titleLarge: TextStyle(
      fontSize: 16,
      height: 1.5,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.08,
    ),
    titleMedium: TextStyle(
      fontSize: 14,
      height: 1.43,
      fontWeight: FontWeight.w600,
    ),
    titleSmall: TextStyle(
      fontSize: 12,
      height: 1.33,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.24,
    ),
    bodyLarge: TextStyle(fontSize: 16, height: 1.63),
    bodyMedium: TextStyle(fontSize: 14, height: 1.57),
    bodySmall: TextStyle(fontSize: 13, height: 1.38, letterSpacing: 0.07),
    labelLarge: TextStyle(
      fontSize: 16,
      height: 1.5,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.08,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      height: 1.33,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.24,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      height: 1.27,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.44,
    ),
  ).apply(fontFamily: family);

  /// Monospaced style for clinical numbers (macros, weights, portions).
  ///
  /// Tabular by hand: use it wherever digits must line up in a column.
  static TextStyle data(BuildContext context) {
    final base = Theme.of(context).textTheme.bodySmall ?? const TextStyle();
    return base.copyWith(
      fontFamily: monoFamily,
      fontSize: 13,
      height: 1.38,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.13,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }
}
