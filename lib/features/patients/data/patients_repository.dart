import '../../../core/network/api_client.dart';
import '../../../core/network/paged.dart';
import 'paciente_resumen.dart';

/// Lists patients. Transport and failures live in [ApiClient].
class PatientsRepository {
  const PatientsRepository(this._api);

  final ApiClient _api;

  Future<Paged<PacienteResumen>> recientes({int limit = 4}) => _api.getPaged(
    '/pacientes',
    query: {'limit': limit},
    itemFromJson: PacienteResumen.fromJson,
  );
}
