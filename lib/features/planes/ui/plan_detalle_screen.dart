import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/fechas.dart';
import '../../../core/network/api_failure.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_pill.dart';
import '../../../shared/widgets/app_refresh.dart';
import '../data/plan.dart';
import '../data/planes_formato.dart';
import '../data/planes_providers.dart';

/// The week of one plan, read only for an `ACTIVO` or `ARCHIVADO` plan.
///
/// The shell owns the top bar, so the screen draws its own back row inside the
/// scroll. It draws **only the days the plan carries** (`dias`), one expanded at
/// a time, and every figure of a total comes from the payload: the app never
/// adds or multiplies kcal.
///
/// Only a `BORRADOR` opens the meal-time editor, through [onEditarTiempo]: the
/// contract does not say what happens to the meals a patient already recorded
/// when the items of an active plan change, so an active plan is never edited
/// from here. The state (`estado`) is shown, never used to infer content.
class PlanDetalleScreen extends ConsumerStatefulWidget {
  const PlanDetalleScreen({
    required this.planId,
    required this.onBack,
    this.onEditarTiempo,
    super.key,
  });

  final String planId;
  final VoidCallback onBack;

  /// Opens the editor of one meal time of one day. The editor comes back here
  /// by navigation, so this screen is rebuilt and re-reads the plan. When it is
  /// null the rows carry no chevron, whatever the state of the plan.
  final void Function(DiaSemana dia, TipoComida tipo)? onEditarTiempo;

  @override
  ConsumerState<PlanDetalleScreen> createState() => _PlanDetalleScreenState();
}

class _PlanDetalleScreenState extends ConsumerState<PlanDetalleScreen> {
  /// The day the user picked; when the plan no longer carries it (after a
  /// refresh) the first day of the plan is shown instead.
  DiaSemana? _elegido;

  /// Completes when the plan is fresh; a failure is drawn by the error state.
  Future<void> _refrescar() async {
    final carga = ref.refresh(planDetalleProvider(widget.planId).future);
    try {
      await carga;
    } catch (_) {
      // The failure is drawn by the provider's error state.
    }
  }

  void _reintentar() => ref.invalidate(planDetalleProvider(widget.planId));

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(planDetalleProvider(widget.planId));
    final onEditar = widget.onEditarTiempo;

    return Material(
      type: MaterialType.transparency,
      child: AppRefresh(
        onRefresh: _refrescar,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppDimensions.screenPadding,
          children: [
            _Cabecera(onBack: widget.onBack, plan: plan.asData?.value),
            const SizedBox(height: AppDimensions.spaceMd),
            plan.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: AppDimensions.spaceXl),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) =>
                  _FalloCarga(error: error, onReintentar: _reintentar),
              data: (detalle) => _Contenido(
                plan: detalle,
                elegido: _elegido,
                onElegir: (dia) => setState(() => _elegido = dia),
                onEditar: onEditar,
                // Only a draft is editable: the contract does not regulate what
                // happens to a patient's recorded meals when an active plan
                // changes.
                editable: detalle.estado == EstadoPlan.borrador,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Back arrow, plan name and the line under it: `Borrador · sin publicar`, or
/// the date line of the list for an activated or archived plan.
class _Cabecera extends StatelessWidget {
  const _Cabecera({required this.onBack, required this.plan});

  final VoidCallback onBack;
  final PlanDetalle? plan;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final plan = this.plan;
    final linea = plan == null ? null : _lineaDeFecha(plan);

    return Row(
      children: [
        IconButton(
          tooltip: 'Volver a planes',
          icon: const Icon(Icons.arrow_back, size: AppDimensions.iconMd),
          onPressed: onBack,
        ),
        if (plan != null)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plan.nombre, style: textTheme.titleLarge),
                if (linea != null)
                  Text(
                    linea,
                    style: textTheme.labelSmall?.copyWith(
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

/// The date line of a plan, after `toLocal()`.
String? _lineaDeFecha(PlanDetalle plan) {
  switch (plan.estado) {
    case EstadoPlan.borrador:
      return 'Borrador · sin publicar';
    case EstadoPlan.activo:
      final fecha = plan.aprobadoEn ?? plan.creadoEn;
      return fecha == null ? null : 'Activo el ${diaYMes(fecha)}';
    case EstadoPlan.archivado:
      final fecha = plan.creadoEn;
      return fecha == null
          ? 'solo lectura'
          : 'Creado el ${diaYMes(fecha)} · solo lectura';
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({
    required this.plan,
    required this.elegido,
    required this.onElegir,
    required this.onEditar,
    required this.editable,
  });

  final PlanDetalle plan;
  final DiaSemana? elegido;
  final ValueChanged<DiaSemana> onElegir;

  /// Opens the editor of a meal time; null when the screen cannot edit.
  final void Function(DiaSemana dia, TipoComida tipo)? onEditar;

  /// Whether the plan is a draft, the only state the contract lets edit.
  final bool editable;

  @override
  Widget build(BuildContext context) {
    final dias = plan.dias;
    final DiaPlan? actual = dias.isEmpty
        ? null
        : dias.firstWhere((d) => d.dia == elegido, orElse: () => dias.first);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TarjetaDeEstado(plan: plan),
        const SizedBox(height: AppDimensions.spaceMd),
        if (dias.isEmpty)
          const _SinDias()
        else ...[
          _TarjetaDeTotales(plan: plan),
          const SizedBox(height: AppDimensions.spaceMd),
          _TiraDeDias(dias: dias, actual: actual!.dia, onElegir: onElegir),
          const SizedBox(height: AppDimensions.spaceMd),
          _DiaExpandido(dia: actual, onEditar: onEditar, editable: editable),
        ],
      ],
    );
  }
}

class _TarjetaDeEstado extends StatelessWidget {
  const _TarjetaDeEstado({required this.plan});

  final PlanDetalle plan;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final justificacion = plan.justificacion?.trim();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppPill(label: plan.estado.codigo),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spaceSm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: colors.outlineVariant),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                ),
                child: Text(
                  plan.origen.etiqueta,
                  style: textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceMd - 4),
          Row(
            children: [
              _Meta(
                rotulo: 'KCAL / DÍA',
                valor: formatearKcal(plan.kcalObjetivo),
              ),
              _Meta(rotulo: 'PROT', valor: formatearGramos(plan.proteinaG)),
              _Meta(rotulo: 'CARB', valor: formatearGramos(plan.carbohidratoG)),
              _Meta(rotulo: 'GRASA', valor: formatearGramos(plan.grasaG)),
            ],
          ),
          if (justificacion != null && justificacion.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spaceMd - 4),
            Divider(height: 1, color: colors.surfaceContainer),
            const SizedBox(height: AppDimensions.spaceMd - 4),
            _Justificacion(texto: justificacion),
          ],
        ],
      ),
    );
  }
}

/// The plan's explanation. The assistant writes paragraphs where the design
/// expected a line, so past [_Justificacion._limite] words it is cut and the
/// rest is offered behind `Ver más` instead of pushing the week off screen.
class _Justificacion extends StatefulWidget {
  const _Justificacion({required this.texto});

  final String texto;

  static const _limite = 150;

  @override
  State<_Justificacion> createState() => _JustificacionState();
}

class _JustificacionState extends State<_Justificacion> {
  bool _abierta = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    // Split on whitespace rather than on characters: a word is never cut in
    // half, and the count is the one the limit names.
    final palabras = widget.texto
        .split(RegExp(r'\s+'))
        .where((palabra) => palabra.isNotEmpty)
        .toList();
    final corta = palabras.length > _Justificacion._limite && !_abierta;
    final texto = !corta
        ? widget.texto
        : '${palabras.take(_Justificacion._limite).join(' ')}…';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          texto,
          style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
        ),
        if (palabras.length > _Justificacion._limite)
          AppButton(
            label: _abierta ? 'Ver menos' : 'Ver más',
            variant: AppButtonVariant.text,
            onPressed: () => setState(() => _abierta = !_abierta),
          ),
      ],
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.rotulo, required this.valor});

  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rotulo,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: colors.onSurfaceVariant),
          ),
          Text(valor, style: AppTypography.data(context)),
        ],
      ),
    );
  }
}

/// `Totales de la semana`: the plan's own deviation and the plan's own total.
/// The goal is `kcalObjetivo` × the days the plan carries, as the contract
/// defines it.
class _TarjetaDeTotales extends StatelessWidget {
  const _TarjetaDeTotales({required this.plan});

  final PlanDetalle plan;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final totales = plan.totales;
    final desviacion = plan.desviacion;
    final dias = plan.dias.length;
    final meta = plan.kcalObjetivo * dias;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Totales de la semana', style: textTheme.titleMedium),
              if (desviacion != null)
                AppPill(label: formatearDesviacion(desviacion)),
            ],
          ),
          if (totales != null) ...[
            const SizedBox(height: AppDimensions.spaceSm),
            Text(
              '${formatearKcal(totales.kcal)} kcal reales de '
              '${formatearKcal(meta)} kcal meta '
              '(${dias == 1 ? '1 día' : '$dias días'})',
              style: AppTypography.data(context)
                  .copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

/// `DÍA` and one chip for each day the plan has: no empty chips.
class _TiraDeDias extends StatelessWidget {
  const _TiraDeDias({
    required this.dias,
    required this.actual,
    required this.onElegir,
  });

  final List<DiaPlan> dias;
  final DiaSemana actual;
  final ValueChanged<DiaSemana> onElegir;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DÍA',
          style: textTheme.labelMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppDimensions.spaceSm),
        Row(
          children: [
            for (var i = 0; i < dias.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: _ChipDia(
                  dia: dias[i].dia,
                  seleccionado: dias[i].dia == actual,
                  onTap: () => onElegir(dias[i].dia),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _ChipDia extends StatelessWidget {
  const _ChipDia({
    required this.dia,
    required this.seleccionado,
    required this.onTap,
  });

  final DiaSemana dia;
  final bool seleccionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: seleccionado ? colors.primary : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: seleccionado
            ? BorderSide.none
            : BorderSide(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 40,
          child: Center(
            child: Text(
              dia.abreviatura,
              maxLines: 1,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: seleccionado
                    ? colors.onPrimary
                    : colors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The expanded day: its title with its own totals and deviation, then its
/// meal times in `orden`.
class _DiaExpandido extends StatelessWidget {
  const _DiaExpandido({
    required this.dia,
    required this.onEditar,
    required this.editable,
  });

  final DiaPlan dia;
  final void Function(DiaSemana dia, TipoComida tipo)? onEditar;
  final bool editable;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final totales = dia.totales;
    final desviacion = dia.desviacion;
    final resumen = [
      if (totales != null) '${formatearKcal(totales.kcal)} kcal',
      if (desviacion != null) formatearDesviacion(desviacion),
    ].join(' · ');

    // `List.sort` is not stable: the position breaks ties between equal `orden`.
    final indexados =
        [for (var i = 0; i < dia.tiempos.length; i++) (i, dia.tiempos[i])]
          ..sort((a, b) {
            final porOrden = a.$2.orden.compareTo(b.$2.orden);
            return porOrden != 0 ? porOrden : a.$1.compareTo(b.$1);
          });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(dia.dia.etiqueta, style: textTheme.titleMedium),
            if (resumen.isNotEmpty)
              Text(
                resumen,
                style: AppTypography.data(context)
                    .copyWith(color: colors.onSurfaceVariant),
              ),
          ],
        ),
        const SizedBox(height: AppDimensions.spaceSm),
        for (final (_, tiempo) in indexados) ...[
          _FilaDeTiempo(
            tiempo: tiempo,
            onTap: editable && onEditar != null
                ? () => onEditar!(dia.dia, tiempo.tipo)
                : null,
          ),
          const SizedBox(height: AppDimensions.spaceSm),
        ],
      ],
    );
  }
}

/// One meal time: `25% · meta 375 kcal · 2 alimentos`. The figure is
/// `kcalMeta`, so it is labelled as a goal; the percentage is `pctKcal × 100`.
///
/// A draft opens its editor when [onTap] is given; an active or archived plan
/// gets no chevron and cannot be tapped.
class _FilaDeTiempo extends StatelessWidget {
  const _FilaDeTiempo({required this.tiempo, this.onTap});

  final TiempoComida tiempo;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final items = tiempo.items;
    final resumen = [
      formatearFraccion(tiempo.pctKcal),
      'meta ${formatearKcal(tiempo.kcalMeta)} kcal',
      if (items.isNotEmpty)
        items.length == 1 ? '1 alimento' : '${items.length} alimentos',
    ].join(' · ');

    return AppCard(
      key: Key('tiempo-${tiempo.tipo.codigo}'),
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceMd,
        vertical: AppDimensions.spaceMd - 4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _IconoDeTiempo(tipo: tiempo.tipo),
              const SizedBox(width: AppDimensions.spaceSm + 4),
              Expanded(
                child: Text(tiempo.tipo.etiqueta, style: textTheme.titleMedium),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right,
                  key: Key('editar-${tiempo.tipo.codigo}'),
                  size: AppDimensions.iconSm,
                  color: colors.onSurfaceVariant,
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            resumen,
            style: AppTypography.data(context)
                .copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          Divider(height: 1, color: colors.surfaceContainer),
          const SizedBox(height: AppDimensions.spaceSm),
          if (items.isEmpty)
            Text(
              'Sin alimentos',
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            )
          else
            for (final item in items) _FilaDeAlimento(item: item),
        ],
      ),
    );
  }
}

/// The decorative icon of a meal time in a 36 px tinted circle. It is out of
/// the semantics tree: the row reads as its text.
class _IconoDeTiempo extends StatelessWidget {
  const _IconoDeTiempo({required this.tipo});

  final TipoComida tipo;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (icono, fondo, frente) = switch (tipo) {
      TipoComida.desayuno => (
        Icons.breakfast_dining,
        colors.secondaryContainer,
        colors.onSecondaryContainer,
      ),
      TipoComida.meriendaAm => (
        Icons.local_cafe,
        colors.surfaceContainer,
        colors.onSurfaceVariant,
      ),
      TipoComida.almuerzo => (
        Icons.lunch_dining,
        colors.primaryContainer,
        colors.onPrimaryContainer,
      ),
      TipoComida.meriendaPm => (
        Icons.cookie,
        colors.surfaceContainer,
        colors.onSurfaceVariant,
      ),
      TipoComida.cena => (
        Icons.dinner_dining,
        colors.tertiaryContainer,
        colors.onTertiaryContainer,
      ),
    };

    return ExcludeSemantics(
      child: Container(
        key: Key('icono-${tipo.codigo}'),
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: fondo, shape: BoxShape.circle),
        child: Icon(icono, size: AppDimensions.iconSm + 4, color: frente),
      ),
    );
  }
}

/// One food: its name and portions, and under it the portion in words with the
/// kcal **per portion** (`alimento.kcal`, never multiplied by `porciones`).
class _FilaDeAlimento extends StatelessWidget {
  const _FilaDeAlimento({required this.item});

  final PlanItem item;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final alimento = item.alimento;
    final porcion = alimento?.porcionDescripcion ?? '';
    final kcal = alimento?.kcal;
    final detalle = [
      if (porcion.isNotEmpty) porcion,
      if (kcal != null) '${formatearKcal(kcal)} kcal por porción',
    ].join(' · ');
    final porciones = formatearPorciones(item.porciones);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spaceSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (alimento != null)
                  Text(alimento.nombre, style: textTheme.bodySmall),
                if (detalle.isNotEmpty)
                  Text(
                    detalle,
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.spaceSm),
          Text(
            porciones == '1' ? '1 porción' : '$porciones porciones',
            style: AppTypography.data(context)
                .copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _SinDias extends StatelessWidget {
  const _SinDias();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceXl),
      child: Text(
        'Este plan todavía no tiene días.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
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
        : 'No pudimos cargar el plan.';

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
