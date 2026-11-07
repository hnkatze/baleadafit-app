import 'package:flutter/material.dart';

/// Spacing, radius and sizing tokens.
///
/// The scale mirrors the design system the screens are drawn with
/// (`odd/designs/mobile/`): a 4pt grid, radii of 4/8/12/16 plus full, and the
/// two control heights the mockups use. Layout code uses these instead of magic
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
  static const double radiusXs = 4;
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusFull = 999;

  /// Height of a primary action button (48 in the mockups).
  static const double buttonHeight = 48;

  /// Height of a text field (44 in the mockups).
  static const double fieldHeight = 44;

  static const double iconSm = 18;
  static const double iconMd = 24;

  /// Default gutters for a screen body: 16 side margin, 24 vertical breathing.
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: spaceMd,
    vertical: spaceLg,
  );

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 250);
}
