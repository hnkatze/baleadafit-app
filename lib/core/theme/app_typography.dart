import 'package:flutter/material.dart';

/// Type scale of the app.
///
/// The family stays the platform default (SF Pro on iOS, Roboto on Android) so
/// screens render natively. Add `fontFamily` here once a brand font ships.
abstract final class AppTypography {
  static const TextTheme textTheme = TextTheme(
    displaySmall: TextStyle(fontSize: 32, height: 1.2, fontWeight: FontWeight.w700),
    headlineMedium: TextStyle(fontSize: 28, height: 1.25, fontWeight: FontWeight.w700),
    headlineSmall: TextStyle(fontSize: 24, height: 1.25, fontWeight: FontWeight.w700),
    titleLarge: TextStyle(fontSize: 20, height: 1.3, fontWeight: FontWeight.w600),
    titleMedium: TextStyle(fontSize: 16, height: 1.3, fontWeight: FontWeight.w600),
    titleSmall: TextStyle(fontSize: 14, height: 1.3, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(fontSize: 16, height: 1.5),
    bodyMedium: TextStyle(fontSize: 14, height: 1.5),
    bodySmall: TextStyle(fontSize: 12, height: 1.5),
    labelLarge: TextStyle(fontSize: 16, height: 1.2, fontWeight: FontWeight.w600),
    labelMedium: TextStyle(fontSize: 13, height: 1.2, fontWeight: FontWeight.w500),
    labelSmall: TextStyle(fontSize: 11, height: 1.2, fontWeight: FontWeight.w500),
  );
}
