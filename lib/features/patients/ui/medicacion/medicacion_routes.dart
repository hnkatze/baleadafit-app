import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../data/medicamento.dart';
import '../../data/patients_providers.dart';
import 'baja_medicamento.dart';
import 'medicacion_screen.dart';
import 'medicamento_form_screen.dart';

/// Medication list of one patient, fed by the ficha the app already loads (S5).
///
/// It watches [pacienteFichaProvider] and keeps no copy. Every write (the
/// editor's save, the deactivation) already invalidates that provider, so the
/// list re-reads on its own when the user comes back and needs no refresh hook
/// of its own.
class MedicacionListaRoute extends ConsumerWidget {
  const MedicacionListaRoute({
    required this.pacienteId,
    required this.onVolver,
    required this.onRegistrar,
    required this.onAbrir,
    super.key,
  });

  final String pacienteId;
  final VoidCallback onVolver;
  final VoidCallback onRegistrar;
  final void Function(Medicamento medicamento) onAbrir;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ficha = ref.watch(pacienteFichaProvider(pacienteId));

    return ficha.when(
      // A reload keeps drawing the list it had instead of flashing a spinner.
      skipLoadingOnReload: true,
      loading: () => _Carga(onVolver: onVolver),
      error: (error, _) => _Falla(
        error: error,
        onVolver: onVolver,
        onReintentar: () => ref.invalidate(pacienteFichaProvider(pacienteId)),
      ),
      data: (data) => MedicacionScreen(
        pacienteNombre: data.paciente.nombreCompleto,
        medicamentos: data.situacion.medicamentos,
        onRegistrar: onRegistrar,
        onAbrir: onAbrir,
        onVolver: onVolver,
      ),
    );
  }
}

/// Editor of one medication, or the registration form when [medicamentoId] is
/// null.
///
/// The medication to edit is looked up in the ficha already loaded. When the
/// id is not there (a stale link, or the medication was just deactivated) the
/// route leaves through [onCerrar] instead of drawing an empty editor.
class MedicamentoFormRoute extends ConsumerWidget {
  const MedicamentoFormRoute({
    required this.pacienteId,
    required this.onCerrar,
    required this.onBaja,
    this.medicamentoId,
    super.key,
  });

  final String pacienteId;
  final String? medicamentoId;

  /// Leaves without writing anything, or after a save.
  final VoidCallback onCerrar;

  /// Runs once the deactivation was accepted.
  final VoidCallback onBaja;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ficha = ref.watch(pacienteFichaProvider(pacienteId));

    return ficha.when(
      skipLoadingOnReload: true,
      loading: () => _Carga(onCerrar: onCerrar),
      error: (error, _) => _Falla(
        error: error,
        onCerrar: onCerrar,
        onReintentar: () => ref.invalidate(pacienteFichaProvider(pacienteId)),
      ),
      data: (data) {
        final id = medicamentoId;
        final medicamento = id == null
            ? null
            : data.situacion.medicamentos.where((m) => m.id == id).firstOrNull;

        if (id != null && medicamento == null) {
          // Not in the ficha: back to the list, once this frame is built.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) onCerrar();
          });
          return const Material(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return MedicamentoFormScreen(
          pacienteId: pacienteId,
          pacienteNombre: data.paciente.nombreCompleto,
          medicamento: medicamento,
          onCerrar: onCerrar,
          onGuardado: (_) => onCerrar(),
          // Only an existing medication can be deactivated.
          onDarDeBaja: medicamento == null
              ? null
              : () async {
                  final hecho = await confirmarBajaMedicamento(
                    context,
                    ref,
                    pacienteId: pacienteId,
                    medicamento: medicamento,
                  );
                  if (hecho && context.mounted) onBaja();
                },
        );
      },
    );
  }
}

class _Carga extends StatelessWidget {
  const _Carga({this.onVolver, this.onCerrar});

  final VoidCallback? onVolver;
  final VoidCallback? onCerrar;

  @override
  Widget build(BuildContext context) {
    return _Salida(
      onVolver: onVolver,
      onCerrar: onCerrar,
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _Falla extends StatelessWidget {
  const _Falla({
    required this.error,
    required this.onReintentar,
    this.onVolver,
    this.onCerrar,
  });

  final Object error;
  final VoidCallback onReintentar;
  final VoidCallback? onVolver;
  final VoidCallback? onCerrar;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final failure = error;
    final detalle = failure is ApiFailure
        ? failure.mensaje
        : 'Revisá tu conexión e intentá de nuevo.';

    return _Salida(
      onVolver: onVolver,
      onCerrar: onCerrar,
      child: ListView(
        padding: AppDimensions.screenPadding,
        children: [
          Text('No pudimos cargar la ficha.', style: textTheme.titleMedium),
          const SizedBox(height: AppDimensions.spaceXs),
          Text(detalle, style: textTheme.bodyMedium),
          const SizedBox(height: AppDimensions.spaceMd),
          AppButton(
            label: 'Reintentar',
            icon: Icons.refresh,
            variant: AppButtonVariant.secondary,
            onPressed: onReintentar,
          ),
        ],
      ),
    );
  }
}

/// A way out while there is no board yet: back arrow for the list, `x` for the
/// form, so the user is never stuck on a spinner or a failure.
class _Salida extends StatelessWidget {
  const _Salida({required this.child, this.onVolver, this.onCerrar});

  final Widget child;
  final VoidCallback? onVolver;
  final VoidCallback? onCerrar;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: onVolver != null
                  ? IconButton(
                      tooltip: 'Volver a la ficha',
                      onPressed: onVolver,
                      icon: const Icon(Icons.arrow_back),
                    )
                  : IconButton(
                      tooltip: 'Cerrar sin guardar',
                      onPressed: onCerrar,
                      icon: const Icon(Icons.close),
                    ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
