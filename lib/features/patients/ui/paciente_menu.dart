import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_failure.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../shared/widgets/app_button.dart';
import '../data/patients_providers.dart';

/// What the overflow menu of the ficha can ask for.
enum _Accion { editar, medicamentos, darDeBaja }

/// Opens the overflow menu of the ficha: edit, medication and the deactivation.
///
/// [onEditarDatos] and [onMedicamentos] are null until those destinations
/// exist; their entries are drawn but only close the menu. [onDadoDeBaja]
/// runs once the API accepted the deactivation, and is where the host leaves
/// the ficha.
Future<void> mostrarMenuPaciente(
  BuildContext context,
  WidgetRef ref, {
  required String pacienteId,
  required VoidCallback onDadoDeBaja,
  VoidCallback? onEditarDatos,
  VoidCallback? onMedicamentos,
}) async {
  // The dialog names the patient, so the destructive entry waits for the ficha.
  final nombre = ref
      .read(pacienteFichaProvider(pacienteId))
      .value
      ?.paciente
      .nombreCompleto;

  final accion = await showModalBottomSheet<_Accion>(
    context: context,
    showDragHandle: true,
    builder: (_) => _Menu(puedeDarDeBaja: nombre != null),
  );
  if (accion == null || !context.mounted) return;

  switch (accion) {
    case _Accion.editar:
      onEditarDatos?.call();
    case _Accion.medicamentos:
      onMedicamentos?.call();
    case _Accion.darDeBaja:
      await _confirmarBaja(
        context,
        ref,
        pacienteId: pacienteId,
        nombre: nombre!,
        onDadoDeBaja: onDadoDeBaja,
      );
  }
}

Future<void> _confirmarBaja(
  BuildContext context,
  WidgetRef ref, {
  required String pacienteId,
  required String nombre,
  required VoidCallback onDadoDeBaja,
}) async {
  final confirmo = await showDialog<bool>(
    context: context,
    builder: (_) => _ConfirmarBaja(nombre: nombre),
  );
  if (confirmo != true || !context.mounted) return;

  // Captured before the await: the ficha may be gone by the time it answers.
  final messenger = ScaffoldMessenger.of(context);
  try {
    await ref.read(patientsRepositoryProvider).darDeBaja(pacienteId);
  } on ApiFailure catch (failure) {
    messenger.showSnackBar(SnackBar(content: Text(failure.mensaje)));
    return;
  }

  // The directory lists inactive patients under their own filter, and the
  // ficha now reads as inactive, so both must be read again.
  ref.invalidate(pacienteFichaProvider(pacienteId));
  ref.invalidate(pacientesDirectorioProvider);
  onDadoDeBaja();
}

class _Menu extends StatelessWidget {
  const _Menu({required this.puedeDarDeBaja});

  final bool puedeDarDeBaja;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Entrada(
            icono: Icons.edit_outlined,
            texto: 'Editar datos',
            onTap: () => Navigator.pop(context, _Accion.editar),
          ),
          _Entrada(
            icono: Icons.medication_outlined,
            texto: 'Medicamentos',
            onTap: () => Navigator.pop(context, _Accion.medicamentos),
          ),
          Divider(color: colors.surfaceContainer),
          _Entrada(
            icono: Icons.person_off_outlined,
            texto: 'Dar de baja',
            color: colors.error,
            onTap: puedeDarDeBaja
                ? () => Navigator.pop(context, _Accion.darDeBaja)
                : null,
          ),
        ],
      ),
    );
  }
}

class _Entrada extends StatelessWidget {
  const _Entrada({
    required this.icono,
    required this.texto,
    required this.onTap,
    this.color,
  });

  final IconData icono;
  final String texto;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ListTile(
      minTileHeight: 52,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceMd,
      ),
      leading: Icon(icono, color: color ?? colors.onSurfaceVariant),
      title: Text(
        texto,
        style: Theme.of(context).textTheme.labelLarge
            ?.copyWith(color: color ?? colors.onSurface),
      ),
      enabled: onTap != null,
      onTap: onTap,
    );
  }
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
        child: const Icon(Icons.person_off_outlined),
      ),
      title: Text('¿Dar de baja a $nombre?'),
      content: Text(
        'Deja de aparecer en tus pacientes activos. Su ficha, mediciones y '
        'planes se conservan, y lo encontrás en el filtro «Dados de baja».',
        style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Cancelar',
                variant: AppButtonVariant.secondary,
                onPressed: () => Navigator.pop(context, false),
              ),
            ),
            const SizedBox(width: AppDimensions.spaceXs),
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
