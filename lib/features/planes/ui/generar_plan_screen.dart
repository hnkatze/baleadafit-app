import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/fechas.dart';
import '../../../core/network/api_failure.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../patients/data/patients_providers.dart';
import '../data/plan.dart';
import '../data/planes_formato.dart';
import '../data/planes_providers.dart';
import '../data/planes_repository.dart';

/// Defaults of the contract for the meal times: 25 / 10 / 35 / 10 / 20, as
/// **fractions**. The macro defaults live in [_macros].
const _tiemposPorDefecto = <TipoComida, double>{
  TipoComida.desayuno: 0.25,
  TipoComida.meriendaAm: 0.1,
  TipoComida.almuerzo: 0.35,
  TipoComida.meriendaPm: 0.1,
  TipoComida.cena: 0.2,
};

/// The default name of a plan: the patient and the moment it was asked for, so
/// two plans of the same patient never read the same.
/// `María Isabel Hernández Paz_2026-11-16_14:35`.
///
/// The contract caps the name at 120 characters. The patient gives up the room,
/// never the timestamp: the moment is what makes the name unique.
String nombrePorDefecto(String? paciente, DateTime ahora) {
  final momento =
      '${fechaIso(ahora)}_${_dos(ahora.hour)}:${_dos(ahora.minute)}';
  final nombre = paciente?.trim() ?? '';
  if (nombre.isEmpty) return 'Plan $momento';

  final espacio = 120 - momento.length - 1;
  final recortado = nombre.length <= espacio
      ? nombre
      : nombre.substring(0, espacio).trimRight();

  return '${recortado}_$momento';
}

String _dos(int valor) => valor.toString().padLeft(2, '0');

/// A macro of the form: its label, the contract range in **percent** and the
/// default fraction.
class _Macro {
  const _Macro(this.clave, this.etiqueta, this.min, this.max, this.defecto);

  final String clave;
  final String etiqueta;
  final double min;
  final double max;
  final double defecto;
}

const _macros = [
  _Macro('proteina', 'Proteína', 10, 50, 0.25),
  _Macro('carbohidrato', 'Carbohidrato', 20, 70, 0.5),
  _Macro('grasa', 'Grasa', 10, 50, 0.25),
];

/// Generates a plan (`POST /pacientes/{id}/planes/generar`) and hands the id of
/// the draft it created to [onGenerado].
///
/// The screen owns the percentage ↔ fraction conversion: the form shows and
/// reads `35%`, the body carries `0.35`. It does not check for a measurement
/// beforehand (the contract declares no code for its absence), so a failure
/// shows the API message, keeps everything typed and offers the way back.
///
/// While the request runs (up to 25 s with the AI) the button keeps its loading
/// state and the whole form is read only. There is no cancellation.
class GenerarPlanScreen extends ConsumerStatefulWidget {
  const GenerarPlanScreen({
    required this.pacienteId,
    required this.onCerrar,
    required this.onGenerado,
    super.key,
  });

  final String pacienteId;

  /// Closes the form without generating.
  final VoidCallback onCerrar;

  /// Called with the id of the plan the API created (201).
  final ValueChanged<String> onGenerado;

  @override
  ConsumerState<GenerarPlanScreen> createState() => _GenerarPlanScreenState();
}

class _GenerarPlanScreenState extends ConsumerState<GenerarPlanScreen> {
  /// The moment the form was opened, so the suggested name does not change
  /// while the screen lives.
  late final DateTime _momento = DateTime.now();

  late final TextEditingController _nombre;

  /// The name this screen wrote, to tell an untouched field from one the
  /// nutritionist typed over.
  late String _sugerido;
  bool _editado = false;

  final _kcal = TextEditingController();
  final _indicaciones = TextEditingController();
  late final Map<String, TextEditingController> _macroCampos = {
    for (final macro in _macros)
      macro.clave: TextEditingController(
        text: formatearFraccion(macro.defecto),
      ),
  };
  late final Map<TipoComida, TextEditingController> _tiempoCampos = {
    for (final tipo in TipoComida.values)
      tipo: TextEditingController(
        text: formatearFraccion(_tiemposPorDefecto[tipo]!),
      ),
  };

  bool _usarIa = true;
  bool _enviando = false;

  /// Local range errors, by field key.
  Map<String, String> _errores = const {};

  /// What the API answered when the generation failed.
  ApiFailure? _fallo;

  @override
  void initState() {
    super.initState();
    // The ficha is usually already in cache: the flow comes from the patient
    // file. If it is not, [build] fills the name when it arrives.
    final paciente = ref
        .read(pacienteFichaProvider(widget.pacienteId))
        .asData
        ?.value
        .paciente
        .nombreCompleto;
    _sugerido = nombrePorDefecto(paciente, _momento);
    _nombre = TextEditingController(text: _sugerido);
  }

  @override
  void dispose() {
    _nombre.dispose();
    _kcal.dispose();
    _indicaciones.dispose();
    for (final campo in _macroCampos.values) {
      campo.dispose();
    }
    for (final campo in _tiempoCampos.values) {
      campo.dispose();
    }
    super.dispose();
  }

  /// Reads `35%`, `35`, `12,5 %` as a percentage; `null` when it is not a
  /// number.
  double? _leerPorcentaje(String texto) => double.tryParse(
    texto.replaceAll('%', '').replaceAll(' ', '').replaceAll(',', '.'),
  );

  /// A percentage as the fraction the body carries (`35` → `0.35`).
  double _aFraccion(double porcentaje) =>
      double.parse((porcentaje / 100).toStringAsFixed(4));

  Future<void> _generar() async {
    final errores = <String, String>{};

    final nombre = _nombre.text.trim();
    if (nombre.length > 120) errores['nombre'] = 'Máximo 120 caracteres.';

    int? kcal;
    final textoKcal = _kcal.text.replaceAll(RegExp(r'[.\s]'), '');
    if (textoKcal.isNotEmpty) {
      kcal = int.tryParse(textoKcal);
      if (kcal == null || kcal < 1000 || kcal > 5000) {
        errores['kcal'] = 'Entre 1.000 y 5.000.';
      }
    }

    final macros = <String, double>{};
    for (final macro in _macros) {
      final valor = _leerPorcentaje(_macroCampos[macro.clave]!.text);
      if (valor == null) {
        errores[macro.clave] = 'Escribí un porcentaje.';
      } else if (valor < macro.min || valor > macro.max) {
        errores[macro.clave] =
            'Entre ${formatearPorcentaje(macro.min)} y '
            '${formatearPorcentaje(macro.max)}.';
      } else {
        macros[macro.clave] = _aFraccion(valor);
      }
    }

    final tiempos = <TipoComida, double>{};
    for (final tipo in TipoComida.values) {
      final valor = _leerPorcentaje(_tiempoCampos[tipo]!.text);
      if (valor == null || valor < 0 || valor > 100) {
        errores[tipo.codigo] = '${tipo.etiqueta}: entre 0% y 100%.';
      } else {
        tiempos[tipo] = _aFraccion(valor);
      }
    }

    final indicaciones = _indicaciones.text.trim();
    if (indicaciones.length > 500) {
      errores['indicaciones'] = 'Máximo 500 caracteres.';
    }

    if (errores.isNotEmpty) {
      setState(() {
        _errores = errores;
        _fallo = null;
      });
      return;
    }

    setState(() {
      _errores = const {};
      _fallo = null;
      _enviando = true;
    });

    final pidioIa = _usarIa;
    try {
      final plan = await ref
          .read(planesRepositoryProvider)
          .generar(
            widget.pacienteId,
            nombre: nombre.isEmpty ? null : nombre,
            kcalObjetivo: kcal,
            usarIa: pidioIa,
            indicaciones: indicaciones,
            distribucionMacros: DistribucionMacros(
              proteina: macros['proteina']!,
              carbohidrato: macros['carbohidrato']!,
              grasa: macros['grasa']!,
            ),
            distribucionTiempos: tiempos,
          );
      if (!mounted) return;
      ref.invalidate(planesDePacienteProvider(widget.pacienteId));

      // The contract documents a fallback to rules, and production returns it
      // today: say so instead of pretending the AI proposed this plan. The
      // messenger belongs to the app, so the notice survives the navigation
      // to the detail, which shows the origin itself.
      if (pidioIa && plan.origen == OrigenPlan.reglas) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pediste IA, pero este plan se generó por reglas.'),
          ),
        );
      }
      widget.onGenerado(plan.id);
    } on ApiFailure catch (fallo) {
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _fallo = fallo;
      });
    } catch (_) {
      // Anything that is not an API failure must still free the form: a stuck
      // spinner leaves no way to retry and no message to report.
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _fallo = const ApiFailure(
          mensaje: 'No pudimos generar el plan. Probá de nuevo.',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final colores = Theme.of(context).colorScheme;
    final paciente = ref
        .watch(pacienteFichaProvider(widget.pacienteId))
        .asData
        ?.value
        .paciente
        .nombreCompleto;

    // The patient can arrive after the first frame. Fill the name once, and stop
    // as soon as the nutritionist types her own.
    if (!_editado && paciente != null && paciente.isNotEmpty) {
      if (_nombre.text != _sugerido) {
        _editado = true;
      } else {
        final sugerido = nombrePorDefecto(paciente, _momento);
        if (sugerido != _sugerido) {
          _nombre.text = sugerido;
          _sugerido = sugerido;
        }
      }
    }
    final editable = !_enviando;

    return PopScope(
      canPop: editable,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Cerrar sin generar',
            icon: const Icon(Icons.close),
            onPressed: editable ? widget.onCerrar : null,
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Generar plan'),
              if (paciente != null && paciente.isNotEmpty)
                Text(
                  paciente,
                  style: texto.labelSmall?.copyWith(
                    color: colores.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: AppDimensions.screenPadding,
                children: [
                  AppTextField(
                    key: const Key('nombre'),
                    controller: _nombre,
                    label: 'Nombre',
                    enabled: editable,
                    errorText: _errores['nombre'],
                  ),
                  const SizedBox(height: AppDimensions.spaceLg),
                  AppTextField(
                    key: const Key('kcal'),
                    controller: _kcal,
                    label: 'Kcal objetivo · opcional',
                    hint: 'Calculado automáticamente',
                    helperText:
                        '1.000 a 5.000. Si lo dejás vacío, se calcula con '
                        'Mifflin-St Jeor y la meta del paciente.',
                    keyboardType: TextInputType.number,
                    enabled: editable,
                    errorText: _errores['kcal'],
                  ),
                  const SizedBox(height: AppDimensions.spaceLg),
                  _distribucionDeMacros(texto, colores, editable),
                  const SizedBox(height: AppDimensions.spaceLg),
                  _distribucionPorTiempo(texto, colores, editable),
                  const SizedBox(height: AppDimensions.spaceLg),
                  AppTextField(
                    key: const Key('indicaciones'),
                    controller: _indicaciones,
                    label: 'Indicaciones para el recomendador · opcional',
                    hint: 'Prefiere desayunos rápidos y cenas sin frituras',
                    maxLines: 3,
                    enabled: editable,
                    errorText: _errores['indicaciones'],
                  ),
                  const SizedBox(height: AppDimensions.spaceLg),
                  AppCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Usar IA', style: texto.titleSmall),
                              Text(
                                'Si no está disponible, cae a reglas '
                                'automáticamente.',
                                style: texto.bodySmall?.copyWith(
                                  color: colores.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          key: const Key('usarIa'),
                          value: _usarIa,
                          onChanged: editable
                              ? (valor) => setState(() => _usarIa = valor)
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _BarraInferior(
              fallo: _fallo,
              enviando: _enviando,
              onGenerar: _generar,
              onCerrar: widget.onCerrar,
            ),
          ],
        ),
      ),
    );
  }

  Widget _distribucionDeMacros(
    TextTheme texto,
    ColorScheme colores,
    bool editable,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Distribución de macros', style: texto.titleSmall),
          const SizedBox(height: AppDimensions.spaceMd),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final macro in _macros) ...[
                if (macro != _macros.first)
                  const SizedBox(width: AppDimensions.spaceSm),
                Expanded(
                  child: AppTextField(
                    key: Key('macro-${macro.clave}'),
                    controller: _macroCampos[macro.clave],
                    label: macro.etiqueta,
                    keyboardType: TextInputType.number,
                    enabled: editable,
                    errorText: _errores[macro.clave],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          Text(
            'Rangos: proteína 10–50 %, carbohidrato 20–70 %, grasa 10–50 %. '
            'Los tres son obligatorios si se cambia uno.',
            style: texto.labelSmall?.copyWith(color: colores.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _distribucionPorTiempo(
    TextTheme texto,
    ColorScheme colores,
    bool editable,
  ) {
    final errores = [
      for (final tipo in TipoComida.values)
        if (_errores[tipo.codigo] != null) _errores[tipo.codigo]!,
    ];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Distribución por tiempo de comida', style: texto.titleSmall),
          const SizedBox(height: AppDimensions.spaceMd),
          for (final tipo in TipoComida.values)
            Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.spaceSm),
              child: Row(
                children: [
                  Expanded(child: Text(tipo.etiqueta)),
                  SizedBox(
                    width: 88,
                    child: AppTextField(
                      key: Key('tiempo-${tipo.codigo}'),
                      controller: _tiempoCampos[tipo],
                      keyboardType: TextInputType.number,
                      enabled: editable,
                    ),
                  ),
                ],
              ),
            ),
          for (final error in errores)
            Text(error, style: texto.bodySmall?.copyWith(color: colores.error)),
        ],
      ),
    );
  }
}

/// The fixed bottom area: the failure of the last attempt, the button and the
/// note under it.
class _BarraInferior extends StatelessWidget {
  const _BarraInferior({
    required this.fallo,
    required this.enviando,
    required this.onGenerar,
    required this.onCerrar,
  });

  final ApiFailure? fallo;
  final bool enviando;
  final VoidCallback onGenerar;
  final VoidCallback onCerrar;

  /// One line per field error the API listed, when it gave a readable shape.
  List<String> _detalles() => [
    for (final detalle in fallo?.detalles ?? const <Object?>[])
      if (detalle is String)
        detalle
      else if (detalle is Map)
        [detalle['campo'], detalle['mensaje']].whereType<String>().join(': '),
  ].where((linea) => linea.isNotEmpty).toList();

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final colores = Theme.of(context).colorScheme;
    final fallo = this.fallo;

    return Material(
      color: colores.surface,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (fallo != null) ...[
                Text(
                  fallo.mensaje,
                  key: const Key('fallo'),
                  style: texto.bodySmall?.copyWith(color: colores.error),
                ),
                for (final linea in _detalles())
                  Text(
                    linea,
                    style: texto.bodySmall?.copyWith(color: colores.error),
                  ),
                // The code is what makes a failure diagnosable afterwards: the
                // message alone does not say what the server rejected.
                if (fallo.codigo != null || fallo.statusCode != null)
                  Text(
                    [
                      if (fallo.codigo != null) fallo.codigo!,
                      if (fallo.statusCode != null) 'HTTP ${fallo.statusCode}',
                    ].join(' · '),
                    key: const Key('fallo-codigo'),
                    style: texto.labelSmall?.copyWith(color: colores.error),
                  ),
                AppButton(
                  label: 'Cerrar sin generar',
                  variant: AppButtonVariant.text,
                  onPressed: onCerrar,
                ),
                const SizedBox(height: AppDimensions.spaceSm),
              ],
              AppButton(
                label: 'Generar plan',
                isLoading: enviando,
                onPressed: onGenerar,
              ),
              const SizedBox(height: AppDimensions.spaceSm),
              Text(
                'Con IA puede tardar hasta 3 minutos. El plan queda en '
                'borrador.',
                textAlign: TextAlign.center,
                style: texto.labelSmall?.copyWith(
                  color: colores.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
