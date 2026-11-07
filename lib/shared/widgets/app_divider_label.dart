import 'package:flutter/material.dart';

import '../../core/theme/app_dimensions.dart';

/// A hairline split by a centered label, used to separate sign-in methods.
class AppDividerLabel extends StatelessWidget {
  const AppDividerLabel({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lineColor = theme.colorScheme.surfaceContainerHighest;

    return Row(
      children: [
        Expanded(child: Divider(color: lineColor, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceMd - 4,
          ),
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ),
        Expanded(child: Divider(color: lineColor, height: 1)),
      ],
    );
  }
}
