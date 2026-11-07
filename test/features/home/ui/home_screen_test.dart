import 'package:baleadafit/core/theme/app_theme.dart';
import 'package:baleadafit/features/auth/application/session_controller.dart';
import 'package:baleadafit/features/auth/data/auth_session.dart';
import 'package:baleadafit/features/auth/data/user_role.dart';
import 'package:baleadafit/features/home/data/dashboard_providers.dart';
import 'package:baleadafit/features/home/data/dashboard_resumen.dart';
import 'package:baleadafit/features/home/ui/home_screen.dart';
import 'dart:async';

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

final _resumen = DashboardResumen(
  pacientesActivos: 12,
  planesEnBorrador: 3,
  citasHoy: [
    CitaResumen(
      id: 'cita-1',
      fechaHora: DateTime(2026, 11, 6, 9, 30),
      duracionMin: 45,
      motivo: 'Control mensual',
      paciente: const PacienteBreve(id: 'pac-1', nombre: 'Carlos', apellido: 'Mendoza'),
    ),
  ],
);

Future<void> _pumpHome(
  WidgetTester tester, {
  required Future<DashboardResumen> Function() load,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionControllerProvider.overrideWith(_FixedSession.new),
        dashboardProvider.overrideWith((ref) => load()),
      ],
      child: MaterialApp(theme: AppTheme.light, home: const HomeScreen()),
    ),
  );
}

void main() {
  testWidgets('greets the signed-in nutritionist', (tester) async {
    await _pumpHome(tester, load: () async => _resumen);
    await tester.pump();

    expect(find.textContaining('Camilo Henriquez'), findsOneWidget);
  });

  testWidgets('shows a spinner while the summary loads', (tester) async {
    final pending = Completer<DashboardResumen>();
    await _pumpHome(tester, load: () => pending.future);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    pending.complete(_resumen);
    await tester.pumpAndSettle();
  });

  testWidgets('shows the counts and today appointments', (tester) async {
    await _pumpHome(tester, load: () async => _resumen);
    await tester.pumpAndSettle();

    expect(find.text('12'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Pacientes activos'), findsOneWidget);
    expect(find.text('Planes en borrador'), findsOneWidget);
    expect(find.text('Citas hoy'), findsWidgets);
    expect(find.textContaining('Carlos Mendoza'), findsOneWidget);
    expect(find.textContaining('09:30'), findsOneWidget);
  });

  testWidgets('explains an empty day instead of showing a blank list', (tester) async {
    await _pumpHome(
      tester,
      load: () async => DashboardResumen(
        pacientesActivos: 0,
        planesEnBorrador: 0,
        citasHoy: const [],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('No tenés citas hoy'), findsOneWidget);
  });

  testWidgets('shows the API message and lets the user retry', (tester) async {
    var attempts = 0;

    await _pumpHome(
      tester,
      load: () async {
        attempts++;
        if (attempts == 1) throw Exception('sin red');
        return _resumen;
      },
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('No pudimos'), findsOneWidget);

    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.text('12'), findsOneWidget);
  });
}
