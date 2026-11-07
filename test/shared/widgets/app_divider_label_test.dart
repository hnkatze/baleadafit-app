import 'package:baleadafit/core/theme/app_theme.dart';
import 'package:baleadafit/shared/widgets/app_divider_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the label once between two lines', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: AppDividerLabel(label: 'o autenticación rápida'),
        ),
      ),
    );

    expect(find.text('o autenticación rápida'), findsOneWidget);
    expect(find.byType(Divider), findsNWidgets(2));
  });
}
