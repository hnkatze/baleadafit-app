import 'package:flutter/widgets.dart';

/// Spacing, radius and sizing tokens. Layout code uses these instead of magic
/// numbers so the whole app keeps one rhythm.
abstract final class AppDimensions {
  // Spacing scale.
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 16;
  static const double spaceLg = 24;
  static const double spaceXl = 32;
  static const double spaceXxl = 48;

  // Corner radius scale.
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;

  /// Height of a primary action button.
  static const double buttonHeight = 52;

  static const double iconSm = 18;
  static const double iconMd = 24;

  /// Default gutters for a screen body.
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: spaceMd,
    vertical: spaceLg,
  );

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 250);
}
