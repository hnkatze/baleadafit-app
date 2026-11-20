import '../../../core/network/api_client.dart';
import '../../../core/network/paged.dart';
import 'catalogo_item.dart';
import 'medicamento.dart';
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

  /// Updates a patient through `PATCH /pacientes/{id}`.
  ///
  /// [body] carries documented fields only. `condiciones` and `restricciones`
  /// are REPLACED wholesale when sent, so the caller sends the complete
  /// selection, never a diff. A mail that belongs to another patient answers
  /// 409 with a message the form shows as is. The ficha is refreshed instead
  /// of reading the answer back.
  Future<void> actualizarPaciente(
    String pacienteId, {
    required Map<String, Object?> body,
  }) => _api.patchAck('/pacientes/$pacienteId', body: body);

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

  // ---- Medication ----------------------------------------------------------
  //
  // No endpoint lists medications: the list arrives inside the ficha
  // (`situacion.medicacion`). These three write it.

  /// `POST /pacientes/{id}/medicamentos`, 201 with the created medication and
  /// `duplicadoDe` when an active one has the same name (saved anyway).
  ///
  /// A field with no text does not travel: the contract validates `dosis` and
  /// `frecuencia` only when they exist, and a blank string is a 400.
  Future<MedicamentoCreado> registrarMedicamento(
    String pacienteId, {
    required String nombre,
    String? dosis,
    String? frecuencia,
  }) {
    return _api.post(
      '/pacientes/${Uri.encodeComponent(pacienteId)}/medicamentos',
      body: {
        'nombre': nombre.trim(),
        if (_conTexto(dosis)) 'dosis': dosis!.trim(),
        if (_conTexto(frecuencia)) 'frecuencia': frecuencia!.trim(),
      },
      fromJson: MedicamentoCreado.fromJson,
    );
  }

  /// `PATCH /medicamentos/{id}`, 200 with the updated medication.
  ///
  /// Omitting a field keeps the stored value (contract fact), so the caller
  /// sends what it wants to change and nothing else. Clearing is explicit:
  /// [limpiarDosis] / [limpiarFrecuencia] send `null`.
  // Tri-state per field: omit keeps the stored value, null clears it, text sets it.
  Future<Medicamento> actualizarMedicamento(
    String id, {
    String? nombre,
    String? dosis,
    String? frecuencia,
    bool limpiarDosis = false,
    bool limpiarFrecuencia = false,
  }) {
    return _api.patch(
      '/medicamentos/${Uri.encodeComponent(id)}',
      body: {
        if (_conTexto(nombre)) 'nombre': nombre!.trim(),
        if (limpiarDosis)
          'dosis': null
        else if (_conTexto(dosis))
          'dosis': dosis!.trim(),
        if (limpiarFrecuencia)
          'frecuencia': null
        else if (_conTexto(frecuencia))
          'frecuencia': frecuencia!.trim(),
      },
      fromJson: Medicamento.fromJson,
    );
  }

  /// `DELETE /medicamentos/{id}`: a logical deletion that answers 200 with the
  /// medication already in `activo: false`, so the caller takes it from here.
  /// The API can bring it back (`PATCH {"activo": true}`); the app does not yet.
  Future<Medicamento> darDeBajaMedicamento(String id) => _api.delete(
    '/medicamentos/${Uri.encodeComponent(id)}',
    fromJson: Medicamento.fromJson,
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

bool _conTexto(String? value) => value != null && value.trim().isNotEmpty;
