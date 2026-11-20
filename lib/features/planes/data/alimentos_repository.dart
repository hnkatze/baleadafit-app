import '../../../core/network/api_client.dart';
import '../../../core/network/paged.dart';
import 'alimento_catalogo.dart';

/// `GET /alimentos`: the food catalogue, read only.
///
/// The picker of the meal-time editor is its only consumer today. The catalogue
/// module owns this endpoint eventually; until it exists the query lives here,
/// with the fields a plan row draws and nothing else.
class AlimentosRepository {
  const AlimentosRepository(this._api);

  final ApiClient _api;

  /// One page of a search by name. The endpoint pages with `limit`/`offset` or a
  /// cursor; the picker needs the first page of a query, so neither travels.
  ///
  /// Only active foods are returned by the endpoint, and `q` is what the
  /// nutritionist typed: no filter is applied on the client.
  Future<Paged<AlimentoCatalogo>> buscar(String consulta, {int limit = 20}) =>
      _api.getPaged(
        '/alimentos',
        itemFromJson: AlimentoCatalogo.fromJson,
        query: {'q': consulta, 'limit': limit},
      );
}
