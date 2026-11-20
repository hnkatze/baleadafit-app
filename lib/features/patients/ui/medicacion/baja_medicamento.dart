import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_failure.dart';
import '../../data/medicamento.dart';
import '../../data/patients_providers.dart';

/// Asks for confirmation and deactivates [medicamento] (S9).
///
/// Returns true only when the API accepted the deactivation, so the caller can
/// leave the editor. Closing the dialog or a refusal returns false and leaves
/// everything as it was; a refusal also says why in a snack bar.
Future<bool> confirmarBajaMedicamento(
  BuildContext context,
  WidgetRef ref, {
  required String pacienteId,
  required Medicamento medicamento,
}) async {
  // Captured before any await: the editor may be gone when the API answers.
  final messenger = ScaffoldMessenger.maybeOf(context);
  final confirmo = await showDialog<bool>(
    context: context,
    builder: (_) => _ConfirmarBaja(nombre: medicamento.nombre),
  );
  if (confirmo != true) return false;

  try {
    await ref
        .read(patientsRepositoryProvider)
        .darDeBajaMedicamento(medicamento.id);
  } on ApiFailure catch (failure) {
    messenger?.showSnackBar(SnackBar(content: Text(failure.mensaje)));
    return false;
  }

  // The list and the expediente read the same ficha: reload it, no local copy.
  ref.invalidate(pacienteFichaProvider(pacienteId));
  return true;
}

class _ConfirmarBaja extends StatelessWidget {
  const _ConfirmarBaja({required this.nombre});

  final String nombre;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return AlertDialog(
      icon: CircleAvatar(
        backgroundColor: colors.errorContainer,
        foregroundColor: colors.onErrorContainer,
        child: const Icon(Icons.medication_liquid_outlined),
      ),
      // The way out is the red cross in the corner, and only that: a second
      // Cancel button beside the destructive action invites the wrong tap.
      title: Row(
        children: [
          Expanded(child: Text('¿Dar de baja $nombre?')),
          IconButton(
            key: const Key('cerrar-dialogo'),
            tooltip: 'Cancelar',
            onPressed: () => Navigator.pop(context, false),
            icon: Icon(Icons.close, size: 28, color: colors.error),
          ),
        ],
      ),
      content: Text(
        'Se conserva en el historial clínico, pero sale de la lista.',
        style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
      ),
      actions: [
        Row(
          children: [
            Expanded(
              // Destructive, so it takes the error role instead of the brand
              // mint the primary variant carries.
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: colors.error,
                  foregroundColor: colors.onError,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Dar de baja'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
