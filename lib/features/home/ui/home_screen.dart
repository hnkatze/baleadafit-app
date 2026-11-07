import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_failure.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../shared/widgets/app_button.dart';
import '../../auth/application/session_controller.dart';
import '../data/dashboard_providers.dart';
import '../data/dashboard_resumen.dart';

/// Home of the authenticated area: the summary `GET /dashboard` returns.
///
/// Only what the API exposes is drawn. The mockup also shows InBody readings,
/// the WhatsApp bot and an adherence score; none of that has an endpoint yet.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final name = ref.watch(sessionControllerProvider).session?.displayName;
    final resumen = ref.watch(dashboardProvider);

    return ListView(
      padding: AppDimensions.screenPadding,
      children: [
        Text(
          name == null ? 'Tu resumen' : 'Hola, $name',
          style: textTheme.headlineSmall,
        ),
        const SizedBox(height: AppDimensions.spaceXs),
        Text('Así va tu consulta hoy.', style: textTheme.bodyMedium),
        const SizedBox(height: AppDimensions.spaceLg),
        ...resumen.when(
          loading: () => const [
            Padding(
              padding: EdgeInsets.symmetric(vertical: AppDimensions.spaceXl),
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
          error: (error, _) => [
            _LoadFailure(
              error: error,
              onRetry: () => ref.invalidate(dashboardProvider),
            ),
          ],
          data: (data) => [_Summary(data: data)],
        ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.data});

  final DashboardResumen data;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _Kpi(
                icon: Icons.groups_2_outlined,
                value: '${data.pacientesActivos}',
                label: 'Pacientes activos',
              ),
            ),
            const SizedBox(width: AppDimensions.spaceSm),
            Expanded(
              child: _Kpi(
                icon: Icons.description_outlined,
                value: '${data.planesEnBorrador}',
                label: 'Planes en borrador',
              ),
            ),
            const SizedBox(width: AppDimensions.spaceSm),
            Expanded(
              child: _Kpi(
                icon: Icons.event_available_outlined,
                value: '${data.citasHoy.length}',
                label: 'Citas hoy',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spaceLg),
        Text('Citas de hoy', style: textTheme.titleMedium),
        const SizedBox(height: AppDimensions.spaceSm),
        if (data.citasHoy.isEmpty)
          Text(
            'No tenés citas hoy. Buen momento para revisar los planes en borrador.',
            style: textTheme.bodyMedium,
          )
        else
          ...data.citasHoy.map((cita) => _CitaTile(cita: cita)),
      ],
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceSm),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppDimensions.iconSm, color: colors.primary),
          const SizedBox(height: AppDimensions.spaceXs),
          Text(value, style: textTheme.headlineSmall),
          Text(label, style: textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _CitaTile extends StatelessWidget {
  const _CitaTile({required this.cita});

  final CitaResumen cita;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spaceSm),
      padding: const EdgeInsets.all(AppDimensions.spaceMd),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(cita.hora, style: textTheme.titleMedium),
              Text('${cita.duracionMin} min', style: textTheme.bodySmall),
            ],
          ),
          const SizedBox(width: AppDimensions.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cita.paciente?.nombreCompleto ?? 'Paciente sin nombre',
                  style: textTheme.titleSmall,
                ),
                Text(
                  cita.motivo,
                  style: textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadFailure extends StatelessWidget {
  const _LoadFailure({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final failure = error;
    final detail = failure is ApiFailure
        ? failure.mensaje
        : 'Revisá tu conexión e intentá de nuevo.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('No pudimos cargar tu resumen.', style: textTheme.titleMedium),
        const SizedBox(height: AppDimensions.spaceXs),
        Text(detail, style: textTheme.bodyMedium),
        const SizedBox(height: AppDimensions.spaceMd),
        AppButton(
          label: 'Reintentar',
          icon: Icons.refresh,
          variant: AppButtonVariant.secondary,
          onPressed: onRetry,
        ),
      ],
    );
  }
}
