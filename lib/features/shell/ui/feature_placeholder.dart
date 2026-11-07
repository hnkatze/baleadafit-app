import 'package:flutter/material.dart';

import '../../../core/theme/app_dimensions.dart';
import '../../../shared/widgets/app_pill.dart';

/// Stand-in for a screen that has a route but no content yet.
class FeaturePlaceholder extends StatelessWidget {
  const FeaturePlaceholder({
    required this.title,
    required this.description,
    this.icon = Icons.construction_outlined,
    super.key,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: AppDimensions.screenPadding,
      children: [
        Icon(icon, size: 40, color: colorScheme.primary),
        const SizedBox(height: AppDimensions.spaceMd),
        Text(title, style: textTheme.headlineSmall),
        const SizedBox(height: AppDimensions.spaceSm),
        Text(
          description,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppDimensions.spaceLg),
        const Align(
          alignment: Alignment.centerLeft,
          child: AppPill(label: 'PANTALLA POR CONSTRUIR'),
        ),
      ],
    );
  }
}
