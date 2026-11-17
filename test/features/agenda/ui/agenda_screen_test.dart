import 'dart:async';

import 'package:baleadafit/core/network/api_failure.dart';
import 'package:baleadafit/core/network/paged.dart';
import 'package:baleadafit/core/theme/app_theme.dart';
import 'package:baleadafit/features/agenda/data/cita.dart';
import 'package:baleadafit/features/agenda/data/citas_providers.dart';
import 'package:baleadafit/features/agenda/ui/agenda_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/pump.dart';

Paged<Cita> _pagina(List<Cita> citas) => Paged(
  items: citas,
  meta: PageMeta(limit: 100, offset: 0, total: citas.length, hasMore: false),
);

Cita _cita({
  String id = 'c1',
  DateTime? fechaHora,
  EstadoCita estado = EstadoCita.programada,
  String motivo = 'Revisión de mediciones',
}) => Cita(
  id: id,
  pacienteId: 'p1',
  fechaHora: fechaHora ?? DateTime(2026, 11, 7, 9),
  duracionMin: 45,
  estado: estado,
  motivo: motivo,
  paciente: const PacienteCita(
    id: 'p1',
    nombre: 'Paciente',
    apellido: 'De Prueba',
    telefono: '9999-9999',
  ),
);

Future<void> _pump(
  WidgetTester tester, {
  required Future<Paged<Cita>> Function(DateTime dia) cargar,
  Future<CitasDelMes> Function(DateTime mes)? cargarMes,
  DateTime? diaInicial,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        agendaDelDiaProvider.overrideWith((ref, dia) => cargar(dia)),
        citasDelMesProvider.overrideWith(
          (ref, mes) =>
              cargarMes?.call(mes) ?? Future.value(CitasDelMes(const [])),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: AgendaScreen(diaInicial: diaInicial)),
      ),
    ),
  );
}

void main() {
  testWidgets('pulling down reloads the day and the month', (tester) async {
    var dias = 0;
    var meses = 0;
    await _pump(
      tester,
      cargar: (_) async {
        dias++;
        return _pagina([_cita()]);
      },
      cargarMes: (_) async {
        meses++;
        return CitasDelMes(const []);
      },
      diaInicial: DateTime(2026, 11, 7),
    );
    await pumpStable(tester);
    expect((dias, meses), (1, 1));

    await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
    await tester.pumpAndSettle();

    expect((dias, meses), (2, 2));
    expect(find.text('Paciente De Prueba'), findsOneWidget);
  });

  testWidgets('pulling down reloads a day with no appointments', (
    tester,
  ) async {
    var dias = 0;
    await _pump(
      tester,
      cargar: (_) async {
        dias++;
        return _pagina(const []);
      },
    );
    await pumpStable(tester);
    expect(dias, 1);

    await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
    await tester.pumpAndSettle();

    expect(dias, 2);
    expect(find.text('Sin citas este día'), findsOneWidget);
  });

  testWidgets('shows a spinner while the agenda loads', (tester) async {
    await _pump(tester, cargar: (_) => Completer<Paged<Cita>>().future);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows the appointments of the day', (tester) async {
    await _pump(tester, cargar: (_) async => _pagina([_cita()]));
    await pumpStable(tester);

    expect(find.text('Paciente De Prueba'), findsOneWidget);
    expect(find.text('09:00'), findsOneWidget);
    expect(find.text('Revisión de mediciones'), findsOneWidget);
    expect(find.text('Programada'), findsOneWidget);
  });

  testWidgets('shows the empty state when the day has no appointments', (
    tester,
  ) async {
    await _pump(tester, cargar: (_) async => _pagina(const []));
    await pumpStable(tester);

    expect(find.text('Sin citas este día'), findsOneWidget);
  });

  testWidgets('shows the API message and retries the load', (tester) async {
    var llamadas = 0;
    await _pump(
      tester,
      cargar: (_) async {
        llamadas++;
        if (llamadas == 1) {
          throw const ApiFailure(mensaje: 'No pudimos cargar la agenda.');
        }
        return _pagina([_cita()]);
      },
    );
    await pumpStable(tester);

    expect(find.text('No pudimos cargar la agenda.'), findsOneWidget);

    await tester.tap(find.text('Reintentar'));
    await pumpStable(tester);

    expect(find.text('Paciente De Prueba'), findsOneWidget);
  });

  testWidgets('asks for the next day when the arrow is tapped', (tester) async {
    final pedidos = <DateTime>[];
    await _pump(
      tester,
      cargar: (dia) async {
        pedidos.add(dia);
        return _pagina(const []);
      },
    );
    await pumpStable(tester);

    final hoy = DateTime.now();
    expect(pedidos.single, DateTime(hoy.year, hoy.month, hoy.day));

    await tester.tap(find.byTooltip('Día siguiente'));
    await pumpStable(tester);

    expect(pedidos.last, DateTime(hoy.year, hoy.month, hoy.day + 1));
  });

  testWidgets('comes back to today from another day', (tester) async {
    final pedidos = <DateTime>[];
    await _pump(
      tester,
      cargar: (dia) async {
        pedidos.add(dia);
        return _pagina(const []);
      },
    );
    await pumpStable(tester);

    expect(find.text('Hoy'), findsNothing);

    await tester.tap(find.byTooltip('Día siguiente'));
    await pumpStable(tester);
    expect(find.text('Hoy'), findsOneWidget);

    await tester.tap(find.text('Hoy'));
    await pumpStable(tester);

    final hoy = DateTime.now();
    expect(pedidos.last, DateTime(hoy.year, hoy.month, hoy.day));
    expect(find.text('Hoy'), findsNothing);
  });

  group('month strip', () {
    Future<Paged<Cita>> vacio(DateTime _) async => _pagina(const []);
    final celdas = find.byWidgetPredicate(
      (w) => w.key.toString().startsWith("[<'dia-"),
    );

    testWidgets('labels a 31-day month and draws 31 day cells', (tester) async {
      await _pump(tester, cargar: vacio, diaInicial: DateTime(2026, 12, 10));
      await pumpStable(tester);

      expect(find.text('Diciembre 2026'), findsOneWidget);
      expect(celdas, findsNWidgets(31));
      for (final inicial in ['L', 'J', 'V', 'S', 'D']) {
        expect(find.text(inicial), findsWidgets);
      }
    });

    testWidgets('labels a 28-day month and draws 28 day cells', (tester) async {
      await _pump(tester, cargar: vacio, diaInicial: DateTime(2027, 2, 3));
      await pumpStable(tester);

      expect(find.text('Febrero 2027'), findsOneWidget);
      expect(celdas, findsNWidgets(28));
    });

    testWidgets('marks only the days that have appointments', (tester) async {
      await _pump(
        tester,
        cargar: vacio,
        cargarMes: (_) async => CitasDelMes([
          _cita(id: 'a', fechaHora: DateTime(2026, 12, 4, 9)),
          _cita(id: 'b', fechaHora: DateTime(2026, 12, 4, 11)),
        ]),
        diaInicial: DateTime(2026, 12, 10),
      );
      await pumpStable(tester);

      expect(find.byKey(const Key('marca-2026-12-04')), findsOneWidget);
      expect(find.byKey(const Key('marca-2026-12-05')), findsNothing);
      expect(find.bySemanticsLabel(RegExp('2 citas')), findsOneWidget);
    });

    testWidgets('tapping a day selects it and loads it', (tester) async {
      final pedidos = <DateTime>[];
      await _pump(
        tester,
        cargar: (dia) async {
          pedidos.add(dia);
          return _pagina(const []);
        },
        diaInicial: DateTime(2026, 12, 10),
      );
      await pumpStable(tester);

      await tester.tap(find.byKey(const Key('dia-2026-12-20')));
      await pumpStable(tester);

      expect(pedidos.last, DateTime(2026, 12, 20));
      expect(find.text('Domingo, 20 de diciembre'), findsOneWidget);
    });

    testWidgets('the month arrows move the strip and the day', (tester) async {
      final pedidos = <DateTime>[];
      await _pump(
        tester,
        cargar: (dia) async {
          pedidos.add(dia);
          return _pagina(const []);
        },
        diaInicial: DateTime(2026, 12, 31),
      );
      await pumpStable(tester);

      await tester.tap(find.byTooltip('Mes siguiente'));
      await pumpStable(tester);
      expect(find.text('Enero 2027'), findsOneWidget);
      expect(pedidos.last, DateTime(2027, 1, 31));

      await tester.tap(find.byTooltip('Mes anterior'));
      await tester.tap(find.byTooltip('Mes anterior'));
      await pumpStable(tester);
      expect(find.text('Noviembre 2026'), findsOneWidget);
      expect(pedidos.last, DateTime(2026, 11, 30));
    });

    testWidgets('the day arrows carry the strip into another month', (
      tester,
    ) async {
      await _pump(tester, cargar: vacio, diaInicial: DateTime(2026, 11, 30));
      await pumpStable(tester);
      expect(find.text('Noviembre 2026'), findsOneWidget);

      await tester.tap(find.byTooltip('Día siguiente'));
      await pumpStable(tester);

      expect(find.text('Diciembre 2026'), findsOneWidget);
    });
  });
}
