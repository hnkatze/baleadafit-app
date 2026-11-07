import 'package:flutter_test/flutter_test.dart';

/// Pumps a few frames instead of waiting for the widget tree to settle.
///
/// The login screen keeps a pulse animation running on purpose, so
/// `pumpAndSettle` never returns there. A handful of pumps is enough for
/// navigation transitions and for pending futures to complete.
Future<void> pumpStable(WidgetTester tester, {int frames = 5}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}
