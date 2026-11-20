import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_failure.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../shared/widgets/app_button.dart';
import '../data/alimento.dart';
import '../data/catalogo_providers.dart';

/// A value of the API and the label the app shows for it.
typedef _Opcion = ({String valor, String etiqueta, IconData icono});

/// `categoria` enum (`odd/designs/catalogo-context.md` §2). The labels are copy
/// of the app; the value is what travels.
const _categorias = <_Opcion>[
  (valor: 'PLATO_TIPICO', etiqueta: 'Plato típico', icono: Icons.dinner_dining),
  (valor: 'PROTEINA', etiqueta: 'Proteína', icono: Icons.egg_alt_outlined),
  (
    valor: 'CEREAL_TUBERCULO',
    etiqueta: 'Cereal y tubérculo',
    icono: Icons.grain,
  ),
  (valor: 'LEGUMINOSA', etiqueta: 'Leguminosa', icono: Icons.spa_outlined),
  (valor: 'LACTEO', etiqueta: 'Lácteo', icono: Icons.icecream_outlined),
  (valor: 'FRUTA', etiqueta: 'Fruta', icono: Icons.apple),
  (valor: 'VERDURA', etiqueta: 'Verdura', icono: Icons.eco_outlined),
  (valor: 'GRASA', etiqueta: 'Grasa', icono: Icons.opacity),
  (valor: 'BEBIDA', etiqueta: 'Bebida', icono: Icons.local_drink_outlined),
];

/// `tiposComida` enum (§2).
const _tiempos = <_Opcion>[
  (
    valor: 'DESAYUNO',
    etiqueta: 'Desayuno',
    icono: Icons.free_breakfast_outlined,
  ),
  (
    valor: 'MERIENDA_AM',
    etiqueta: 'Merienda AM',
    icono: Icons.bakery_dining_outlined,
  ),
  (valor: 'ALMUERZO', etiqueta: 'Almuerzo', icono: Icons.lunch_dining),
  (
    valor: 'MERIENDA_PM',
    etiqueta: 'Merienda PM',
    icono: Icons.restaurant_outlined,
  ),
  (valor: 'CENA', etiqueta: 'Cena', icono: Icons.dinner_dining_outlined),
];

const _aviso =
    'Todos los valores son por porción. Si vaciás un campo, se conserva el '
    'valor guardado. Cambiar un nutriente crea una versión nueva.';
const _ayudaSodio = 'Se guarda como aproximado. Verificar con INCAP.';
const _ayudaIndiceGlucemico =
    'Dejalo vacío si el alimento no tiene carbohidratos: queda “sin dato”, '
    'no 0.';
const _notaContiene =
    'Ninguna marcada: aparece aunque se excluyan restricciones en la búsqueda.';

/// Name of every writable field of the body: the keys of `detalles.campo` this
/// form can blame. `id` and `activo` of the 21 never travel from here.
const _numericos = [
  'porcionGramos',
  'kcal',
  'proteinaG',
  'carbohidratoG',
  'grasaG',
  'fibraG',
  'sodioMg',
  'potasioMg',
  'fosforoMg',
  'azucaresG',
  'grasasSatG',
  'indiceGlucemico',
];
const _campos = [
  'nombre',
  'categoria',
  'esTipicoHn',
  'fuente',
  'porcionDescripcion',
  ..._numericos,
  'tiposComida',
  'contiene',
];

/// Board shared by adding (`alimento == null`) and editing a food. It only
/// draws and submits: closing and what happens after saving belong to whoever
/// places it.
class AlimentoFormScreen extends ConsumerStatefulWidget {
  const AlimentoFormScreen({
    required this.onCerrar,
    required this.onGuardado,
    this.alimento,
    super.key,
  });

  /// Null adds a new food; otherwise it is edited and preloaded.
  final Alimento? alimento;

  /// The `x` in the corner: there is no cancel button.
  final VoidCallback onCerrar;

  /// Called with the entity the API answered.
  final void Function(Alimento alimento) onGuardado;

  @override
  ConsumerState<AlimentoFormScreen> createState() => _AlimentoFormScreenState();
}

class _AlimentoFormScreenState extends ConsumerState<AlimentoFormScreen> {
  late final _nombre = TextEditingController(text: widget.alimento?.nombre);
  late final _fuente = TextEditingController(text: widget.alimento?.fuente);
  late final _porcionDescripcion = TextEditingController(
    text: widget.alimento?.porcionDescripcion,
  );
  late final Map<String, TextEditingController> _numeros = {
    for (final campo in _numericos)
      campo: TextEditingController(text: _mostrar(_guardado(campo))),
  };

  late String? _categoria = widget.alimento?.categoria;
  late bool _tipico = widget.alimento?.esTipicoHn ?? false;
  late final Set<String> _tiposComida = {...?widget.alimento?.tiposComida};
  late final Set<String> _contiene = {...?widget.alimento?.contiene};

  Map<String, String> _errores = {};
  ApiFailure? _falla;
  bool _enviando = false;

  bool get _edicion => widget.alimento != null;

  @override
  void dispose() {
    _nombre.dispose();
    _fuente.dispose();
    _porcionDescripcion.dispose();
    for (final c in _numeros.values) {
      c.dispose();
    }
    super.dispose();
  }

  double? _guardado(String campo) {
    final a = widget.alimento;
    if (a == null) return null;
    return switch (campo) {
      'porcionGramos' => a.porcionGramos,
      'kcal' => a.kcal,
      'proteinaG' => a.proteinaG,
      'carbohidratoG' => a.carbohidratoG,
      'grasaG' => a.grasaG,
      'fibraG' => a.fibraG,
      'sodioMg' => a.sodioMg,
      'potasioMg' => a.potasioMg,
      'fosforoMg' => a.fosforoMg,
      'azucaresG' => a.azucaresG,
      'grasasSatG' => a.grasasSatG,
      'indiceGlucemico' => a.indiceGlucemico,
      _ => null,
    };
  }

  /// `120.0` reads as `120`; a missing value is an empty field, never `0`.
  static String _mostrar(num? valor) {
    if (valor == null) return '';
    return valor == valor.truncate() ? '${valor.truncate()}' : '$valor';
  }

  /// A whole number travels as an `int`, anything else as a `double`.
  static num _comoNumero(double valor) =>
      valor == valor.truncateToDouble() ? valor.truncate() : valor;

  /// The text to send for an optional text. An emptied field resends what was
  /// stored: the API has no way to clear it, so the form never pretends to.
  String? _opcional(TextEditingController controller, String? guardado) {
    final texto = controller.text.trim();
    if (texto.isNotEmpty) return texto;
    if (!_edicion || guardado == null || guardado.isEmpty) return null;
    return guardado;
  }

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
    final errores = <String, String>{};
    final cuerpo = <String, Object?>{};

    final nombre = _nombre.text.trim();
    if (nombre.isEmpty) errores['nombre'] = 'Ingresá el nombre del alimento';
    cuerpo['nombre'] = nombre;

    for (final campo in _numericos) {
      final texto = _numeros[campo]!.text.trim();
      if (texto.isEmpty) {
        final anterior = _guardado(campo);
        if (anterior != null) cuerpo[campo] = _comoNumero(anterior);
        continue;
      }
      final valor = double.tryParse(texto.replaceAll(',', '.'));
      if (valor == null || !valor.isFinite || valor < 0) {
        errores[campo] = 'Ingresá un número';
      } else {
        cuerpo[campo] = _comoNumero(valor);
      }
    }

    if (errores.isNotEmpty) {
      setState(() {
        _errores = errores;
        _falla = null;
      });
      return;
    }

    final actual = widget.alimento;
    final categoria = _categoria ?? (_edicion ? actual?.categoria : null);
    final fuente = _opcional(_fuente, actual?.fuente);
    final descripcion = _opcional(
      _porcionDescripcion,
      actual?.porcionDescripcion,
    );
    // Both lists are the whole selection, so an empty one is a value, not a
    // missing field: it is how a food loses its meal times or its restriction
    // labels. Sending the stored list back would make the last tag impossible
    // to un-choose.
    final tipos = _tiposComida.toList(growable: false);
    final contiene = _contiene.toList(growable: false);
    cuerpo
      ..['categoria'] = categoria
      ..['esTipicoHn'] = _tipico
      ..['fuente'] = fuente
      ..['porcionDescripcion'] = descripcion
      ..['tiposComida'] = tipos
      ..['contiene'] = contiene
      ..removeWhere((_, v) => v == null);

    setState(() {
      _errores = {};
      _falla = null;
      _enviando = true;
    });

    final repositorio = ref.read(catalogoRepositoryProvider);
    final Alimento guardado;
    try {
      guardado = actual == null
          ? await repositorio.crear(cuerpo)
          : await repositorio.actualizar(actual.id, body: cuerpo);
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
    setState(() => _enviando = false);
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

  void _alternar(Set<String> conjunto, String valor) => setState(() {
    if (!conjunto.remove(valor)) conjunto.add(valor);
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final titulo = _edicion ? 'Editar alimento' : 'Agregar alimento';
    final restricciones = ref.watch(restriccionesCatalogoProvider);

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Cabecera(titulo: titulo, onCerrar: widget.onCerrar),
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
                    const _Aviso(texto: _aviso),
                    const SizedBox(height: AppDimensions.spaceLg),
                    const _Bloque('1 · Identidad'),
                    _Campo(
                      etiqueta: 'Nombre',
                      clave: 'nombre',
                      controller: _nombre,
                      error: _errores['nombre'],
                      texto: true,
                    ),
                    const SizedBox(height: AppDimensions.spaceMd),
                    _Etiqueta('Categoría'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final c in _categorias)
                          FilterChip(
                            key: ValueKey('categoria-${c.valor}'),
                            label: Text(c.etiqueta),
                            avatar: Icon(c.icono, size: 18),
                            selected: _categoria == c.valor,
                            onSelected: (_) => setState(
                              () => _categoria = _categoria == c.valor
                                  ? null
                                  : c.valor,
                            ),
                          ),
                      ],
                    ),
                    _ErrorCampo(_errores['categoria']),
                    const SizedBox(height: AppDimensions.spaceSm),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.flag_outlined),
                      title: const Text('Típico hondureño'),
                      value: _tipico,
                      onChanged: (v) => setState(() => _tipico = v),
                    ),
                    _Campo(
                      etiqueta: 'Fuente',
                      clave: 'fuente',
                      controller: _fuente,
                      hint: 'INCAP, USDA, etiqueta del producto…',
                      error: _errores['fuente'],
                      texto: true,
                    ),
                    const SizedBox(height: AppDimensions.spaceLg),
                    const _Bloque('2 · Porción'),
                    _Campo(
                      etiqueta: 'Descripción',
                      clave: 'porcionDescripcion',
                      controller: _porcionDescripcion,
                      error: _errores['porcionDescripcion'],
                      texto: true,
                    ),
                    const SizedBox(height: AppDimensions.spaceMd),
                    _numero('Gramos', 'porcionGramos'),
                    const SizedBox(height: AppDimensions.spaceLg),
                    const _Bloque('3 · Composición por porción'),
                    const _Subtitulo('ENERGÍA Y MACROS'),
                    _numero('Energía · kcal', 'kcal'),
                    _numero('Proteína · g', 'proteinaG'),
                    _numero('Carbohidrato · g', 'carbohidratoG'),
                    _numero('Grasa · g', 'grasaG'),
                    _numero('Fibra · g', 'fibraG'),
                    const SizedBox(height: AppDimensions.spaceSm),
                    const _Subtitulo('MICRONUTRIENTES'),
                    _numero(
                      'Sodio · mg',
                      'sodioMg',
                      ayuda: _ayudaSodio,
                      estimado: true,
                    ),
                    _numero('Potasio · mg', 'potasioMg'),
                    _numero('Fósforo · mg', 'fosforoMg'),
                    _numero('Azúcares · g', 'azucaresG'),
                    _numero('Grasas sat. · g', 'grasasSatG'),
                    _numero(
                      'Índice glucémico',
                      'indiceGlucemico',
                      hint: 'Sin dato',
                      ayuda: _ayudaIndiceGlucemico,
                    ),
                    const SizedBox(height: AppDimensions.spaceLg),
                    const _Bloque('4 · Uso'),
                    _Etiqueta('Tiempos de comida'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final t in _tiempos)
                          FilterChip(
                            key: ValueKey('tipo-${t.valor}'),
                            label: Text(t.etiqueta),
                            avatar: Icon(t.icono, size: 18),
                            selected: _tiposComida.contains(t.valor),
                            onSelected: (_) => _alternar(_tiposComida, t.valor),
                          ),
                      ],
                    ),
                    _ErrorCampo(_errores['tiposComida']),
                    const SizedBox(height: AppDimensions.spaceMd),
                    _Etiqueta('Contiene'),
                    restricciones.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(AppDimensions.spaceSm),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, _) => Row(
                        children: [
                          Expanded(
                            child: Text(
                              'No se pudieron cargar las restricciones.',
                              style: textTheme.bodySmall?.copyWith(
                                color: colors.error,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                ref.invalidate(restriccionesCatalogoProvider),
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                      data: (lista) => Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final r in lista)
                            FilterChip(
                              key: ValueKey('contiene-${r.codigo}'),
                              label: Text(r.nombre),
                              avatar: const Icon(
                                Icons.warning_amber_outlined,
                                size: 18,
                              ),
                              selected: _contiene.contains(r.codigo),
                              onSelected: (_) => _alternar(_contiene, r.codigo),
                            ),
                        ],
                      ),
                    ),
                    _ErrorCampo(_errores['contiene']),
                    const SizedBox(height: AppDimensions.spaceSm),
                    Text(
                      _notaContiene,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _Accion(
              falla: _falla,
              enviando: _enviando,
              etiqueta: titulo == 'Editar alimento'
                  ? 'Guardar cambios'
                  : 'Agregar alimento',
              onGuardar: _guardar,
            ),
          ],
        ),
      ),
    );
  }

  Widget _numero(
    String etiqueta,
    String clave, {
    String? hint,
    String? ayuda,
    bool estimado = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: AppDimensions.spaceSm),
    child: _Campo(
      etiqueta: etiqueta,
      clave: clave,
      controller: _numeros[clave]!,
      hint: hint,
      ayuda: ayuda,
      error: _errores[clave],
      estimado: estimado,
    ),
  );
}

class _Cabecera extends StatelessWidget {
  const _Cabecera({required this.titulo, required this.onCerrar});

  final String titulo;
  final VoidCallback onCerrar;

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
            tooltip: 'Cerrar sin guardar',
            icon: const Icon(Icons.close, size: AppDimensions.iconMd),
            onPressed: onCerrar,
          ),
          Expanded(
            child: Text(titulo, style: Theme.of(context).textTheme.titleLarge),
          ),
        ],
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.texto});

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

class _Bloque extends StatelessWidget {
  const _Bloque(this.titulo);

  final String titulo;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppDimensions.spaceSm),
    child: Text(titulo, style: Theme.of(context).textTheme.titleMedium),
  );
}

class _Subtitulo extends StatelessWidget {
  const _Subtitulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppDimensions.spaceSm),
    child: Text(
      texto,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      texto,
      style: Theme.of(context).textTheme.labelMedium
          ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
    ),
  );
}

class _ErrorCampo extends StatelessWidget {
  const _ErrorCampo(this.mensaje);

  final String? mensaje;

  @override
  Widget build(BuildContext context) {
    final mensaje = this.mensaje;
    if (mensaje == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        mensaje,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}

class _Campo extends StatelessWidget {
  const _Campo({
    required this.etiqueta,
    required this.clave,
    required this.controller,
    this.hint,
    this.ayuda,
    this.error,
    this.texto = false,
    this.estimado = false,
  });

  final String etiqueta;
  final String clave;
  final TextEditingController controller;
  final String? hint;
  final String? ayuda;
  final String? error;

  /// Free text; otherwise a decimal number.
  final bool texto;

  /// Draws the `Estimado` mark next to the label (sodium).
  final bool estimado;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              etiqueta,
              style: textTheme.labelMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            if (estimado) ...[
              const SizedBox(width: 8),
              Icon(Icons.info_outline, size: 14, color: colors.tertiary),
              const SizedBox(width: 2),
              Text(
                'Estimado',
                style: textTheme.labelSmall?.copyWith(color: colors.tertiary),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          key: ValueKey(clave),
          controller: controller,
          keyboardType: texto
              ? TextInputType.text
              : const TextInputType.numberWithOptions(decimal: true),
          textCapitalization: texto
              ? TextCapitalization.sentences
              : TextCapitalization.none,
          decoration: InputDecoration(
            hintText: hint,
            helperText: ayuda,
            helperMaxLines: 3,
            errorText: error,
          ),
        ),
      ],
    );
  }
}

/// Fixed bottom bar: the failure of the last attempt and the primary action.
class _Accion extends StatelessWidget {
  const _Accion({
    required this.falla,
    required this.enviando,
    required this.etiqueta,
    required this.onGuardar,
  });

  final ApiFailure? falla;
  final bool enviando;
  final String etiqueta;
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
              label: etiqueta,
              icon: Icons.save_outlined,
              isLoading: enviando,
              onPressed: onGuardar,
            ),
          ],
        ),
      ),
    );
  }
}
