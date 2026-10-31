import 'package:baleadafit/shared/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpButton(WidgetTester tester, AppButton button) {
    return tester.pumpWidget(
      MaterialApp(home: Scaffold(body: Center(child: button))),
    );
  }

  testWidgets('renders the label', (tester) async {
    await pumpButton(
      tester,
      AppButton(label: 'Guardar', onPressed: () {}),
    );

    expect(find.text('Guardar'), findsOneWidget);
  });

  testWidgets('calls onPressed when tapped', (tester) async {
    var taps = 0;

    await pumpButton(
      tester,
      AppButton(label: 'Guardar', onPressed: () => taps++),
    );
    await tester.tap(find.byType(AppButton));
    await tester.pump();

    expect(taps, 1);
  });

  testWidgets('shows a progress indicator and ignores taps while loading', (
    tester,
  ) async {
    var taps = 0;

    await pumpButton(
      tester,
      AppButton(label: 'Guardar', isLoading: true, onPressed: () => taps++),
    );
    await tester.tap(find.byType(AppButton));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Guardar'), findsNothing);
    expect(taps, 0);
  });

  testWidgets('is disabled when onPressed is null', (tester) async {
    await pumpButton(tester, const AppButton(label: 'Guardar'));

    final button = tester.widget<FilledButton>(find.byType(FilledButton));

    expect(button.onPressed, isNull);
  });
}
