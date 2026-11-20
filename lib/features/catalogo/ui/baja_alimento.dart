import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_failure.dart';
import '../data/alimento.dart';
import '../data/catalogo_providers.dart';

/// Asks to take a food out of the catalogue and, once confirmed, deactivates it
/// (`PATCH /alimentos/{id}` with `activo: false`).
///
/// Answers `true` only when the API accepted the deactivation. A failure shows
/// the message of the API in a [SnackBar] and answers `false`. It never
/// navigates: leaving the detail is up to the caller.
Future<bool> confirmarBajaAlimento(
  BuildContext context,
  WidgetRef ref, {
  required Alimento alimento,
}) async {
  final confirmo = await showDialog<bool>(
    context: context,
    // The way out is the red cross, and only that.
    barrierDismissible: false,
    builder: (_) => _ConfirmarBaja(nombre: alimento.nombre),
  );
  if (confirmo != true || !context.mounted) return false;

  // Captured before the await: the detail may be gone by the time it answers.
  final messenger = ScaffoldMessenger.of(context);
  try {
    await ref.read(catalogoRepositoryProvider).darDeBaja(alimento.id);
  } on ApiFailure catch (failure) {
    messenger.showSnackBar(SnackBar(content: Text(failure.mensaje)));
    return false;
  } on Object {
    messenger.showSnackBar(
      const SnackBar(
        content: Text('No pudimos dar de baja el alimento. Probá de nuevo.'),
      ),
    );
    return false;
  }
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
      scrollable: true,
      // No Cancel button beside the destructive action: it invites the wrong tap.
      title: Row(
        children: [
          Expanded(child: Text('¿Dar de baja “$nombre”?')),
          IconButton(
            key: const Key('cerrar-dialogo'),
            tooltip: 'Cancelar',
            onPressed: () => Navigator.pop(context, false),
            icon: Icon(Icons.close, size: 28, color: colors.error),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final punto in _puntos) _Punto(texto: punto),
          const SizedBox(height: 8),
          Text(
            _advertencia,
            style: textTheme.bodySmall?.copyWith(color: colors.error),
          ),
        ],
      ),
      actions: [
        Row(
          children: [
            Expanded(
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

const _puntos = [
  'Es una baja lógica: el alimento no se borra.',
  'Deja de aparecer en el catálogo y en las búsquedas para armar planes.',
  'Se conservan sus datos y su historial de versiones.',
];

const _advertencia =
    'El catálogo no lista alimentos inactivos, así que después no vas a '
    'encontrarlo desde la búsqueda para reactivarlo.';

class _Punto extends StatelessWidget {
  const _Punto({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check, size: 18, color: colors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
