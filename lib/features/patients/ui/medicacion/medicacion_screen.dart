import 'package:flutter/material.dart';

import '../../../../core/theme/app_dimensions.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../data/medicamento.dart';

/// The medication list of one patient.
///
/// Stateless on purpose: everything comes in through the constructor, so the
/// wiring (ficha data, routes, invalidation) lives with whoever mounts it.
class MedicacionScreen extends StatelessWidget {
  const MedicacionScreen({
    required this.pacienteNombre,
    required this.medicamentos,
    required this.onRegistrar,
    required this.onAbrir,
    this.onVolver,
    super.key,
  });

  final String pacienteNombre;
  final List<Medicamento> medicamentos;
  final VoidCallback onRegistrar;
  final void Function(Medicamento medicamento) onAbrir;

  /// Draws the back arrow when given; without it no navigation is invented.
  final VoidCallback? onVolver;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surface,
      child: Column(
        children: [
          _Cabecera(pacienteNombre: pacienteNombre, onVolver: onVolver),
          Expanded(
            child: medicamentos.isEmpty
                ? const _SinMedicacion()
                : ListView(
                    padding: AppDimensions.screenPadding,
                    children: [
                      const _Aviso(),
                      for (final medicamento in medicamentos) ...[
                        const SizedBox(height: _separacionFilas),
                        _FilaMedicamento(
                          medicamento: medicamento,
                          onAbrir: () => onAbrir(medicamento),
                        ),
                      ],
                    ],
                  ),
          ),
          // Fixed in every state: the empty state does not carry its own button.
          _BarraRegistrar(onRegistrar: onRegistrar),
        ],
      ),
    );
  }
}

/// Gap between the note and the rows (12 in the artboard).
const double _separacionFilas = 12;

/// Optional back arrow, the section name and the patient it belongs to.
class _Cabecera extends StatelessWidget {
  const _Cabecera({required this.pacienteNombre, required this.onVolver});

  final String pacienteNombre;
  final VoidCallback? onVolver;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final volver = onVolver;

    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: EdgeInsets.only(
        left: volver == null ? AppDimensions.spaceMd : AppDimensions.spaceXs,
        right: AppDimensions.spaceMd,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            if (volver != null)
              IconButton(
                tooltip: 'Volver a la ficha',
                icon: const Icon(Icons.arrow_back, size: AppDimensions.iconMd),
                onPressed: volver,
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Medicación', style: textTheme.titleLarge),
                  if (pacienteNombre.isNotEmpty)
                    Text(
                      pacienteNombre,
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Informative note above the rows.
class _Aviso extends StatelessWidget {
  const _Aviso();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceMd,
        vertical: _separacionFilas,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: colors.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Medicación vigente. Una baja la saca de esta lista y del '
              'expediente; el historial clínico se conserva.',
              style: textTheme.titleSmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Round tinted badge holding the pill icon, shared by rows and empty state.
class _InsigniaPastilla extends StatelessWidget {
  const _InsigniaPastilla({required this.diametro, required this.icono});

  final double diametro;
  final double icono;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: diametro,
      height: diametro,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.surfaceContainer,
      ),
      child: Icon(Icons.medication, size: icono, color: colors.primary),
    );
  }
}

class _FilaMedicamento extends StatelessWidget {
  const _FilaMedicamento({required this.medicamento, required this.onAbrir});

  final Medicamento medicamento;
  final VoidCallback onAbrir;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    // Missing data means no second line at all (never "·", "null" or a dash).
    final composicion = medicamento.composicion;

    return Material(
      color: colors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        side: BorderSide(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onAbrir,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceMd,
            vertical: _separacionFilas,
          ),
          child: Row(
            children: [
              const _InsigniaPastilla(diametro: 40, icono: 20),
              const SizedBox(width: _separacionFilas),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(medicamento.nombre, style: textTheme.titleMedium),
                    if (composicion != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          composicion,
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 22, color: colors.outline),
            ],
          ),
        ),
      ),
    );
  }
}

class _SinMedicacion extends StatelessWidget {
  const _SinMedicacion();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceMd,
        vertical: AppDimensions.spaceLg,
      ),
      children: [
        const SizedBox(height: AppDimensions.spaceXxl),
        const Center(child: _InsigniaPastilla(diametro: 72, icono: 36)),
        const SizedBox(height: AppDimensions.spaceMd),
        Text(
          'Sin medicación registrada',
          style: textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimensions.spaceSm),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Text(
              'Registrá los medicamentos que el paciente toma, con dosis y '
              'frecuencia si las conocés.',
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}

/// The fixed primary action at the foot of the screen.
class _BarraRegistrar extends StatelessWidget {
  const _BarraRegistrar({required this.onRegistrar});

  final VoidCallback onRegistrar;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.spaceMd,
            _separacionFilas,
            AppDimensions.spaceMd,
            AppDimensions.spaceMd,
          ),
          child: AppButton(
            label: 'Registrar medicamento',
            icon: Icons.add,
            onPressed: onRegistrar,
          ),
        ),
      ),
    );
  }
}
