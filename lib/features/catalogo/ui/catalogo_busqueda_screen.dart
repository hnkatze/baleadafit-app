import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_failure.dart';
import '../../../core/network/paged.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_refresh.dart';
import '../data/alimento.dart';
import '../data/catalogo_providers.dart';
import '../data/restriccion.dart';

/// Page size of the list; the API default, spelled out so the "load more"
/// arithmetic does not depend on it.
const int _tamanoPagina = 20;

/// How long the search box waits after the last keystroke before it asks the
/// API: typing a word must not fire one request per letter.
const Duration _esperaDeTexto = Duration(milliseconds: 300);

/// The nine `categoria` values and their label (copy of the app, the value is
/// the enum).
const List<(String, String)> _categorias = [
  ('PLATO_TIPICO', 'Plato típico'),
  ('PROTEINA', 'Proteína'),
  ('CEREAL_TUBERCULO', 'Cereal y tubérculo'),
  ('LEGUMINOSA', 'Leguminosa'),
  ('LACTEO', 'Lácteo'),
  ('FRUTA', 'Fruta'),
  ('VERDURA', 'Verdura'),
  ('GRASA', 'Grasa'),
  ('BEBIDA', 'Bebida'),
];

/// The five `tipoComida` values and their label.
const List<(String, String)> _tiempos = [
  ('DESAYUNO', 'Desayuno'),
  ('MERIENDA_AM', 'Merienda AM'),
  ('ALMUERZO', 'Almuerzo'),
  ('MERIENDA_PM', 'Merienda PM'),
  ('CENA', 'Cena'),
];

String? _etiquetaDe(List<(String, String)> tabla, String? codigo) {
  for (final (valor, etiqueta) in tabla) {
    if (valor == codigo) return etiqueta;
  }
  return null;
}

/// The filters of the search, as the API takes them.
@immutable
class FiltrosCatalogo {
  const FiltrosCatalogo({
    this.q,
    this.categoria,
    this.tipoComida,
    this.soloTipicos = false,
    this.excluir = const [],
  });

  /// Free text; `null` when the box is empty.
  final String? q;
  final String? categoria;
  final String? tipoComida;
  final bool soloTipicos;

  /// Restriction codes (`lactosa`, `gluten`…), never labels.
  final List<String> excluir;

  /// Filters set, not counting the text: it has its own box.
  int get cantidad =>
      (categoria != null ? 1 : 0) +
      (tipoComida != null ? 1 : 0) +
      (soloTipicos ? 1 : 0) +
      excluir.length;

  bool get vacio => q == null && cantidad == 0;

  @override
  bool operator ==(Object other) =>
      other is FiltrosCatalogo &&
      other.q == q &&
      other.categoria == categoria &&
      other.tipoComida == tipoComida &&
      other.soloTipicos == soloTipicos &&
      listEquals(other.excluir, excluir);

  @override
  int get hashCode => Object.hash(
    q,
    categoria,
    tipoComida,
    soloTipicos,
    Object.hashAll(excluir),
  );
}

/// Search state of the screen. Lives only while the screen does.
class FiltrosCatalogoNotifier extends Notifier<FiltrosCatalogo> {
  @override
  FiltrosCatalogo build() => const FiltrosCatalogo();

  void texto(String valor) {
    final limpio = valor.trim();
    final nuevo = limpio.isEmpty ? null : limpio;
    if (nuevo == state.q) return;
    state = FiltrosCatalogo(
      q: nuevo,
      categoria: state.categoria,
      tipoComida: state.tipoComida,
      soloTipicos: state.soloTipicos,
      excluir: state.excluir,
    );
  }

  void categoria(String? valor) => state = FiltrosCatalogo(
    q: state.q,
    categoria: valor,
    tipoComida: state.tipoComida,
    soloTipicos: state.soloTipicos,
    excluir: state.excluir,
  );

  void tiempo(String? valor) => state = FiltrosCatalogo(
    q: state.q,
    categoria: state.categoria,
    tipoComida: valor,
    soloTipicos: state.soloTipicos,
    excluir: state.excluir,
  );

  void soloTipicos({required bool valor}) => state = FiltrosCatalogo(
    q: state.q,
    categoria: state.categoria,
    tipoComida: state.tipoComida,
    soloTipicos: valor,
    excluir: state.excluir,
  );

  /// Adds the code when absent, removes it when present.
  void alternarExclusion(String codigo) {
    final actuales = state.excluir;
    state = FiltrosCatalogo(
      q: state.q,
      categoria: state.categoria,
      tipoComida: state.tipoComida,
      soloTipicos: state.soloTipicos,
      excluir: actuales.contains(codigo)
          ? [
              for (final c in actuales)
                if (c != codigo) c,
            ]
          : [...actuales, codigo],
    );
  }

  /// Drops the chips of the FILTROS section; the text stays.
  void limpiarFiltros() => state = FiltrosCatalogo(q: state.q);

  /// Drops the text and every filter.
  void limpiarTodo() => state = const FiltrosCatalogo();
}

final filtrosCatalogoProvider =
    NotifierProvider.autoDispose<FiltrosCatalogoNotifier, FiltrosCatalogo>(
      FiltrosCatalogoNotifier.new,
    );

/// What the list draws: the pages loaded so far and the total of the search.
@immutable
class ResultadosCatalogo {
  const ResultadosCatalogo({
    required this.items,
    required this.total,
    required this.hayMas,
    this.cargandoMas = false,
    this.falloMas,
  });

  final List<Alimento> items;
  final int total;
  final bool hayMas;
  final bool cargandoMas;

  /// Failure of the last "load more"; the pages already loaded stay.
  final Object? falloMas;

  ResultadosCatalogo copyWith({
    List<Alimento>? items,
    int? total,
    bool? hayMas,
    bool? cargandoMas,
    Object? falloMas,
    bool quitarFallo = false,
  }) => ResultadosCatalogo(
    items: items ?? this.items,
    total: total ?? this.total,
    hayMas: hayMas ?? this.hayMas,
    cargandoMas: cargandoMas ?? this.cargandoMas,
    falloMas: quitarFallo ? null : (falloMas ?? this.falloMas),
  );
}

/// The search: the first page for the current filters, plus the following ones
/// on demand. Paging is by `offset`, which is what gives the real `total`
/// ("38 resultados"); the cursor mode would not.
class ResultadosCatalogoNotifier extends AsyncNotifier<ResultadosCatalogo> {
  @override
  Future<ResultadosCatalogo> build() async {
    final filtros = ref.watch(filtrosCatalogoProvider);
    final pagina = await _pedir(filtros, offset: 0);
    return ResultadosCatalogo(
      items: pagina.items,
      total: pagina.meta.total,
      hayMas: pagina.meta.hasMore,
    );
  }

  Future<Paged<Alimento>> _pedir(FiltrosCatalogo f, {required int offset}) =>
      ref
          .read(catalogoRepositoryProvider)
          .buscar(
            q: f.q,
            categoria: f.categoria,
            tipoComida: f.tipoComida,
            soloTipicos: f.soloTipicos ? true : null,
            excluir: f.excluir,
            limit: _tamanoPagina,
            offset: offset,
          );

  /// Appends the next page. A failure keeps what is on screen and is reported
  /// in [ResultadosCatalogo.falloMas]; a search that changed meanwhile wins and
  /// this answer is dropped.
  Future<void> cargarMas() async {
    final actual = state.value;
    if (actual == null || actual.cargandoMas || !actual.hayMas) return;
    final filtros = ref.read(filtrosCatalogoProvider);
    state = AsyncData(actual.copyWith(cargandoMas: true, quitarFallo: true));
    try {
      final pagina = await _pedir(filtros, offset: actual.items.length);
      if (!ref.mounted || ref.read(filtrosCatalogoProvider) != filtros) return;
      state = AsyncData(
        ResultadosCatalogo(
          items: [...actual.items, ...pagina.items],
          total: pagina.meta.total,
          hayMas: pagina.meta.hasMore,
        ),
      );
    } on Object catch (error) {
      if (!ref.mounted || ref.read(filtrosCatalogoProvider) != filtros) return;
      state = AsyncData(actual.copyWith(cargandoMas: false, falloMas: error));
    }
  }
}

final resultadosCatalogoProvider =
    AsyncNotifierProvider.autoDispose<
      ResultadosCatalogoNotifier,
      ResultadosCatalogo
    >(ResultadosCatalogoNotifier.new);

/// Header count: `meta.total` of an unfiltered search with `limit: 1`. There is
/// no count endpoint; this is the documented workaround.
final totalCatalogoProvider = FutureProvider.autoDispose<int>((ref) async {
  final pagina = await ref.watch(catalogoRepositoryProvider).buscar(limit: 1);
  return pagina.meta.total;
});

/// Search and list of the food catalogue.
///
/// Search text, category, meal time, "only typical" and exclusions live here;
/// the screen only reports the three ways out: add a food, open one, go back.
class CatalogoBusquedaScreen extends ConsumerStatefulWidget {
  const CatalogoBusquedaScreen({
    required this.onAgregar,
    required this.onAbrir,
    this.onVolver,
    super.key,
  });

  final VoidCallback onAgregar;
  final void Function(Alimento) onAbrir;

  /// Draws a back arrow in the header when given.
  final VoidCallback? onVolver;

  @override
  ConsumerState<CatalogoBusquedaScreen> createState() =>
      _CatalogoBusquedaScreenState();
}

class _CatalogoBusquedaScreenState
    extends ConsumerState<CatalogoBusquedaScreen> {
  final _controlador = TextEditingController();
  Timer? _espera;
  bool _excluirAbierto = false;

  @override
  void dispose() {
    _espera?.cancel();
    _controlador.dispose();
    super.dispose();
  }

  void _alEscribir(String texto) {
    _espera?.cancel();
    _espera = Timer(
      _esperaDeTexto,
      () => ref.read(filtrosCatalogoProvider.notifier).texto(texto),
    );
  }

  void _borrarTexto() {
    _espera?.cancel();
    _controlador.clear();
    ref.read(filtrosCatalogoProvider.notifier).texto('');
  }

  void _limpiarTodo() {
    _espera?.cancel();
    _controlador.clear();
    ref.read(filtrosCatalogoProvider.notifier).limpiarTodo();
  }

  Future<void> _recargar() async {
    ref.invalidate(totalCatalogoProvider);
    await ref
        .refresh(resultadosCatalogoProvider.future)
        .catchError(
          (Object _) =>
              const ResultadosCatalogo(items: [], total: 0, hayMas: false),
        );
  }

  @override
  Widget build(BuildContext context) {
    final filtros = ref.watch(filtrosCatalogoProvider);
    final notifier = ref.read(filtrosCatalogoProvider.notifier);
    final resultados = ref.watch(resultadosCatalogoProvider);
    final totalCatalogo = ref.watch(totalCatalogoProvider).asData?.value;
    final restricciones = ref.watch(restriccionesCatalogoProvider);
    final nombresRestriccion = {
      for (final r in restricciones.asData?.value ?? const <Restriccion>[])
        r.codigo: r.nombre,
    };

    return Material(
      type: MaterialType.transparency,
      child: Column(
        children: [
          Expanded(
            child: AppRefresh(
              onRefresh: _recargar,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: AppDimensions.screenPadding,
                children: [
                  _Cabecera(total: totalCatalogo, onVolver: widget.onVolver),
                  const SizedBox(height: AppDimensions.spaceMd),
                  _Buscador(
                    controlador: _controlador,
                    onChanged: _alEscribir,
                    onBorrar: _borrarTexto,
                  ),
                  const SizedBox(height: AppDimensions.spaceSm),
                  _ChipsCategoria(
                    elegida: filtros.categoria,
                    onElegir: notifier.categoria,
                  ),
                  const SizedBox(height: AppDimensions.spaceSm),
                  _Controles(
                    filtros: filtros,
                    excluirAbierto: _excluirAbierto,
                    onTiempo: notifier.tiempo,
                    onSoloTipicos: () =>
                        notifier.soloTipicos(valor: !filtros.soloTipicos),
                    onExcluir: () =>
                        setState(() => _excluirAbierto = !_excluirAbierto),
                  ),
                  if (_excluirAbierto)
                    _PanelExclusiones(
                      restricciones: restricciones,
                      elegidas: filtros.excluir,
                      onAlternar: notifier.alternarExclusion,
                      onReintentar: () =>
                          ref.invalidate(restriccionesCatalogoProvider),
                    ),
                  if (filtros.cantidad > 0) ...[
                    const SizedBox(height: AppDimensions.spaceMd),
                    _SeccionFiltros(
                      filtros: filtros,
                      nombres: nombresRestriccion,
                      notifier: notifier,
                    ),
                  ],
                  const SizedBox(height: AppDimensions.spaceMd),
                  _Cuerpo(
                    resultados: resultados,
                    filtros: filtros,
                    totalCatalogo: totalCatalogo,
                    onAbrir: widget.onAbrir,
                    onAgregar: widget.onAgregar,
                    onLimpiar: _limpiarTodo,
                    onReintentar: () =>
                        ref.invalidate(resultadosCatalogoProvider),
                    onCargarMas: () => ref
                        .read(resultadosCatalogoProvider.notifier)
                        .cargarMas(),
                  ),
                ],
              ),
            ),
          ),
          _BotonAgregar(onAgregar: widget.onAgregar),
        ],
      ),
    );
  }
}

/// Title, the active count under it and the optional back arrow.
class _Cabecera extends StatelessWidget {
  const _Cabecera({required this.total, required this.onVolver});

  final int? total;
  final VoidCallback? onVolver;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final conteo = total;

    return Row(
      children: [
        if (onVolver != null)
          IconButton(
            tooltip: 'Volver',
            icon: const Icon(Icons.arrow_back, size: AppDimensions.iconMd),
            onPressed: onVolver,
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Catálogo de alimentos', style: textTheme.titleLarge),
              // No count until the API answers: a missing one draws nothing.
              if (conteo != null)
                Text(
                  conteo == 1
                      ? '1 alimento activo'
                      : '$conteo alimentos activos',
                  style: textTheme.labelMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Buscador extends StatelessWidget {
  const _Buscador({
    required this.controlador,
    required this.onChanged,
    required this.onBorrar,
  });

  final TextEditingController controlador;
  final ValueChanged<String> onChanged;
  final VoidCallback onBorrar;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controlador,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Buscar por nombre…',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controlador,
          builder: (context, value, _) => value.text.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
                  key: const Key('buscador-borrar'),
                  tooltip: 'Borrar búsqueda',
                  icon: const Icon(Icons.close),
                  onPressed: onBorrar,
                ),
        ),
      ),
    );
  }
}

/// `Todas` plus the nine categories, scrolling sideways.
class _ChipsCategoria extends StatelessWidget {
  const _ChipsCategoria({required this.elegida, required this.onElegir});

  final String? elegida;
  final ValueChanged<String?> onElegir;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const Key('chips-categoria'),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('Todas'),
            selected: elegida == null,
            onSelected: (_) => onElegir(null),
          ),
          for (final (valor, etiqueta) in _categorias) ...[
            const SizedBox(width: AppDimensions.spaceSm),
            ChoiceChip(
              label: Text(etiqueta),
              selected: elegida == valor,
              onSelected: (_) => onElegir(valor),
            ),
          ],
        ],
      ),
    );
  }
}

/// Meal time, "only typical" and the exclusions.
class _Controles extends StatelessWidget {
  const _Controles({
    required this.filtros,
    required this.excluirAbierto,
    required this.onTiempo,
    required this.onSoloTipicos,
    required this.onExcluir,
  });

  final FiltrosCatalogo filtros;
  final bool excluirAbierto;
  final ValueChanged<String?> onTiempo;
  final VoidCallback onSoloTipicos;
  final VoidCallback onExcluir;

  @override
  Widget build(BuildContext context) {
    final tiempo = _etiquetaDe(_tiempos, filtros.tipoComida);
    final excluidas = filtros.excluir.length;

    return Wrap(
      spacing: AppDimensions.spaceSm,
      runSpacing: AppDimensions.spaceSm,
      children: [
        PopupMenuButton<String>(
          key: const Key('filtro-tiempo'),
          tooltip: 'Tiempo de comida',
          onSelected: onTiempo,
          itemBuilder: (_) => [
            for (final (valor, etiqueta) in _tiempos)
              PopupMenuItem(value: valor, child: Text(etiqueta)),
          ],
          child: _Pastilla(
            icono: Icons.schedule,
            etiqueta: tiempo ?? 'Tiempo de comida',
            activa: tiempo != null,
            trailing: Icons.expand_more,
          ),
        ),
        _Pastilla(
          key: const Key('filtro-solo-tipicos'),
          icono: Icons.flag,
          etiqueta: 'Sólo típicos HN',
          activa: filtros.soloTipicos,
          onTap: onSoloTipicos,
        ),
        _Pastilla(
          key: const Key('filtro-excluir'),
          icono: Icons.block,
          etiqueta: excluidas == 0 ? 'Excluir' : 'Excluir · $excluidas',
          activa: excluidas > 0,
          trailing: excluirAbierto ? Icons.expand_less : Icons.expand_more,
          onTap: onExcluir,
        ),
      ],
    );
  }
}

/// A rounded control with an icon and a label; filled when its filter is on.
class _Pastilla extends StatelessWidget {
  const _Pastilla({
    required this.icono,
    required this.etiqueta,
    required this.activa,
    this.trailing,
    this.onTap,
    super.key,
  });

  final IconData icono;
  final String etiqueta;
  final bool activa;
  final IconData? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final fondo = activa ? colors.secondaryContainer : colors.surface;
    final texto = activa ? colors.onSecondaryContainer : colors.onSurface;

    return Material(
      color: fondo,
      shape: StadiumBorder(side: BorderSide(color: colors.outlineVariant)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceMd,
            vertical: AppDimensions.spaceSm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icono, size: AppDimensions.iconSm, color: texto),
              const SizedBox(width: AppDimensions.spaceXs),
              Text(
                etiqueta,
                style: textTheme.labelLarge?.copyWith(color: texto),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppDimensions.spaceXs),
                Icon(trailing, size: AppDimensions.iconSm, color: texto),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The restrictions of `GET /restricciones`, toggled to exclude them.
class _PanelExclusiones extends StatelessWidget {
  const _PanelExclusiones({
    required this.restricciones,
    required this.elegidas,
    required this.onAlternar,
    required this.onReintentar,
  });

  final AsyncValue<List<Restriccion>> restricciones;
  final List<String> elegidas;
  final ValueChanged<String> onAlternar;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: AppDimensions.spaceSm),
      child: restricciones.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppDimensions.spaceSm),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, _) => Row(
          children: [
            Expanded(
              child: Text(
                'No pudimos cargar las restricciones.',
                style: textTheme.bodySmall?.copyWith(color: colors.error),
              ),
            ),
            TextButton(
              onPressed: onReintentar,
              child: const Text('Reintentar'),
            ),
          ],
        ),
        data: (lista) => Wrap(
          spacing: AppDimensions.spaceSm,
          runSpacing: AppDimensions.spaceSm,
          children: [
            for (final r in lista)
              FilterChip(
                key: Key('excluir-${r.codigo}'),
                label: Text(r.nombre),
                selected: elegidas.contains(r.codigo),
                onSelected: (_) => onAlternar(r.codigo),
              ),
          ],
        ),
      ),
    );
  }
}

/// `FILTROS`: every filter set as a chip with an `x`, and `Limpiar`.
class _SeccionFiltros extends StatelessWidget {
  const _SeccionFiltros({
    required this.filtros,
    required this.nombres,
    required this.notifier,
  });

  final FiltrosCatalogo filtros;
  final Map<String, String> nombres;
  final FiltrosCatalogoNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final categoria = _etiquetaDe(_categorias, filtros.categoria);
    final tiempo = _etiquetaDe(_tiempos, filtros.tipoComida);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'FILTROS',
                style: textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
            TextButton(
              key: const Key('filtros-limpiar'),
              onPressed: notifier.limpiarFiltros,
              child: const Text('Limpiar'),
            ),
          ],
        ),
        Wrap(
          spacing: AppDimensions.spaceSm,
          runSpacing: AppDimensions.spaceSm,
          children: [
            if (categoria != null)
              _ChipFiltro(
                quitarKey: const Key('quitar-categoria'),
                icono: Icons.category,
                etiqueta: categoria,
                onQuitar: () => notifier.categoria(null),
              ),
            if (tiempo != null)
              _ChipFiltro(
                quitarKey: const Key('quitar-tiempo'),
                icono: Icons.schedule,
                etiqueta: tiempo,
                onQuitar: () => notifier.tiempo(null),
              ),
            if (filtros.soloTipicos)
              _ChipFiltro(
                quitarKey: const Key('quitar-solo-tipicos'),
                icono: Icons.flag,
                etiqueta: 'Sólo típicos HN',
                onQuitar: () => notifier.soloTipicos(valor: false),
              ),
            for (final codigo in filtros.excluir)
              _ChipFiltro(
                quitarKey: Key('quitar-excluir-$codigo'),
                icono: Icons.block,
                // The name comes from the API; the code only shows while the
                // vocabulary has not arrived.
                etiqueta: nombres[codigo] ?? codigo,
                onQuitar: () => notifier.alternarExclusion(codigo),
              ),
          ],
        ),
      ],
    );
  }
}

class _ChipFiltro extends StatelessWidget {
  const _ChipFiltro({
    required this.quitarKey,
    required this.icono,
    required this.etiqueta,
    required this.onQuitar,
  });

  final Key quitarKey;
  final IconData icono;
  final String etiqueta;
  final VoidCallback onQuitar;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: ShapeDecoration(
        color: colors.secondaryContainer,
        shape: const StadiumBorder(),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: AppDimensions.spaceMd),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: AppDimensions.iconSm),
            const SizedBox(width: AppDimensions.spaceXs),
            Text(
              etiqueta,
              style: textTheme.labelLarge?.copyWith(
                color: colors.onSecondaryContainer,
              ),
            ),
            IconButton(
              key: quitarKey,
              tooltip: 'Quitar $etiqueta',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close, size: AppDimensions.iconSm),
              onPressed: onQuitar,
            ),
          ],
        ),
      ),
    );
  }
}

/// Loading, failure, empty state or the list, whichever applies.
class _Cuerpo extends StatelessWidget {
  const _Cuerpo({
    required this.resultados,
    required this.filtros,
    required this.totalCatalogo,
    required this.onAbrir,
    required this.onAgregar,
    required this.onLimpiar,
    required this.onReintentar,
    required this.onCargarMas,
  });

  final AsyncValue<ResultadosCatalogo> resultados;
  final FiltrosCatalogo filtros;
  final int? totalCatalogo;
  final void Function(Alimento) onAbrir;
  final VoidCallback onAgregar;
  final VoidCallback onLimpiar;
  final VoidCallback onReintentar;
  final VoidCallback onCargarMas;

  @override
  Widget build(BuildContext context) {
    final datos = resultados.value;

    // A new search in flight keeps the previous list on screen under a thin
    // bar; the very first load has nothing to keep, so it shows a spinner.
    if (resultados.isLoading) {
      if (datos == null) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: AppDimensions.spaceXl),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      return Column(
        children: [
          const LinearProgressIndicator(),
          const SizedBox(height: AppDimensions.spaceSm),
          _Lista(datos: datos, onAbrir: onAbrir, onCargarMas: onCargarMas),
        ],
      );
    }
    if (resultados.hasError) {
      return _FalloCarga(error: resultados.error!, onReintentar: onReintentar);
    }
    if (datos == null) return const SizedBox.shrink();
    if (datos.items.isEmpty) {
      return _SinResultados(
        filtros: filtros,
        totalCatalogo: totalCatalogo,
        onLimpiar: onLimpiar,
        onAgregar: onAgregar,
      );
    }
    return _Lista(datos: datos, onAbrir: onAbrir, onCargarMas: onCargarMas);
  }
}

class _Lista extends StatelessWidget {
  const _Lista({
    required this.datos,
    required this.onAbrir,
    required this.onCargarMas,
  });

  final ResultadosCatalogo datos;
  final void Function(Alimento) onAbrir;
  final VoidCallback onCargarMas;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final faltan = datos.total - datos.items.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              datos.total == 1 ? '1 resultado' : '${datos.total} resultados',
              style: textTheme.titleMedium,
            ),
            const SizedBox(width: AppDimensions.spaceSm),
            Text(
              'por porción',
              style: textTheme.labelMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spaceSm),
        for (final alimento in datos.items) ...[
          _FilaAlimento(alimento: alimento, onTap: () => onAbrir(alimento)),
          const SizedBox(height: AppDimensions.spaceSm),
        ],
        const SizedBox(height: AppDimensions.spaceXs),
        Text(
          'Mostrando ${datos.items.length} de ${datos.total}',
          style: textTheme.labelMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        if (datos.falloMas != null) ...[
          const SizedBox(height: AppDimensions.spaceSm),
          Text(
            datos.falloMas is ApiFailure
                ? (datos.falloMas! as ApiFailure).mensaje
                : 'No pudimos cargar más alimentos.',
            style: textTheme.bodySmall?.copyWith(color: colors.error),
            textAlign: TextAlign.center,
          ),
        ],
        if (datos.hayMas) ...[
          const SizedBox(height: AppDimensions.spaceSm),
          AppButton(
            label: 'Cargar ${faltan < 1 ? 1 : faltan} más',
            variant: AppButtonVariant.secondary,
            isLoading: datos.cargandoMas,
            onPressed: onCargarMas,
          ),
        ],
      ],
    );
  }
}

/// One food: name, category · portion, macros, energy and the typical badge.
class _FilaAlimento extends StatelessWidget {
  const _FilaAlimento({required this.alimento, required this.onTap});

  final Alimento alimento;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        side: BorderSide(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceMd),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            alimento.nombre,
                            style: textTheme.titleSmall,
                          ),
                        ),
                        if (alimento.esTipicoHn) ...[
                          const SizedBox(width: AppDimensions.spaceSm),
                          const _InsigniaTipico(),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spaceXs),
                    Text(
                      _lineaSecundaria(alimento),
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spaceXs),
                    Text(
                      'P ${_cifra(alimento.proteinaG)} · '
                      'C ${_cifra(alimento.carbohidratoG)} · '
                      'G ${_cifra(alimento.grasaG)} g',
                      style: AppTypography.data(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.spaceSm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _cifra(alimento.kcal),
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'KCAL',
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `categoria · porcionDescripcion · porcionGramos g`, skipping what is
/// missing so a gap never reads as `null`.
String _lineaSecundaria(Alimento a) => [
  _etiquetaDe(_categorias, a.categoria),
  a.porcionDescripcion,
  if (a.porcionGramos != null) '${_cifra(a.porcionGramos)} g',
].whereType<String>().where((s) => s.isNotEmpty).join(' · ');

/// A figure without a useless `.0`; a missing one draws a dash.
String _cifra(double? valor) {
  if (valor == null) return '–';
  return valor == valor.roundToDouble()
      ? valor.toInt().toString()
      : valor.toStringAsFixed(1);
}

class _InsigniaTipico extends StatelessWidget {
  const _InsigniaTipico();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: ShapeDecoration(
        color: colors.secondaryContainer,
        shape: const StadiumBorder(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceSm,
          vertical: 2,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flag, size: 12, color: colors.onSecondaryContainer),
            const SizedBox(width: 2),
            Text(
              'Típico',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// S5: nothing matches. Not an error: it names what was searched and offers the
/// way out, plus the way to add the missing food.
class _SinResultados extends StatelessWidget {
  const _SinResultados({
    required this.filtros,
    required this.totalCatalogo,
    required this.onLimpiar,
    required this.onAgregar,
  });

  final FiltrosCatalogo filtros;
  final int? totalCatalogo;
  final VoidCallback onLimpiar;
  final VoidCallback onAgregar;

  String get _cuerpo {
    final n = filtros.cantidad;
    final q = filtros.q;
    final filtrosTexto = n == 1 ? 'el filtro' : 'los $n filtros';
    final coincide = switch ((q != null, n > 0)) {
      (true, true) => 'con “$q” y $filtrosTexto',
      (true, false) => 'con “$q”',
      (false, true) => 'con $filtrosTexto',
      (false, false) => '',
    };
    final base = totalCatalogo == null
        ? ' alimentos coinciden'
        : ' de $totalCatalogo alimentos coinciden';
    final cierre = n == 0
        ? 'Probá con otro nombre.'
        : (n == 1
              ? 'Quitalo para ampliar la búsqueda.'
              : 'Quitá uno para ampliar la búsqueda.');
    return '$base${coincide.isEmpty ? '' : ' $coincide'}. $cierre';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppDimensions.spaceLg),
        Icon(
          Icons.search_off,
          size: AppDimensions.spaceXxl,
          color: colors.onSurfaceVariant,
        ),
        const SizedBox(height: AppDimensions.spaceMd),
        Text(
          'Ningún alimento con estos filtros',
          style: textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimensions.spaceSm),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '0',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.onSurface,
                ),
              ),
              TextSpan(text: _cuerpo),
            ],
          ),
          style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimensions.spaceLg),
        AppButton(
          label: 'Limpiar filtros',
          icon: Icons.filter_alt_off,
          variant: AppButtonVariant.secondary,
          onPressed: onLimpiar,
        ),
        const SizedBox(height: AppDimensions.spaceLg),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spaceMd),
            child: Row(
              children: [
                Icon(Icons.playlist_add, color: colors.onSurfaceVariant),
                const SizedBox(width: AppDimensions.spaceSm),
                Expanded(
                  child: Text(
                    '¿No está en el catálogo? Nadie más lo carga: lo agregás '
                    'vos.',
                    style: textTheme.bodySmall,
                  ),
                ),
                const SizedBox(width: AppDimensions.spaceSm),
                // The theme gives buttons an infinite minimum width, so the
                // button needs a bounded slot inside the row.
                SizedBox(
                  width: 112,
                  child: AppButton(
                    key: const Key('sin-resultados-agregar'),
                    label: 'Agregar',
                    variant: AppButtonVariant.tonal,
                    onPressed: onAgregar,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The failure of the search, with the API message when it carried one.
class _FalloCarga extends StatelessWidget {
  const _FalloCarga({required this.error, required this.onReintentar});

  final Object error;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final fallo = error;

    return Column(
      children: [
        const SizedBox(height: AppDimensions.spaceXl),
        Text(
          'No pudimos cargar los alimentos.',
          style: textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        if (fallo is ApiFailure) ...[
          const SizedBox(height: AppDimensions.spaceSm),
          Text(
            fallo.mensaje,
            style: textTheme.bodySmall?.copyWith(color: colors.error),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: AppDimensions.spaceLg),
        AppButton(
          label: 'Reintentar',
          variant: AppButtonVariant.secondary,
          onPressed: onReintentar,
        ),
      ],
    );
  }
}

/// The fixed primary action under the list.
class _BotonAgregar extends StatelessWidget {
  const _BotonAgregar({required this.onAgregar});

  final VoidCallback onAgregar;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surface,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceLg),
          child: AppButton(
            label: 'Agregar alimento',
            icon: Icons.add,
            onPressed: onAgregar,
          ),
        ),
      ),
    );
  }
}
