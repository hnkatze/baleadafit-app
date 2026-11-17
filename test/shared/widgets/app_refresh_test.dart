import 'dart:async';

import 'package:baleadafit/core/theme/app_theme.dart';
import 'package:baleadafit/shared/widgets/app_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester, {
  required Future<void> Function() onRefresh,
}) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: AppRefresh(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [Text('contenido')],
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('dragging down triggers onRefresh once', (tester) async {
    var llamadas = 0;
    await _pump(tester, onRefresh: () async => llamadas++);

    await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
    await tester.pumpAndSettle();

    expect(llamadas, 1);
    expect(find.text('contenido'), findsOneWidget);
  });

  testWidgets('the indicator lasts while the future is pending', (
    tester,
  ) async {
    final pendiente = Completer<void>();
    await _pump(tester, onRefresh: () => pendiente.future);
    expect(find.byType(RefreshProgressIndicator), findsNothing);

    await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(RefreshProgressIndicator), findsOneWidget);

    pendiente.complete();
    await tester.pumpAndSettle();

    expect(find.byType(RefreshProgressIndicator), findsNothing);
  });

  testWidgets('paints the indicator with the theme primary colour', (
    tester,
  ) async {
    final pendiente = Completer<void>();
    await _pump(tester, onRefresh: () => pendiente.future);

    await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final indicator = tester.widget<RefreshIndicator>(
      find.byType(RefreshIndicator),
    );
    expect(indicator.color, AppTheme.light.colorScheme.primary);

    pendiente.complete();
    await tester.pumpAndSettle();
  });
}
