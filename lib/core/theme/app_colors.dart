import 'package:flutter/material.dart';

/// Raw color tokens of the BaleadaFit brand.
///
/// Widgets normally read colors from `Theme.of(context).colorScheme`, so a
/// future dark theme keeps working without touching feature code. These tokens
/// exist to build that scheme and for the few brand cases Material roles do
/// not cover.
abstract final class AppColors {
  // Brand — leaf green.
  static const Color green50 = Color(0xFFE9F6EE);
  static const Color green100 = Color(0xFFC9EAD6);
  static const Color green200 = Color(0xFFA0DBB6);
  static const Color green300 = Color(0xFF72C995);
  static const Color green400 = Color(0xFF46B673);
  static const Color green500 = Color(0xFF1FA25B);
  static const Color green600 = Color(0xFF168648);
  static const Color green700 = Color(0xFF0F6A38);
  static const Color green800 = Color(0xFF094E29);
  static const Color green900 = Color(0xFF05351C);

  /// Accent for energy, calories and highlighted metrics.
  static const Color mango100 = Color(0xFFFDF0D8);
  static const Color mango300 = Color(0xFFF8CD88);
  static const Color mango500 = Color(0xFFF2A63B);
  static const Color mango700 = Color(0xFFC97C1B);

  // Neutrals.
  static const Color white = Color(0xFFFFFFFF);
  static const Color neutral50 = Color(0xFFF6F9F7);
  static const Color neutral100 = Color(0xFFEDF1EE);
  static const Color neutral200 = Color(0xFFDCE3DE);
  static const Color neutral300 = Color(0xFFC2CCC6);
  static const Color neutral500 = Color(0xFF8A968F);
  static const Color neutral700 = Color(0xFF55625B);
  static const Color neutral900 = Color(0xFF1C211E);
  static const Color black = Color(0xFF0E120F);

  // Semantic roles.
  static const Color success = green600;
  static const Color warning = mango700;
  static const Color error = Color(0xFFC62828);
  static const Color info = Color(0xFF1565C0);

  /// Main action color. 4.57:1 against white text.
  static const Color primary = green600;
  static const Color onPrimary = white;
  static const Color primaryContainer = green50;
  static const Color onPrimaryContainer = green900;

  /// Brand accent. Pair it with [neutral900] for text, never with white.
  static const Color accent = mango500;
  static const Color accentContainer = mango100;
}
