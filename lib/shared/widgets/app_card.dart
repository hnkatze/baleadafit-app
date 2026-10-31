import 'package:flutter/material.dart';

import '../../core/theme/app_dimensions.dart';

/// Grouped content surface. Shape, border and elevation come from the app card
/// theme; pass [onTap] to make the whole card tappable.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppDimensions.spaceMd),
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
