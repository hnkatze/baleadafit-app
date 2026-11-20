import 'package:baleadafit/core/theme/app_theme.dart';
import 'package:baleadafit/features/patients/data/medicamento.dart';
import 'package:baleadafit/features/patients/ui/medicacion/medicacion_screen.dart';
import 'package:baleadafit/shared/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _aviso =
    'Medicación vigente. Una baja la saca de esta lista y del expediente; '
    'el historial clínico se conserva.';
const _vacioTitulo = 'Sin medicación registrada';
const _vacioCuerpo =
    'Registrá los medicamentos que el paciente toma, con dosis y frecuencia '
    'si las conocés.';

const _metformina = Medicamento(
  id: 'med-1',
  nombre: 'Metformina',
  dosis: '500 mg',
  frecuencia: 'Cada 12 horas con comida',
);
const _losartan = Medicamento(id: 'med-2', nombre: 'Losartán', dosis: '50 mg');
const _hierro = Medicamento(
  id: 'med-3',
  nombre: 'Hierro',
  frecuencia: 'Una vez al día',
);
const _folico = Medicamento(id: 'med-4', nombre: 'Ácido fólico');

Medicamento? _abierto;
int _registrar = 0;
int _volver = 0;

Future<void> _pump(
  WidgetTester tester, {
  List<Medicamento> medicamentos = const [],
  bool conVolver = true,
}) async {
  _abierto = null;
  _registrar = 0;
  _volver = 0;

  tester.view.physicalSize = const Size(1200, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: MedicacionScreen(
          pacienteNombre: 'Paciente De Prueba',
          medicamentos: medicamentos,
          onRegistrar: () => _registrar++,
          onAbrir: (m) => _abierto = m,
          onVolver: conVolver ? () => _volver++ : null,
        ),
      ),
    ),
  );
}

Finder _fila(String nombre) =>
    find.ancestor(of: find.text(nombre), matching: find.byType(InkWell));

void main() {
  group('lista con medicamentos', () {
    testWidgets('S1: título, paciente debajo y volver', (tester) async {
      await _pump(tester, medicamentos: [_metformina]);

      expect(find.text('Medicación'), findsOneWidget);
      expect(find.text('Paciente De Prueba'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      expect(_volver, 1);
    });

    testWidgets('S1: dosis y frecuencia en la línea secundaria', (
      tester,
    ) async {
      await _pump(tester, medicamentos: [_metformina]);

      expect(find.text('Metformina'), findsOneWidget);
      expect(find.text('500 mg · Cada 12 horas con comida'), findsOneWidget);
      expect(find.byIcon(Icons.medication), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('S1: sólo dosis o sólo frecuencia, sin separador', (
      tester,
    ) async {
      await _pump(tester, medicamentos: [_losartan, _hierro]);

      expect(find.text('50 mg'), findsOneWidget);
      expect(find.text('Una vez al día'), findsOneWidget);
      expect(find.textContaining('·'), findsNothing);
    });

    testWidgets('S1/S12: sin dosis ni frecuencia no hay segunda línea', (
      tester,
    ) async {
      await _pump(tester, medicamentos: [_folico]);

      expect(find.text('Ácido fólico'), findsOneWidget);
      expect(find.textContaining('·'), findsNothing);
      expect(find.textContaining('null'), findsNothing);
      expect(find.textContaining('—'), findsNothing);
      // Only the screen title, the patient, the note, the name and the button.
      final textos = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .whereType<String>()
          .toList();
      expect(textos, isNot(contains('')));
      expect(textos, hasLength(5));
    });

    testWidgets('S1: tocar una fila abre ese medicamento', (tester) async {
      await _pump(tester, medicamentos: [_metformina, _losartan, _folico]);

      await tester.tap(_fila('Losartán'));
      expect(_abierto, same(_losartan));

      await tester.tap(find.byIcon(Icons.chevron_right).last);
      expect(_abierto, same(_folico));
    });

    testWidgets('S2: aviso con el texto exacto', (tester) async {
      await _pump(tester, medicamentos: [_metformina]);

      expect(find.text(_aviso), findsOneWidget);
      expect(find.text(_vacioTitulo), findsNothing);
    });

    testWidgets('S3: Registrar medicamento llama a onRegistrar', (
      tester,
    ) async {
      await _pump(tester, medicamentos: [_metformina]);

      expect(find.text('Registrar medicamento'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      await tester.tap(find.widgetWithText(AppButton, 'Registrar medicamento'));
      expect(_registrar, 1);
      expect(_abierto, isNull);
    });
  });

  group('estado vacío', () {
    testWidgets('S4: texto exacto y sin aviso ni filas', (tester) async {
      await _pump(tester);

      expect(find.text(_vacioTitulo), findsOneWidget);
      expect(find.text(_vacioCuerpo), findsOneWidget);
      expect(find.text(_aviso), findsNothing);
      expect(find.byIcon(Icons.chevron_right), findsNothing);
      expect(find.byIcon(Icons.medication), findsOneWidget);
    });

    testWidgets('S3: la acción primaria sigue y llama a onRegistrar', (
      tester,
    ) async {
      await _pump(tester);

      expect(find.text('Registrar medicamento'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      await tester.tap(find.widgetWithText(AppButton, 'Registrar medicamento'));
      expect(_registrar, 1);
    });
  });

  group('volver', () {
    testWidgets('sin onVolver no se dibuja la flecha', (tester) async {
      await _pump(tester, medicamentos: [_metformina], conVolver: false);

      expect(find.byIcon(Icons.arrow_back), findsNothing);
      expect(find.text('Medicación'), findsOneWidget);
    });

    testWidgets('sin onVolver tampoco en el estado vacío', (tester) async {
      await _pump(tester, conVolver: false);

      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });
  });
}
