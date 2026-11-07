import 'package:baleadafit/core/theme/app_colors.dart';
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

  testWidgets('paints the tonal variant with the soft mint surface', (
    tester,
  ) async {
    await pumpButton(
      tester,
      AppButton(
        label: 'Ingreso rápido',
        variant: AppButtonVariant.tonal,
        onPressed: () {},
      ),
    );

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    const states = <WidgetState>{};

    expect(
      button.style?.backgroundColor?.resolve(states),
      AppColors.secondaryContainer,
    );
    expect(
      button.style?.foregroundColor?.resolve(states),
      AppColors.onSecondaryContainer,
    );
  });

  testWidgets('paints the secondary variant as an outline', (tester) async {
    await pumpButton(
      tester,
      AppButton(
        label: 'Continuar con Google',
        variant: AppButtonVariant.secondary,
        onPressed: () {},
      ),
    );

    expect(find.byType(OutlinedButton), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
  });
}
