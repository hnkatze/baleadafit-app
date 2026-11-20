import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../data/medicamento.dart';
import '../../data/patients_providers.dart';

const _nombreMin = 2;
const _nombreMax = 120;
const _dosisMax = 80;
const _frecuenciaMax = 120;

const _notaOpcionales =
    'Vaciado, el campo conserva lo que ya estaba: para borrar la dosis o la '
    'frecuencia usá la x del campo.';

const _textoBaja =
    'Se conserva en el historial clínico, pero sale de la lista.';

const _campos = ['nombre', 'dosis', 'frecuencia'];

/// Board shared by registering (`medicamento == null`) and editing a
/// medication. It only draws and submits: closing, the post-save navigation and
/// the deactivation flow belong to whoever places it.
class MedicamentoFormScreen extends ConsumerStatefulWidget {
  const MedicamentoFormScreen({
    required this.pacienteId,
    required this.pacienteNombre,
    required this.onCerrar,
    required this.onGuardado,
    this.medicamento,
    this.onDarDeBaja,
    super.key,
  });

  final String pacienteId;
  final String pacienteNombre;

  /// Null registers a new medication; otherwise it is edited.
  final Medicamento? medicamento;

  /// The `x` in the corner: there is no cancel button.
  final VoidCallback onCerrar;

  /// Called with the entity the API answered, after the ficha was invalidated.
  final void Function(Medicamento medicamento) onGuardado;

  /// Taps on `Dar de baja`. Confirmation and the call itself live elsewhere.
  final VoidCallback? onDarDeBaja;

  @override
  ConsumerState<MedicamentoFormScreen> createState() =>
      _MedicamentoFormScreenState();
}

class _MedicamentoFormScreenState extends ConsumerState<MedicamentoFormScreen> {
  late final _nombre = TextEditingController(text: widget.medicamento?.nombre);
  late final _dosis = TextEditingController(text: widget.medicamento?.dosis);
  late final _frecuencia = TextEditingController(
    text: widget.medicamento?.frecuencia,
  );

  // Set by the field's `x`: the PATCH sends null instead of resending the value.
  bool _limpiarDosis = false;
  bool _limpiarFrecuencia = false;

  Map<String, String> _errores = {};
  ApiFailure? _falla;
  bool _enviando = false;

  bool get _edicion => widget.medicamento != null;

  @override
  void initState() {
    super.initState();
    // Typing after the x means the user no longer wants the stored value gone.
    _dosis.addListener(() => _olvidarLimpieza(dosis: true));
    _frecuencia.addListener(() => _olvidarLimpieza(dosis: false));
  }

  @override
  void dispose() {
    _nombre.dispose();
    _dosis.dispose();
    _frecuencia.dispose();
    super.dispose();
  }

  /// The text to send for an optional field. A field emptied by hand resends
  /// what was stored (S8); only the `x` clears, through the `limpiar*` flags.
  String? _opcional(TextEditingController controller, String? guardado) {
    final texto = controller.text.trim();
    if (texto.isNotEmpty) return texto;
    return _edicion ? guardado : null;
  }

  /// The `x` of a field: empties it and marks it to be cleared on save. Text
  /// typed afterwards wins over the mark (see `_guardar`).
  void _limpiar(TextEditingController controller, {required bool dosis}) {
    controller.clear();
    setState(() {
      if (dosis) {
        _limpiarDosis = true;
      } else {
        _limpiarFrecuencia = true;
      }
    });
  }

  /// Forgets a pending clear as soon as the user types again: emptying the field
  /// by hand means "keep what was stored" (S8), not "delete it".
  void _olvidarLimpieza({required bool dosis}) {
    if (dosis ? !_limpiarDosis : !_limpiarFrecuencia) return;
    setState(() {
      if (dosis) {
        _limpiarDosis = false;
      } else {
        _limpiarFrecuencia = false;
      }
    });
  }

  /// `campo` of a `detalles` entry when it names one of this form's fields.
  static (String, String?)? _detalleDeCampo(Object? detalle) {
    if (detalle is Map) {
      final campo = detalle['campo'];
      final mensaje = detalle['mensaje'];
      if (campo is String && _campos.contains(campo)) {
        return (campo, mensaje is String ? mensaje : null);
      }
    }
    return null;
  }

  Future<void> _guardar() async {
    FocusScope.of(context).unfocus();
    final nombre = _nombre.text.trim();
    if (nombre.length < _nombreMin || nombre.length > _nombreMax) {
      setState(() {
        _errores = {
          'nombre': 'Ingresá entre $_nombreMin y $_nombreMax caracteres',
        };
        _falla = null;
      });
      return;
    }

    setState(() {
      _errores = {};
      _falla = null;
      _enviando = true;
    });

    final limpiarDosis = _limpiarDosis && _dosis.text.trim().isEmpty;    final limpiarFrecuencia =
        _limpiarFrecuencia && _frecuencia.text.trim().isEmpty;
    final dosis = limpiarDosis
        ? null
        : _opcional(_dosis, widget.medicamento?.dosis);
    final frecuencia = limpiarFrecuencia
        ? null
        : _opcional(_frecuencia, widget.medicamento?.frecuencia);
    final repositorio = ref.read(patientsRepositoryProvider);

    final Medicamento guardado;
    DuplicadoMedicamento? duplicado;
    try {
      final actual = widget.medicamento;
      if (actual == null) {
        final creado = await repositorio.registrarMedicamento(
          widget.pacienteId,
          nombre: nombre,
          dosis: dosis,
          frecuencia: frecuencia,
        );
        guardado = creado.medicamento;
        duplicado = creado.duplicadoDe;
      } else {
        guardado = await repositorio.actualizarMedicamento(
          actual.id,
          nombre: nombre,
          dosis: dosis,
          frecuencia: frecuencia,
          limpiarDosis: limpiarDosis,
          limpiarFrecuencia: limpiarFrecuencia,
        );
      }
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      _mostrarFalla(failure);
      return;
    } on Object {
      if (!mounted) return;
      _mostrarFalla(
        const ApiFailure(mensaje: 'Algo salió mal. Intentá de nuevo.'),
      );
      return;
    }

    if (!mounted) return;
    // The list and the expediente read the same ficha: reload it, no local copy.
    ref.invalidate(pacienteFichaProvider(widget.pacienteId));
    setState(() => _enviando = false);
    // The warning goes out BEFORE onGuardado: the caller closes the form, and a
    // snackbar on the app-level messenger outlives it, so the user still sees it.
    if (duplicado != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ya hay un medicamento vigente con ese nombre: '
            '${duplicado.nombre}. Se guardó igual.',
          ),
        ),
      );
    }
    widget.onGuardado(guardado);
  }

  void _mostrarFalla(ApiFailure failure) {
    final errores = <String, String>{};
    if (failure.statusCode == 400) {
      for (final detalle in failure.detalles ?? const <Object?>[]) {
        final campo = _detalleDeCampo(detalle);
        if (campo != null) {
          errores.putIfAbsent(campo.$1, () => campo.$2 ?? failure.mensaje);
        }
      }
    }
    setState(() {
      _errores = errores;
      // Without a field to blame, the message goes to the block above the action.
      _falla = errores.isEmpty ? failure : null;
      _enviando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Cabecera(
              titulo: _edicion ? 'Editar medicamento' : 'Registrar medicamento',
              paciente: widget.pacienteNombre,
              onCerrar: widget.onCerrar,
            ),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.spaceMd,
                  20,
                  AppDimensions.spaceMd,
                  AppDimensions.spaceLg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Campo(
                      etiqueta: 'Nombre',
                      clave: 'nombre',
                      controller: _nombre,
                      maximo: _nombreMax,
                      error: _errores['nombre'],
                      capitalizacion: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: AppDimensions.spaceMd),
                    _Campo(
                      etiqueta: 'Dosis · opcional',
                      clave: 'dosis',
                      controller: _dosis,
                      maximo: _dosisMax,
                      hint: '500 mg',
                      ayuda: 'ej. 500 mg',
                      error: _errores['dosis'],
                      onLimpiar: _edicion
                          ? () => _limpiar(_dosis, dosis: true)
                          : null,
                    ),
                    const SizedBox(height: AppDimensions.spaceMd),
                    _Campo(
                      etiqueta: 'Frecuencia · opcional',
                      clave: 'frecuencia',
                      controller: _frecuencia,
                      maximo: _frecuenciaMax,
                      hint: 'Cada 12 horas con comida',
                      ayuda: 'ej. Cada 12 horas con comida',
                      error: _errores['frecuencia'],
                      onLimpiar: _edicion
                          ? () => _limpiar(_frecuencia, dosis: false)
                          : null,
                    ),
                    if (_edicion) ...[
                      const SizedBox(height: AppDimensions.spaceMd),
                      const _Nota(texto: _notaOpcionales),
                      const SizedBox(height: AppDimensions.spaceLg),
                      _DarDeBaja(onPressed: widget.onDarDeBaja),
                    ],
                  ],
                ),
              ),
            ),
            _Accion(falla: _falla, enviando: _enviando, onGuardar: _guardar),
          ],
        ),
      ),
    );
  }
}

class _Cabecera extends StatelessWidget {
  const _Cabecera({
    required this.titulo,
    required this.paciente,
    required this.onCerrar,
  });

  final String titulo;
  final String paciente;
  final VoidCallback onCerrar;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceXs),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Cerrar sin guardar',
            icon: const Icon(Icons.close, size: AppDimensions.iconMd),
            onPressed: onCerrar,
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: textTheme.titleLarge),
                if (paciente.isNotEmpty)
                  Text(
                    paciente,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Campo extends StatelessWidget {
  const _Campo({
    required this.etiqueta,
    required this.clave,
    required this.controller,
    required this.maximo,
    this.hint,
    this.ayuda,
    this.error,
    this.onLimpiar,
    this.capitalizacion = TextCapitalization.none,
  });

  final String etiqueta;
  final String clave;
  final TextEditingController controller;
  final int maximo;
  final String? hint;
  final String? ayuda;
  final String? error;

  /// Edition only: draws the `x` suffix while the field has text.
  final VoidCallback? onLimpiar;
  final TextCapitalization capitalizacion;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 6),
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) => TextField(
            key: ValueKey(clave),
            controller: controller,
            maxLength: maximo,
            textCapitalization: capitalizacion,
            decoration: InputDecoration(
              hintText: hint,
              helperText: ayuda,
              errorText: error,
              suffixIcon: onLimpiar != null && controller.text.isNotEmpty
                  ? IconButton(
                      tooltip:
                          'Borrar ${etiqueta.split(' ').first.toLowerCase()}',
                      icon: const Icon(Icons.close),
                      onPressed: onLimpiar,
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _Nota extends StatelessWidget {
  const _Nota({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceMd),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 20, color: colors.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              texto,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

/// Destructive section of the editor. It only delegates the tap: the
/// confirmation dialog and the `DELETE` are not this screen's job.
class _DarDeBaja extends StatelessWidget {
  const _DarDeBaja({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceMd),
      decoration: BoxDecoration(
        border: Border.all(color: colors.errorContainer),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DAR DE BAJA',
            style: textTheme.labelMedium?.copyWith(
              color: colors.onErrorContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          Text(
            _textoBaja,
            style: textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          OutlinedButton.icon(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.error,
              minimumSize: const Size(0, 40),
              side: BorderSide(color: colors.error, width: 1.6),
            ),
            icon: const Icon(Icons.medication_liquid_outlined, size: 18),
            label: const Text('Dar de baja'),
          ),
        ],
      ),
    );
  }
}

/// Fixed bottom bar: the failure of the last attempt and `Guardar cambios`.
class _Accion extends StatelessWidget {
  const _Accion({
    required this.falla,
    required this.enviando,
    required this.onGuardar,
  });

  final ApiFailure? falla;
  final bool enviando;
  final VoidCallback onGuardar;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final falla = this.falla;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.spaceMd,
        12,
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.errorContainer,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: AppDimensions.iconSm,
                        color: colors.onErrorContainer,
                      ),
                      const SizedBox(width: AppDimensions.spaceSm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              falla.mensaje,
                              style: textTheme.bodySmall?.copyWith(
                                color: colors.onErrorContainer,
                              ),
                            ),
                            if (falla.codigo != null ||
                                falla.statusCode != null)
                              Text(
                                [
                                  if (falla.codigo != null) falla.codigo!,
                                  if (falla.statusCode != null)
                                    'HTTP ${falla.statusCode}',
                                ].join(' · '),
                                key: const Key('fallo-codigo'),
                                style: textTheme.labelSmall?.copyWith(
                                  color: colors.onErrorContainer,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            AppButton(
              label: 'Guardar cambios',
              isLoading: enviando,
              onPressed: onGuardar,
            ),
          ],
        ),
      ),
    );
  }
}
