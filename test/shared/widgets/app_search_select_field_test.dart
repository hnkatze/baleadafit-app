import 'package:baleadafit/core/theme/app_theme.dart';
import 'package:baleadafit/shared/widgets/app_search_select_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/pump.dart';

class _Arnes {
  _Arnes({
    this.resultado = const ['Ana Gómez', 'Ana Pérez'],
    this.falla = false,
  });

  final List<String> resultado;
  final bool falla;
  final consultas = <String>[];
  final elegidos = <String>[];

  Future<List<String>> buscar(String consulta) async {
    consultas.add(consulta);
    if (falla) throw Exception('boom');
    return resultado;
  }
}

Future<void> _pump(WidgetTester tester, _Arnes arnes, {String? valor}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: AppSearchSelectField<String>(
          label: 'Paciente',
          hint: 'Buscar paciente',
          valor: valor,
          buscar: arnes.buscar,
          etiquetaDe: (item) => item,
          onElegido: arnes.elegidos.add,
        ),
      ),
    ),
  );
}

Future<void> _abrir(WidgetTester tester) async {
  await tester.tap(find.byType(InkWell));
  await pumpStable(tester);
}

Future<void> _escribir(WidgetTester tester, String texto) async {
  await tester.enterText(find.byType(TextField), texto);
  await tester.pump(const Duration(milliseconds: 400));
  await pumpStable(tester);
}

void main() {
  testWidgets('does not search below two characters', (tester) async {
    final arnes = _Arnes();
    await _pump(tester, arnes);
    await _abrir(tester);

    expect(find.text('Escribí al menos 2 letras'), findsOneWidget);
    await _escribir(tester, 'a');

    expect(find.text('Escribí al menos 2 letras'), findsOneWidget);
    expect(arnes.consultas, isEmpty);
  });

  testWidgets('debounces a word typed quickly into one call', (tester) async {
    final arnes = _Arnes();
    await _pump(tester, arnes);
    await _abrir(tester);

    for (final texto in ['an', 'ana', 'ana ']) {
      await tester.enterText(find.byType(TextField), texto);
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(arnes.consultas, isEmpty);
    await tester.pump(const Duration(milliseconds: 400));

    expect(arnes.consultas, ['ana']);
  });

  testWidgets('lists candidates; tapping one selects it and closes', (
    tester,
  ) async {
    final arnes = _Arnes();
    await _pump(tester, arnes);
    await _abrir(tester);
    await _escribir(tester, 'ana');

    expect(find.text('Ana Gómez'), findsOneWidget);
    expect(find.text('Ana Pérez'), findsOneWidget);

    await tester.tap(find.text('Ana Pérez'));
    await pumpStable(tester);

    expect(arnes.elegidos, ['Ana Pérez']);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('shows the empty message', (tester) async {
    await _pump(tester, _Arnes(resultado: const []));
    await _abrir(tester);
    await _escribir(tester, 'zz');

    expect(find.text('Sin resultados'), findsOneWidget);
  });

  testWidgets('shows the error message when the search throws', (tester) async {
    await _pump(tester, _Arnes(falla: true));
    await _abrir(tester);
    await _escribir(tester, 'zz');

    expect(find.text('No pudimos buscar.'), findsOneWidget);
  });

  testWidgets('renders the selected value in the collapsed field', (
    tester,
  ) async {
    await _pump(tester, _Arnes(), valor: 'Ana Gómez');

    expect(find.text('Ana Gómez'), findsOneWidget);
    expect(find.text('Paciente'), findsOneWidget);
  });

  testWidgets('reopens with an empty query', (tester) async {
    final arnes = _Arnes();
    await _pump(tester, arnes, valor: 'Ana Gómez');
    await _abrir(tester);
    await _escribir(tester, 'ana');
    await tester.tap(find.text('Ana Pérez'));
    await pumpStable(tester);

    await _abrir(tester);
    expect(find.text('Escribí al menos 2 letras'), findsOneWidget);
    expect(find.text('Ana Pérez'), findsNothing);
  });
}
