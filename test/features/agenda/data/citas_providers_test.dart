import 'package:baleadafit/core/network/api_client.dart';
import 'package:baleadafit/core/network/paged.dart';
import 'package:baleadafit/features/agenda/data/cita.dart';
import 'package:baleadafit/features/agenda/data/citas_providers.dart';
import 'package:baleadafit/features/agenda/data/citas_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Espia extends CitasRepository {
  _Espia() : super(ApiClient(Dio()));

  final llamadas = <DateTime>[];
  final hastas = <DateTime>[];
  var citas = <Cita>[];

  @override
  Future<Paged<Cita>> listar({
    required DateTime desde,
    required DateTime hasta,
    EstadoCita? estado,
    String? pacienteId,
    int limit = 100,
  }) async {
    llamadas.add(desde);
    hastas.add(hasta);
    return Paged(
      items: citas,
      meta: PageMeta(limit: limit, offset: 0, total: 0, hasMore: false),
    );
  }
}

void main() {
  test('agendaDelDiaProvider asks for the day without its time', () async {
    final espia = _Espia();
    final container = ProviderContainer(
      overrides: [citasRepositoryProvider.overrideWithValue(espia)],
    );
    addTearDown(container.dispose);

    await container.read(
      agendaDelDiaProvider(DateTime(2026, 11, 7, 15, 30)).future,
    );

    expect(espia.llamadas.single, DateTime(2026, 11, 7));
  });

  test(
    'citasDelMesProvider asks for the whole month and counts per local day',
    () async {
      final espia = _Espia()
        ..citas = [
          for (final (id, hora) in [
            ('a', DateTime(2026, 11, 7, 9)),
            ('b', DateTime(2026, 11, 7, 23, 30)),
            ('c', DateTime(2026, 11, 8, 0, 15)),
          ])
            Cita(id: id, pacienteId: 'p', fechaHora: hora),
        ];
      final container = ProviderContainer(
        overrides: [citasRepositoryProvider.overrideWithValue(espia)],
      );
      addTearDown(container.dispose);

      final mes = await container.read(
        citasDelMesProvider(DateTime(2026, 11, 19, 8)).future,
      );

      expect(espia.llamadas.single, DateTime(2026, 11));
      expect(espia.hastas.single, DateTime(2026, 11, 30));
      expect(mes.cuantasEl(DateTime(2026, 11, 7)), 2);
      expect(mes.cuantasEl(DateTime(2026, 11, 8, 15)), 1);
      expect(mes.cuantasEl(DateTime(2026, 11, 9)), 0);
    },
  );

  test(
    'CitasDelMes groups by the local day of an instant, not the UTC one',
    () {
      final instante = DateTime.utc(2026, 11, 8, 1);
      final local = instante.toLocal();
      final mes = CitasDelMes([
        Cita(id: 'x', pacienteId: 'p', fechaHora: instante),
      ]);

      expect(mes.cuantasEl(DateTime(local.year, local.month, local.day)), 1);
    },
  );
}
