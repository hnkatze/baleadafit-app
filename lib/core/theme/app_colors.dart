import 'package:flutter/material.dart';

/// Color tokens of the BaleadaFit brand.
///
/// These are the exact tokens of the **Clinical Mint Precision** design system
/// that the mobile screens are drawn with (see `odd/designs/mobile/`), so the
/// app and the reference share one palette instead of two similar ones.
///
/// Widgets normally read colors from `Theme.of(context).colorScheme`; these
/// tokens exist to build that scheme and for the few cases Material roles do
/// not cover. Never hardcode a hex value in a widget.
abstract final class AppColors {
  // Primary — the mint that carries actions and the brand.
  static const Color primary = Color(0xFF006C49);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF10B981);
  static const Color onPrimaryContainer = Color(0xFF00422B);
  static const Color primaryFixed = Color(0xFF6FFBBE);
  static const Color primaryFixedDim = Color(0xFF4EDEA3);
  static const Color onPrimaryFixedVariant = Color(0xFF005236);

  // Secondary — soft mint used for fast, non-primary actions.
  static const Color secondary = Color(0xFF1B6B51);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFA6F2D1);
  static const Color onSecondaryContainer = Color(0xFF237157);

  // Tertiary — deep green for positive metrics (adherence, goals met).
  static const Color tertiary = Color(0xFF006C4B);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFF00B982);
  static const Color onTertiaryContainer = Color(0xFF00422C);

  // Surfaces — the blue-tinted off-white the screens sit on.
  static const Color surface = Color(0xFFF9F9FF);
  static const Color onSurface = Color(0xFF111C2D);
  static const Color onSurfaceVariant = Color(0xFF3C4A42);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF0F3FF);
  static const Color surfaceContainer = Color(0xFFE7EEFF);
  static const Color surfaceContainerHigh = Color(0xFFDEE8FF);
  static const Color surfaceContainerHighest = Color(0xFFD8E3FB);
  static const Color surfaceTint = Color(0xFF006C49);

  static const Color inverseSurface = Color(0xFF263143);
  static const Color inverseOnSurface = Color(0xFFECF1FF);
  static const Color inversePrimary = Color(0xFF4EDEA3);

  // Lines and borders.
  static const Color outline = Color(0xFF6C7A71);
  static const Color outlineVariant = Color(0xFFBBCABF);

  // Feedback.
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);
}
