import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_failure.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_search_select_field.dart';
import '../data/alimento_catalogo.dart';
import '../data/plan.dart';
import '../data/planes_formato.dart';
import '../data/planes_providers.dart';
import '../data/planes_repository.dart';

/// Limits of the list a meal time carries, as `ReemplazarItemsDto` declares
/// them: at most twelve foods, and no minimum, so an empty time is valid.
const maximoAlimentos = 12;

/// Portions run from 0.25 to 6 and the control moves in steps of 0.25, the
/// granularity the contract recommends.
const porcionMinima = 0.25;
const porcionMaxima = 6.0;
const pasoDePorcion = 0.25;

/// One food of the list being edited: what the row draws and what the `PUT`
/// carries back.
class _ItemEditable {
  _ItemEditable({
    required this.alimentoId,
    required this.nombre,
    required this.porcionDescripcion,
    required this.kcal,
    required this.porciones,
  });

  final String alimentoId;
  final String nombre;
  final String porcionDescripcion;

  /// kcal **per portion**: drawn as is, never multiplied.
  final double? kcal;
  double porciones;
}

/// Edits one meal time of one day of a `BORRADOR` and saves the **whole** list
/// with `PUT /planes/{id}/tiempos/{dia}/{tipo}/items`.
///
/// The list starts from the items the plan already has. Saving sends the final
/// state, not the change, so removing a food is simply not sending it, and the
/// contract allows `items: []`: an empty time saves without any invented
/// validation. The plan the API answers with replaces what the detail shows.
///
/// The screen never computes kcal: the row of a food shows `alimento.kcal`, per
/// portion, and the totals of the time are not drawn here at all.
class EditarTiempoScreen extends ConsumerStatefulWidget {
  const EditarTiempoScreen({
    required this.planId,
    required this.dia,
    required this.tipo,
    required this.onCerrar,
    required this.onGuardado,
    super.key,
  });

  final String planId;
  final DiaSemana dia;
  final TipoComida tipo;

  /// Closes without saving: whatever was edited is dropped.
  final VoidCallback onCerrar;

  /// Called with the plan the `PUT` answered (200), which is the new truth.
  final VoidCallback onGuardado;

  @override
  ConsumerState<EditarTiempoScreen> createState() => _EditarTiempoScreenState();
}

class _EditarTiempoScreenState extends ConsumerState<EditarTiempoScreen> {
  final List<_ItemEditable> _items = [];

  /// The meal time as the plan had it when the screen opened: its `pctKcal` and
  /// `kcalMeta` label the summary. Kept after the first read so a later refresh
  /// of the plan never rewrites what is being edited.
  TiempoComida? _tiempo;

  bool _sembrado = false;
  bool _guardando = false;

  /// What the API answered when the save failed.
  ApiFailure? _fallo;

  @override
  void initState() {
    super.initState();
    // The detail that opened this screen already loaded the plan, so the very
    // first read usually has it. A deep link straight here does not: the
    // listener below seeds the list when the plan arrives.
    final plan = ref.read(planDetalleProvider(widget.planId)).asData?.value;
    if (plan != null) _sembrar(plan);
    ref.listenManual(planDetalleProvider(widget.planId), (_, next) {
      final plan = next.asData?.value;
      if (plan == null || _sembrado) return;
      setState(() => _sembrar(plan));
    });
  }

  /// The meal time of this day, from the shape the detail draws (`dias`).
  TiempoComida? _buscar(PlanDetalle plan) {
    for (final dia in plan.dias) {
      if (dia.dia != widget.dia) continue;
      for (final tiempo in dia.tiempos) {
        if (tiempo.tipo == widget.tipo) return tiempo;
      }
    }
    return null;
  }

  /// Copies the current items into the list being edited. Runs once: after that
  /// the list belongs to the user.
  void _sembrar(PlanDetalle plan) {
    final tiempo = _buscar(plan);
    if (tiempo == null) {
      // The plan no longer carries this time: mark it seeded so the screen can
      // say so instead of spinning for ever.
      _sembrado = true;
      return;
    }
    _tiempo = tiempo;
    _items
      ..clear()
      ..addAll([
        for (final item in tiempo.items)
          _ItemEditable(
            alimentoId: item.alimentoId,
            nombre: item.alimento?.nombre ?? '',
            porcionDescripcion: item.alimento?.porcionDescripcion ?? '',
            kcal: item.alimento?.kcal,
            porciones: item.porciones,
          ),
      ]);
    _sembrado = true;
  }

  /// One step of the portion control, rounded to the two decimals a quarter
  /// keeps, so `1 + 0.25 + 0.25` is `1.5` and not `1.5000000000000002`.
  double _paso(double actual, int pasos) =>
      double.parse((actual + pasos * pasoDePorcion).toStringAsFixed(2));

  void _sumar(_ItemEditable item) {
    if (item.porciones >= porcionMaxima - 1e-9) return;
    setState(() => item.porciones = _paso(item.porciones, 1));
  }

  void _restar(_ItemEditable item) {
    if (item.porciones <= porcionMinima + 1e-9) return;
    setState(() => item.porciones = _paso(item.porciones, -1));
  }

  void _quitar(_ItemEditable item) => setState(() {
    _items.remove(item);
    _fallo = null;
  });

  void _agregar(AlimentoCatalogo alimento) {
    if (_items.length >= maximoAlimentos) return;
    setState(() {
      _items.add(
        _ItemEditable(
          alimentoId: alimento.id,
          nombre: alimento.nombre,
          porcionDescripcion: alimento.porcionDescripcion,
          kcal: alimento.kcal,
          porciones: 1,
        ),
      );
      _fallo = null;
    });
  }

  Future<void> _guardar() async {
    if (_guardando) return;
    setState(() {
      _guardando = true;
      _fallo = null;
    });

    try {
      await ref
          .read(planesRepositoryProvider)
          .reemplazarItems(
            widget.planId,
            dia: widget.dia,
            tipo: widget.tipo,
            // The whole list, always: `[]` included, which the contract allows.
            items: [
              for (final item in _items)
                ItemReemplazo(
                  alimentoId: item.alimentoId,
                  porciones: item.porciones,
                ),
            ],
          );
      if (!mounted) return;
      // The response only proves the write happened; the detail re-reads.
      ref.invalidate(planDetalleProvider(widget.planId));
      widget.onGuardado();
    } on ApiFailure catch (fallo) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _fallo = fallo;
      });
    } catch (_) {
      // Anything that is not an API failure must still free the form: a stuck
      // spinner leaves no way to retry and no message to report.
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _fallo = const ApiFailure(
          mensaje: 'No pudimos guardar el tiempo. Probá de nuevo.',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final colores = Theme.of(context).colorScheme;
    final carga = ref.watch(planDetalleProvider(widget.planId));
    final tiempo = _tiempo;
    final editable = !_guardando;

    return PopScope(
      canPop: editable,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Cerrar sin guardar',
            icon: const Icon(Icons.close),
            onPressed: editable ? widget.onCerrar : null,
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Editar tiempo'),
              Text(
                '${widget.tipo.etiqueta} · ${widget.dia.etiqueta}',
                style: texto.labelSmall?.copyWith(
                  color: colores.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        body: tiempo == null
            ? _SinTiempo(
                carga: carga,
                onReintentar: () =>
                    ref.invalidate(planDetalleProvider(widget.planId)),
                onVolver: widget.onCerrar,
              )
            : ListView(
                padding: AppDimensions.screenPadding,
                children: [
                  const _AvisoReemplazo(),
                  const SizedBox(height: AppDimensions.spaceLg),
                  _Resumen(tiempo: tiempo, cantidad: _items.length),
                  const SizedBox(height: AppDimensions.spaceMd),
                  if (_items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppDimensions.spaceSm,
                      ),
                      child: Text(
                        'Sin alimentos',
                        key: const Key('sin-alimentos'),
                        style: texto.bodySmall?.copyWith(
                          color: colores.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    for (final item in _items) ...[
                      _FilaEditable(
                        item: item,
                        habilitado: editable,
                        onSumar: () => _sumar(item),
                        onRestar: () => _restar(item),
                        onQuitar: () => _quitar(item),
                      ),
                      const SizedBox(height: AppDimensions.spaceSm),
                    ],
                  const SizedBox(height: AppDimensions.spaceMd),
                  _AgregarAlimento(
                    habilitado: editable && _items.length < maximoAlimentos,
                    onElegido: _agregar,
                  ),
                ],
              ),
        bottomNavigationBar: tiempo == null
            ? null
            : _BarraGuardar(
                fallo: _fallo,
                guardando: _guardando,
                onGuardar: _guardar,
                onCerrar: widget.onCerrar,
              ),
      ),
    );
  }
}

/// `35% del día · meta 525 kcal` and `3 de 12 alimentos`. The percentage is
/// `pctKcal`, a fraction, and the kcal is `kcalMeta`: a goal, not what was
/// eaten.
class _Resumen extends StatelessWidget {
  const _Resumen({required this.tiempo, required this.cantidad});

  final TiempoComida tiempo;
  final int cantidad;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final colores = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: Text(
            '${formatearFraccion(tiempo.pctKcal)} del día · '
            'meta ${formatearKcal(tiempo.kcalMeta)} kcal',
            key: const Key('resumen-tiempo'),
            style: AppTypography.data(context)
                .copyWith(color: colores.onSurfaceVariant),
          ),
        ),
        Text(
          '$cantidad de $maximoAlimentos alimentos',
          key: const Key('cantidad-alimentos'),
          style: texto.labelSmall?.copyWith(color: colores.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// One food: its name, `1 taza · 205 kcal por porción`, the portion control and
/// the `close` that takes it off the list.
class _FilaEditable extends StatelessWidget {
  const _FilaEditable({
    required this.item,
    required this.habilitado,
    required this.onSumar,
    required this.onRestar,
    required this.onQuitar,
  });

  final _ItemEditable item;
  final bool habilitado;
  final VoidCallback onSumar;
  final VoidCallback onRestar;
  final VoidCallback onQuitar;

  /// `1 taza · 205 kcal por porción`. The kcal is per portion and says so: it is
  /// never multiplied by [porciones].
  String? get _detalle {
    final kcal = item.kcal;
    final partes = [
      if (item.porcionDescripcion.isNotEmpty) item.porcionDescripcion,
      if (kcal != null) '${formatearKcal(kcal)} kcal',
    ];
    if (partes.isEmpty) return null;
    return [partes.join(' · '), if (kcal != null) 'por porción'].join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final colores = Theme.of(context).colorScheme;
    final detalle = _detalle;
    final puedeRestar = habilitado && item.porciones > porcionMinima + 1e-9;
    final puedeSumar = habilitado && item.porciones < porcionMaxima - 1e-9;

    return AppCard(
      key: Key('item-${item.alimentoId}'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceMd,
        vertical: AppDimensions.spaceMd - AppDimensions.spaceXs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.nombre, style: texto.titleMedium),
                if (detalle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      detalle,
                      style: texto.titleSmall?.copyWith(
                        color: colores.onSurfaceVariant,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.spaceMd - AppDimensions.spaceXs),
          _BotonPorcion(
            botonKey: Key('menos-${item.alimentoId}'),
            tooltip: 'Menos porciones',
            icono: Icons.remove,
            onPressed: puedeRestar ? onRestar : null,
          ),
          const SizedBox(width: _espacioControl),
          // A fixed slot wide enough for `0.25`: shrinking the text to fit the
          // 28 px of the artboard made a decimal read smaller than a whole
          // number, which looks like a different size, not a different value.
          SizedBox(
            width: _anchoValor,
            child: Text(
              formatearPorciones(item.porciones),
              key: Key('porciones-${item.alimentoId}'),
              textAlign: TextAlign.center,
              maxLines: 1,
              softWrap: false,
              style: AppTypography.data(
                context,
              ).copyWith(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: _espacioControl),
          _BotonPorcion(
            botonKey: Key('mas-${item.alimentoId}'),
            tooltip: 'Más porciones',
            icono: Icons.add,
            onPressed: puedeSumar ? onSumar : null,
          ),
          const SizedBox(width: AppDimensions.spaceMd - AppDimensions.spaceXs),
          IconButton(
            key: Key('quitar-${item.alimentoId}'),
            tooltip: 'Quitar alimento',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 24, height: 24),
            visualDensity: VisualDensity.compact,
            iconSize: 20,
            color: colores.outline,
            icon: const Icon(Icons.close),
            // No growing halo: a soft tint while pressed is feedback enough on a
            // button this small.
            style: ButtonStyle(
              splashFactory: NoSplash.splashFactory,
              overlayColor: WidgetStateProperty.resolveWith(
                (estados) => estados.contains(WidgetState.pressed)
                    ? colores.onSurfaceVariant.withValues(alpha: 0.10)
                    : Colors.transparent,
              ),
            ),
            onPressed: habilitado ? onQuitar : null,
          ),
        ],
      ),
    );
  }
}

const double _ladoControl = 28;
const double _espacioControl = 6;

/// Wide enough for the four characters of `0.25` at 13 px of the mono font, so
/// every portion value draws at the same size and only the digits change.
const double _anchoValor = 34;

/// A `-` or `+` of the portion control: a 28 × 28 square with a 1 px
/// `outlineVariant` border and radius 8. Disabled it drops to the disabled
/// icon colour and a softer border, so a limit reads as a limit.
class _BotonPorcion extends StatelessWidget {
  const _BotonPorcion({
    required this.botonKey,
    required this.tooltip,
    required this.icono,
    required this.onPressed,
  });

  /// Lands on the `IconButton` itself, so `Key('menos-<id>')` finds the button.
  final Key botonKey;
  final String tooltip;
  final IconData icono;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final habilitado = onPressed != null;

    // The border and the icon keep the 28 px the artboard draws, but the tap
    // target around them is 40: a 28 px target is below what a finger hits
    // reliably on a phone.
    return SizedBox.square(
      dimension: _ladoControl + 12,
      child: IconButton(
        key: botonKey,
        tooltip: tooltip,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        style: ButtonStyle(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          // The expanding halo reads as a bubble growing inside a 28 px square:
          // a soft tint while pressed is feedback enough.
          splashFactory: NoSplash.splashFactory,
          overlayColor: WidgetStateProperty.resolveWith(
            (estados) => estados.contains(WidgetState.pressed)
                ? colores.onSurfaceVariant.withValues(alpha: 0.10)
                : Colors.transparent,
          ),
        ),
        icon: Container(
          width: _ladoControl,
          height: _ladoControl,
          decoration: BoxDecoration(
            border: Border.all(
              color: habilitado
                  ? colores.outlineVariant
                  : colores.outlineVariant.withValues(alpha: 0.5),
            ),
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          ),
          child: Icon(
            icono,
            size: 16,
            color: habilitado
                ? colores.onSurfaceVariant
                : colores.onSurface.withValues(alpha: 0.38),
          ),
        ),
      ),
    );
  }
}

/// The notice that saving replaces the whole list: `surfaceContainerLow`
/// block, radius 12, an `info` icon and the copy.
class _AvisoReemplazo extends StatelessWidget {
  const _AvisoReemplazo();

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final colores = Theme.of(context).colorScheme;

    return Container(
      key: const Key('aviso-reemplazo'),
      padding: const EdgeInsets.all(AppDimensions.spaceMd),
      decoration: BoxDecoration(
        color: colores.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 20, color: colores.onSurfaceVariant),
          const SizedBox(width: AppDimensions.spaceMd - AppDimensions.spaceXs),
          Expanded(
            child: Text(
              'Guardar reemplaza la lista completa de este tiempo. Lo '
              'que no esté acá se elimina; no se agrega sobre lo '
              'anterior.',
              style: texto.bodySmall?.copyWith(color: colores.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

/// The food picker: the same search select the rest of the app uses, against
/// `GET /alimentos`. With twelve foods on the list there is no room for one
/// more, so the field stops answering instead of failing at save time.
class _AgregarAlimento extends ConsumerWidget {
  const _AgregarAlimento({required this.habilitado, required this.onElegido});

  final bool habilitado;
  final ValueChanged<AlimentoCatalogo> onElegido;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final texto = Theme.of(context).textTheme;
    final colores = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IgnorePointer(
          ignoring: !habilitado,
          child: Opacity(
            opacity: habilitado ? 1 : 0.5,
            child: AppSearchSelectField<AlimentoCatalogo>(
              key: const Key('agregar-alimento'),
              label: 'Agregar alimento',
              hint: 'Buscar alimento',
              buscar: (consulta) async =>
                  (await ref.read(alimentosRepositoryProvider).buscar(consulta))
                      .items,
              etiquetaDe: (alimento) => alimento.nombre,
              onElegido: onElegido,
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.spaceXs),
        Text(
          'Usa el mismo buscador del catálogo, como selector. Porciones de 0.25 '
          'a 6.',
          style: texto.labelSmall?.copyWith(color: colores.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// The fixed bottom area: the failure of the last attempt and the save button.
class _BarraGuardar extends StatelessWidget {
  const _BarraGuardar({
    required this.fallo,
    required this.guardando,
    required this.onGuardar,
    required this.onCerrar,
  });

  final ApiFailure? fallo;
  final bool guardando;
  final VoidCallback onGuardar;
  final VoidCallback onCerrar;

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
                // The code is what makes a failure diagnosable afterwards.
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
                  label: 'Cerrar sin guardar',
                  variant: AppButtonVariant.text,
                  onPressed: onCerrar,
                ),
                const SizedBox(height: AppDimensions.spaceSm),
              ],
              AppButton(
                label: 'Guardar tiempo',
                isLoading: guardando,
                onPressed: onGuardar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// What the screen shows while the plan is not there: loading, the failure of
/// the read, or a day that no longer carries this meal time.
class _SinTiempo extends StatelessWidget {
  const _SinTiempo({
    required this.carga,
    required this.onReintentar,
    required this.onVolver,
  });

  final AsyncValue<PlanDetalle> carga;
  final VoidCallback onReintentar;
  final VoidCallback onVolver;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final colores = Theme.of(context).colorScheme;

    return carga.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: AppDimensions.screenPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                error is ApiFailure
                    ? error.mensaje
                    : 'No pudimos cargar el plan.',
                key: const Key('fallo-carga'),
                textAlign: TextAlign.center,
                style: texto.bodyMedium?.copyWith(color: colores.error),
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              AppButton(label: 'Reintentar', onPressed: onReintentar),
            ],
          ),
        ),
      ),
      data: (_) => Center(
        child: Padding(
          padding: AppDimensions.screenPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Este tiempo de comida ya no está en el plan.',
                key: const Key('tiempo-ausente'),
                textAlign: TextAlign.center,
                style: texto.bodyMedium,
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              AppButton(label: 'Volver al plan', onPressed: onVolver),
            ],
          ),
        ),
      ),
    );
  }
}
