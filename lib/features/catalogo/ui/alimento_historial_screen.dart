import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/fechas.dart';
import '../../../core/network/api_failure.dart';
import '../../../core/network/paged.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../core/format/numeros.dart';
import '../data/alimento_version.dart';
import '../data/catalogo_providers.dart';

/// First page of the version history of a food (`GET /alimentos/{id}/versiones`,
/// newest first). The next pages are fetched by the screen on demand.
///
/// No silent retry: the failure state offers an explicit `Reintentar`.
final alimentoVersionesProvider = FutureProvider.autoDispose
    .family<Paged<AlimentoVersion>, String>(
      (ref, alimentoId) =>
          ref.watch(catalogoRepositoryProvider).versiones(alimentoId),
      retry: (_, _) => null,
    );

const double _separacion = 12;

/// S9: the version history of a food, read-only. The comparison is visual:
/// no diff is computed.
class AlimentoHistorialScreen extends ConsumerStatefulWidget {
  const AlimentoHistorialScreen({
    required this.alimentoId,
    required this.alimentoNombre,
    required this.onVolver,
    super.key,
  });

  final String alimentoId;
  final String alimentoNombre;
  final VoidCallback onVolver;

  @override
  ConsumerState<AlimentoHistorialScreen> createState() =>
      _AlimentoHistorialScreenState();
}

class _AlimentoHistorialScreenState
    extends ConsumerState<AlimentoHistorialScreen> {
  /// Pages after the first one, already fetched.
  final List<AlimentoVersion> _siguientes = [];
  PageMeta? _metaUltima;
  bool _cargandoMas = false;
  bool _falloMas = false;

  void _reiniciar() {
    _siguientes.clear();
    _metaUltima = null;
    _falloMas = false;
    ref.invalidate(alimentoVersionesProvider(widget.alimentoId));
  }

  Future<void> _cargarMas(Paged<AlimentoVersion> primera) async {
    final cargadas = primera.items.length + _siguientes.length;
    setState(() {
      _cargandoMas = true;
      _falloMas = false;
    });
    try {
      final pagina = await ref
          .read(catalogoRepositoryProvider)
          .versiones(widget.alimentoId, offset: cargadas);
      if (!mounted) return;
      setState(() {
        _siguientes.addAll(pagina.items);
        _metaUltima = pagina.meta;
        _cargandoMas = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _cargandoMas = false;
        _falloMas = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final historial = ref.watch(alimentoVersionesProvider(widget.alimentoId));

    return Material(
      color: colors.surface,
      child: Column(
        children: [
          _Cabecera(
            nombre: widget.alimentoNombre,
            total: historial.asData?.value.meta.total,
            onVolver: widget.onVolver,
          ),
          Expanded(
            child: historial.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  _Fallo(error: error, onReintentar: _reiniciar),
              data: _contenido,
            ),
          ),
        ],
      ),
    );
  }

  Widget _contenido(Paged<AlimentoVersion> primera) {
    final versiones = [...primera.items, ..._siguientes];
    if (versiones.isEmpty) {
      return Center(
        child: Text(
          'Sin versiones registradas.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    final meta = _metaUltima ?? primera.meta;
    // Decision: the explanatory block shows only when the food has exactly one
    // version in total (the spec leaves the trigger open).
    final soloUna = primera.meta.total == 1 && versiones.length == 1;

    return ListView(
      padding: AppDimensions.screenPadding,
      children: [
        const _Aviso(),
        for (final version in versiones) ...[
          const SizedBox(height: _separacion),
          _TarjetaVersion(version: version),
        ],
        if (meta.hasMore) ...[
          const SizedBox(height: _separacion),
          if (_falloMas)
            Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.spaceSm),
              child: Text(
                'No pudimos cargar más versiones.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          AppButton(
            label: 'Cargar más versiones',
            variant: AppButtonVariant.secondary,
            isLoading: _cargandoMas,
            onPressed: _cargandoMas ? null : () => _cargarMas(primera),
          ),
        ],
        if (soloUna) ...[
          const SizedBox(height: _separacion),
          const _EstadoUnaVersion(),
        ],
      ],
    );
  }
}

class _Cabecera extends StatelessWidget {
  const _Cabecera({
    required this.nombre,
    required this.total,
    required this.onVolver,
  });

  final String nombre;
  final int? total;
  final VoidCallback onVolver;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final n = total;
    final subtitulo = n == null
        ? nombre
        : '$nombre · $n ${n == 1 ? 'versión' : 'versiones'}';

    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.only(
        left: AppDimensions.spaceXs,
        right: AppDimensions.spaceMd,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              tooltip: 'Volver',
              icon: const Icon(Icons.arrow_back, size: AppDimensions.iconMd),
              onPressed: onVolver,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Historial de versiones', style: textTheme.titleLarge),
                  Text(
                    subtitulo,
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceMd,
        vertical: _separacion,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: colors.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Cada cambio de nutrientes guarda una versión. Es la prueba de '
              'qué valores tenía el alimento cuando se armó un plan. Valores '
              'por porción.',
              style: textTheme.titleSmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// `12 nov 2026`: the app's `diaYMes` plus the year, from the instant in the
/// device's time zone.
String _diaConAnio(DateTime instante) =>
    '${diaYMes(instante)} ${instante.toLocal().year}';

String _rango(AlimentoVersion version) {
  final desde = version.vigenteDesde;
  final hasta = version.vigenteHasta;
  final fin = hasta == null ? 'hoy' : _diaConAnio(hasta);
  return desde == null ? '→ $fin' : '${_diaConAnio(desde)} → $fin';
}

class _TarjetaVersion extends StatelessWidget {
  const _TarjetaVersion({required this.version});

  final AlimentoVersion version;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final tabla = version.tabla;

    String? valor(double? v, {String unidad = ' g', String prefijo = ''}) =>
        v == null ? null : '$prefijo${formatearNumero(v)}$unidad';

    final celdas = <(String, String?)>[
      ('KCAL', valor(version.kcal, unidad: '')),
      ('PROT', valor(version.proteinaG)),
      ('CARB', valor(version.carbohidratoG)),
      ('GRASA', valor(version.grasaG)),
      // Sodium is an estimate, drawn with `~` as in the detail.
      ('SODIO', valor(version.sodioMg, unidad: ' mg', prefijo: '~')),
      ('FIBRA', valor(version.fibraG)),
      ('SAT', valor(version.grasasSatG)),
      ('IG', valor(version.indiceGlucemico, unidad: '')),
    ];

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceMd),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: version.vigente ? colors.primary : colors.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                version.vigente ? Icons.check : Icons.history,
                size: AppDimensions.iconSm,
                color: colors.primary,
              ),
              const SizedBox(width: AppDimensions.spaceSm),
              Expanded(
                child: Text(
                  'Versión ${version.version}',
                  style: textTheme.titleMedium,
                ),
              ),
              if (version.vigente)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spaceSm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.secondaryContainer,
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusFull,
                    ),
                  ),
                  child: Text(
                    'VIGENTE',
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.onSecondaryContainer,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          if (tabla != null && tabla.isNotEmpty)
            _LineaMeta(icono: Icons.table_chart, texto: 'Tabla: $tabla'),
          _LineaMeta(icono: Icons.date_range, texto: _rango(version)),
          const SizedBox(height: _separacion),
          Wrap(
            spacing: _separacion,
            runSpacing: _separacion,
            children: [
              for (final (etiqueta, texto) in celdas)
                _Celda(etiqueta: etiqueta, valor: texto),
            ],
          ),
        ],
      ),
    );
  }
}

class _LineaMeta extends StatelessWidget {
  const _LineaMeta({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spaceXs),
      child: Row(
        children: [
          Icon(icono, size: 16, color: colors.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              texto,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _Celda extends StatelessWidget {
  const _Celda({required this.etiqueta, required this.valor});

  final String etiqueta;
  final String? valor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final dato = valor;

    return SizedBox(
      width: 72,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            etiqueta,
            style: textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          Text(
            dato ?? 'sin dato',
            style: dato == null
                ? textTheme.bodySmall?.copyWith(color: colors.outline)
                : textTheme.titleSmall,
          ),
        ],
      ),
    );
  }
}

class _EstadoUnaVersion extends StatelessWidget {
  const _EstadoUnaVersion();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        Icon(Icons.fiber_new, size: 32, color: colors.primary),
        const SizedBox(height: AppDimensions.spaceSm),
        Text('Estado: una sola versión', style: textTheme.titleMedium),
        const SizedBox(height: AppDimensions.spaceXs),
        Text(
          'Un alimento recién agregado muestra sólo la Versión 1, vigente, '
          'con “→ hoy”. Sin línea de tiempo ni comparación.',
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _Fallo extends StatelessWidget {
  const _Fallo({required this.error, required this.onReintentar});

  final Object error;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final fallo = error;
    final detalle = fallo is ApiFailure
        ? fallo.mensaje
        : 'Revisá tu conexión e intentá de nuevo.';

    return Padding(
      padding: AppDimensions.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('No pudimos cargar el historial.', style: textTheme.titleMedium),
          const SizedBox(height: AppDimensions.spaceXs),
          Text(detalle, style: textTheme.bodyMedium),
          const SizedBox(height: AppDimensions.spaceMd),
          AppButton(
            label: 'Reintentar',
            icon: Icons.refresh,
            variant: AppButtonVariant.secondary,
            onPressed: onReintentar,
          ),
        ],
      ),
    );
  }
}
