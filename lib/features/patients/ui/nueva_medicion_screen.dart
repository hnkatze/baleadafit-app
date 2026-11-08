import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_failure.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_button.dart';
import '../data/paciente_ficha.dart';
import '../data/patients_providers.dart';

/// One numeric input of the form. [clave] is the exact field name of
/// `POST /pacientes/{id}/mediciones`, so the body is built without a second
/// mapping that could drift.
class _Campo {
  const _Campo(
    this.clave,
    this.etiqueta,
    this.min,
    this.max, {
    this.entero = false,
  });

  final String clave;
  final String etiqueta;

  /// Bounds the API documents; checking them here avoids a round trip that
  /// could only answer `Datos inválidos.`.
  final num min;
  final num max;
  final bool entero;
}

const _peso = _Campo('pesoKg', 'Peso · kg', 20, 400);
const _talla = _Campo('tallaCm', 'Talla · cm', 80, 250);
const _grasa = _Campo('pctGrasa', '% grasa', 2, 70);

const _composicion = [
  _Campo('cinturaCm', 'Cintura · cm', 40, 250),
  _Campo('masaMuscularKg', 'Masa muscular · kg', 1, 200),
  _Campo('masaGrasaKg', 'Masa grasa · kg', 0, 200),
  _Campo('grasaVisceral', 'Grasa visceral · 1–20', 1, 20, entero: true),
  _Campo('aguaIntracelularL', 'Agua intracel. · L', 0, 100),
  _Campo('aguaExtracelularL', 'Agua extracel. · L', 0, 100),
  _Campo('anguloFase', 'Ángulo de fase · °', 1, 15),
];

const _pliegues = [
  _Campo('pliegueTricipitalMm', 'Tricipital · mm', 2, 80),
  _Campo('pliegueSubescapularMm', 'Subescapular · mm', 2, 80),
  _Campo('pliegueSuprailiacoMm', 'Suprailiaco · mm', 2, 80),
  _Campo('pliegueBicipitalMm', 'Bicipital · mm', 2, 80),
];

const _perimetros = [
  _Campo('perimetroBrazoCm', 'Brazo · cm', 10, 200),
  _Campo('perimetroCaderaCm', 'Cadera · cm', 10, 200),
  _Campo('perimetroMusloCm', 'Muslo · cm', 10, 200),
];

const _tension = [
  _Campo('presionSistolica', 'Sistólica · mmHg', 60, 250),
  _Campo('presionDiastolica', 'Diastólica · mmHg', 40, 250),
];

/// Titles and detail of the collapsible groups, in the order the artboard draws.
const _grupos = [
  _Grupo('Composición corporal', ' · opcional', _composicion),
  _Grupo('Pliegues', ' · 4 campos · mm', _pliegues),
  _Grupo('Perímetros', ' · 3 campos · cm', _perimetros),
  _Grupo('Tensión arterial', ' · 2 campos · mmHg', _tension),
];

class _Grupo {
  const _Grupo(this.titulo, this.detalle, this.campos);

  final String titulo;
  final String detalle;
  final List<_Campo> campos;
}

/// `fuente` values of the API with the label the form shows.
const _fuentes = {
  'MANUAL': 'Manual',
  'BASCULA': 'Báscula',
  'INBODY': 'InBody',
  'OMRON': 'Omron',
  'OTRO': 'Otro',
};

const _notasMaximo = 1000;

const _meses = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

/// Capture of a new measurement for one patient, from
/// `POST /pacientes/{id}/mediciones`.
///
/// Only weight and height are required (the API rejects a measurement without
/// them). Everything else is optional and stays out of the body when empty.
class NuevaMedicionScreen extends ConsumerStatefulWidget {
  const NuevaMedicionScreen({required this.pacienteId, super.key});

  final String pacienteId;

  @override
  ConsumerState<NuevaMedicionScreen> createState() =>
      _NuevaMedicionScreenState();
}

class _NuevaMedicionScreenState extends ConsumerState<NuevaMedicionScreen> {
  // Controllers live here, not in the sections: a collapsed section unmounts
  // its fields, and what was typed in it must survive that.
  final _controllers = <String, TextEditingController>{
    for (final campo in [
      _peso,
      _talla,
      _grasa,
      for (final grupo in _grupos) ...grupo.campos,
    ])
      campo.clave: TextEditingController(),
  };
  final _notas = TextEditingController();
  final _secciones = [for (final _ in _grupos) ExpansibleController()];

  late DateTime _fecha = _hoy();
  String _fuente = 'MANUAL';
  Map<String, String> _errores = {};
  String? _falla;
  bool _enviando = false;

  static DateTime _hoy() {
    final ahora = DateTime.now();
    return DateTime(ahora.year, ahora.month, ahora.day);
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _notas.dispose();
    super.dispose();
  }

  /// Parses the text as the keyboard of an es-HN user types it: a comma is a
  /// decimal separator too.
  num? _leer(_Campo campo) {
    final texto = _controllers[campo.clave]!.text.trim().replaceAll(',', '.');
    if (texto.isEmpty) return null;
    final valor = double.tryParse(texto);
    if (valor == null) return double.nan;
    return campo.entero ? valor.truncate() : valor;
  }

  String? _validarCampo(
    _Campo campo, {
    required bool obligatorio,
    String? falta,
  }) {
    final valor = _leer(campo);
    if (valor == null) return obligatorio ? falta : null;
    if (valor.isNaN || valor < campo.min || valor > campo.max) {
      return 'Entre ${_formatear(campo.min)} y ${_formatear(campo.max)}';
    }
    return null;
  }

  Map<String, String> _validar() {
    final errores = <String, String>{};
    void revisar(_Campo campo, {String? falta}) {
      final error = _validarCampo(
        campo,
        obligatorio: falta != null,
        falta: falta,
      );
      if (error != null) errores[campo.clave] = error;
    }

    revisar(_peso, falta: 'Ingresá el peso');
    revisar(_talla, falta: 'Ingresá la talla');
    revisar(_grasa);
    for (final grupo in _grupos) {
      grupo.campos.forEach(revisar);
    }
    if (_notas.text.length > _notasMaximo) {
      errores['notas'] = 'Máximo $_notasMaximo caracteres';
    }
    return errores;
  }

  /// Only the fields the API documents, and only the ones that were filled.
  Map<String, Object?> _cuerpo() {
    final cuerpo = <String, Object?>{'fecha': _fechaIso(_fecha)};
    for (final campo in [
      _peso,
      _talla,
      _grasa,
      for (final grupo in _grupos) ...grupo.campos,
    ]) {
      final valor = _leer(campo);
      if (valor != null) cuerpo[campo.clave] = valor;
    }
    cuerpo['fuente'] = _fuente;
    final notas = _notas.text.trim();
    if (notas.isNotEmpty) cuerpo['notas'] = notas;
    return cuerpo;
  }

  Future<void> _guardar() async {
    FocusScope.of(context).unfocus();
    final errores = _validar();
    if (errores.isNotEmpty) {
      setState(() {
        _errores = errores;
        _falla = null;
      });
      // A collapsed group hides its error, so open the ones that have one.
      for (var i = 0; i < _grupos.length; i++) {
        if (_grupos[i].campos.any((c) => errores.containsKey(c.clave))) {
          _secciones[i].expand();
        }
      }
      return;
    }

    setState(() {
      _errores = {};
      _falla = null;
      _enviando = true;
    });
    try {
      await ref
          .read(patientsRepositoryProvider)
          .registrarMedicion(widget.pacienteId, body: _cuerpo());
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
    // The ficha derives its BMI, trend and requirement from the measurements,
    // so it is reloaded instead of patched by hand.
    ref.invalidate(pacienteFichaProvider(widget.pacienteId));
    Navigator.of(context).pop(true);
  }

  Future<void> _elegirFecha() async {
    final hoy = _hoy();
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(hoy.year - 10),
      // A measurement cannot be taken in the future.
      lastDate: hoy,
    );
    if (elegida != null) setState(() => _fecha = elegida);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final ficha = ref.watch(pacienteFichaProvider(widget.pacienteId)).value;
    final anterior = ficha?.evolucion.lastOrNull;
    final antes = {
      _peso.clave: anterior?.pesoKg,
      _talla.clave: anterior?.tallaCm,
      _grasa.clave: anterior?.pctGrasa,
    };

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Cabecera(ficha: ficha),
            Expanded(
              child: SingleChildScrollView(
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
                    _FechaYFuente(
                      fecha: _fecha,
                      fuente: _fuente,
                      onFecha: _elegirFecha,
                      onFuente: (valor) => setState(() => _fuente = valor),
                    ),
                    const SizedBox(height: AppDimensions.spaceMd),
                    _Basicos(
                      controllers: _controllers,
                      errores: _errores,
                      antes: antes,
                    ),
                    for (var i = 0; i < _grupos.length; i++) ...[
                      const SizedBox(height: AppDimensions.spaceMd),
                      _GrupoOpcional(
                        grupo: _grupos[i],
                        controller: _secciones[i],
                        controllers: _controllers,
                        errores: _errores,
                      ),
                    ],
                    const SizedBox(height: AppDimensions.spaceMd),
                    _EtiquetaYCampo(
                      etiqueta: 'Notas',
                      child: TextField(
                        key: const ValueKey('notas'),
                        controller: _notas,
                        minLines: 3,
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: 'Condiciones de la medición, observaciones',
                          errorText: _errores['notas'],
                        ),
                      ),
                    ),
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

/// `Nueva medición`, the patient and the close action.
class _Cabecera extends StatelessWidget {
  const _Cabecera({required this.ficha});

  final PacienteFicha? ficha;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final nombre = ficha?.paciente.nombreCompleto;

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
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nueva medición', style: textTheme.titleLarge),
                if (nombre != null && nombre.isNotEmpty)
                  Text(
                    nombre,
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

class _FechaYFuente extends StatelessWidget {
  const _FechaYFuente({
    required this.fecha,
    required this.fuente,
    required this.onFecha,
    required this.onFuente,
  });

  final DateTime fecha;
  final String fuente;
  final VoidCallback onFecha;
  final ValueChanged<String> onFuente;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _EtiquetaYCampo(
            etiqueta: 'Fecha',
            child: InkWell(
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              onTap: onFecha,
              child: Container(
                height: AppDimensions.fieldHeight,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: Text(_fechaLegible(fecha), style: textTheme.bodyMedium),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.spaceSm + 4),
        Expanded(
          child: _EtiquetaYCampo(
            etiqueta: 'Fuente',
            child: DropdownButtonFormField<String>(
              initialValue: fuente,
              isExpanded: true,
              icon: const Icon(Icons.expand_more, size: 20),
              style: textTheme.bodyMedium?.copyWith(color: colors.onSurface),
              items: [
                for (final entrada in _fuentes.entries)
                  DropdownMenuItem(
                    value: entrada.key,
                    child: Text(entrada.value),
                  ),
              ],
              onChanged: (valor) {
                if (valor != null) onFuente(valor);
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// The only required group: weight and height, plus the body-fat percentage
/// the artboard keeps beside them.
class _Basicos extends StatelessWidget {
  const _Basicos({
    required this.controllers,
    required this.errores,
    required this.antes,
  });

  final Map<String, TextEditingController> controllers;
  final Map<String, String> errores;
  final Map<String, num?> antes;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceMd),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Básicos', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppDimensions.spaceSm + 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, campo) in [_peso, _talla, _grasa].indexed) ...[
                if (i > 0) const SizedBox(width: AppDimensions.spaceSm),
                Expanded(
                  child: _CampoNumero(
                    campo: campo,
                    controller: controllers[campo.clave]!,
                    error: errores[campo.clave],
                    // No previous value means no hint, not a dash or a zero.
                    antes: antes[campo.clave],
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

/// A collapsible, optional group. Collapsed by default so the form opens short.
class _GrupoOpcional extends StatelessWidget {
  const _GrupoOpcional({
    required this.grupo,
    required this.controller,
    required this.controllers,
    required this.errores,
  });

  final _Grupo grupo;
  final ExpansibleController controller;
  final Map<String, TextEditingController> controllers;
  final Map<String, String> errores;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final filas = <List<_Campo>>[
      for (var i = 0; i < grupo.campos.length; i += 2)
        grupo.campos.sublist(i, (i + 2).clamp(0, grupo.campos.length)),
    ];

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: ExpansionTile(
        controller: controller,
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceMd,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppDimensions.spaceMd,
          0,
          AppDimensions.spaceMd,
          AppDimensions.spaceMd,
        ),
        iconColor: colors.onSurfaceVariant,
        collapsedIconColor: colors.onSurfaceVariant,
        title: Text.rich(
          TextSpan(
            text: grupo.titulo,
            style: textTheme.titleMedium,
            children: [
              TextSpan(
                text: grupo.detalle,
                style: textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        children: [
          for (final (i, fila) in filas.indexed) ...[
            if (i > 0) const SizedBox(height: AppDimensions.spaceSm + 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (j, campo) in fila.indexed) ...[
                  if (j > 0) const SizedBox(width: AppDimensions.spaceSm),
                  Expanded(
                    child: _CampoNumero(
                      campo: campo,
                      controller: controllers[campo.clave]!,
                      error: errores[campo.clave],
                    ),
                  ),
                ],
                // Keeps a lone last field at half width like its siblings.
                if (fila.length == 1) const Expanded(child: SizedBox()),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// A label above its input, like the other mobile forms (no floating label).
class _EtiquetaYCampo extends StatelessWidget {
  const _EtiquetaYCampo({required this.etiqueta, required this.child});

  final String etiqueta;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          etiqueta,
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppDimensions.spaceXs + 2),
        child,
      ],
    );
  }
}

class _CampoNumero extends StatelessWidget {
  const _CampoNumero({
    required this.campo,
    required this.controller,
    required this.error,
    this.antes,
  });

  final _Campo campo;
  final TextEditingController controller;
  final String? error;

  /// The value of the last measurement, drawn as `antes <valor>`.
  final num? antes;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return _EtiquetaYCampo(
      etiqueta: campo.etiqueta,
      child: TextField(
        key: ValueKey(campo.clave),
        controller: controller,
        keyboardType: TextInputType.numberWithOptions(decimal: !campo.entero),
        inputFormatters: [
          FilteringTextInputFormatter.allow(
            campo.entero ? RegExp(r'\d') : RegExp(r'[\d.,]'),
          ),
        ],
        // Figures are tabular mono so a column of readings lines up.
        style: AppTypography.data(context)
            .copyWith(fontSize: 15, color: colors.onSurface),
        decoration: InputDecoration(
          hintText: '—',
          errorText: error,
          errorMaxLines: 2,
          helperText: antes == null ? null : 'antes ${_formatear(antes!)}',
          helperStyle: textTheme.labelSmall?.copyWith(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w400,
          ),
        ),
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
    required this.onGuardar,
  });

  final String? falla;
  final bool enviando;
  final VoidCallback onGuardar;

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
              label: 'Guardar medición',
              isLoading: enviando,
              onPressed: onGuardar,
            ),
          ],
        ),
      ),
    );
  }
}

/// `72.4` and `174` read as the nutritionist writes them, without `.0`.
String _formatear(num valor) =>
    valor == valor.roundToDouble() ? valor.toInt().toString() : '$valor';

String _fechaLegible(DateTime fecha) {
  final hoy = DateTime.now();
  final corta = '${fecha.day} ${_meses[fecha.month - 1]}';
  final esHoy =
      fecha.year == hoy.year &&
      fecha.month == hoy.month &&
      fecha.day == hoy.day;
  return esHoy ? 'Hoy, $corta' : '$corta ${fecha.year}';
}

String _fechaIso(DateTime fecha) {
  String dos(int n) => n.toString().padLeft(2, '0');
  return '${fecha.year}-${dos(fecha.month)}-${dos(fecha.day)}';
}
