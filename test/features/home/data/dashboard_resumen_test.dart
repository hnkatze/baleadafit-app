import 'package:baleadafit/features/home/data/dashboard_resumen.dart';
import 'package:flutter_test/flutter_test.dart';

CitaResumen _cita(String id, DateTime hora) =>
    CitaResumen(id: id, fechaHora: hora, duracionMin: 45, motivo: 'Control');

DashboardResumen _dia(List<CitaResumen> citas) =>
    DashboardResumen(pacientesActivos: 1, planesEnBorrador: 1, citasHoy: citas);

void main() {
  final now = DateTime(2026, 11, 6, 10);

  test('picks the first appointment that has not started yet', () {
    final resumen = _dia([
      _cita('pasada', DateTime(2026, 11, 6, 9)),
      _cita('tarde', DateTime(2026, 11, 6, 16)),
      _cita('siguiente', DateTime(2026, 11, 6, 11)),
    ]);

    expect(resumen.proxima(now)?.id, 'siguiente');
  });

  test('a day with only past appointments has no next one', () {
    final resumen = _dia([_cita('pasada', DateTime(2026, 11, 6, 9))]);

    expect(resumen.proxima(now), isNull);
  });

  test('an empty day has no next appointment', () {
    expect(_dia(const []).proxima(now), isNull);
  });

  test('an appointment starting now still counts', () {
    final resumen = _dia([_cita('ahora', DateTime(2026, 11, 6, 10))]);

    expect(resumen.proxima(now)?.id, 'ahora');
  });
}
