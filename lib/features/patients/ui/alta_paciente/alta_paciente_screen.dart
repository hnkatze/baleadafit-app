import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../data/paciente_ficha.dart';
import '../../data/patients_providers.dart';
import 'alta_paciente_borrador.dart';
import 'paso_clinica.dart';
import 'paso_habitos.dart';
import 'paso_identidad.dart';
import 'paso_objetivo.dart';

/// The new-patient wizard: identity, goal, clinical picture and habits, then
/// `POST /pacientes`.
///
/// Steps 1 and 2 follow `MpAltaIdentidad.html` and `MpAltaObjetivo.html`;
/// steps 3 and 4 have no artboard and extend their language. Each step checks
/// its own required fields before the next one opens, so nothing reaches the
/// API half-filled.
///
/// [AltaPacienteScreen.editar] reuses the same four steps to edit an existing
/// patient: the draft is prefilled from their ficha and the last step saves
/// with `PATCH /pacientes/{id}`.
class AltaPacienteScreen extends ConsumerStatefulWidget {
  const AltaPacienteScreen({
    required this.onCerrar,
    required this.onCreado,
    super.key,
  }) : pacienteId = null,
       ficha = null;

  /// The edit form of the patient [pacienteId], prefilled from [ficha].
  /// [onGuardado] runs once the API accepted the changes and the ficha and
  /// the directory were marked for a new read.
  AltaPacienteScreen.editar({
    required String this.pacienteId,
    required PacienteFicha this.ficha,
    required this.onCerrar,
    required VoidCallback onGuardado,
    super.key,
  }) : onCreado = ((_) => onGuardado());

  /// Set only when editing.
  final String? pacienteId;
  final PacienteFicha? ficha;

  /// Leaves the wizard without saving.
  final VoidCallback onCerrar;

  /// Called with the id of the patient the API created (or saved, when
  /// editing), after the directory was refreshed. The router decides where
  /// that leads.
  final ValueChanged<String> onCreado;

  @override
  ConsumerState<AltaPacienteScreen> createState() => _AltaPacienteScreenState();
}

class _AltaPacienteScreenState extends ConsumerState<AltaPacienteScreen> {
  late final _borrador = widget.ficha == null
      ? AltaPacienteBorrador()
      : AltaPacienteBorrador.desdeFicha(widget.ficha!);
  int _paso = 0;
  Map<String, String> _errores = {};
  String? _falla;
  bool _enviando = false;

  bool get _editando => widget.ficha != null;

  bool get _esUltimo => _paso == pasosAlta.length - 1;

  @override
  void dispose() {
    _borrador.dispose();
    super.dispose();
  }

  /// A field the nutritionist is fixing loses its error right away; a choice
  /// (no key) only redraws.
  void _cambio([String? clave]) {
    setState(() {
      if (clave != null) _errores = {..._errores}..remove(clave);
    });
  }

  void _atras() {
    if (_enviando) return;
    if (_paso == 0) {
      widget.onCerrar();
      return;
    }
    setState(() {
      _paso -= 1;
      _errores = {};
      _falla = null;
    });
  }

  Future<void> _adelante() async {
    FocusScope.of(context).unfocus();
    final errores = _borrador.validar(_paso);
    if (errores.isNotEmpty) {
      setState(() {
        _errores = errores;
        _falla = null;
      });
      return;
    }
    if (!_esUltimo) {
      setState(() {
        _paso += 1;
        _errores = {};
        _falla = null;
      });
      return;
    }
    await _enviar();
  }

  Future<void> _enviar() async {
    setState(() {
      _errores = {};
      _falla = null;
      _enviando = true;
    });
    final String id;
    try {
      final repositorio = ref.read(patientsRepositoryProvider);
      if (_editando) {
        id = widget.pacienteId!;
        await repositorio.actualizarPaciente(id, body: _borrador.cuerpo());
      } else {
        id = await repositorio.crearPaciente(_borrador.cuerpo());
      }
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _falla = failure.mensaje;
        _enviando = false;
      });
      return;
    } on Object {
      if (!mounted) return;
      setState(() {
        _falla = 'Algo salió mal. Intentá de nuevo.';
        _enviando = false;
      });
      return;
    }

    if (!mounted) return;
    // The directory and the home list were read before this patient existed
    // (or changed); the ficha too, since it shows the edited data.
    if (_editando) ref.invalidate(pacienteFichaProvider(id));
    ref.invalidate(pacientesDirectorioProvider);
    ref.invalidate(pacientesRecientesProvider);
    widget.onCreado(id);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    // Watched here, not in step 3, so both catalogues load once for the whole
    // wizard and survive going back and forth.
    final condiciones = ref.watch(condicionesProvider);
    final restricciones = ref.watch(restriccionesProvider);

    return PopScope(
      // The system back walks the steps back like the arrow does; only the
      // first step leaves.
      canPop: _paso == 0 && !_enviando,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _atras();
      },
      child: Scaffold(
        backgroundColor: colors.surface,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _Cabecera(
                titulo: _editando ? 'Editar paciente' : 'Nuevo paciente',
                primerPaso: _paso == 0,
                onPressed: _atras,
              ),
              Expanded(
                child: SingleChildScrollView(
                  // Keyed by step so each one opens at the top.
                  key: ValueKey('paso-$_paso'),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(
                    AppDimensions.spaceMd,
                    AppDimensions.spaceLg,
                    AppDimensions.spaceMd,
                    AppDimensions.spaceLg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'PASO ${_paso + 1} DE ${pasosAlta.length}',
                        style: textTheme.labelSmall?.copyWith(
                          color: colors.primary,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spaceXs),
                      Text(pasosAlta[_paso], style: textTheme.headlineMedium),
                      const SizedBox(height: AppDimensions.spaceSm + 4),
                      _Progreso(paso: _paso),
                      const SizedBox(height: AppDimensions.spaceLg),
                      switch (_paso) {
                        0 => PasoIdentidad(
                          borrador: _borrador,
                          errores: _errores,
                          onCambio: _cambio,
                        ),
                        1 => PasoObjetivo(
                          borrador: _borrador,
                          errores: _errores,
                          onCambio: _cambio,
                        ),
                        2 => PasoClinica(
                          borrador: _borrador,
                          condiciones: condiciones,
                          restricciones: restricciones,
                          onReintentarCondiciones: () =>
                              ref.invalidate(condicionesProvider),
                          onReintentarRestricciones: () =>
                              ref.invalidate(restriccionesProvider),
                          onCambio: _cambio,
                        ),
                        _ => PasoHabitos(
                          borrador: _borrador,
                          errores: _errores,
                          onCambio: _cambio,
                        ),
                      },
                    ],
                  ),
                ),
              ),
              _Accion(
                falla: _falla,
                enviando: _enviando,
                ultimo: _esUltimo,
                etiquetaFinal: _editando ? 'Guardar cambios' : 'Crear paciente',
                onPressed: _adelante,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `Nuevo paciente` (or `Editar paciente`) with `x` on the first step (nothing
/// to go back to) and an arrow on the others.
class _Cabecera extends StatelessWidget {
  const _Cabecera({
    required this.titulo,
    required this.primerPaso,
    required this.onPressed,
  });

  final String titulo;
  final bool primerPaso;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceXs),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: primerPaso
                ? 'Cerrar sin guardar'
                : 'Volver al paso anterior',
            icon: Icon(
              primerPaso ? Icons.close : Icons.arrow_back,
              size: AppDimensions.iconMd,
            ),
            onPressed: onPressed,
          ),
          Expanded(
            child: Text(titulo, style: Theme.of(context).textTheme.titleLarge),
          ),
        ],
      ),
    );
  }
}

/// Four bars, filled up to the current step, with the step names under them.
class _Progreso extends StatelessWidget {
  const _Progreso({required this.paso});

  final int paso;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      label: 'Paso ${paso + 1} de ${pasosAlta.length}',
      excludeSemantics: true,
      child: Column(
        children: [
          Row(
            children: [
              for (final (i, _) in pasosAlta.indexed) ...[
                if (i > 0) const SizedBox(width: AppDimensions.spaceXs),
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: i <= paso
                          ? colors.primary
                          : colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (final (i, nombre) in pasosAlta.indexed) ...[
                if (i > 0) const SizedBox(width: AppDimensions.spaceXs),
                Expanded(
                  child: Text(
                    nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelSmall?.copyWith(
                      letterSpacing: 0,
                      fontWeight: FontWeight.w600,
                      color: i == paso
                          ? colors.primary
                          : colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// The fixed bottom action, with the API refusal right above it so it stays in
/// view whatever the scroll position.
class _Accion extends StatelessWidget {
  const _Accion({
    required this.falla,
    required this.enviando,
    required this.ultimo,
    required this.etiquetaFinal,
    required this.onPressed,
  });

  final String? falla;
  final bool enviando;
  final bool ultimo;
  final String etiquetaFinal;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.spaceMd,
        AppDimensions.spaceSm + 4,
        AppDimensions.spaceMd,
        AppDimensions.spaceMd,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (falla != null) ...[
              Semantics(
                liveRegion: true,
                child: Container(
                  padding: const EdgeInsets.all(AppDimensions.spaceSm + 4),
                  decoration: BoxDecoration(
                    color: colors.errorContainer,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: AppDimensions.iconSm,
                        color: colors.onErrorContainer,
                      ),
                      const SizedBox(width: AppDimensions.spaceSm),
                      Expanded(
                        child: Text(
                          falla!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.onErrorContainer),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.spaceSm + 4),
            ],
            AppButton(
              label: ultimo ? etiquetaFinal : 'Siguiente',
              icon: ultimo ? Icons.check : Icons.arrow_forward,
              isLoading: enviando,
              onPressed: onPressed,
            ),
          ],
        ),
      ),
    );
  }
}
