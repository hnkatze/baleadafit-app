import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/fechas.dart';
import '../../../core/network/api_failure.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_pill.dart';
import '../../../shared/widgets/app_refresh.dart';
import '../data/cita.dart';
import '../data/citas_providers.dart';
import 'detalle_cita_screen.dart';

/// The nutritionist's agenda for one day.
///
/// There is no availability endpoint in the API, so this screen never invents
/// free slots: it draws the appointments that exist for the day and lets the
/// day be moved back and forth. The shell owns the bar, so the screen draws
/// only its content.
class AgendaScreen extends ConsumerStatefulWidget {
  const AgendaScreen({super.key, this.diaInicial});

  /// The day to open on; today when null. Mostly for tests, so they do not
  /// depend on the clock.
  final DateTime? diaInicial;

  @override
  ConsumerState<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends ConsumerState<AgendaScreen> {
  late DateTime _dia = _soloFecha(widget.diaInicial ?? DateTime.now());

  void _mover(int dias) => setState(() {
    _dia = DateTime(_dia.year, _dia.month, _dia.day + dias);
  });

  void _elegir(DateTime dia) => setState(() => _dia = _soloFecha(dia));

  /// Moves the strip a month; the selected day follows, clamped to the length
  /// of the new month, because the strip always shows the month of the day.
  void _moverMes(int meses) => setState(() {
    final destino = DateTime(_dia.year, _dia.month + meses);
    final ultimo = DateTime(destino.year, destino.month + 1, 0).day;
    _dia = DateTime(destino.year, destino.month, math.min(_dia.day, ultimo));
  });

  void _irAHoy() => setState(() => _dia = _soloFecha(DateTime.now()));

  void _programar() => context.push(AppRoutes.nuevaCita(dia: _dia));

  @override
  Widget build(BuildContext context) {
    final agenda = ref.watch(agendaDelDiaProvider(_dia));

    return Material(
      type: MaterialType.transparency,
      child: AppRefresh(
        onRefresh: _refrescar,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppDimensions.screenPadding,
          children: [
            _TiraDelMes(
              dia: _dia,
              onElegir: _elegir,
              onMesAnterior: () => _moverMes(-1),
              onMesSiguiente: () => _moverMes(1),
            ),
            const SizedBox(height: AppDimensions.spaceLg),
            _NavegacionDia(
              dia: _dia,
              esHoy: _esHoy(_dia),
              onAnterior: () => _mover(-1),
              onSiguiente: () => _mover(1),
              onHoy: _irAHoy,
              onProgramar: _programar,
            ),
            const SizedBox(height: AppDimensions.spaceLg),
            agenda.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: AppDimensions.spaceXl),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => _FalloCarga(
                error: error,
                onReintentar: () => ref.invalidate(agendaDelDiaProvider(_dia)),
              ),
              data: (page) => page.items.isEmpty
                  ? _SinCitas(onProgramar: _programar)
                  : _CitasDelDia(citas: page.items, dia: _dia),
            ),
          ],
        ),
      ),
    );
  }

  /// Completes when both the selected day and its month are fresh. Each load
  /// is awaited on its own so one failure does not cut the other short.
  Future<void> _refrescar() async {
    final mes = DateTime(_dia.year, _dia.month);
    Future<void> recargar<T>(Future<T> carga) async {
      try {
        await carga;
      } catch (_) {
        // The failure is drawn by the provider's error state.
      }
    }

    await Future.wait([
      recargar(ref.refresh(agendaDelDiaProvider(_dia).future)),
      recargar(ref.refresh(citasDelMesProvider(mes).future)),
    ]);
  }
}

DateTime _soloFecha(DateTime fecha) =>
    DateTime(fecha.year, fecha.month, fecha.day);

bool _esHoy(DateTime dia) => dia == _soloFecha(DateTime.now());

/// The month of the selected day as a 7-column grid, Monday first.
///
/// A day with appointments carries a dot; the counts come from
/// [citasDelMesProvider]. While that loads, or if it fails, the grid still
/// draws and simply shows no markers: the day view below owns the error state.
class _TiraDelMes extends ConsumerWidget {
  const _TiraDelMes({
    required this.dia,
    required this.onElegir,
    required this.onMesAnterior,
    required this.onMesSiguiente,
  });

  final DateTime dia;
  final ValueChanged<DateTime> onElegir;
  final VoidCallback onMesAnterior;
  final VoidCallback onMesSiguiente;

  static const _iniciales = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final texto = Theme.of(context).textTheme;
    final mes = DateTime(dia.year, dia.month);
    final diasDelMes = DateTime(dia.year, dia.month + 1, 0).day;
    final blancos = mes.weekday - 1;
    final citas = ref.watch(citasDelMesProvider(mes)).asData?.value;

    final celdas = <Widget>[
      for (var i = 0; i < blancos; i++) const SizedBox.shrink(),
      for (var d = 1; d <= diasDelMes; d++)
        _CeldaDia(
          fecha: DateTime(dia.year, dia.month, d),
          seleccionado: d == dia.day,
          citas: citas?.cuantasEl(DateTime(dia.year, dia.month, d)) ?? 0,
          onTap: onElegir,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: onMesAnterior,
              tooltip: 'Mes anterior',
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                mesYAnio(mes),
                textAlign: TextAlign.center,
                style: texto.titleMedium,
              ),
            ),
            IconButton(
              onPressed: onMesSiguiente,
              tooltip: 'Mes siguiente',
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        Row(
          children: [
            for (final inicial in _iniciales)
              Expanded(
                child: Center(child: Text(inicial, style: texto.labelSmall)),
              ),
          ],
        ),
        const SizedBox(height: AppDimensions.spaceXs),
        GridView(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisExtent: 44,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: celdas,
        ),
      ],
    );
  }
}

class _CeldaDia extends StatelessWidget {
  const _CeldaDia({
    required this.fecha,
    required this.seleccionado,
    required this.citas,
    required this.onTap,
  });

  final DateTime fecha;
  final bool seleccionado;
  final int citas;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final estilo = texto.bodyMedium?.copyWith(
      color: seleccionado ? AppColors.onPrimary : null,
      fontWeight: seleccionado ? FontWeight.w700 : null,
    );

    return Semantics(
      button: true,
      selected: seleccionado,
      label: citas == 0 ? null : (citas == 1 ? '1 cita' : '$citas citas'),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Material(
          color: seleccionado ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          child: InkWell(
            key: Key('dia-${fechaIso(fecha)}'),
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            onTap: () => onTap(fecha),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${fecha.day}', style: estilo),
                const SizedBox(height: 2),
                if (citas > 0)
                  Container(
                    key: Key('marca-${fechaIso(fecha)}'),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: seleccionado
                          ? AppColors.onPrimary
                          : AppColors.primary,
                    ),
                  )
                else
                  const SizedBox(height: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The day heading with the arrows that move it. `Hoy` only shows once the day
/// on screen is not today, so the way back is always one tap.
class _NavegacionDia extends StatelessWidget {
  const _NavegacionDia({
    required this.dia,
    required this.esHoy,
    required this.onAnterior,
    required this.onSiguiente,
    required this.onHoy,
    required this.onProgramar,
  });

  final DateTime dia;
  final bool esHoy;
  final VoidCallback onAnterior;
  final VoidCallback onSiguiente;
  final VoidCallback onHoy;
  final VoidCallback onProgramar;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;

    return Row(
      children: [
        IconButton(
          onPressed: onAnterior,
          tooltip: 'Día anterior',
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Text(
            fechaLarga(dia),
            textAlign: TextAlign.center,
            style: texto.titleMedium,
          ),
        ),
        IconButton(
          onPressed: onSiguiente,
          tooltip: 'Día siguiente',
          icon: const Icon(Icons.chevron_right),
        ),
        if (!esHoy) TextButton(onPressed: onHoy, child: const Text('Hoy')),
        IconButton(
          onPressed: onProgramar,
          tooltip: 'Programar cita',
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}

class _CitasDelDia extends StatelessWidget {
  const _CitasDelDia({required this.citas, required this.dia});

  final List<Cita> citas;
  final DateTime dia;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _LineaDelDia(citas: citas),
      const SizedBox(height: AppDimensions.spaceLg),
      for (final cita in citas) ...[
        _CitaTile(cita: cita, dia: dia),
        const SizedBox(height: AppDimensions.spaceSm),
      ],
    ],
  );
}

/// The day drawn as a line, with each appointment sized by `duracionMin`.
///
/// It is the same idea as the home's day line, rebuilt inside the feature: the
/// home's widgets are private and assume a single day with no navigation.
class _LineaDelDia extends StatelessWidget {
  const _LineaDelDia({required this.citas});

  final List<Cita> citas;

  @override
  Widget build(BuildContext context) {
    final inicios = citas.map((cita) => cita.fechaHora.toLocal());
    final finales = citas.map((cita) => cita.fin.toLocal());
    final desde = math.min(
      inicios.map((hora) => hora.hour).reduce(math.min),
      8,
    );
    final hasta = math.max(
      finales.map((hora) => hora.hour + 1).reduce(math.max),
      18,
    );
    final minutosTotales = (hasta - desde) * 60;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 44,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final ancho = constraints.maxWidth;
              return Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusFull,
                        ),
                      ),
                    ),
                  ),
                  for (final cita in citas)
                    Positioned(
                      left:
                          ancho *
                          _posicion(cita.fechaHora, desde, minutosTotales),
                      top: 6,
                      bottom: 6,
                      width: math.max(
                        6,
                        ancho *
                            (cita.duracionMin / minutosTotales).clamp(
                              0.02,
                              1.0,
                            ),
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: _colorDe(cita.estado),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusSm,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: AppDimensions.spaceXs),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$desde:00', style: Theme.of(context).textTheme.bodySmall),
            Text('$hasta:00', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ],
    );
  }

  double _posicion(DateTime hora, int desde, int minutosTotales) {
    final local = hora.toLocal();
    final minutos = (local.hour - desde) * 60 + local.minute;
    return (minutos / minutosTotales).clamp(0.0, 1.0);
  }
}

Color _colorDe(EstadoCita estado) => switch (estado) {
  EstadoCita.programada => AppColors.primary,
  EstadoCita.completada => AppColors.tertiary,
  EstadoCita.cancelada => AppColors.outline,
};

class _CitaTile extends StatelessWidget {
  const _CitaTile({required this.cita, required this.dia});

  final Cita cita;
  final DateTime dia;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;

    return AppCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => DetalleCitaScreen(cita: cita, dia: dia),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(cita.hora, style: AppTypography.data(context)),
              Text('${cita.duracionMin} min', style: texto.bodySmall),
            ],
          ),
          const SizedBox(width: AppDimensions.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cita.pacienteNombre, style: texto.titleSmall),
                if (cita.motivo.isNotEmpty)
                  Text(cita.motivo, style: texto.bodySmall),
                if (cita.paciente?.telefono.isNotEmpty ?? false)
                  Text(cita.paciente!.telefono, style: texto.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.spaceSm),
          AppPill(label: cita.estado.etiqueta, dotColor: _colorDe(cita.estado)),
        ],
      ),
    );
  }
}

class _SinCitas extends StatelessWidget {
  const _SinCitas({required this.onProgramar});

  final VoidCallback onProgramar;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceXl),
      child: Column(
        children: [
          Icon(
            Icons.event_available_outlined,
            size: AppDimensions.iconMd,
            color: AppColors.onSurfaceVariant,
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          Text('Sin citas este día', style: texto.titleSmall),
          const SizedBox(height: AppDimensions.spaceMd),
          AppButton(
            label: 'Programar cita',
            variant: AppButtonVariant.tonal,
            onPressed: onProgramar,
            expand: false,
          ),
        ],
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
        : 'No pudimos cargar la agenda.';

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
