import 'package:baleadafit/core/theme/app_dimensions.dart';
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
import 'package:baleadafit/shared/widgets/app_tinted_pill.dart';

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
  ValueChanged<String>? onAbrirPaciente,
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
      child: MaterialApp(
        theme: AppTheme.light,
        home: HomeScreen(onAbrirPaciente: onAbrirPaciente),
      ),
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

  testWidgets('the day card reaches the right edge with no appointments', (
    tester,
  ) async {
    await _pumpHome(tester, load: () async => _resumenCon([]));
    await tester.pumpAndSettle();

    final card = find
        .ancestor(
          of: find.text('Sin citas hoy'),
          matching: find.byType(Container),
        )
        .first;
    final anchoUtil =
        tester.getSize(find.byType(ListView)).width -
        AppDimensions.screenPadding.horizontal;

    expect(tester.getSize(card).width, closeTo(anchoUtil, 0.5));
  });

  testWidgets('pulling down reloads the summary and the patients', (
    tester,
  ) async {
    var cargas = 0;
    var cargasPacientes = 0;
    await _pumpHome(
      tester,
      load: () async {
        cargas++;
        return _resumen;
      },
      patients: () async {
        cargasPacientes++;
        return Paged<PacienteResumen>(items: const [], meta: _sinPacientes);
      },
    );
    await tester.pumpAndSettle();
    expect(cargas, 1);
    expect(cargasPacientes, 1);

    await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
    await tester.pumpAndSettle();

    expect(cargas, 2);
    // The patients block is drawn by this same screen, so a refresh that only
    // reloaded the summary would leave it stale.
    expect(cargasPacientes, 2);
    expect(find.text('12'), findsOneWidget);
  });

  testWidgets('the metric icon sits on the value line instead of above it', (
    tester,
  ) async {
    await _pumpHome(tester, load: () async => _resumenCon([]));
    await tester.pumpAndSettle();

    final icono = tester.getCenter(find.byIcon(Icons.groups_2_outlined)).dy;
    final valor = tester.getCenter(find.text('12')).dy;

    expect(icono, closeTo(valor, 1));
  });

  group('abrir la ficha desde el inicio', () {
    Future<Paged<PacienteResumen>> dosPacientes() async => _pagina([
      const PacienteResumen(
        id: 'pac-con',
        nombre: 'Ana',
        apellido: 'Con Plan',
        planActivo: {'id': 'plan-1'},
      ),
      const PacienteResumen(
        id: 'pac-sin',
        nombre: 'Beto',
        apellido: 'Sin Plan',
      ),
    ]);

    testWidgets('tapping a Tus pacientes row opens that patient', (
      tester,
    ) async {
      final abiertos = <String>[];
      await _pumpHome(
        tester,
        load: () async => _resumenCon(const []),
        patients: dosPacientes,
        onAbrirPaciente: abiertos.add,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Beto Sin Plan'));
      await tester.pumpAndSettle();

      expect(abiertos, ['pac-sin']);
      expect(find.byIcon(Icons.chevron_right), findsNWidgets(2));
    });

    testWidgets('tapping the next appointment opens its patient', (
      tester,
    ) async {
      final abiertos = <String>[];
      await _pumpHome(
        tester,
        load: () async => _resumen,
        onAbrirPaciente: abiertos.add,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Carlos Mendoza'));
      await tester.pumpAndSettle();

      expect(abiertos, ['pac-cita-1']);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('tapping an appointment under Después opens its patient', (
      tester,
    ) async {
      final abiertos = <String>[];
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
        onAbrirPaciente: abiertos.add,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mariana Mendoza'));
      await tester.pumpAndSettle();

      expect(abiertos, ['pac-b']);
    });

    testWidgets('without the callback nothing is tappable and no chevron', (
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
        patients: dosPacientes,
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.chevron_right), findsNothing);
      expect(find.byType(InkWell), findsNothing);
    });
  });

  testWidgets('the plan pill is tinted with and without an active plan', (
    tester,
  ) async {
    await _pumpHome(
      tester,
      load: () async => _resumenCon(const []),
      patients: () async => _pagina([
        const PacienteResumen(
          id: 'pac-con',
          nombre: 'Ana',
          apellido: 'Con Plan',
          planActivo: {'id': 'plan-1'},
        ),
        const PacienteResumen(
          id: 'pac-sin',
          nombre: 'Beto',
          apellido: 'Sin Plan',
        ),
      ]),
    );
    await tester.pumpAndSettle();

    final colors = Theme.of(tester.element(find.byType(HomeScreen)))
        .colorScheme;
    AppTintedPill pill(String label) =>
        tester.widget<AppTintedPill>(find.widgetWithText(AppTintedPill, label));

    final con = pill('Con plan');
    expect(con.background, colors.secondaryContainer);
    expect(con.foreground, colors.onSecondaryContainer);
    expect(con.dotColor, colors.primary);

    final sin = pill('Sin plan');
    expect(sin.background, colors.surfaceContainer);
    expect(sin.foreground, colors.onSurfaceVariant);
    expect(sin.dotColor, isNull);
  });
}
