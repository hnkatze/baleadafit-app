import 'package:baleadafit/core/network/api_client.dart';
import 'package:baleadafit/core/theme/app_theme.dart';
import 'package:baleadafit/features/catalogo/data/alimento.dart';
import 'package:baleadafit/features/catalogo/data/catalogo_providers.dart';
import 'package:baleadafit/features/catalogo/data/catalogo_repository.dart';
import 'package:baleadafit/features/catalogo/ui/baja_alimento.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_http_adapter.dart';

const _alimento = Alimento(id: 'ali-1', nombre: 'Quesillo');

/// Result of the last `confirmarBajaAlimento`; null until it completes.
bool? _resultado;

Future<void> _pump(WidgetTester tester, FakeHttpAdapter adapter) async {
  _resultado = null;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        catalogoRepositoryProvider.overrideWithValue(
          CatalogoRepository(ApiClient(dioWith(adapter))),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) => TextButton(
              onPressed: () async => _resultado = await confirmarBajaAlimento(
                context,
                ref,
                alimento: _alimento,
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

FakeHttpAdapter _adapterOk() => FakeHttpAdapter(
  (_) async => jsonBody({
    'ok': true,
    'data': {'id': 'ali-1', 'nombre': 'Quesillo', 'activo': false},
  }),
);

void main() {
  testWidgets('S7: draws the title, the three points and the warning', (
    tester,
  ) async {
    await _pump(tester, _adapterOk());

    expect(find.text('¿Dar de baja “Quesillo”?'), findsOneWidget);
    expect(
      find.text('Es una baja lógica: el alimento no se borra.'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Deja de aparecer en el catálogo y en las búsquedas para armar planes.',
      ),
      findsOneWidget,
    );
    expect(
      find.text('Se conservan sus datos y su historial de versiones.'),
      findsOneWidget,
    );
    expect(
      find.text(
        'El catálogo no lista alimentos inactivos, así que después no vas a '
        'encontrarlo desde la búsqueda para reactivarlo.',
      ),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilledButton, 'Dar de baja'), findsOneWidget);
    expect(find.text('Cancelar'), findsNothing);
  });

  testWidgets('S7: the red cross closes with false and never calls the API', (
    tester,
  ) async {
    final adapter = _adapterOk();
    await _pump(tester, adapter);

    final cruz = tester.widget<IconButton>(
      find.byKey(const Key('cerrar-dialogo')),
    );
    expect(cruz.tooltip, 'Cancelar');
    expect((cruz.icon as Icon).icon, Icons.close);
    expect(
      (cruz.icon as Icon).color,
      Theme.of(tester.element(find.byType(AlertDialog))).colorScheme.error,
    );

    await tester.tap(find.byKey(const Key('cerrar-dialogo')));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(_resultado, isFalse);
    expect(adapter.requests, isEmpty);
  });

  testWidgets('S7: a tap outside does not close the dialog', (tester) async {
    await _pump(tester, _adapterOk());

    await tester.tapAt(const Offset(2, 2));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(_resultado, isNull);
  });

  testWidgets(
    'S7: confirming sends one PATCH with activo false, returns true',
    (tester) async {
      final adapter = _adapterOk();
      await _pump(tester, adapter);

      await tester.tap(find.widgetWithText(FilledButton, 'Dar de baja'));
      await tester.pumpAndSettle();

      final pedido = adapter.requests.single;
      expect(pedido.method, 'PATCH');
      expect(pedido.path, '/alimentos/ali-1');
      expect(pedido.data, {'activo': false});
      expect(_resultado, isTrue);
      expect(find.byType(AlertDialog), findsNothing);
    },
  );

  testWidgets('S7: a 404 returns false and shows the API message', (
    tester,
  ) async {
    final adapter = FakeHttpAdapter(
      (_) async => jsonBody({
        'ok': false,
        'error': {
          'codigo': 'NO_ENCONTRADO',
          'mensaje': 'El alimento no existe',
        },
      }, status: 404),
    );
    await _pump(tester, adapter);

    await tester.tap(find.widgetWithText(FilledButton, 'Dar de baja'));
    await tester.pumpAndSettle();

    expect(_resultado, isFalse);
    expect(find.text('El alimento no existe'), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(adapter.requests, hasLength(1));
  });
}
