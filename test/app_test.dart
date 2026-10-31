import 'package:baleadafit/app.dart';
import 'package:baleadafit/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('boots with the app theme applied', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: BaleadaFitApp()));

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));

    expect(materialApp.theme?.colorScheme.primary, AppColors.primary);
    expect(find.text('BaleadaFit · Design system'), findsOneWidget);
  });
}
