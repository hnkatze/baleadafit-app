import 'dart:ui' as ui;

import 'package:baleadafit/core/theme/app_theme.dart';
import 'package:baleadafit/features/auth/application/session_controller.dart';
import 'package:baleadafit/features/auth/data/auth_session.dart';
import 'package:baleadafit/features/auth/data/user_role.dart';
import 'package:baleadafit/shared/widgets/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FixedSession extends SessionController {
  @override
  SessionState build() => const SessionState(
    status: SessionStatus.authenticated,
    session: AuthSession(
      rol: UserRole.nutricionista,
      displayName: 'Lic. Camilo Henriquez',
    ),
  );

  @override
  Future<void> restore() async {}
}

Future<void> _pumpDrawer(WidgetTester tester, String activeRoute) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sessionControllerProvider.overrideWith(_FixedSession.new)],
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: AppDrawer(activeRoute: activeRoute)),
      ),
    ),
  );
  await tester.pump();
}

/// Whether the drawer marks the entry with [label] as the current section.
bool _seleccionada(WidgetTester tester, String label) {
  final item = find.ancestor(
    of: find.text(label),
    matching: find.byType(Semantics),
  );
  final nodo = tester.getSemantics(item.first).getSemanticsData();
  return nodo.flagsCollection.isSelected == ui.Tristate.isTrue;
}

void main() {
  testWidgets('highlights the section of a list route', (tester) async {
    await _pumpDrawer(tester, '/pacientes');

    expect(_seleccionada(tester, 'Pacientes'), isTrue);
    expect(_seleccionada(tester, 'Inicio'), isFalse);
  });

  testWidgets('keeps the section highlighted on a child route', (tester) async {
    // The patient file lives at `/pacientes/:id`: the drawer must keep pointing
    // at Pacientes instead of losing the highlight.
    await _pumpDrawer(tester, '/pacientes/0d1f3c2a');

    expect(_seleccionada(tester, 'Pacientes'), isTrue);
  });
}
