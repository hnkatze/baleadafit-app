import 'package:baleadafit/core/theme/app_colors.dart';
import 'package:baleadafit/core/theme/app_dimensions.dart';
import 'package:baleadafit/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppTheme.light', () {
    final theme = AppTheme.light;

    test('is a light theme with the brand green as primary color', () {
      expect(theme.colorScheme.brightness, Brightness.light);
      expect(theme.colorScheme.primary, AppColors.primary);
      expect(theme.colorScheme.onPrimary, AppColors.white);
    });

    test('paints the scaffold with the neutral background', () {
      expect(theme.scaffoldBackgroundColor, AppColors.neutral50);
    });

    test('wires the shared typography scale', () {
      expect(theme.textTheme.titleLarge?.fontSize, 20);
      expect(theme.textTheme.bodyMedium?.fontSize, 14);
      expect(theme.textTheme.displaySmall?.fontWeight, FontWeight.w700);
      expect(theme.textTheme.labelLarge?.fontSize, 16);
    });

    test('gives buttons the app minimum height and radius', () {
      final style = theme.filledButtonTheme.style;
      final size = style?.minimumSize?.resolve(const <WidgetState>{});
      final shape = style?.shape?.resolve(const <WidgetState>{});

      expect(size?.height, AppDimensions.buttonHeight);
      expect(shape, isA<RoundedRectangleBorder>());
    });

    test('gives text fields the filled brand decoration', () {
      final decoration = theme.inputDecorationTheme;

      expect(decoration.filled, isTrue);
      expect(decoration.fillColor, AppColors.white);
      expect(decoration.border, isA<OutlineInputBorder>());
      expect(decoration.focusedBorder, isA<OutlineInputBorder>());
    });

    test('gives cards the neutral border instead of an elevation shadow', () {
      final cardTheme = theme.cardTheme;

      expect(cardTheme.elevation, 0);
      expect(cardTheme.color, AppColors.white);
      expect(cardTheme.shape, isA<RoundedRectangleBorder>());
    });
  });
}
