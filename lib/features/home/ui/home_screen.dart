import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_failure.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_pill.dart';
import '../../auth/application/session_controller.dart';
import '../../patients/data/paciente_resumen.dart';
import '../../patients/data/patients_providers.dart';
import '../data/dashboard_providers.dart';
import '../data/dashboard_resumen.dart';

/// Home of the authenticated area: the day ahead, from `GET /dashboard`.
///
/// Only what the API exposes is drawn. The mockup also shows adherence, InBody
/// readings and the WhatsApp bot; none of that has an endpoint yet.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resumen = ref.watch(dashboardProvider);
    final name = ref.watch(sessionControllerProvider).session?.displayName;

    return ListView(
      padding: AppDimensions.screenPadding,
      children: [
        _DayHeader(name: name),
        const SizedBox(height: AppDimensions.spaceMd),
        ...resumen.when(
          loading: () => const [
            Padding(
              padding: EdgeInsets.symmetric(vertical: AppDimensions.spaceXl),
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
          error: (error, _) => [
            _LoadFailure(
              error: error,
              onRetry: () => ref.invalidate(dashboardProvider),
            ),
          ],
          data: (data) => [_DaySection(data: data)],
        ),
        const SizedBox(height: AppDimensions.spaceLg),
        const _TusPacientes(),
      ],
    );
  }
}

/// Date overline and the greeting of the hour.
class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final now = DateTime.now();
    final saludo = switch (now.hour) {
      < 12 => 'Buenos días',
      < 19 => 'Buenas tardes',
      _ => 'Buenas noches',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _fechaLarga(now),
          style: textTheme.labelSmall?.copyWith(
            color: colors.primary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: AppDimensions.spaceXs),
        Text(
          name == null ? saludo : '$saludo, ${_trato(name!)}',
          style: textTheme.headlineSmall,
        ),
      ],
    );
  }
}

/// `Lic. Camilo Henriquez` greets as `Lic. Henriquez`: honorific plus surname.
String _trato(String nombre) {
  final partes = nombre
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (partes.length < 3) return nombre;
  return '${partes.first} ${partes.last}';
}

const _dias = [
  'LUNES',
  'MARTES',
  'MIÉRCOLES',
  'JUEVES',
  'VIERNES',
  'SÁBADO',
  'DOMINGO',
];

const _meses = [
  'ENERO',
  'FEBRERO',
  'MARZO',
  'ABRIL',
  'MAYO',
  'JUNIO',
  'JULIO',
  'AGOSTO',
  'SEPTIEMBRE',
  'OCTUBRE',
  'NOVIEMBRE',
  'DICIEMBRE',
];

String _fechaLarga(DateTime date) =>
    '${_dias[date.weekday - 1]} ${date.day} DE ${_meses[date.month - 1]}';

String _hora(DateTime date) {
  final local = date.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}

/// The hero of the day: the next appointment and where it sits in the day.
class _DaySection extends StatelessWidget {
  const _DaySection({required this.data});

  final DashboardResumen data;

  @override
  Widget build(BuildContext context) {
    final proxima = data.proxima(DateTime.now());
    final restantes = data.citasHoy.where((cita) => cita != proxima).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _NextAppointmentCard(data: data, proxima: proxima),
        const SizedBox(height: AppDimensions.spaceSm),
        _Metrics(data: data),
        if (restantes.isNotEmpty) ...[
          const SizedBox(height: AppDimensions.spaceLg),
          Text('Después', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppDimensions.spaceSm),
          ...restantes.map((cita) => _AfterCard(cita: cita)),
        ],
      ],
    );
  }
}

class _NextAppointmentCard extends StatelessWidget {
  const _NextAppointmentCard({required this.data, required this.proxima});

  final DashboardResumen data;
  final CitaResumen? proxima;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final cita = proxima;
    final lastEnd = data.citasHoy.isEmpty
        ? null
        : data.citasHoy
              .map(
                (c) =>
                    c.fechaHora.toLocal().add(Duration(minutes: c.duracionMin)),
              )
              .reduce((a, b) => a.isAfter(b) ? a : b);

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceMd),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -8,
            top: 6,
            child: Opacity(
              opacity: 0.28,
              child: CustomPaint(
                size: const Size(150, 54),
                painter: _PulsePainter(color: colors.onPrimaryContainer),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cita == null ? 'HOY' : 'PRÓXIMA CITA',
                style: textTheme.labelSmall?.copyWith(letterSpacing: 0.8),
              ),
              if (cita == null) ...[
                const SizedBox(height: AppDimensions.spaceXs),
                Text(
                  data.citasHoy.isEmpty ? 'Sin citas hoy' : 'Sin pendientes',
                  style: textTheme.headlineSmall,
                ),
                Text(
                  data.citasHoy.isEmpty
                      ? 'Buen momento para revisar los planes en borrador.'
                      : 'Ya pasaron todas las citas del día.',
                  style: textTheme.bodySmall,
                ),
              ] else ...[
                const SizedBox(height: AppDimensions.spaceSm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      cita.hora,
                      style: textTheme.displayLarge?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spaceSm),
                    Text(_enCuanto(cita), style: textTheme.titleMedium),
                  ],
                ),
                Text(
                  cita.pacienteNombre ?? 'Paciente',
                  style: textTheme.titleLarge,
                ),
                Text(
                  '${cita.motivo} · ${cita.duracionMin} min',
                  style: textTheme.bodySmall,
                ),
              ],
              if (data.citasHoy.isNotEmpty && lastEnd != null) ...[
                const SizedBox(height: AppDimensions.spaceMd),
                Container(
                  padding: const EdgeInsets.only(top: AppDimensions.spaceSm),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: colors.onPrimaryContainer.withValues(
                          alpha: 0.18,
                        ),
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: data.citasHoy.length == 1
                                      ? '1 cita'
                                      : '${data.citasHoy.length} citas',
                                  style: textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextSpan(
                                  text:
                                      ' ${_diaRelativo(data.citasHoy.first.fechaHora, DateTime.now())}',
                                  style: textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'termina ${_hora(lastEnd)}',
                            style: textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spaceXs),
                      SizedBox(
                        height: 40,
                        child: _DayTimeline(
                          citas: data.citasHoy,
                          now: DateTime.now(),
                        ),
                      ),
                    ],
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

/// `hoy`, `mañana` or the date, because the API groups by UTC day.
String _diaRelativo(DateTime date, DateTime now) {
  final cita = DateTime(date.year, date.month, date.day);
  final hoy = DateTime(now.year, now.month, now.day);
  return switch (cita.difference(hoy).inDays) {
    0 => 'hoy',
    1 => 'mañana',
    _ => 'el ${cita.day}/${cita.month}',
  };
}

String _enCuanto(CitaResumen cita) {
  final minutos = cita.fechaHora.difference(DateTime.now()).inMinutes;
  if (minutos <= 0) return 'ahora';
  if (minutos < 60) return 'en $minutos min';
  return 'en ${minutos ~/ 60} h ${minutos % 60} min';
}

/// The day as a horizontal scale: appointments as blocks, now as a marker.
class _DayTimeline extends StatelessWidget {
  const _DayTimeline({required this.citas, required this.now});

  final List<CitaResumen> citas;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return CustomPaint(
      size: Size.infinite,
      painter: _TimelinePainter(
        citas: citas,
        now: now,
        track: colors.onPrimaryContainer.withValues(alpha: 0.12),
        block: colors.onPrimaryContainer,
        tick: colors.onPrimaryContainer.withValues(alpha: 0.25),
        marker: colors.surface,
        outline: colors.onPrimaryContainer,
        label: colors.onPrimaryContainer,
        labelFont: AppTypography.monoFamily,
      ),
    );
  }
}

class _TimelinePainter extends CustomPainter {
  const _TimelinePainter({
    required this.citas,
    required this.now,
    required this.track,
    required this.block,
    required this.tick,
    required this.marker,
    required this.outline,
    required this.label,
    required this.labelFont,
  });

  final List<CitaResumen> citas;
  final DateTime now;
  final Color track;
  final Color block;
  final Color tick;
  final Color marker;
  final Color outline;
  final Color label;
  final String labelFont;

  static const _fallbackStart = 7;
  static const _fallbackEnd = 19;

  @override
  void paint(Canvas canvas, Size size) {
    final starts = citas.map((c) => _hours(c.fechaHora.toLocal())).toList();
    final ends = citas
        .map(
          (c) => _hours(
            c.fechaHora.toLocal().add(Duration(minutes: c.duracionMin)),
          ),
        )
        .toList();
    final nowHour = _hours(now.toLocal());
    final from = <double>[
      _fallbackStart.toDouble(),
      ...starts,
      nowHour,
    ].reduce(_min);
    final to = <double>[_fallbackEnd.toDouble(), ...ends, nowHour].reduce(_max);
    final span = (to - from).clamp(1, 24).toDouble();
    double x(double hour) => ((hour - from) / span) * size.width;

    final trackY = 9.0;
    final trackRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, trackY, size.width, 10),
      const Radius.circular(AppDimensions.radiusFull),
    );
    canvas.drawRRect(trackRect, Paint()..color = track);

    final tickPaint = Paint()
      ..color = tick
      ..strokeWidth = 1;
    for (var hour = from.ceil(); hour <= to.floor(); hour++) {
      canvas.drawLine(
        Offset(x(hour.toDouble()), 12),
        Offset(x(hour.toDouble()), 16),
        tickPaint,
      );
    }

    for (final cita in citas) {
      final start = _hours(cita.fechaHora.toLocal());
      final end = start + cita.duracionMin / 60;
      final paint = Paint()
        ..color = cita == citas.first ? block : block.withValues(alpha: 0.45);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            x(start),
            trackY,
            (x(end) - x(start)).clamp(6, size.width),
            10,
          ),
          const Radius.circular(AppDimensions.radiusFull),
        ),
        paint,
      );
    }

    final nowX = x(_hours(now.toLocal()));
    canvas.drawLine(
      Offset(nowX, 3),
      Offset(nowX, 25),
      Paint()
        ..color = marker
        ..strokeWidth = 2,
    );
    canvas.drawCircle(Offset(nowX, 3), 3.5, Paint()..color = marker);
    canvas.drawCircle(
      Offset(nowX, 3),
      3.5,
      Paint()
        ..color = outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final step = span >= 12 ? 3 : 2;
    for (var hour = from; hour <= to; hour += step) {
      final painter = TextPainter(
        text: TextSpan(
          text: hour.round().toString().padLeft(2, '0'),
          style: TextStyle(
            color: label,
            fontFamily: labelFont,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final dx = (x(hour) - painter.width / 2).clamp(
        0.0,
        size.width - painter.width,
      );
      painter.paint(canvas, Offset(dx.toDouble(), 28));
    }
  }

  double _hours(DateTime date) => date.hour + date.minute / 60;

  double _min(double a, double b) => a < b ? a : b;

  double _max(double a, double b) => a > b ? a : b;

  @override
  bool shouldRepaint(_TimelinePainter old) =>
      old.citas != citas || old.now != now;
}

/// The decorative pulse of the card: a small ECG line in the corner.
class _PulsePainter extends CustomPainter {
  const _PulsePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(2, size.height * 0.62)
      ..lineTo(size.width * 0.30, size.height * 0.62)
      ..lineTo(size.width * 0.36, size.height * 0.22)
      ..lineTo(size.width * 0.42, size.height * 0.90)
      ..lineTo(size.width * 0.47, size.height * 0.40)
      ..lineTo(size.width * 0.52, size.height * 0.62)
      ..lineTo(size.width, size.height * 0.62);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_PulsePainter old) => old.color != color;
}

/// The two context numbers, with their icon.
class _Metrics extends StatelessWidget {
  const _Metrics({required this.data});

  final DashboardResumen data;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _MetricCard(
              icon: Icons.groups_2_outlined,
              value: data.pacientesActivos,
              label: 'Pacientes activos',
            ),
          ),
          const SizedBox(width: AppDimensions.spaceSm),
          Expanded(
            child: _MetricCard(
              icon: Icons.description_outlined,
              value: data.planesEnBorrador,
              label: 'Planes en borrador',
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceMd),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          Text(
            '$value',
            style: textTheme.headlineSmall?.copyWith(
              color: value == 0 ? colors.onSurfaceVariant : null,
            ),
          ),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _AfterCard extends StatelessWidget {
  const _AfterCard({required this.cita});

  final CitaResumen cita;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spaceSm),
      padding: const EdgeInsets.all(AppDimensions.spaceMd),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cita.hora,
                style: textTheme.titleMedium?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                '${cita.duracionMin} min',
                style: textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(width: AppDimensions.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cita.pacienteNombre ?? 'Paciente',
                  style: textTheme.titleSmall,
                ),
                Text(
                  cita.motivo,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The patients of this nutritionist, with their last weight and plan state.
class _TusPacientes extends ConsumerWidget {
  const _TusPacientes();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final pacientes = ref.watch(pacientesRecientesProvider);

    return pacientes.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) =>
          Text('No pudimos cargar tus pacientes.', style: textTheme.bodySmall),
      data: (page) {
        if (page.items.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tus pacientes', style: textTheme.titleMedium),
            const SizedBox(height: AppDimensions.spaceSm),
            ...page.items.map((paciente) => _PacienteTile(paciente: paciente)),
          ],
        );
      },
    );
  }
}

class _PacienteTile extends StatelessWidget {
  const _PacienteTile({required this.paciente});

  final PacienteResumen paciente;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final medicion = paciente.ultimaMedicion?.resumen;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spaceSm),
      padding: const EdgeInsets.all(AppDimensions.spaceMd),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          _InitialsAvatar(paciente: paciente),
          const SizedBox(width: AppDimensions.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(paciente.nombreCompleto, style: textTheme.titleSmall),
                if (medicion != null)
                  Text(
                    medicion,
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          AppPill(
            label: paciente.tienePlanActivo ? 'Con plan' : 'Sin plan',
            dotColor: paciente.tienePlanActivo
                ? colors.primary
                : colors.outline,
          ),
        ],
      ),
    );
  }
}

/// Round initials so a patient row reads as a person, not as a record.
class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.paciente});

  final PacienteResumen paciente;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final iniciales = [
      paciente.nombre.isEmpty ? '' : paciente.nombre[0],
      paciente.apellido.isEmpty ? '' : paciente.apellido[0],
    ].join().toUpperCase();

    return CircleAvatar(
      radius: 18,
      backgroundColor: colors.surfaceContainerHighest,
      child: Text(
        iniciales,
        style: textTheme.labelMedium?.copyWith(color: colors.onSurfaceVariant),
      ),
    );
  }
}

class _LoadFailure extends StatelessWidget {
  const _LoadFailure({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final failure = error;
    final detail = failure is ApiFailure
        ? failure.mensaje
        : 'Revisá tu conexión e intentá de nuevo.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('No pudimos cargar tu día.', style: textTheme.titleMedium),
        const SizedBox(height: AppDimensions.spaceXs),
        Text(detail, style: textTheme.bodyMedium),
        const SizedBox(height: AppDimensions.spaceMd),
        AppButton(
          label: 'Reintentar',
          icon: Icons.refresh,
          variant: AppButtonVariant.secondary,
          onPressed: onRetry,
        ),
      ],
    );
  }
}
