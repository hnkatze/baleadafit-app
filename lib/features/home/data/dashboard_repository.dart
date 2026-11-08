import '../../../core/network/api_client.dart';
import 'dashboard_resumen.dart';

/// Reads the home summary. The transport and its failures live in [ApiClient].
class DashboardRepository {
  const DashboardRepository(this._api);

  final ApiClient _api;

  Future<DashboardResumen> resumen() =>
      _api.get('/dashboard', fromJson: DashboardResumen.fromJson);
}
