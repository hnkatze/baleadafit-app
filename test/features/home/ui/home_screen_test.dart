import 'package:baleadafit/core/theme/app_theme.dart';
import 'package:baleadafit/features/auth/application/session_controller.dart';
import 'package:baleadafit/features/auth/data/auth_session.dart';
import 'package:baleadafit/features/auth/data/user_role.dart';
import 'package:baleadafit/features/home/data/dashboard_providers.dart';
import 'package:baleadafit/features/home/data/dashboard_resumen.dart';
import 'package:baleadafit/features/home/ui/home_screen.dart';
import 'package:baleadafit/core/network/paged.dart';
import 'package:baleadafit/features/patients/data/paciente_resumen.dart';
import 'package:baleadafit/features/patients/data/patients_providers.dart';

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

DateTime get _enUnaHora => DateTime.now().add(const Duration(minutes: 60));

CitaResumen _cita({
  required String id,
  required DateTime hora,
  required String nombre,
  String motivo = 'Control mensual',
}) => CitaResumen(
  id: id,
  fechaHora: hora,
  duracionMin: 45,
  motivo: motivo,
  paciente: PacienteBreve(id: 'pac-$id', nombre: nombre, apellido: 'Mendoza'),
);

DashboardResumen _resumenCon(List<CitaResumen> citas) => DashboardResumen(
  pacientesActivos: 12,
  planesEnBorrador: 3,
  citasHoy: citas,
);

final _resumen = _resumenCon([
  _cita(id: 'cita-1', hora: _enUnaHora, nombre: 'Carlos'),
]);

Paged<PacienteResumen> _pagina(List<PacienteResumen> items) => Paged(
  items: items,
  meta: const PageMeta(limit: 4, offset: 0, total: 0, hasMore: false),
);

const _sinPacientes = PageMeta(limit: 4, offset: 0, total: 0, hasMore: false);

Future<void> _pumpHome(
  WidgetTester tester, {
  required Future<DashboardResumen> Function() load,
  Future<Paged<PacienteResumen>> Function()? patients,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionControllerProvider.overrideWith(_FixedSession.new),
        dashboardProvider.overrideWith((ref) => load()),
        pacientesRecientesProvider.overrideWith(
          (ref) => patients == null
              ? Future.value(
                  Paged<PacienteResumen>(items: const [], meta: _sinPacientes),
                )
              : patients(),
        ),
      ],
      child: MaterialApp(theme: AppTheme.light, home: const HomeScreen()),
    ),
  );
}

void main() {
  testWidgets('greets the signed-in nutritionist', (tester) async {
    await _pumpHome(tester, load: () async => _resumen);
    await tester.pump();

    expect(find.textContaining('Lic. Henriquez'), findsOneWidget);
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
    expect(find.textContaining('Carlos Mendoza'), findsOneWidget);
    expect(find.text('PRÓXIMA CITA'), findsOneWidget);
    expect(find.textContaining('1 cita'), findsWidgets);
  });

  testWidgets('keeps the rest of the day apart from the next one', (
    tester,
  ) async {
    await _pumpHome(
      tester,
      load: () async => _resumenCon([
        _cita(id: 'a', hora: _enUnaHora, nombre: 'Carlos'),
        _cita(
          id: 'b',
          hora: DateTime.now().add(const Duration(hours: 4)),
          nombre: 'Mariana',
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('PRÓXIMA CITA'), findsOneWidget);
    expect(find.text('Después'), findsOneWidget);
    expect(find.textContaining('Mariana Mendoza'), findsOneWidget);
  });

  testWidgets('a finished day lists its appointments without a next one', (
    tester,
  ) async {
    await _pumpHome(
      tester,
      load: () async => _resumenCon([
        _cita(
          id: 'a',
          hora: DateTime.now().subtract(const Duration(hours: 2)),
          nombre: 'Carlos',
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('PRÓXIMA CITA'), findsNothing);
    expect(find.text('Sin pendientes'), findsOneWidget);
    expect(find.text('Después'), findsOneWidget);
    expect(find.textContaining('Carlos Mendoza'), findsOneWidget);
  });

  testWidgets('explains an empty day instead of showing a blank list', (
    tester,
  ) async {
    await _pumpHome(tester, load: () async => _resumenCon(const []));
    await tester.pumpAndSettle();

    expect(find.text('Sin citas hoy'), findsOneWidget);
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

  testWidgets('lists the patients with their last measurement', (tester) async {
    await _pumpHome(
      tester,
      load: () async => _resumen,
      patients: () async => _pagina([
        PacienteResumen(
          id: 'pac-1',
          nombre: 'Paciente',
          apellido: 'De Prueba',
          ultimaMedicion: UltimaMedicion(
            fecha: DateTime(2026, 10, 31),
            pesoKg: 72.4,
            pctGrasa: 19.5,
          ),
          planActivo: {'id': 'plan-1'},
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tus pacientes'), findsOneWidget);
    expect(find.text('Paciente De Prueba'), findsOneWidget);
    expect(find.text('72.4 kg · 19.5% grasa'), findsOneWidget);
    expect(find.text('Con plan'), findsOneWidget);
  });

  testWidgets('a patient list that fails leaves the summary alone', (
    tester,
  ) async {
    await _pumpHome(
      tester,
      load: () async => _resumen,
      patients: () async => throw Exception('sin red'),
    );
    await tester.pumpAndSettle();

    expect(find.text('12'), findsOneWidget);
    expect(
      find.textContaining('No pudimos cargar tus pacientes'),
      findsOneWidget,
    );
  });
}
