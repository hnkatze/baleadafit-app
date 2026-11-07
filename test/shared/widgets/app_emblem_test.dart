import 'package:baleadafit/core/theme/app_theme.dart';
import 'package:baleadafit/shared/widgets/app_emblem.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpEmblem(WidgetTester tester, Widget emblem) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: Center(child: emblem)),
      ),
    );
  }

  testWidgets('paints at any size without throwing', (tester) async {
    await pumpEmblem(tester, const AppEmblem(size: 40));
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(AppEmblem)), const Size(40, 40));

    await pumpEmblem(tester, const AppEmblem(size: 96));
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(AppEmblem)), const Size(96, 96));
  });

  testWidgets('draws a rounded background when one is given', (tester) async {
    await pumpEmblem(
      tester,
      const AppEmblem(size: 80, background: Color(0xFF111C2D)),
    );

    final container = tester.widget<Container>(
      find.descendant(
        of: find.byType(AppEmblem),
        matching: find.byType(Container),
      ),
    );
    final decoration = container.decoration! as BoxDecoration;

    expect(decoration.color, const Color(0xFF111C2D));
    expect(decoration.borderRadius, isNotNull);
  });
}
