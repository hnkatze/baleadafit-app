import 'package:baleadafit/core/network/api_client.dart';
import 'package:baleadafit/core/network/api_failure.dart';
import 'package:baleadafit/core/network/paged.dart';
import 'package:baleadafit/core/theme/app_theme.dart';
import 'package:baleadafit/features/agenda/data/cita.dart';
import 'package:baleadafit/features/agenda/data/citas_providers.dart';
import 'package:baleadafit/features/agenda/data/citas_repository.dart';
import 'package:baleadafit/features/agenda/ui/nueva_cita_screen.dart';
import 'package:baleadafit/features/patients/data/paciente_resumen.dart';
import 'package:baleadafit/features/patients/data/patients_providers.dart';
import 'package:baleadafit/features/patients/data/patients_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/pump.dart';

class _RepoFalso extends CitasRepository {
  _RepoFalso({this.falla}) : super(ApiClient(Dio()));

  final ApiFailure? falla;
  final creadas = <Map<String, Object?>>[];

  @override
  Future<Cita> crear({
    required String pacienteId,
    required DateTime fechaHora,
    int duracionMin = 45,
    String motivo = '',
    String notas = '',
  }) async {
    creadas.add({
      'pacienteId': pacienteId,
      'fechaHora': fechaHora,
      'duracionMin': duracionMin,
      'motivo': motivo,
      'notas': notas,
    });
    if (falla != null) throw falla!;
    return Cita(
      id: 'c1',
      pacienteId: pacienteId,
      fechaHora: fechaHora,
      duracionMin: duracionMin,
      motivo: motivo,
    );
  }
}

Paged<PacienteResumen> _directorio(List<PacienteResumen> pacientes) => Paged(
  items: pacientes,
  meta: PageMeta(
    limit: 100,
    offset: 0,
    total: pacientes.length,
    hasMore: false,
  ),
);

class _PacientesFalso extends PatientsRepository {
  _PacientesFalso() : super(ApiClient(Dio()));

  @override
  Future<Paged<PacienteResumen>> directorio({
    String? q,
    int limit = 100,
  }) async => _directorio(const [
    PacienteResumen(id: 'p1', nombre: 'Paciente', apellido: 'De Prueba'),
  ]);
}

Future<void> _pump(WidgetTester tester, {required _RepoFalso repo}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        citasRepositoryProvider.overrideWithValue(repo),
        patientsRepositoryProvider.overrideWithValue(_PacientesFalso()),
      ],
      child: MaterialApp(theme: AppTheme.light, home: const NuevaCitaScreen()),
    ),
  );
  await pumpStable(tester);
}

Future<void> _elegirPaciente(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('paciente')));
  await pumpStable(tester);
  await tester.enterText(
    find.descendant(
      of: find.byType(BottomSheet),
      matching: find.byType(TextField),
    ),
    'pac',
  );
  await tester.pump(const Duration(milliseconds: 400));
  await pumpStable(tester);
  await tester.tap(find.text('Paciente De Prueba'));
  await pumpStable(tester);
}

Future<void> _hastaElBoton(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.text('Programar cita'),
    120,
    scrollable: find.byType(Scrollable).first,
  );
  await pumpStable(tester);
}

void main() {
  testWidgets('shows the fields of a new appointment', (tester) async {
    await _pump(tester, repo: _RepoFalso());

    // The form is longer than the viewport, so each field is reached the way
    // the nutritionist reaches it.
    for (final etiqueta in [
      'Paciente',
      'Fecha',
      'Hora',
      'Duración · min',
      'Motivo',
      'Notas · opcional',
      'Programar cita',
    ]) {
      await tester.scrollUntilVisible(
        find.text(etiqueta),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(etiqueta), findsOneWidget);
    }
  });

  testWidgets('asks for a patient before reaching the API', (tester) async {
    final repo = _RepoFalso();
    await _pump(tester, repo: repo);

    await _hastaElBoton(tester);
    await tester.tap(find.text('Programar cita'));
    await pumpStable(tester);

    expect(find.text('Elegí un paciente'), findsOneWidget);
    expect(repo.creadas, isEmpty);
  });

  testWidgets('creates the appointment with what was written', (tester) async {
    final repo = _RepoFalso();
    await _pump(tester, repo: repo);

    await _elegirPaciente(tester);

    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('motivo')),
        matching: find.byType(TextFormField),
      ),
      'Control mensual',
    );
    await _hastaElBoton(tester);
    await tester.tap(find.text('Programar cita'));
    await pumpStable(tester);

    expect(repo.creadas.single['pacienteId'], 'p1');
    expect(repo.creadas.single['motivo'], 'Control mensual');
    expect(repo.creadas.single['duracionMin'], 45);
    expect(repo.creadas.single['fechaHora'], isA<DateTime>());
  });

  testWidgets('shows the overlap message and keeps what was written', (
    tester,
  ) async {
    await _pump(
      tester,
      repo: _RepoFalso(
        falla: const ApiFailure(
          mensaje: 'Esa hora se traslapa con otra cita.',
          statusCode: 409,
        ),
      ),
    );

    await _elegirPaciente(tester);
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('motivo')),
        matching: find.byType(TextFormField),
      ),
      'Control mensual',
    );
    await _hastaElBoton(tester);
    await tester.tap(find.text('Programar cita'));
    await pumpStable(tester);

    expect(find.text('Esa hora se traslapa con otra cita.'), findsOneWidget);
    expect(find.text('Control mensual'), findsOneWidget);
  });
}
