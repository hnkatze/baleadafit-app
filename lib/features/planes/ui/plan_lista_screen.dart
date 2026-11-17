import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/fechas.dart';
import '../../../core/network/api_failure.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_pill.dart';
import '../../../shared/widgets/app_refresh.dart';
import '../../patients/data/patients_providers.dart';
import '../data/plan.dart';
import '../data/planes_formato.dart';
import '../data/planes_providers.dart';

/// The plans of one patient, reached from the patient file.
///
/// Two ways out and one forward: back to the patient file, generate a plan, or
/// open one plan. It edits nothing: activation and deletion live in the detail.
class PlanListaScreen extends ConsumerWidget {
  const PlanListaScreen({
    required this.pacienteId,
    required this.onAbrir,
    required this.onGenerar,
    required this.onBack,
    super.key,
  });

  final String pacienteId;
  final ValueChanged<String> onAbrir;
  final VoidCallback onGenerar;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planes = ref.watch(planesDePacienteProvider(pacienteId));
    final paciente = ref
        .watch(pacienteFichaProvider(pacienteId))
        .asData
        ?.value
        .paciente
        .nombreCompleto;
    final items = planes.asData?.value.items ?? const <Plan>[];

    return Material(
      type: MaterialType.transparency,
      child: Column(
        children: [
          Expanded(
            child: AppRefresh(
              onRefresh: () async =>
                  ref.invalidate(planesDePacienteProvider(pacienteId)),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: AppDimensions.screenPadding,
                children: [
                  _Cabecera(onBack: onBack, paciente: paciente),
                  const SizedBox(height: AppDimensions.spaceMd),
                  planes.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: AppDimensions.spaceXl,
                      ),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (error, _) => _FalloCarga(
                      error: error,
                      onReintentar: () =>
                          ref.invalidate(planesDePacienteProvider(pacienteId)),
                    ),
                    data: (paged) => paged.items.isEmpty
                        ? _SinPlanes(onGenerar: onGenerar)
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final plan in paged.items) ...[
                                _TarjetaPlan(
                                  plan: plan,
                                  onAbrir: () => onAbrir(plan.id),
                                ),
                                const SizedBox(height: AppDimensions.spaceMd),
                              ],
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
          // The empty state carries its own button, so the fixed one only shows
          // over a real list.
          if (items.isNotEmpty) _BotonGenerar(onGenerar: onGenerar),
        ],
      ),
    );
  }
}

/// Back arrow, the section name and the patient it belongs to.
class _Cabecera extends StatelessWidget {
  const _Cabecera({required this.onBack, required this.paciente});

  final VoidCallback onBack;
  final String? paciente;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final nombre = paciente;

    return Row(
      children: [
        IconButton(
          tooltip: 'Volver a la ficha',
          icon: const Icon(Icons.arrow_back, size: AppDimensions.iconMd),
          onPressed: onBack,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Planes', style: textTheme.titleLarge),
              if (nombre != null && nombre.isNotEmpty)
                Text(
                  nombre,
                  style: textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TarjetaPlan extends StatelessWidget {
  const _TarjetaPlan({required this.plan, required this.onAbrir});

  final Plan plan;
  final VoidCallback onAbrir;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final linea = fechaDelPlan(plan);

    return AppCard(
      child: InkWell(
        onTap: onAbrir,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(plan.nombre, style: textTheme.titleMedium),
                  ),
                  const SizedBox(width: AppDimensions.spaceSm),
                  AppPill(label: plan.estado.codigo),
                ],
              ),
              const SizedBox(height: AppDimensions.spaceXs),
              Text(
                plan.origen.etiqueta,
                style: textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _Metrica(
                      etiqueta: 'KCAL',
                      valor: formatearKcal(plan.kcalObjetivo),
                    ),
                  ),
                  Expanded(
                    child: _Metrica(
                      etiqueta: 'PROT',
                      valor: formatearGramos(plan.proteinaG),
                    ),
                  ),
                  Expanded(
                    child: _Metrica(
                      etiqueta: 'CARB',
                      valor: formatearGramos(plan.carbohidratoG),
                    ),
                  ),
                  Expanded(
                    child: _Metrica(
                      etiqueta: 'GRASA',
                      valor: formatearGramos(plan.grasaG),
                    ),
                  ),
                ],
              ),
              if (linea != null) ...[
                const SizedBox(height: AppDimensions.spaceMd),
                Text(
                  linea,
                  style: textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// One cell of the card grid: the label above, the figure under it.
class _Metrica extends StatelessWidget {
  const _Metrica({required this.etiqueta, required this.valor});

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          style: textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
        ),
        Text(valor, style: textTheme.titleSmall),
      ],
    );
  }
}

/// The date line of a plan in the list, after `toLocal()`: `Activo el 7 nov`,
/// `Creado el 20 oct · solo lectura`. An archived plan says it is read only even
/// when the API gives no date, and a plan with no date draws no line.
String? fechaDelPlan(Plan plan) {
  switch (plan.estado) {
    case EstadoPlan.borrador:
      final fecha = plan.creadoEn;
      return fecha == null ? null : 'Creado el ${diaYMes(fecha)}';
    case EstadoPlan.activo:
      final fecha = plan.aprobadoEn ?? plan.creadoEn;
      return fecha == null ? null : 'Activo el ${diaYMes(fecha)}';
    case EstadoPlan.archivado:
      final fecha = plan.creadoEn;
      return fecha == null
          ? 'solo lectura'
          : 'Creado el ${diaYMes(fecha)} · solo lectura';
  }
}

class _SinPlanes extends StatelessWidget {
  const _SinPlanes({required this.onGenerar});

  final VoidCallback onGenerar;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        const SizedBox(height: AppDimensions.spaceXl),
        Icon(
          Icons.restaurant_menu,
          size: AppDimensions.spaceXxl,
          color: colors.onSurfaceVariant,
        ),
        const SizedBox(height: AppDimensions.spaceMd),
        Text(
          'Todavía no tiene un plan',
          style: textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimensions.spaceSm),
        Text(
          'Generá el primero con sus metas y restricciones. Va a quedar en '
          'borrador hasta que lo revisés y lo activés.',
          style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimensions.spaceLg),
        AppButton(label: 'Generar plan', onPressed: onGenerar),
      ],
    );
  }
}

/// The failure of the list, with the API message when it carried one.
class _FalloCarga extends StatelessWidget {
  const _FalloCarga({required this.error, required this.onReintentar});

  final Object error;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final fallo = error;

    return Column(
      children: [
        const SizedBox(height: AppDimensions.spaceXl),
        Text(
          'No pudimos cargar los planes.',
          style: textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        if (fallo is ApiFailure) ...[
          const SizedBox(height: AppDimensions.spaceSm),
          Text(
            fallo.mensaje,
            style: textTheme.bodySmall?.copyWith(color: colors.error),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: AppDimensions.spaceLg),
        AppButton(
          label: 'Reintentar',
          variant: AppButtonVariant.secondary,
          onPressed: onReintentar,
        ),
      ],
    );
  }
}

/// The fixed action under a real list.
class _BotonGenerar extends StatelessWidget {
  const _BotonGenerar({required this.onGenerar});

  final VoidCallback onGenerar;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surface,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceLg),
          child: AppButton(label: 'Generar plan', onPressed: onGenerar),
        ),
      ),
    );
  }
}
