import 'package:flutter/material.dart';

import '../../../core/theme/app_dimensions.dart';
import '../data/plan.dart';

/// The state of a plan as a coloured pill: `ACTIVO` in the secondary container,
/// `BORRADOR` and `ARCHIVADO` in the neutral one. The list and the detail draw
/// the same badge; the colours come from the `colorScheme`.
class PlanInsignia extends StatelessWidget {
  const PlanInsignia({required this.estado, super.key});

  final EstadoPlan estado;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final activo = estado == EstadoPlan.activo;

    return Container(
      key: const Key('insignia-estado'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceSm + 2,
        vertical: AppDimensions.spaceXs,
      ),
      decoration: BoxDecoration(
        color: activo ? colors.secondaryContainer : colors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Text(
        estado.codigo,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: activo ? colors.onSecondaryContainer : colors.onSurfaceVariant,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
