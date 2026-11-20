import 'package:flutter/material.dart';

import '../../core/theme/app_dimensions.dart';

/// Status label that carries the colour of the state it names.
///
/// [AppPill] stays the neutral, outlined label the rest of the app uses; this
/// one is for the few states that deserve a tint, like a plan active or not. The
/// colours come from the caller so the meaning of each state lives with the
/// screen that draws it, not here.
class AppTintedPill extends StatelessWidget {
  const AppTintedPill({
    required this.label,
    required this.background,
    required this.foreground,
    this.dotColor,
    super.key,
  });

  final String label;
  final Color background;
  final Color foreground;

  /// Draws an 8pt dot in this colour. No dot when it is null.
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    final dotColor = this.dotColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotColor != null) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: AppDimensions.spaceXs + 2),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
