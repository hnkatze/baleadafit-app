import 'package:baleadafit/core/network/api_client.dart';
import 'package:baleadafit/core/network/paged.dart';
import 'package:baleadafit/features/planes/data/plan.dart';
import 'package:baleadafit/features/planes/data/planes_providers.dart';
import 'package:baleadafit/features/planes/data/planes_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Espia extends PlanesRepository {
  _Espia() : super(ApiClient(Dio()));

  final listados = <(String, int?)>[];
  final detalles = <String>[];

  @override
  Future<Paged<Plan>> listar(
    String pacienteId, {
    int? limit,
    int? offset,
    String? cursor,
  }) async {
    listados.add((pacienteId, limit));
    return const Paged(
      items: [],
      meta: PageMeta(limit: 100, offset: 0, total: 0, hasMore: false),
    );
  }

  @override
  Future<PlanDetalle> detalle(String planId) async {
    detalles.add(planId);
    return PlanDetalle(
      id: planId,
      nombre: 'Plan',
      estado: EstadoPlan.borrador,
      origen: OrigenPlan.reglas,
    );
  }
}

void main() {
  test(
    'planesDePacienteProvider asks for the patient with the widest page',
    () async {
      final espia = _Espia();
      final container = ProviderContainer(
        overrides: [planesRepositoryProvider.overrideWithValue(espia)],
      );
      addTearDown(container.dispose);

      final page = await container.read(planesDePacienteProvider('p1').future);

      expect(espia.listados.single, ('p1', 100));
      expect(page.meta.total, 0);
    },
  );

  test('planDetalleProvider asks for the plan by id', () async {
    final espia = _Espia();
    final container = ProviderContainer(
      overrides: [planesRepositoryProvider.overrideWithValue(espia)],
    );
    addTearDown(container.dispose);

    final plan = await container.read(planDetalleProvider('pl9').future);

    expect(espia.detalles.single, 'pl9');
    expect(plan.id, 'pl9');
  });
}
