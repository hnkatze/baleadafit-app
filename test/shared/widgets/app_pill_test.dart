import 'package:baleadafit/core/theme/app_theme.dart';
import 'package:baleadafit/shared/widgets/app_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpPill(WidgetTester tester, Widget pill) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: Center(child: pill)),
      ),
    );
  }

  testWidgets('renders its label', (tester) async {
    await pumpPill(tester, const AppPill(label: 'Portal Clínico'));
    expect(find.text('Portal Clínico'), findsOneWidget);
  });

  testWidgets('renders a leading icon instead of a dot', (tester) async {
    await pumpPill(
      tester,
      const AppPill(label: 'Verificado', icon: Icons.verified_user),
    );

    expect(find.byIcon(Icons.verified_user), findsOneWidget);
  });

  testWidgets('animates the dot only when pulse is true', (tester) async {
    await pumpPill(
      tester,
      const AppPill(label: 'En vivo', dotColor: Colors.green, pulse: true),
    );

    await tester.pump(const Duration(milliseconds: 350));
    expect(tester.takeException(), isNull);
    expect(find.text('En vivo'), findsOneWidget);
  });

  testWidgets('keeps the dot static when animations are disabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: Center(
              child: AppPill(
                label: 'En vivo',
                dotColor: Colors.green,
                pulse: true,
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      find.descendant(
        of: find.byType(AppPill),
        matching: find.byType(FadeTransition),
      ),
      findsNothing,
    );
  });
}
