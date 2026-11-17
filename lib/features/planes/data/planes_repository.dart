import '../../../core/network/api_client.dart';
import '../../../core/network/paged.dart';
import 'plan.dart';

/// `distribucionMacros` of the generator. The contract asks for the three
/// together or none, so they are all required here.
///
/// The values are **fractions** 0..1 (`0.25` is 25%), not percentages.
class DistribucionMacros {
  const DistribucionMacros({
    required this.proteina,
    required this.carbohidrato,
    required this.grasa,
  });

  final double proteina;
  final double carbohidrato;
  final double grasa;

  Map<String, Object?> toJson() => {
    'proteina': proteina,
    'carbohidrato': carbohidrato,
    'grasa': grasa,
  };
}

/// One food of the list that replaces a meal time: `{alimentoId, porciones}`.
class ItemReemplazo {
  const ItemReemplazo({required this.alimentoId, required this.porciones});

  final String alimentoId;

  /// 0.25 to 6, in multiples of 0.25.
  final double porciones;

  Map<String, Object?> toJson() => {
    'alimentoId': alimentoId,
    'porciones': porciones,
  };
}

/// The meal-plan endpoints of the API the app uses, and nothing else.
///
/// `PATCH /planes/{id}` is not here on purpose: no screen edits the name, the
/// goals or the justification. The deprecated `PUT /planes/{id}/tiempos/{tipo}/items`
/// (no day, equivalent to `LUNES`) is never used.
class PlanesRepository {
  const PlanesRepository(this._api);

  final ApiClient _api;

  /// `GET /pacientes/{id}/planes`, newest first, without the week.
  ///
  /// The API sorts and does not filter: the state is read row by row. The page
  /// is the standard one; an [offset] and a [cursor] never travel together.
  Future<Paged<Plan>> listar(
    String pacienteId, {
    int? limit,
    int? offset,
    String? cursor,
  }) {
    if (offset != null && cursor != null) {
      throw ArgumentError('offset and cursor cannot be used together');
    }
    return _api.getPaged(
      '/pacientes/${Uri.encodeComponent(pacienteId)}/planes',
      itemFromJson: Plan.fromJson,
      query: {'limit': ?limit, 'offset': ?offset, 'cursor': ?cursor},
    );
  }

  /// `POST /pacientes/{id}/planes/generar`. Answers 201 with the detail of a
  /// plan created in `BORRADOR`. It needs at least one measurement of the
  /// patient, and the contract does not declare the error without one.
  ///
  /// Every field is optional and only what is given travels, except [usarIa],
  /// which is always sent (`true` by default, like the contract). [kcalObjetivo]
  /// goes from 1000 to 5000. [distribucionMacros] and [distribucionTiempos] are
  /// **fractions**. A blank [indicaciones] is not sent.
  Future<PlanDetalle> generar(
    String pacienteId, {
    String? nombre,
    int? kcalObjetivo,
    bool usarIa = true,
    String? indicaciones,
    DistribucionMacros? distribucionMacros,
    Map<TipoComida, double>? distribucionTiempos,
  }) {
    final texto = indicaciones?.trim();
    return _api.post(
      '/pacientes/${Uri.encodeComponent(pacienteId)}/planes/generar',
      body: {
        'nombre': ?nombre,
        'kcalObjetivo': ?kcalObjetivo,
        'usarIa': usarIa,
        'indicaciones': ?(texto == null || texto.isEmpty ? null : texto),
        'distribucionMacros': ?distribucionMacros?.toJson(),
        'distribucionTiempos': ?distribucionTiempos?.map(
          (tipo, fraccion) => MapEntry(tipo.codigo, fraccion),
        ),
      },
      // The assistant answers in up to 180 seconds. Without its own bound the
      // client would cut a generation the server did finish.
      receiveTimeout: const Duration(minutes: 4),
      fromJson: PlanDetalle.fromJson,
    );
  }

  /// `GET /planes/{id}`: the week, the items and the totals.
  Future<PlanDetalle> detalle(String planId) => _api.get(
    '/planes/${Uri.encodeComponent(planId)}',
    fromJson: PlanDetalle.fromJson,
  );

  /// `POST /planes/{id}/activar`. Answers 201 with the detail; the previous
  /// active plan of the patient becomes `ARCHIVADO`. The 400 the contract does
  /// not explain reaches the caller as an `ApiFailure`.
  Future<PlanDetalle> activar(String planId) => _api.post(
    '/planes/${Uri.encodeComponent(planId)}/activar',
    fromJson: PlanDetalle.fromJson,
  );

  /// `PUT /planes/{id}/tiempos/{dia}/{tipo}/items`.
  ///
  /// It replaces the **whole** list of one meal time of one day, so [items] is
  /// always the final state, not the change, and `[]` is a valid list (the
  /// contract declares a maximum of 12 and no minimum). Answers 200 with the
  /// full plan, which replaces whatever the caller holds.
  Future<PlanDetalle> reemplazarItems(
    String planId, {
    required DiaSemana dia,
    required TipoComida tipo,
    required List<ItemReemplazo> items,
  }) => _api.put(
    '/planes/${Uri.encodeComponent(planId)}'
    '/tiempos/${dia.codigo}/${tipo.codigo}/items',
    body: {'items': items.map((item) => item.toJson()).toList()},
    fromJson: PlanDetalle.fromJson,
  );

  /// `DELETE /planes/{id}`: only a `BORRADOR`. Answers 204 with no body.
  Future<void> eliminar(String planId) =>
      _api.deleteAck('/planes/${Uri.encodeComponent(planId)}');
}
