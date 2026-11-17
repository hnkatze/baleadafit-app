import '../../../core/format/fechas.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/paged.dart';
import 'cita.dart';

/// The three appointment endpoints of the API, and nothing else.
///
/// There is no `GET /citas/{id}`: a cita arrives inside the list, so the detail
/// screen is handed the object that was already loaded instead of fetching it
/// again.
class CitasRepository {
  const CitasRepository(this._api);

  final ApiClient _api;

  /// The agenda of a range of days, both ends included.
  ///
  /// The API parses these with `new Date(...)` and compares with `gte`/`lte`,
  /// and a date with no time is midnight UTC. Sending `yyyy-MM-dd` there would
  /// cut the range at the first instant of the day and leave every appointment
  /// of the day outside it, so both ends travel as instants with a zone: the
  /// first and the last instant of the local day.
  Future<Paged<Cita>> listar({
    required DateTime desde,
    required DateTime hasta,
    EstadoCita? estado,
    String? pacienteId,
    int limit = 100,
  }) => _api.getPaged(
    '/citas',
    itemFromJson: Cita.fromJson,
    query: {
      'desde': _inicioDelDia(desde).toUtc().toIso8601String(),
      'hasta': _finDelDia(hasta).toUtc().toIso8601String(),
      'limit': limit,
      if (estado != null) 'estado': estado.codigo,
      'pacienteId': ?pacienteId,
    },
  );

  /// `POST /citas`. Answers 201 with the cita or a 409 [ApiFailure] when it
  /// overlaps another programmed one; there is no availability endpoint.
  Future<Cita> crear({
    required String pacienteId,
    required DateTime fechaHora,
    int duracionMin = 45,
    String motivo = '',
    String notas = '',
  }) => _api.post(
    '/citas',
    body: {
      'pacienteId': pacienteId,
      'fechaHora': fechaHora.toUtc().toIso8601String(),
      'duracionMin': duracionMin,
      'motivo': motivo,
      'notas': notas,
    },
    fromJson: Cita.fromJson,
  );

  /// `PATCH /citas/{id}`: reprogramar, completar or cancelar, plus the SOAP
  /// note. Only the fields given are sent, so one call never overwrites what
  /// the caller did not touch.
  Future<Cita> actualizar(
    String id, {
    DateTime? fechaHora,
    int? duracionMin,
    EstadoCita? estado,
    String? motivo,
    String? notas,
    String? subjetivo,
    String? objetivo,
    String? analisis,
    String? plan,
    DateTime? proximaCitaSugerida,
  }) {
    final sugerida = proximaCitaSugerida;
    return _api.patch(
      '/citas/${Uri.encodeComponent(id)}',
      body: {
        'fechaHora': ?fechaHora?.toUtc().toIso8601String(),
        'duracionMin': ?duracionMin,
        'estado': ?estado?.codigo,
        'motivo': ?motivo,
        'notas': ?notas,
        'subjetivo': ?subjetivo,
        'objetivo': ?objetivo,
        'analisis': ?analisis,
        'plan': ?plan,
        'proximaCitaSugerida': ?(sugerida == null ? null : fechaIso(sugerida)),
      },
      fromJson: Cita.fromJson,
    );
  }
}

/// The first instant of the local day.
DateTime _inicioDelDia(DateTime fecha) =>
    DateTime(fecha.year, fecha.month, fecha.day);

/// The last instant of the local day, since the API compares with `lte`.
DateTime _finDelDia(DateTime fecha) => DateTime(
  fecha.year,
  fecha.month,
  fecha.day + 1,
).subtract(const Duration(milliseconds: 1));
