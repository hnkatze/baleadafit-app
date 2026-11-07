import 'package:baleadafit/core/theme/app_colors.dart';
import 'package:baleadafit/core/theme/app_dimensions.dart';
import 'package:baleadafit/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppTheme.light', () {
    final theme = AppTheme.light;

    test('is a light theme carrying the Clinical Mint roles', () {
      expect(theme.colorScheme.brightness, Brightness.light);
      expect(theme.colorScheme.primary, AppColors.primary);
      expect(theme.colorScheme.onPrimary, AppColors.onPrimary);
      expect(theme.colorScheme.secondary, AppColors.secondary);
      expect(theme.colorScheme.secondaryContainer, AppColors.secondaryContainer);
      expect(theme.colorScheme.error, AppColors.error);
    });

    test('paints the scaffold with the surface token', () {
      expect(theme.scaffoldBackgroundColor, AppColors.surface);
      expect(theme.colorScheme.surface, AppColors.surface);
    });

    test('wires the Plus Jakarta Sans scale from the design', () {
      // google_fonts registers the bundled family as PlusJakartaSans_<weight>.
      expect(
        theme.textTheme.titleLarge?.fontFamily,
        startsWith('PlusJakartaSans'),
      );
      expect(theme.textTheme.displaySmall?.fontSize, 28);
      expect(theme.textTheme.displaySmall?.fontWeight, FontWeight.w800);
      expect(theme.textTheme.headlineMedium?.fontSize, 24);
      expect(theme.textTheme.headlineMedium?.fontWeight, FontWeight.w700);
      expect(theme.textTheme.titleLarge?.fontSize, 16);
      expect(theme.textTheme.bodyMedium?.fontSize, 14);
      expect(theme.textTheme.labelLarge?.fontSize, 16);
      expect(theme.textTheme.labelSmall?.fontSize, 11);
    });

    test('gives buttons the design height and radius', () {
      final size = theme.filledButtonTheme.style?.minimumSize?.resolve(
        const <WidgetState>{},
      );
      final shape =
          theme.filledButtonTheme.style?.shape?.resolve(const <WidgetState>{})
              as RoundedRectangleBorder?;

      expect(size?.height, AppDimensions.buttonHeight);
      expect(size?.height, 48);
      expect(
        shape?.borderRadius,
        BorderRadius.circular(AppDimensions.radiusSm),
      );
    });

    test('gives text fields the borderless filled decoration', () {
      final decoration = theme.inputDecorationTheme;

      expect(decoration.filled, isTrue);
      expect(decoration.fillColor, AppColors.surfaceContainerLow);
      expect(decoration.border, isA<OutlineInputBorder>());
      expect(decoration.focusedBorder, isA<OutlineInputBorder>());

      final enabled = decoration.enabledBorder! as OutlineInputBorder;
      expect(enabled.borderSide.style, BorderStyle.none);
      final focused = decoration.focusedBorder! as OutlineInputBorder;
      expect(focused.borderSide.color, AppColors.primary);
    });

    test('gives cards the bordered container instead of a shadow', () {
      final cardTheme = theme.cardTheme;
      final shape = cardTheme.shape! as RoundedRectangleBorder;

      expect(cardTheme.elevation, 0);
      expect(cardTheme.color, AppColors.surfaceContainerLowest);
      expect(shape.side.color, AppColors.outlineVariant);
      expect(shape.borderRadius, BorderRadius.circular(AppDimensions.radiusLg));
    });
  });
}
