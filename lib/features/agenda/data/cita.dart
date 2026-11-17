import '../../../core/format/fechas.dart';

/// `estado` of `GET /citas`, and the only three values the contract declares.
///
/// There is no "en curso", no "confirmada por el paciente" and no "no asistió":
/// the agenda cannot show what the API does not have.
enum EstadoCita {
  programada('PROGRAMADA', 'Programada'),
  completada('COMPLETADA', 'Completada'),
  cancelada('CANCELADA', 'Cancelada');

  const EstadoCita(this.codigo, this.etiqueta);

  final String codigo;
  final String etiqueta;

  /// Reads the `estado` of a payload. An unknown value falls back to
  /// [programada] so a new server state cannot blank the whole agenda.
  static EstadoCita desdeApi(Object? valor) => values.firstWhere(
    (estado) => estado.codigo == valor,
    orElse: () => programada,
  );
}

/// The patient as every cita embeds it: the agenda never needs a second call.
class PacienteCita {
  const PacienteCita({
    required this.id,
    required this.nombre,
    required this.apellido,
    this.telefono = '',
  });

  factory PacienteCita.fromJson(Map<String, dynamic> json) => PacienteCita(
    id: json['id'] as String,
    nombre: _texto(json['nombre']),
    apellido: _texto(json['apellido']),
    telefono: _texto(json['telefono']),
  );

  final String id;
  final String nombre;
  final String apellido;
  final String telefono;

  String get nombreCompleto => '$nombre $apellido'.trim();
}

/// One appointment of `GET /citas`.
///
/// The cita is at once the agenda event and the clinical note of the visit:
/// it carries the four SOAP fields, and they are saved with the same
/// `PATCH /citas/{id}` that reprograms or completes it.
class Cita {
  const Cita({
    required this.id,
    required this.pacienteId,
    required this.fechaHora,
    this.duracionMin = 45,
    this.estado = EstadoCita.programada,
    this.motivo = '',
    this.notas = '',
    this.paciente,
    this.subjetivo = '',
    this.objetivo = '',
    this.analisis = '',
    this.plan = '',
    this.proximaCitaSugerida,
    this.creadoEn,
  });

  factory Cita.fromJson(Map<String, dynamic> json) {
    final paciente = json['paciente'];
    return Cita(
      id: json['id'] as String,
      pacienteId: _texto(json['pacienteId']),
      fechaHora: DateTime.parse(json['fechaHora'] as String),
      duracionMin: (json['duracionMin'] as num?)?.toInt() ?? 45,
      estado: EstadoCita.desdeApi(json['estado']),
      motivo: _texto(json['motivo']),
      notas: _texto(json['notas']),
      paciente: paciente is Map<String, dynamic>
          ? PacienteCita.fromJson(paciente)
          : null,
      subjetivo: _texto(json['subjetivo']),
      objetivo: _texto(json['objetivo']),
      analisis: _texto(json['analisis']),
      plan: _texto(json['plan']),
      proximaCitaSugerida: _fechaCalendario(json['proximaCitaSugerida']),
      creadoEn: _instante(json['creadoEn']),
    );
  }

  final String id;
  final String pacienteId;

  /// The instant of the appointment, in UTC as the API sends it. Format it with
  /// [hora] (or `toLocal()` at the render site) to show it in local time.
  final DateTime fechaHora;
  final int duracionMin;
  final EstadoCita estado;
  final String motivo;
  final String notas;
  final PacienteCita? paciente;
  final String subjetivo;
  final String objetivo;
  final String analisis;
  final String plan;

  /// A calendar date (solo fecha), stored at midnight UTC. Never convert it
  /// with `toLocal()`: west of Greenwich it would show the previous day.
  final DateTime? proximaCitaSugerida;
  final DateTime? creadoEn;

  /// The start in local time, `HH:mm`.
  String get hora {
    final local = fechaHora.toLocal();
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(local.hour)}:${dos(local.minute)}';
  }

  /// When the appointment ends, to size it on the day line.
  DateTime get fin => fechaHora.add(Duration(minutes: duracionMin));

  /// The name to draw on a row, or a readable fallback when the payload
  /// carries no nested patient.
  String get pacienteNombre =>
      paciente == null || paciente!.nombreCompleto.isEmpty
      ? 'Paciente sin nombre'
      : paciente!.nombreCompleto;

  /// [proximaCitaSugerida] as the request body expects it, `yyyy-MM-dd`.
  String? get proximaCitaIso {
    final fecha = proximaCitaSugerida;
    return fecha == null ? null : fechaIso(fecha);
  }
}

String _texto(Object? valor) => valor is String ? valor : '';

DateTime? _instante(Object? valor) =>
    valor is String ? DateTime.parse(valor) : null;

/// A calendar date read from its own fields, with no timezone conversion.
DateTime? _fechaCalendario(Object? valor) =>
    valor is String ? DateTime.parse(valor) : null;
