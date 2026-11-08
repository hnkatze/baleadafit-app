import '../../../core/network/api_client.dart';
import '../../../core/network/paged.dart';
import 'catalogo_item.dart';
import 'paciente_ficha.dart';
import 'paciente_resumen.dart';

/// Reads the patients of the signed-in nutritionist. Transport and failures
/// live in [ApiClient].
class PatientsRepository {
  const PatientsRepository(this._api);

  final ApiClient _api;

  Future<Paged<PacienteResumen>> recientes({int limit = 4}) => _api.getPaged(
    '/pacientes',
    query: {'limit': limit},
    itemFromJson: PacienteResumen.fromJson,
  );

  /// The directory page: inactive patients included, so the "Dados de baja"
  /// filter needs no second call.
  ///
  /// The API has no "has a plan" filter, so the chip counts are derived locally
  /// from this single page, capped at [limit] (100) rows.
  Future<Paged<PacienteResumen>> directorio({String? q, int limit = 100}) =>
      _api.getPaged(
        '/pacientes',
        query: {
          'incluirInactivos': true,
          'limit': limit,
          if (q != null && q.isNotEmpty) 'q': q,
        },
        itemFromJson: PacienteResumen.fromJson,
      );

  /// The whole file of one patient in a single call: header, progress,
  /// requirement, adherence, alerts, evolution, appointments and plans.
  Future<PacienteFicha> ficha(String pacienteId) => _api.get(
    '/pacientes/$pacienteId/ficha',
    fromJson: PacienteFicha.fromJson,
  );

  /// Records a measurement through `POST /pacientes/{id}/mediciones`.
  ///
  /// [body] carries only the fields the API documents; the caller leaves out
  /// what the nutritionist did not fill. The answer (the stored measurement
  /// with its BMI) is not needed: the ficha is refreshed instead, so a failure
  /// is the only thing worth reporting back.
  Future<void> registrarMedicion(
    String pacienteId, {
    required Map<String, Object?> body,
  }) => _api.postAck('/pacientes/$pacienteId/mediciones', body: body);

  /// Deactivates a patient through `DELETE /pacientes/{id}`.
  ///
  /// The API does a logical deletion (`activo = false`; the file, measurements
  /// and plans are kept) and answers `{ok: true, data: <paciente>}`. The
  /// patient is not needed back: the directory and the ficha are refreshed
  /// instead, so a failure is the only thing worth reporting.
  Future<void> darDeBaja(String pacienteId) =>
      _api.deleteAck('/pacientes/$pacienteId');

  /// Creates a patient through `POST /pacientes` and returns its id.
  ///
  /// [body] carries only documented fields, already typed (numbers as numbers)
  /// and without empty values. The id is the only thing the wizard needs back:
  /// it opens the new ficha, which loads the rest itself.
  Future<String> crearPaciente(Map<String, Object?> body) => _api.post(
    '/pacientes',
    body: body,
    fromJson: (json) => json['id']! as String,
  );

  /// The medical conditions a patient can be tagged with (`GET /condiciones`).
  Future<List<CatalogoItem>> condiciones() => _catalogo('/condiciones');

  /// The dietary restrictions a patient can be tagged with
  /// (`GET /restricciones`).
  Future<List<CatalogoItem>> restricciones() => _catalogo('/restricciones');

  // Both catalogues are small (20 and 6 rows) and answer `{ok, data: []}` with
  // no pagination meta, so they are read as plain lists.
  Future<List<CatalogoItem>> _catalogo(String path) =>
      _api.getList(path, itemFromJson: CatalogoItem.fromJson);
}
