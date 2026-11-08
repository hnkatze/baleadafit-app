import 'package:json_annotation/json_annotation.dart';

part 'dashboard_resumen.g.dart';

/// What `GET /dashboard` answers: the numbers the home screen opens with.
@JsonSerializable(createToJson: false)
class DashboardResumen {
  const DashboardResumen({
    required this.pacientesActivos,
    required this.planesEnBorrador,
    required this.citasHoy,
  });

  factory DashboardResumen.fromJson(Map<String, dynamic> json) =>
      _$DashboardResumenFromJson(json);

  final int pacientesActivos;
  final int planesEnBorrador;

  /// Today appointments, cancelled ones already excluded by the API.
  final List<CitaResumen> citasHoy;

  /// First appointment that has not started yet, or null when the day is over.
  CitaResumen? proxima(DateTime now) {
    final pending =
        citasHoy
            .where((cita) => !cita.fechaHora.toLocal().isBefore(now))
            .toList()
          ..sort((a, b) => a.fechaHora.compareTo(b.fechaHora));
    return pending.isEmpty ? null : pending.first;
  }
}

/// One appointment of the day, with only the fields the home screen shows.
@JsonSerializable(createToJson: false)
class CitaResumen {
  const CitaResumen({
    required this.id,
    required this.fechaHora,
    required this.duracionMin,
    required this.motivo,
    this.paciente,
  });

  factory CitaResumen.fromJson(Map<String, dynamic> json) =>
      _$CitaResumenFromJson(json);

  final String id;
  final DateTime fechaHora;
  final int duracionMin;
  final String motivo;
  final PacienteBreve? paciente;

  String? get pacienteNombre => paciente?.nombreCompleto;

  /// Hour of the appointment in the device time zone, as `HH:mm`.
  String get hora {
    final local = fechaHora.toLocal();
    final hours = local.hour.toString().padLeft(2, '0');
    final minutes = local.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }
}

/// The patient of an appointment: the API nests a short version in each cita.
@JsonSerializable(createToJson: false)
class PacienteBreve {
  const PacienteBreve({
    required this.id,
    required this.nombre,
    required this.apellido,
  });

  factory PacienteBreve.fromJson(Map<String, dynamic> json) =>
      _$PacienteBreveFromJson(json);

  final String id;
  final String nombre;
  final String apellido;

  String get nombreCompleto => '$nombre $apellido'.trim();
}
