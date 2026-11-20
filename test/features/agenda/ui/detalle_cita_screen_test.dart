import 'package:baleadafit/core/network/api_client.dart';
import 'package:baleadafit/core/network/api_failure.dart';
import 'package:baleadafit/core/theme/app_theme.dart';
import 'package:baleadafit/features/agenda/data/cita.dart';
import 'package:baleadafit/features/agenda/data/citas_providers.dart';
import 'package:baleadafit/features/agenda/data/citas_repository.dart';
import 'package:baleadafit/features/agenda/ui/detalle_cita_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/pump.dart';

class _RepoFalso extends CitasRepository {
  _RepoFalso({this.falla}) : super(ApiClient(Dio()));

  final ApiFailure? falla;
  final parches = <Map<String, Object?>>[];

  @override
  Future<Cita> actualizar(
    String id, {
    DateTime? fechaHora,
    int? duracionMin,
    EstadoCita? estado,
    String? motivo,
    String? notas,
    String? subjetivo,
    String? objetivo,
    String? analisis,
    String? plan,
    DateTime? proximaCitaSugerida,
  }) async {
    parches.add({
      'id': id,
      'fechaHora': fechaHora,
      'estado': estado,
      'subjetivo': subjetivo,
      'objetivo': objetivo,
      'analisis': analisis,
      'plan': plan,
      'proximaCitaSugerida': proximaCitaSugerida,
    });
    if (falla != null) throw falla!;
    return _cita();
  }
}

Cita _cita({EstadoCita estado = EstadoCita.programada}) => Cita(
  id: 'c1',
  pacienteId: 'p1',
  fechaHora: DateTime(2026, 11, 7, 9),
  duracionMin: 45,
  estado: estado,
  motivo: 'Revisión de mediciones',
  paciente: const PacienteCita(
    id: 'p1',
    nombre: 'Paciente',
    apellido: 'De Prueba',
    telefono: '9999-9999',
  ),
  subjetivo: 'Refiere buen apetito',
);

Future<void> _pump(
  WidgetTester tester, {
  required _RepoFalso repo,
  Cita? cita,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [citasRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => DetalleCitaScreen(
                    cita: cita ?? _cita(),
                    dia: DateTime(2026, 11, 7),
                  ),
                ),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await pumpStable(tester);
}

Finder _campo(String clave) => find.descendant(
  of: find.byKey(Key(clave)),
  matching: find.byType(TextFormField),
);

Future<void> _hasta(WidgetTester tester, Finder objetivo) async {
  await tester.scrollUntilVisible(
    objetivo,
    120,
    scrollable: find.byType(Scrollable).first,
  );
  await pumpStable(tester);
}

Future<void> _escribirSoap(WidgetTester tester) async {
  for (final (clave, valor) in [
    ('subjetivo', 'S escrito'),
    ('objetivo', 'O escrito'),
    ('analisis', 'A escrito'),
    ('plan', 'P escrito'),
  ]) {
    await _hasta(tester, _campo(clave));
    await tester.enterText(_campo(clave), valor);
  }
}

void main() {
  testWidgets('draws the patient, the hour and the SOAP it carries', (
    tester,
  ) async {
    await _pump(tester, repo: _RepoFalso());

    expect(find.text('Paciente De Prueba'), findsOneWidget);
    expect(find.text('07/11/2026 · 09:00'), findsOneWidget);
    expect(find.text('Programada'), findsOneWidget);
    expect(find.text('9999-9999'), findsOneWidget);
    expect(find.text('Refiere buen apetito'), findsOneWidget);
  });

  testWidgets('completes the cita with exactly the four SOAP fields', (
    tester,
  ) async {
    final repo = _RepoFalso();
    await _pump(tester, repo: repo);

    await _escribirSoap(tester);
    await _hasta(tester, find.text('Guardar nota y completar'));
    await tester.tap(find.text('Guardar nota y completar'));
    await pumpStable(tester);

    expect(repo.parches, hasLength(1));
    final parche = repo.parches.single;
    expect(parche['id'], 'c1');
    expect(parche['estado'], EstadoCita.completada);
    expect(parche['subjetivo'], 'S escrito');
    expect(parche['objetivo'], 'O escrito');
    expect(parche['analisis'], 'A escrito');
    expect(parche['plan'], 'P escrito');
    expect(parche['proximaCitaSugerida'], isNull);
    expect(parche['fechaHora'], isNull);
    expect(find.text('Guardar nota y completar'), findsNothing);
  });

  testWidgets('asks before cancelling and patches CANCELADA on confirm', (
    tester,
  ) async {
    final repo = _RepoFalso();
    await _pump(tester, repo: repo);

    await _hasta(tester, find.text('Cancelar cita'));
    await tester.tap(find.text('Cancelar cita'));
    await pumpStable(tester);

    expect(find.text('¿Cancelar esta cita?'), findsOneWidget);
    expect(repo.parches, isEmpty);

    await tester.tap(find.text('Sí, cancelar'));
    await pumpStable(tester, frames: 12);

    expect(repo.parches.single['estado'], EstadoCita.cancelada);
    expect(find.text('Cancelar cita'), findsNothing);
  });

  testWidgets('does not patch when the cancellation is declined', (
    tester,
  ) async {
    final repo = _RepoFalso();
    await _pump(tester, repo: repo);

    await _hasta(tester, find.text('Cancelar cita'));
    await tester.tap(find.text('Cancelar cita'));
    await pumpStable(tester);
    await tester.tap(find.byKey(const Key('cerrar-dialogo')));
    await pumpStable(tester);

    expect(repo.parches, isEmpty);
    expect(find.text('Cancelar cita'), findsOneWidget);
  });

  testWidgets('hides the cancel action on a cancelled cita', (tester) async {
    await _pump(
      tester,
      repo: _RepoFalso(),
      cita: _cita(estado: EstadoCita.cancelada),
    );

    await _hasta(tester, find.text('Reprogramar'));
    expect(find.text('Cancelar cita'), findsNothing);
  });

  testWidgets('reprograms with a new fechaHora only', (tester) async {
    final repo = _RepoFalso();
    await _pump(tester, repo: repo);

    await _hasta(tester, find.text('Reprogramar'));
    await tester.tap(find.text('Reprogramar'));
    await pumpStable(tester);
    await tester.tap(find.text('20'));
    await tester.tap(find.text('OK'));
    await pumpStable(tester);
    await tester.tap(find.text('OK'));
    await pumpStable(tester);

    final parche = repo.parches.single;
    expect(parche['fechaHora'], DateTime(2026, 11, 20, 9));
    expect(parche['estado'], isNull);
    expect(parche['subjetivo'], isNull);
  });

  testWidgets('shows the API message and keeps what was typed', (tester) async {
    final repo = _RepoFalso(
      falla: const ApiFailure(
        mensaje: 'Esa hora se traslapa con otra cita.',
        statusCode: 409,
      ),
    );
    await _pump(tester, repo: repo);

    await _escribirSoap(tester);
    await _hasta(tester, find.text('Guardar nota y completar'));
    await tester.tap(find.text('Guardar nota y completar'));
    await pumpStable(tester);

    expect(repo.parches, hasLength(1));
    expect(find.text('Esa hora se traslapa con otra cita.'), findsOneWidget);
    expect(find.text('Guardar nota y completar'), findsOneWidget);
    await tester.scrollUntilVisible(
      _campo('subjetivo'),
      -120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('S escrito'), findsOneWidget);
  });
}
