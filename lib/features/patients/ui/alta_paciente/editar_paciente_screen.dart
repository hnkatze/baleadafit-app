import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../data/patients_providers.dart';
import 'alta_paciente_screen.dart';

/// The edit form of one patient, opened from a route.
///
/// It takes the ficha from [pacienteFichaProvider], which the file underneath
/// already loaded, so from the menu it opens at once; a deep link waits for
/// the same read.
class EditarPacienteScreen extends ConsumerWidget {
  const EditarPacienteScreen({
    required this.pacienteId,
    required this.onCerrar,
    required this.onGuardado,
    super.key,
  });

  final String pacienteId;
  final VoidCallback onCerrar;
  final VoidCallback onGuardado;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ficha = ref.watch(pacienteFichaProvider(pacienteId));
    // `value` rather than `when`: saving invalidates the ficha, and the
    // reload must not swap the form for a spinner while it closes.
    final datos = ficha.value;
    if (datos != null) {
      return AltaPacienteScreen.editar(
        pacienteId: pacienteId,
        ficha: datos,
        onCerrar: onCerrar,
        onGuardado: onGuardado,
      );
    }

    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Cerrar sin guardar',
          icon: const Icon(Icons.close),
          onPressed: onCerrar,
        ),
        title: const Text('Editar paciente'),
      ),
      body: ficha.hasError
          ? Padding(
              padding: AppDimensions.screenPadding,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    ficha.error is ApiFailure
                        ? (ficha.error! as ApiFailure).mensaje
                        : 'No pudimos cargar la ficha.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimensions.spaceMd),
                  AppButton(
                    label: 'Reintentar',
                    onPressed: () =>
                        ref.invalidate(pacienteFichaProvider(pacienteId)),
                  ),
                ],
              ),
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
