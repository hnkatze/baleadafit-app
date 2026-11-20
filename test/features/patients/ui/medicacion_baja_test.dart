import 'package:baleadafit/core/network/api_client.dart';
import 'package:baleadafit/core/theme/app_theme.dart';
import 'package:baleadafit/features/patients/data/medicamento.dart';
import 'package:baleadafit/features/patients/data/patients_providers.dart';
import 'package:baleadafit/features/patients/data/patients_repository.dart';
import 'package:baleadafit/features/patients/ui/medicacion/baja_medicamento.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_http_adapter.dart';
import '../../../support/pump.dart';

const _medicamento = Medicamento(
  id: 'med-1',
  nombre: 'Metformina',
  pacienteId: 'pac-1',
  dosis: '500 mg',
);

Map<String, Object?> _ficha() => {
  'ok': true,
  'data': {
    'paciente': {'id': 'pac-1', 'nombre': 'Paciente', 'apellido': 'X'},
  },
};

late FakeHttpAdapter _adapter;
bool? _resultado;
int _cargasFicha = 0;

Future<void> _pump(WidgetTester tester, {int statusBaja = 200}) async {
  _resultado = null;
  _cargasFicha = 0;
  _adapter = FakeHttpAdapter((options) async {
    if (options.method == 'DELETE') {
      if (statusBaja == 404) {
        return jsonBody({
          'ok': false,
          'error': {
            'codigo': 'NO_ENCONTRADO',
            'mensaje': 'No existe o no pertenece al usuario.',
          },
        }, status: 404);
      }
      return jsonBody({
        'ok': true,
        'data': {'id': 'med-1', 'nombre': 'Metformina', 'activo': false},
      });
    }
    _cargasFicha++;
    return jsonBody(_ficha());
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        patientsRepositoryProvider.overrideWithValue(
          PatientsRepository(ApiClient(dioWith(_adapter))),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) {
              // Keeps the ficha alive so its invalidation is observable.
              ref.watch(pacienteFichaProvider('pac-1'));
              return Center(
                child: TextButton(
                  onPressed: () async {
                    _resultado = await confirmarBajaMedicamento(
                      context,
                      ref,
                      pacienteId: 'pac-1',
                      medicamento: _medicamento,
                    );
                  },
                  child: const Text('abrir'),
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
  await pumpStable(tester);
}

Future<void> _abrir(WidgetTester tester) async {
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

Finder get _confirmar => find.descendant(
  of: find.byType(AlertDialog),
  matching: find.widgetWithText(FilledButton, 'Dar de baja'),
);

List<String> get _deletes => _adapter.requests
    .where((r) => r.method == 'DELETE')
    .map((r) => r.path)
    .toList();

void main() {
  testWidgets('the dialog only closes with the red cross (S9)', (tester) async {
    await _pump(tester);
    await _abrir(tester);

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('¿Dar de baja Metformina?'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Cancelar'), findsNothing);
    expect(find.widgetWithText(TextButton, 'Cancelar'), findsNothing);
    expect(find.byTooltip('Cancelar'), findsOneWidget);
    final icono = tester.widget<Icon>(
      find.descendant(
        of: find.byKey(const Key('cerrar-dialogo')),
        matching: find.byIcon(Icons.close),
      ),
    );
    expect(
      icono.color,
      Theme.of(tester.element(find.byType(AlertDialog))).colorScheme.error,
    );
  });

  testWidgets('the cross closes without calling the API (S9)', (tester) async {
    await _pump(tester);
    final antes = _cargasFicha;
    await _abrir(tester);

    await tester.tap(find.byKey(const Key('cerrar-dialogo')));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(_resultado, isFalse);
    expect(_deletes, isEmpty);
    expect(_cargasFicha, antes);
  });

  testWidgets('confirming deletes once, reloads the ficha, returns true (S9)', (
    tester,
  ) async {
    await _pump(tester);
    final antes = _cargasFicha;
    await _abrir(tester);

    await tester.tap(_confirmar);
    await pumpStable(tester);

    expect(_deletes, ['/medicamentos/med-1']);
    expect(_resultado, isTrue);
    expect(find.byType(AlertDialog), findsNothing);
    expect(_cargasFicha, greaterThan(antes));
  });

  testWidgets('a 404 shows the message and returns false (S9)', (tester) async {
    await _pump(tester, statusBaja: 404);
    final antes = _cargasFicha;
    await _abrir(tester);

    await tester.tap(_confirmar);
    await pumpStable(tester);

    expect(_deletes, ['/medicamentos/med-1']);
    expect(_resultado, isFalse);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('No existe o no pertenece al usuario.'), findsOneWidget);
    expect(_cargasFicha, antes);
  });
}
