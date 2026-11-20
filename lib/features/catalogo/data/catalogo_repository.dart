import '../../../core/network/api_client.dart';
import '../../../core/network/paged.dart';
import 'alimento.dart';
import 'alimento_version.dart';
import 'restriccion.dart';

/// The food-catalogue endpoints of the API the app uses, and nothing else.
class CatalogoRepository {
  const CatalogoRepository(this._api);

  final ApiClient _api;

  /// `GET /alimentos`. Only the filters given travel; [excluir] goes as
  /// comma-separated restriction codes (`lactosa,gluten`) and an empty list is
  /// not sent. An [offset] and a [cursor] never travel together.
  Future<Paged<Alimento>> buscar({
    String? q,
    String? categoria,
    String? tipoComida,
    bool? soloTipicos,
    List<String>? excluir,
    int? limit,
    int? offset,
    String? cursor,
  }) {
    if (offset != null && cursor != null) {
      throw ArgumentError('offset and cursor cannot be used together');
    }
    return _api.getPaged(
      '/alimentos',
      itemFromJson: Alimento.fromJson,
      query: {
        'q': ?q,
        'categoria': ?categoria,
        'tipoComida': ?tipoComida,
        'soloTipicos': ?soloTipicos,
        'excluir': ?(excluir == null || excluir.isEmpty
            ? null
            : excluir.join(',')),
        'limit': ?limit,
        'offset': ?offset,
        'cursor': ?cursor,
      },
    );
  }

  /// `GET /alimentos/{id}`: the 21 fields, micronutrients included.
  Future<Alimento> detalle(String id) => _api.get(
    '/alimentos/${Uri.encodeComponent(id)}',
    fromJson: Alimento.fromJson,
  );

  /// `POST /alimentos`. Values are per portion.
  Future<Alimento> crear(Map<String, Object?> body) =>
      _api.post('/alimentos', body: body, fromJson: Alimento.fromJson);

  /// `PATCH /alimentos/{id}`. Partial: an omitted field keeps its value.
  Future<Alimento> actualizar(
    String id, {
    required Map<String, Object?> body,
  }) => _api.patch(
    '/alimentos/${Uri.encodeComponent(id)}',
    body: body,
    fromJson: Alimento.fromJson,
  );

  /// Logical delete: `PATCH /alimentos/{id}` with `activo: false`. It answers
  /// 200 with the food, not 204; nothing is erased.
  Future<Alimento> darDeBaja(String id) =>
      actualizar(id, body: const {'activo': false});

  /// `GET /alimentos/{id}/versiones`, newest first.
  Future<Paged<AlimentoVersion>> versiones(
    String id, {
    int? limit,
    int? offset,
  }) => _api.getPaged(
    '/alimentos/${Uri.encodeComponent(id)}/versiones',
    itemFromJson: AlimentoVersion.fromJson,
    query: {'limit': ?limit, 'offset': ?offset},
  );

  /// `GET /restricciones`: the vocabulary of `contiene` and `excluir`. No
  /// pagination.
  Future<List<Restriccion>> restricciones() =>
      _api.getList('/restricciones', itemFromJson: Restriccion.fromJson);
}
