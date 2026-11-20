import 'package:baleadafit/core/theme/app_theme.dart';
import 'package:baleadafit/features/patients/data/paciente_ficha.dart';
import 'package:baleadafit/features/patients/data/patients_providers.dart';
import 'package:baleadafit/features/patients/ui/paciente_ficha_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> _medicamento(int n, {bool conComposicion = true}) => {
  'id': 'med-$n',
  'nombre': 'Medicamento $n',
  if (conComposicion) 'dosis': '${n * 100} mg',
  if (conComposicion) 'frecuencia': 'Cada $n horas',
  'activo': true,
};

Map<String, Object?> _ficha(int medicamentos) => {
  'paciente': {
    'id': 'pac-1',
    'nombre': 'Paciente',
    'apellido': 'De Prueba',
    'sexo': 'M',
    'activo': true,
  },
  'cabecera': <String, Object?>{},
  'progreso': <String, Object?>{},
  'requerimiento': null,
  'adherencia30d': {'porcentaje': null, 'cumplidos': 0, 'total': 0},
  'alertas': <Object?>[],
  'evolucion': <Object?>[],
  'consultas': {'proximas': <Object?>[]},
  'planes': <Object?>[],
  'situacion': {
    'medicacion': [for (var i = 1; i <= medicamentos; i++) _medicamento(i)],
  },
};

Future<void> _pump(
  WidgetTester tester,
  int medicamentos, {
  VoidCallback? onMedicamentos,
}) async {
  tester.view.physicalSize = const Size(390, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        pacienteFichaProvider.overrideWith(
          (ref, id) async => PacienteFicha.fromJson(_ficha(medicamentos)),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: PacienteFichaScreen(
            pacienteId: 'pac-1',
            onBack: () {},
            onMedicamentos: onMedicamentos,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('draws name and composition of each medication (S14)', (
    tester,
  ) async {
    await _pump(tester, 2);

    expect(find.text('Medicación'), findsOneWidget);
    expect(find.text('Medicamento 1'), findsOneWidget);
    expect(find.text('100 mg · Cada 1 horas'), findsOneWidget);
    expect(find.text('Medicamento 2'), findsOneWidget);
    expect(find.text('200 mg · Cada 2 horas'), findsOneWidget);
    expect(find.text('Ver todo · 2'), findsOneWidget);
    expect(find.text('Sin medicación registrada'), findsNothing);
    // No per-row chevron: the whole card is the target.
    expect(find.byIcon(Icons.chevron_right), findsNothing);
  });

  testWidgets('shows three rows and the real total with four (S14)', (
    tester,
  ) async {
    await _pump(tester, 4);

    expect(find.text('Medicamento 1'), findsOneWidget);
    expect(find.text('Medicamento 2'), findsOneWidget);
    expect(find.text('Medicamento 3'), findsOneWidget);
    expect(find.text('Medicamento 4'), findsNothing);
    expect(find.text('Ver todo · 4'), findsOneWidget);
  });

  testWidgets('draws no second line for a medication without data (S14)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final json = _ficha(0);
    (json['situacion']! as Map)['medicacion'] = [
      _medicamento(1, conComposicion: false),
    ];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pacienteFichaProvider.overrideWith(
            (ref, id) async => PacienteFicha.fromJson(json),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: PacienteFichaScreen(pacienteId: 'pac-1', onBack: () {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Medicamento 1'), findsOneWidget);
    expect(find.textContaining('null'), findsNothing);
    expect(find.text('Ver todo · 1'), findsOneWidget);
  });

  testWidgets('draws the empty state with its two texts (S14)', (tester) async {
    await _pump(tester, 0);

    expect(find.text('Medicación'), findsOneWidget);
    expect(find.text('Sin medicación registrada'), findsOneWidget);
    expect(find.text('Registrar medicamento'), findsOneWidget);
    expect(find.textContaining('Ver todo · '), findsNothing);
  });

  testWidgets('tapping the card calls onMedicamentos (S14)', (tester) async {
    var abierta = 0;
    await _pump(tester, 2, onMedicamentos: () => abierta++);

    await tester.tap(find.text('Medicamento 1'));
    expect(abierta, 1);
    await tester.tap(find.text('Ver todo · 2'));
    expect(abierta, 2);
  });

  testWidgets('tapping the empty card calls onMedicamentos (S14)', (
    tester,
  ) async {
    var abierta = 0;
    await _pump(tester, 0, onMedicamentos: () => abierta++);

    await tester.tap(find.text('Registrar medicamento'));
    expect(abierta, 1);
  });

  testWidgets('sits after the next consultations and before the measurements', (
    tester,
  ) async {
    await _pump(tester, 1);

    final medicacion = tester.getTopLeft(find.text('Medicación')).dy;
    final proxima = tester.getTopLeft(find.text('Próximas consultas')).dy;
    expect(medicacion, greaterThan(proxima));
  });
}
