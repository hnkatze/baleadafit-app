import 'package:flutter/material.dart';

import '../../core/theme/app_dimensions.dart';

/// Text input styled by the app input decoration theme.
///
/// Thin wrapper over [TextFormField] that also renders the label the way the
/// mobile screens do: a small row *above* the field (optional icon, optional
/// trailing widget) instead of a floating label inside it, which keeps the
/// 44pt field height of the mockups.
class AppTextField extends StatelessWidget {
  const AppTextField({
    this.controller,
    this.focusNode,
    this.label,
    this.labelIcon,
    this.trailing,
    this.hint,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.enabled = true,
    this.maxLines = 1,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    super.key,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? label;

  /// Rendered at 18pt in the primary color before the label.
  final IconData? labelIcon;

  /// Rendered at the end of the label row, e.g. a "forgot password" link.
  final Widget? trailing;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool enabled;
  final int maxLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final label = this.label;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Row(
            children: [
              if (labelIcon != null) ...[
                Icon(
                  labelIcon,
                  size: AppDimensions.iconSm,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: AppDimensions.spaceXs + 2),
              ],
              Expanded(
                child: Text(
                  label,
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: AppDimensions.spaceXs + 2),
        ],
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          obscureText: obscureText,
          maxLines: maxLines,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          autofillHints: autofillHints,
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: onFieldSubmitted,
          style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            helperText: helperText,
            errorText: errorText,
            prefixIcon: prefixIcon == null
                ? null
                : Icon(prefixIcon, size: AppDimensions.iconSm),
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}
