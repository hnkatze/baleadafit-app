import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_failure.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_refresh.dart';
import '../data/alimento.dart';
import '../data/catalogo_providers.dart';
import 'baja_alimento.dart';

/// `GET /alimentos/{id}`: the 21 fields, micronutrients included.
final alimentoDetalleProvider = FutureProvider.autoDispose
    .family<Alimento, String>(
      (ref, id) => ref.watch(catalogoRepositoryProvider).detalle(id),
    );

/// The sheet of one food (S6) and the entry to its deactivation (S7).
///
/// The screen draws its own back row. Where Editar, Ver historial and the
/// confirmed deactivation lead is up to the host: it only reports them.
class AlimentoDetalleScreen extends ConsumerWidget {
  const AlimentoDetalleScreen({
    required this.alimentoId,
    required this.onVolver,
    required this.onEditar,
    required this.onVerHistorial,
    required this.onDadoDeBaja,
    super.key,
  });

  final String alimentoId;
  final VoidCallback onVolver;
  final VoidCallback onEditar;
  final VoidCallback onVerHistorial;

  /// Asked for once the API accepted the deactivation.
  final VoidCallback onDadoDeBaja;

  Future<void> _refrescar(WidgetRef ref) async {
    try {
      final recarga = ref.refresh(alimentoDetalleProvider(alimentoId).future);
      await recarga;
    } catch (_) {
      // The failure is drawn by the error state.
    }
  }

  Future<void> _darDeBaja(
    BuildContext context,
    WidgetRef ref,
    Alimento alimento,
  ) async {
    final hecho = await confirmarBajaAlimento(context, ref, alimento: alimento);
    if (hecho) onDadoDeBaja();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alimento = ref.watch(alimentoDetalleProvider(alimentoId));
    // The vocabulary only names the labels: while it loads, or if it fails, the
    // codes of the food still draw.
    final restricciones =
        ref.watch(restriccionesCatalogoProvider).asData?.value ?? const [];
    final nombres = {for (final r in restricciones) r.codigo: r.nombre};

    return Material(
      type: MaterialType.transparency,
      child: AppRefresh(
        onRefresh: () => _refrescar(ref),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppDimensions.screenPadding,
          children: [
            _Cabecera(onVolver: onVolver, onVerHistorial: onVerHistorial),
            const SizedBox(height: AppDimensions.spaceMd),
            alimento.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: AppDimensions.spaceXl),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => _FalloCarga(
                error: error,
                onReintentar: () =>
                    ref.invalidate(alimentoDetalleProvider(alimentoId)),
              ),
              data: (a) => _Contenido(
                alimento: a,
                nombres: nombres,
                onEditar: onEditar,
                onVerHistorial: onVerHistorial,
                onDarDeBaja: () => _darDeBaja(context, ref, a),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Cabecera extends StatelessWidget {
  const _Cabecera({required this.onVolver, required this.onVerHistorial});

  final VoidCallback onVolver;
  final VoidCallback onVerHistorial;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Volver',
          onPressed: onVolver,
          icon: const Icon(Icons.arrow_back),
        ),
        Expanded(
          child: Text(
            'Alimento',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        IconButton(
          tooltip: 'Ver historial',
          onPressed: onVerHistorial,
          icon: const Icon(Icons.history),
        ),
      ],
    );
  }
}

class _FalloCarga extends StatelessWidget {
  const _FalloCarga({required this.error, required this.onReintentar});

  final Object error;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    final mensaje = error is ApiFailure
        ? (error as ApiFailure).mensaje
        : 'No pudimos cargar el alimento.';

    return Column(
      children: [
        Text(mensaje, textAlign: TextAlign.center),
        const SizedBox(height: AppDimensions.spaceMd),
        AppButton(
          label: 'Reintentar',
          variant: AppButtonVariant.tonal,
          onPressed: onReintentar,
          expand: false,
        ),
      ],
    );
  }
}

const _categorias = {
  'PLATO_TIPICO': 'Plato típico',
  'PROTEINA': 'Proteína',
  'CEREAL_TUBERCULO': 'Cereal y tubérculo',
  'LEGUMINOSA': 'Leguminosa',
  'LACTEO': 'Lácteo',
  'FRUTA': 'Fruta',
  'VERDURA': 'Verdura',
  'GRASA': 'Grasa',
  'BEBIDA': 'Bebida',
};

const _tiempos = {
  'DESAYUNO': ('Desayuno', Icons.free_breakfast_outlined),
  'MERIENDA_AM': ('Merienda AM', Icons.bakery_dining_outlined),
  'ALMUERZO': ('Almuerzo', Icons.lunch_dining_outlined),
  'MERIENDA_PM': ('Merienda PM', Icons.cookie_outlined),
  'CENA': ('Cena', Icons.dinner_dining_outlined),
};

/// `31`, not `31.0`; one decimal otherwise.
String _numero(double valor) => valor == valor.roundToDouble()
    ? valor.round().toString()
    : valor.toStringAsFixed(1);

String _con(double? valor, String unidad) =>
    valor == null ? '—' : '${_numero(valor)} $unidad';

class _Contenido extends StatelessWidget {
  const _Contenido({
    required this.alimento,
    required this.nombres,
    required this.onEditar,
    required this.onVerHistorial,
    required this.onDarDeBaja,
  });

  final Alimento alimento;
  final Map<String, String> nombres;
  final VoidCallback onEditar;
  final VoidCallback onVerHistorial;
  final VoidCallback onDarDeBaja;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final a = alimento;
    final categoria = _categorias[a.categoria] ?? a.categoria;
    final porcion = [
      ?a.porcionDescripcion,
      if (a.porcionGramos != null) '${_numero(a.porcionGramos!)} g',
    ].join(' · ');
    final tiempos = a.tiposComida.map((t) => _tiempos[t]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(a.nombre, style: textTheme.headlineMedium),
        const SizedBox(height: AppDimensions.spaceSm),
        if (categoria != null)
          _ConIcono(icono: Icons.category_outlined, texto: categoria),
        if (porcion.isNotEmpty)
          _ConIcono(icono: Icons.scale_outlined, texto: porcion),
        const SizedBox(height: AppDimensions.spaceMd),
        _Bloque(
          titulo: 'Por porción',
          icono: Icons.local_fire_department_outlined,
          hijos: [
            Text(
              a.kcal == null ? '—' : '${_numero(a.kcal!)} kcal',
              style: textTheme.headlineLarge,
            ),
            const SizedBox(height: AppDimensions.spaceSm),
            Row(
              children: [
                _Macro(rotulo: 'Proteína', valor: _con(a.proteinaG, 'g')),
                _Macro(rotulo: 'Carbos', valor: _con(a.carbohidratoG, 'g')),
                _Macro(rotulo: 'Grasa', valor: _con(a.grasaG, 'g')),
                _Macro(rotulo: 'Fibra', valor: _con(a.fibraG, 'g')),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spaceMd),
        _Bloque(
          titulo: 'Micronutrientes',
          icono: Icons.science_outlined,
          hijos: [
            _Fila(
              rotulo: 'Sodio',
              marca: 'Estimado',
              valor: a.sodioMg == null ? '—' : '~${_numero(a.sodioMg!)} mg',
            ),
            _Fila(rotulo: 'Potasio', valor: _con(a.potasioMg, 'mg')),
            _Fila(rotulo: 'Fósforo', valor: _con(a.fosforoMg, 'mg')),
            _Fila(rotulo: 'Azúcares', valor: _con(a.azucaresG, 'g')),
            _Fila(rotulo: 'Grasas saturadas', valor: _con(a.grasasSatG, 'g')),
            // A null index is "sin dato", never 0.
            _Fila(
              rotulo: 'Índice glucémico',
              valor: a.indiceGlucemico == null
                  ? null
                  : _numero(a.indiceGlucemico!),
            ),
            const SizedBox(height: AppDimensions.spaceSm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 18, color: colors.outline),
                const SizedBox(width: AppDimensions.spaceSm),
                Expanded(
                  child: Text(
                    'El sodio es aproximado: verificar con INCAP. El índice '
                    'glucémico no aplica a alimentos sin carbohidratos.',
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spaceMd),
        _Bloque(
          titulo: 'Contiene',
          icono: Icons.warning_amber_outlined,
          hijos: [
            if (a.contiene.isEmpty)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.verified_outlined,
                    size: 18,
                    color: colors.primary,
                  ),
                  const SizedBox(width: AppDimensions.spaceSm),
                  Expanded(
                    child: Text(
                      'Sin etiquetas de restricción. Aparece aunque se excluya '
                      'lactosa o gluten.',
                      style: textTheme.bodyMedium,
                    ),
                  ),
                ],
              )
            else
              Wrap(
                spacing: AppDimensions.spaceSm,
                runSpacing: AppDimensions.spaceSm,
                children: [
                  for (final codigo in a.contiene)
                    // An unknown code still draws as itself.
                    Chip(label: Text(nombres[codigo] ?? codigo)),
                ],
              ),
          ],
        ),
        const SizedBox(height: AppDimensions.spaceMd),
        _Bloque(
          titulo: 'Tiempos de comida',
          icono: Icons.schedule_outlined,
          hijos: [
            Wrap(
              spacing: AppDimensions.spaceSm,
              runSpacing: AppDimensions.spaceSm,
              children: [
                for (final (i, t) in tiempos.indexed)
                  Chip(
                    avatar: Icon(t?.$2 ?? Icons.schedule_outlined, size: 18),
                    label: Text(t?.$1 ?? a.tiposComida[i]),
                  ),
              ],
            ),
          ],
        ),
        if (a.fuente != null) ...[
          const SizedBox(height: AppDimensions.spaceMd),
          _ConIcono(
            icono: Icons.menu_book_outlined,
            texto: 'Fuente: ${a.fuente}',
          ),
        ],
        const SizedBox(height: AppDimensions.spaceLg),
        Text(
          'DAR DE BAJA',
          style: textTheme.labelSmall?.copyWith(color: colors.error),
        ),
        const SizedBox(height: AppDimensions.spaceXs),
        Text(
          'Sale del catálogo y de las búsquedas. No se borra: su historial de '
          'versiones se conserva.',
          style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: AppDimensions.spaceSm),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: colors.error,
              foregroundColor: colors.onError,
            ),
            onPressed: onDarDeBaja,
            icon: const Icon(Icons.visibility_off_outlined),
            label: const Text('Dar de baja'),
          ),
        ),
        const SizedBox(height: AppDimensions.spaceMd),
        AppButton(
          label: 'Ver historial',
          icon: Icons.history,
          variant: AppButtonVariant.secondary,
          onPressed: onVerHistorial,
        ),
        const SizedBox(height: AppDimensions.spaceSm),
        AppButton(
          label: 'Editar',
          icon: Icons.edit_outlined,
          onPressed: onEditar,
        ),
      ],
    );
  }
}

class _ConIcono extends StatelessWidget {
  const _ConIcono({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spaceXs),
      child: Row(
        children: [
          Icon(icono, size: 18, color: colors.onSurfaceVariant),
          const SizedBox(width: AppDimensions.spaceSm),
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

class _Bloque extends StatelessWidget {
  const _Bloque({
    required this.titulo,
    required this.icono,
    required this.hijos,
  });

  final String titulo;
  final IconData icono;
  final List<Widget> hijos;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spaceMd),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, size: 18, color: colors.primary),
              const SizedBox(width: AppDimensions.spaceSm),
              Text(titulo, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          ...hijos,
        ],
      ),
    );
  }
}

class _Macro extends StatelessWidget {
  const _Macro({required this.rotulo, required this.valor});

  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(rotulo, style: textTheme.labelSmall),
          Text(valor, style: textTheme.titleMedium),
        ],
      ),
    );
  }
}

/// One micronutrient. A null [valor] reads as `Sin dato` with a `remove` icon.
class _Fila extends StatelessWidget {
  const _Fila({required this.rotulo, required this.valor, this.marca});

  final String rotulo;
  final String? valor;
  final String? marca;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceXs),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: AppDimensions.spaceSm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(rotulo, style: textTheme.bodyMedium),
                if (marca != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline, size: 14, color: colors.outline),
                      const SizedBox(width: 2),
                      Text(
                        marca!,
                        style: textTheme.labelSmall?.copyWith(
                          color: colors.outline,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          if (valor == null) ...[
            Icon(Icons.remove, size: 16, color: colors.outline),
            const SizedBox(width: 2),
            Text(
              'Sin dato',
              style: textTheme.bodyMedium?.copyWith(color: colors.outline),
            ),
          ] else
            Text(valor!, style: textTheme.titleMedium),
        ],
      ),
    );
  }
}
