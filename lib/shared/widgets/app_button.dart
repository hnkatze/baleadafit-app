import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';

/// Visual weight of an [AppButton].
enum AppButtonVariant {
  /// Filled brand button for the main action of a screen.
  primary,

  /// Filled soft-mint button for a fast, secondary action (biometric sign in,
  /// shortcuts).
  tonal,

  /// Outlined button for secondary actions.
  secondary,

  /// Text-only button for low-emphasis actions.
  text,
}

/// Brand button with one API for the three action weights, an optional leading
/// icon and an inline loading state.
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.expand = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;

  /// Replaces the label with a spinner and ignores taps while true.
  final bool isLoading;

  /// Stretches the button to the full width of its parent.
  final bool expand;

  bool get _isInteractive => onPressed != null && !isLoading;

  @override
  Widget build(BuildContext context) {
    final onPressed = _isInteractive ? this.onPressed : null;
    final child = isLoading
        ? _LoadingIndicator(variant: variant)
        : _Label(label: label, icon: icon);
    final button = switch (variant) {
      AppButtonVariant.primary => FilledButton(onPressed: onPressed, child: child),
      AppButtonVariant.tonal => FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.secondaryContainer,
          foregroundColor: AppColors.onSecondaryContainer,
        ),
        child: child,
      ),
      AppButtonVariant.secondary => OutlinedButton(onPressed: onPressed, child: child),
      AppButtonVariant.text => TextButton(onPressed: onPressed, child: child),
    };

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final icon = this.icon;
    if (icon == null) {
      return Text(label);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppDimensions.iconSm),
        const SizedBox(width: AppDimensions.spaceSm),
        Text(label),
      ],
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator({required this.variant});

  final AppButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = switch (variant) {
      AppButtonVariant.primary => colorScheme.onPrimary,
      AppButtonVariant.tonal => colorScheme.onSecondaryContainer,
      AppButtonVariant.secondary || AppButtonVariant.text => colorScheme.primary,
    };
    return SizedBox.square(
      dimension: AppDimensions.iconSm,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}
