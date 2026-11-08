import 'package:flutter/material.dart';

import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../data/paciente_ficha.dart';

/// Weight and body fat of the file, one compact sparkline above the other.
///
/// Two stacked charts instead of one with a legend: kilograms and percent have
/// unrelated scales, so sharing a y axis would flatten one of the two lines, and
/// a dual axis is unreadable at 390pt. Each row carries its own label and latest
/// figure, so no separate legend is needed.
///
/// The x axis is the measurement order, never elapsed time: several measurements
/// can share a date and a proportional axis would stack them into one point.
class EvolucionChart extends StatelessWidget {
  const EvolucionChart({super.key, required this.mediciones});

  /// Oldest first, as the API sends them.
  final List<MedicionFicha> mediciones;

  @override
  Widget build(BuildContext context) {
    // A trend needs two points; with fewer the file keeps its "second
    // measurement" line instead of a lonely dot.
    if (mediciones.length < 2) return const SizedBox.shrink();

    final colors = Theme.of(context).colorScheme;
    final peso = puntosDe(mediciones, (m) => m.pesoKg);
    final grasa = puntosDe(mediciones, (m) => m.pctGrasa);

    return Column(
      key: const Key('evolucion-grafico'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (peso.isNotEmpty)
          _Serie(
            key: const Key('evolucion-peso'),
            etiqueta: 'PESO',
            unidad: 'kg',
            puntos: peso,
            total: mediciones.length,
            color: colors.primary,
          ),
        if (peso.isNotEmpty && grasa.isNotEmpty)
          const SizedBox(height: AppDimensions.spaceSm + 4),
        if (grasa.isNotEmpty)
          _Serie(
            key: const Key('evolucion-grasa'),
            etiqueta: '% GRASA',
            unidad: '%',
            puntos: grasa,
            total: mediciones.length,
            color: colors.tertiary,
          ),
      ],
    );
  }
}

/// The points of one series. A measurement without the value is skipped, never
/// drawn as zero: a zero would read as a collapse in weight or fat.
List<PuntoEvolucion> puntosDe(
  List<MedicionFicha> mediciones,
  num? Function(MedicionFicha) valor,
) {
  return [
    for (final (i, m) in mediciones.indexed)
      if (valor(m) case final v?) PuntoEvolucion(i, v.toDouble()),
  ];
}

/// A value placed at its position in the measurement order.
class PuntoEvolucion {
  const PuntoEvolucion(this.orden, this.valor);

  final int orden;
  final double valor;
}

class _Serie extends StatelessWidget {
  const _Serie({
    super.key,
    required this.etiqueta,
    required this.unidad,
    required this.puntos,
    required this.total,
    required this.color,
  });

  final String etiqueta;
  final String unidad;
  final List<PuntoEvolucion> puntos;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final ultimo = puntos.last.valor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              etiqueta,
              style: textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            Text(
              '${ultimo.toStringAsFixed(1)} $unidad',
              style: AppTypography.data(context).copyWith(color: color),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spaceXs),
        SizedBox(
          height: 48,
          width: double.infinity,
          child: CustomPaint(
            painter: EvolucionPainter(
              puntos: puntos,
              total: total,
              color: color,
              fondo: colors.surface,
            ),
          ),
        ),
      ],
    );
  }
}

/// Paints one series as a line with a dot per measurement.
class EvolucionPainter extends CustomPainter {
  const EvolucionPainter({
    required this.puntos,
    required this.total,
    required this.color,
    required this.fondo,
  });

  final List<PuntoEvolucion> puntos;

  /// Measurements in the whole file, so both series share the same x slots even
  /// when one of them skips an entry.
  final int total;
  final Color color;
  final Color fondo;

  static const _margen = 6.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (puntos.isEmpty || total < 2) return;

    var minimo = puntos.first.valor;
    var maximo = minimo;
    for (final p in puntos) {
      if (p.valor < minimo) minimo = p.valor;
      if (p.valor > maximo) maximo = p.valor;
    }
    final rango = maximo - minimo;

    Offset donde(PuntoEvolucion p) {
      final x = _margen + (size.width - 2 * _margen) * p.orden / (total - 1);
      // A flat series sits in the middle instead of dividing by zero.
      final t = rango == 0 ? 0.5 : (p.valor - minimo) / rango;
      return Offset(x, size.height - _margen - (size.height - 2 * _margen) * t);
    }

    final centros = puntos.map(donde).toList();

    final linea = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    if (centros.length > 1) {
      final trazo = Path()..moveTo(centros.first.dx, centros.first.dy);
      for (final c in centros.skip(1)) {
        trazo.lineTo(c.dx, c.dy);
      }
      canvas.drawPath(trazo, linea);
    }

    final relleno = Paint()..color = fondo;
    final borde = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final c in centros) {
      canvas
        ..drawCircle(c, 3.5, relleno)
        ..drawCircle(c, 3.5, borde);
    }
  }

  @override
  bool shouldRepaint(EvolucionPainter old) =>
      old.puntos != puntos ||
      old.total != total ||
      old.color != color ||
      old.fondo != fondo;
}
