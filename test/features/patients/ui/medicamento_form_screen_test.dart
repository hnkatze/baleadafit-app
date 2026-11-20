import 'package:baleadafit/core/network/api_client.dart';
import 'package:baleadafit/core/theme/app_theme.dart';
import 'package:baleadafit/features/patients/data/medicamento.dart';
import 'package:baleadafit/features/patients/data/patients_providers.dart';
import 'package:baleadafit/features/patients/data/patients_repository.dart';
import 'package:baleadafit/features/patients/ui/medicacion/medicamento_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_http_adapter.dart';
import '../../../support/pump.dart';

const _notaS8 =
    'Vaciado, el campo conserva lo que ya estaba: para borrar la dosis o la '
    'frecuencia usá la x del campo.';
const _textoBaja =
    'Se conserva en el historial clínico, pero sale de la lista.';

Map<String, Object?> _entidad({
  String? dosis,
  String? frecuencia,
  Map<String, Object?>? duplicadoDe,
}) => {
  'ok': true,
  'data': {
    'id': 'med-1',
    'pacienteId': 'pac-1',
    'nombre': 'Metformina',
    'dosis': dosis,
    'frecuencia': frecuencia,
    'activo': true,
    'duplicadoDe': duplicadoDe,
  },
};

Map<String, Object?> _error(
  String codigo,
  String mensaje, {
  List<Object?>? detalles,
}) => {
  'ok': false,
  'error': {'codigo': codigo, 'mensaje': mensaje, 'detalles': ?detalles},
};

const _existente = Medicamento(
  id: 'med-1',
  nombre: 'Metformina',
  pacienteId: 'pac-1',
  dosis: '500 mg',
  frecuencia: 'Cada 12 horas con comida',
);

Future<void> _pump(
  WidgetTester tester,
  FakeHttpAdapter adapter, {
  Medicamento? medicamento,
  VoidCallback? onCerrar,
  void Function(Medicamento)? onGuardado,
  VoidCallback? onDarDeBaja,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        patientsRepositoryProvider.overrideWithValue(
          PatientsRepository(ApiClient(dioWith(adapter))),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: MedicamentoFormScreen(
          pacienteId: 'pac-1',
          pacienteNombre: 'Paciente De Prueba',
          medicamento: medicamento,
          onCerrar: onCerrar ?? () {},
          onGuardado: onGuardado ?? (_) {},
          onDarDeBaja: onDarDeBaja,
        ),
      ),
    ),
  );
}

Finder _campo(String clave) => find.byKey(ValueKey(clave));

Future<void> _guardar(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Guardar cambios'));
  await tester.tap(find.text('Guardar cambios'));
  await pumpStable(tester);
}

bool _guardarHabilitado(WidgetTester tester) => tester
    .widget<FilledButton>(find.widgetWithText(FilledButton, 'Guardar cambios'))
    .enabled;

void main() {
  group('alta (S7, S10)', () {
    testWidgets('draws the registration board with the exact copy', (
      tester,
    ) async {
      await _pump(tester, FakeHttpAdapter((_) async => jsonBody(_entidad())));

      expect(find.text('Registrar medicamento'), findsOneWidget);
      expect(find.text('Editar medicamento'), findsNothing);
      expect(find.text('Paciente De Prueba'), findsOneWidget);
      expect(find.text('Nombre'), findsOneWidget);
      expect(find.text('Dosis · opcional'), findsOneWidget);
      expect(find.text('Frecuencia · opcional'), findsOneWidget);
      expect(find.text('500 mg'), findsOneWidget); // placeholder
      expect(find.text('ej. 500 mg'), findsOneWidget);
      expect(find.text('Cada 12 horas con comida'), findsOneWidget);
      expect(find.text('ej. Cada 12 horas con comida'), findsOneWidget);
      expect(find.text('Guardar cambios'), findsOneWidget);
      expect(find.text('Cancelar'), findsNothing);
    });

    testWidgets('POSTs the name and only the optionals with text', (
      tester,
    ) async {
      final adapter = FakeHttpAdapter(
        (_) async => jsonBody(_entidad(dosis: '500 mg'), status: 201),
      );
      Medicamento? guardado;
      await _pump(tester, adapter, onGuardado: (m) => guardado = m);

      await tester.enterText(_campo('nombre'), '  Metformina ');
      await tester.enterText(_campo('dosis'), '500 mg');
      await tester.enterText(_campo('frecuencia'), '   ');
      await _guardar(tester);

      final pedido = adapter.requests.single;
      expect(pedido.method, 'POST');
      expect(pedido.path, '/pacientes/pac-1/medicamentos');
      expect(pedido.data, {'nombre': 'Metformina', 'dosis': '500 mg'});
      expect(guardado?.id, 'med-1');
    });

    testWidgets('a name shorter than 2 characters never reaches the API', (
      tester,
    ) async {
      final adapter = FakeHttpAdapter((_) async => jsonBody(_entidad()));
      await _pump(tester, adapter);

      await tester.enterText(_campo('nombre'), 'M');
      await _guardar(tester);

      expect(adapter.requests, isEmpty);
      expect(find.text('Ingresá entre 2 y 120 caracteres'), findsOneWidget);
      expect(_guardarHabilitado(tester), isTrue);
    });

    testWidgets('the close x calls onCerrar', (tester) async {
      var cerrado = 0;
      await _pump(
        tester,
        FakeHttpAdapter((_) async => jsonBody(_entidad())),
        onCerrar: () => cerrado++,
      );

      await tester.tap(find.byIcon(Icons.close));
      expect(cerrado, 1);
    });
  });

  group('edición (S7, S8, S10)', () {
    testWidgets(
      'preloads the fields and draws S8 and the DAR DE BAJA section',
      (tester) async {
        await _pump(
          tester,
          FakeHttpAdapter((_) async => jsonBody(_entidad())),
          medicamento: _existente,
        );

        expect(find.text('Editar medicamento'), findsOneWidget);
        expect(find.text('Registrar medicamento'), findsNothing);
        String texto(String clave) =>
            tester.widget<TextField>(_campo(clave)).controller!.text;
        expect(texto('nombre'), 'Metformina');
        expect(texto('dosis'), '500 mg');
        expect(texto('frecuencia'), 'Cada 12 horas con comida');
        await tester.ensureVisible(find.text('DAR DE BAJA'));
        expect(find.text(_notaS8), findsOneWidget);
        expect(find.text('DAR DE BAJA'), findsOneWidget);
        expect(find.text(_textoBaja), findsOneWidget);
        expect(find.text('Dar de baja'), findsOneWidget);
      },
    );

    testWidgets('the S8 note and DAR DE BAJA are absent on registration', (
      tester,
    ) async {
      await _pump(tester, FakeHttpAdapter((_) async => jsonBody(_entidad())));

      expect(find.text(_notaS8), findsNothing);
      expect(find.text('DAR DE BAJA'), findsNothing);
      expect(find.text(_textoBaja), findsNothing);
      expect(find.text('Dar de baja'), findsNothing);
    });

    testWidgets('PATCHes omitting the empty optionals', (tester) async {
      final adapter = FakeHttpAdapter((_) async => jsonBody(_entidad()));
      await _pump(
        tester,
        adapter,
        medicamento: const Medicamento(id: 'med-1', nombre: 'Metformina'),
      );

      await tester.enterText(_campo('nombre'), 'Metformina XR');
      await _guardar(tester);

      final pedido = adapter.requests.single;
      expect(pedido.method, 'PATCH');
      expect(pedido.path, '/medicamentos/med-1');
      expect(pedido.data, {'nombre': 'Metformina XR'});
    });

    testWidgets('a field emptied by the user resends the stored value', (
      tester,
    ) async {
      final adapter = FakeHttpAdapter((_) async => jsonBody(_entidad()));
      await _pump(tester, adapter, medicamento: _existente);

      await tester.enterText(_campo('dosis'), '');
      await _guardar(tester);

      expect(adapter.requests.single.data, {
        'nombre': 'Metformina',
        'dosis': '500 mg',
        'frecuencia': 'Cada 12 horas con comida',
      });
    });

    testWidgets('the x of Dosis shows only in edition and only with a value', (
      tester,
    ) async {
      final adapter = FakeHttpAdapter((_) async => jsonBody(_entidad()));
      await _pump(tester, adapter, medicamento: _existente);

      expect(find.byTooltip('Borrar dosis'), findsOneWidget);
      expect(find.byTooltip('Borrar frecuencia'), findsOneWidget);

      await tester.enterText(_campo('dosis'), '');
      await tester.pump();
      expect(find.byTooltip('Borrar dosis'), findsNothing);
      expect(find.byTooltip('Borrar frecuencia'), findsOneWidget);
    });

    testWidgets('no x on a medication stored without dosis (S16)', (
      tester,
    ) async {
      await _pump(
        tester,
        FakeHttpAdapter((_) async => jsonBody(_entidad())),
        medicamento: const Medicamento(id: 'med-1', nombre: 'Metformina'),
      );

      expect(find.byTooltip('Borrar dosis'), findsNothing);
      expect(find.byTooltip('Borrar frecuencia'), findsNothing);
    });

    testWidgets('no x at all on registration', (tester) async {
      await _pump(tester, FakeHttpAdapter((_) async => jsonBody(_entidad())));
      await tester.enterText(_campo('dosis'), '500 mg');
      await tester.pump();

      expect(find.byTooltip('Borrar dosis'), findsNothing);
      expect(find.byTooltip('Borrar frecuencia'), findsNothing);
    });

    testWidgets('tapping the x clears the field and the PATCH sends null', (
      tester,
    ) async {
      final adapter = FakeHttpAdapter((_) async => jsonBody(_entidad()));
      await _pump(tester, adapter, medicamento: _existente);

      await tester.tap(find.byTooltip('Borrar dosis'));
      await tester.pump();
      expect(tester.widget<TextField>(_campo('dosis')).controller!.text, '');
      expect(find.byTooltip('Borrar dosis'), findsNothing);
      await _guardar(tester);

      expect(adapter.requests.single.data, {
        'nombre': 'Metformina',
        'dosis': null,
        'frecuencia': 'Cada 12 horas con comida',
      });
    });

    testWidgets('typing after the x keeps the stored value instead of clearing', (
      tester,
    ) async {
      final adapter = FakeHttpAdapter((_) async => jsonBody(_entidad()));
      await _pump(tester, adapter, medicamento: _existente);

      await tester.tap(find.byTooltip('Borrar dosis'));
      await tester.pump();
      await tester.enterText(_campo('dosis'), '250 mg');
      await tester.pump();
      await tester.enterText(_campo('dosis'), '');
      await tester.pump();
      await _guardar(tester);

      // The mark died with the first keystroke: an empty field means "keep the
      // stored value" (S8), so the PATCH resends it instead of clearing it.
      expect(adapter.requests.single.data, {
        'nombre': 'Metformina',
        'dosis': '500 mg',
        'frecuencia': 'Cada 12 horas con comida',
      });
    });

    testWidgets('tapping Dar de baja delegates and never calls the API', (
      tester,
    ) async {
      final adapter = FakeHttpAdapter((_) async => jsonBody(_entidad()));
      var bajas = 0;
      await _pump(
        tester,
        adapter,
        medicamento: _existente,
        onDarDeBaja: () => bajas++,
      );

      await tester.ensureVisible(find.text('Dar de baja'));
      await tester.tap(find.text('Dar de baja'));
      await pumpStable(tester);

      expect(bajas, 1);
      expect(adapter.requests, isEmpty);
    });
  });

  group('duplicado (S17)', () {
    testWidgets(
      'an alta with duplicadoDe warns with the name and still saves',
      (tester) async {
        final adapter = FakeHttpAdapter(
          (_) async => jsonBody(
            _entidad(duplicadoDe: {'id': 'med-0', 'nombre': 'Metformina'}),
            status: 201,
          ),
        );
        Medicamento? guardado;
        await _pump(tester, adapter, onGuardado: (m) => guardado = m);

        await tester.enterText(_campo('nombre'), 'Metformina');
        await _guardar(tester);

        expect(
          find.text(
            'Ya hay un medicamento vigente con ese nombre: Metformina. '
            'Se guardó igual.',
          ),
          findsOneWidget,
        );
        expect(guardado?.id, 'med-1');
        expect(_guardarHabilitado(tester), isTrue);
      },
    );

    testWidgets('an alta without duplicadoDe shows no warning', (tester) async {
      final adapter = FakeHttpAdapter(
        (_) async => jsonBody(_entidad(), status: 201),
      );
      await _pump(tester, adapter);

      await tester.enterText(_campo('nombre'), 'Metformina');
      await _guardar(tester);

      expect(find.textContaining('Ya hay un medicamento'), findsNothing);
    });
  });

  group('fallos (S11)', () {
    testWidgets(
      'a 400 with a field detail shows it on the field and re-enables',
      (tester) async {
        final adapter = FakeHttpAdapter(
          (_) async => jsonBody(
            _error(
              'VALIDACION',
              'Datos inválidos',
              detalles: [
                {'campo': 'dosis', 'mensaje': 'Dosis demasiado larga'},
              ],
            ),
            status: 400,
          ),
        );
        Medicamento? guardado;
        await _pump(tester, adapter, onGuardado: (m) => guardado = m);

        await tester.enterText(_campo('nombre'), 'Metformina');
        await _guardar(tester);

        expect(adapter.requests, hasLength(1));
        expect(find.text('Dosis demasiado larga'), findsOneWidget);
        expect(guardado, isNull);
        expect(_guardarHabilitado(tester), isTrue);
      },
    );

    testWidgets('a 400 that names no field goes to the failure block', (
      tester,
    ) async {
      final adapter = FakeHttpAdapter(
        (_) async => jsonBody(
          _error('VALIDACION', 'Datos inválidos', detalles: ['algo raro']),
          status: 400,
        ),
      );
      await _pump(tester, adapter);

      await tester.enterText(_campo('nombre'), 'Metformina');
      await _guardar(tester);

      expect(find.text('Datos inválidos'), findsOneWidget);
      expect(find.byKey(const Key('fallo-codigo')), findsOneWidget);
      expect(_guardarHabilitado(tester), isTrue);
    });

    testWidgets('a 404 shows as a failure and leaves the form usable', (
      tester,
    ) async {
      var intentos = 0;
      final adapter = FakeHttpAdapter((_) async {
        intentos++;
        return intentos == 1
            ? jsonBody(
                _error('NO_ENCONTRADO', 'El medicamento no existe'),
                status: 404,
              )
            : jsonBody(_entidad());
      });
      Medicamento? guardado;
      await _pump(
        tester,
        adapter,
        medicamento: _existente,
        onGuardado: (m) => guardado = m,
      );

      await _guardar(tester);

      expect(find.text('El medicamento no existe'), findsOneWidget);
      expect(find.textContaining('HTTP 404'), findsOneWidget);
      expect(_guardarHabilitado(tester), isTrue);

      // The same form retries and succeeds: nothing stayed locked.
      await _guardar(tester);
      expect(adapter.requests, hasLength(2));
      expect(guardado?.id, 'med-1');
      expect(find.text('El medicamento no existe'), findsNothing);
    });

    testWidgets('disables the button while the request runs', (tester) async {
      final adapter = FakeHttpAdapter((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        return jsonBody(_entidad());
      });
      await _pump(tester, adapter);

      await tester.enterText(_campo('nombre'), 'Metformina');
      await tester.tap(find.text('Guardar cambios'));
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 400));
      await pumpStable(tester);
    });
  });
}
