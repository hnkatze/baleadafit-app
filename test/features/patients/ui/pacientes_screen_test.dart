import 'package:baleadafit/core/network/paged.dart';
import 'package:baleadafit/core/theme/app_theme.dart';
import 'package:baleadafit/features/patients/data/paciente_resumen.dart';
import 'package:baleadafit/features/patients/data/patients_providers.dart';
import 'package:baleadafit/features/patients/ui/pacientes_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

final _ahora = DateTime.now();

DateTime get _hace31Anios =>
    DateTime(_ahora.year - 31, _ahora.month, _ahora.day);

PacienteResumen _paciente({
  required String id,
  required String nombre,
  required String apellido,
  DateTime? fechaNacimiento,
  String? meta,
  num? pesoKg,
  num? pctGrasa,
  bool conPlan = false,
  bool activo = true,
}) => PacienteResumen(
  id: id,
  nombre: nombre,
  apellido: apellido,
  fechaNacimiento: fechaNacimiento,
  meta: meta,
  activo: activo,
  ultimaMedicion: pesoKg == null && pctGrasa == null
      ? null
      : UltimaMedicion(fecha: _ahora, pesoKg: pesoKg, pctGrasa: pctGrasa),
  planActivo: conPlan ? const {'id': 'plan-1'} : null,
);

Paged<PacienteResumen> _pagina(List<PacienteResumen> items) => Paged(
  items: items,
  meta: PageMeta(limit: 100, offset: 0, total: items.length, hasMore: false),
);

Future<void> _pump(
  WidgetTester tester, {
  required Paged<PacienteResumen> page,
  List<String?>? consultas,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        pacientesDirectorioProvider.overrideWith((ref, query) {
          consultas?.add(query);
          return Future.value(page);
        }),
      ],
      child: MaterialApp(theme: AppTheme.light, home: const PacientesScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('opens with the title, the active count and the four filters', (
    tester,
  ) async {
    await _pump(
      tester,
      page: _pagina([
        _paciente(
          id: 'pac-1',
          nombre: 'Paciente',
          apellido: 'De Prueba',
          conPlan: true,
        ),
        _paciente(id: 'pac-2', nombre: 'Ana', apellido: 'Martínez'),
        _paciente(
          id: 'pac-3',
          nombre: 'Baja',
          apellido: 'Logica',
          activo: false,
        ),
      ]),
    );

    expect(find.text('Mis pacientes'), findsOneWidget);
    // The count lives in the filters; the header carries the action instead.
    expect(find.text('2 activos'), findsNothing);
    expect(find.text('Todos · 2'), findsOneWidget);
    expect(find.text('Sin plan · 1'), findsOneWidget);
    expect(find.text('Con plan · 1'), findsOneWidget);
    expect(find.text('De baja'), findsOneWidget);
    expect(find.text('Nuevo paciente'), findsOneWidget);
  });

  testWidgets('draws a row with its age and goal, its figures and its plan', (
    tester,
  ) async {
    await _pump(
      tester,
      page: _pagina([
        _paciente(
          id: 'pac-1',
          nombre: 'Paciente',
          apellido: 'De Prueba',
          fechaNacimiento: _hace31Anios,
          meta: 'BAJAR',
          pesoKg: 72.4,
          pctGrasa: 19.5,
          conPlan: true,
        ),
      ]),
    );

    expect(find.text('PD'), findsOneWidget);
    expect(find.text('Paciente De Prueba'), findsOneWidget);
    expect(find.text('31 años · Bajar'), findsOneWidget);
    expect(find.text('72.4 kg · 19.5% grasa'), findsOneWidget);
    expect(find.text('Con plan'), findsOneWidget);
  });

  testWidgets('a row without a birth date omits the age instead of a gap', (
    tester,
  ) async {
    await _pump(
      tester,
      page: _pagina([
        _paciente(
          id: 'pac-1',
          nombre: 'María',
          apellido: 'Hernández',
          pesoKg: 78.5,
          pctGrasa: 32.4,
        ),
      ]),
    );

    expect(find.textContaining('años'), findsNothing);
    expect(find.text('78.5 kg · 32.4% grasa'), findsOneWidget);
  });

  testWidgets('the filter narrows the list to the patients with a plan', (
    tester,
  ) async {
    await _pump(
      tester,
      page: _pagina([
        _paciente(id: 'pac-1', nombre: 'Con', apellido: 'Plan', conPlan: true),
        _paciente(id: 'pac-2', nombre: 'Sin', apellido: 'Plan'),
      ]),
    );

    await tester.tap(find.text('Con plan · 1'));
    await tester.pumpAndSettle();

    expect(find.text('Con Plan'), findsOneWidget);
    expect(find.text('Sin Plan'), findsNothing);
  });

  testWidgets('an empty directory explains how the first patient arrives', (
    tester,
  ) async {
    await _pump(tester, page: _pagina([]));

    expect(find.text('Todavía no tenés pacientes'), findsOneWidget);
    // Only the empty state offers the action, so it is not duplicated.
    expect(find.text('Nuevo paciente'), findsOneWidget);
    expect(
      find.text(
        'Agregá el primero con su correo. Cuando inicie sesión con ese correo, '
        'va a ver en su app el plan que le armes.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('typing asks the server with the query, once it settles', (
    tester,
  ) async {
    final consultas = <String?>[];
    // The empty-directory artboard has no search field, so the page needs a row.
    await _pump(
      tester,
      page: _pagina([_paciente(id: 'pac-1', nombre: 'Ana', apellido: 'Paz')]),
      consultas: consultas,
    );
    consultas.clear();

    await tester.enterText(find.byType(TextFormField), 'ana');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(consultas, contains('ana'));
  });

  testWidgets('the filters sit side by side instead of one per row', (
    tester,
  ) async {
    await _pump(
      tester,
      page: _pagina([
        _paciente(id: 'pac-1', nombre: 'Con', apellido: 'Plan', conPlan: true),
      ]),
    );

    final todos = tester.getTopLeft(find.text('Todos · 1')).dy;
    final sinPlan = tester.getTopLeft(find.text('Sin plan · 0')).dy;
    final conPlan = tester.getTopLeft(find.text('Con plan · 1')).dy;

    expect(sinPlan, closeTo(todos, 1));
    expect(conPlan, closeTo(todos, 1));
  });

  testWidgets('tapping a row opens that patient file', (tester) async {
    final router = GoRouter(
      initialLocation: '/pacientes',
      routes: [
        GoRoute(
          path: '/pacientes',
          builder: (context, state) => const PacientesScreen(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) =>
                  Text('ficha ${state.pathParameters['id']}'),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pacientesDirectorioProvider.overrideWith(
            (ref, query) => Future.value(
              _pagina([_paciente(id: 'pac-9', nombre: 'Ana', apellido: 'Paz')]),
            ),
          ),
        ],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ana Paz'));
    await tester.pumpAndSettle();

    expect(find.text('ficha pac-9'), findsOneWidget);
  });

  testWidgets('the new-patient action runs the callback it was given', (
    tester,
  ) async {
    var abierto = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pacientesDirectorioProvider.overrideWith(
            (ref, query) => Future.value(
              _pagina([_paciente(id: 'pac-1', nombre: 'Ana', apellido: 'Paz')]),
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: PacientesScreen(onNuevoPaciente: () => abierto++),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nuevo paciente'));

    expect(abierto, 1);
    expect(
      tester
          .widget<FilledButton>(
            find.ancestor(
              of: find.text('Nuevo paciente'),
              matching: find.byType(FilledButton),
            ),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('states how much of the directory a truncated page holds', (
    tester,
  ) async {
    await _pump(
      tester,
      page: Paged<PacienteResumen>(
        items: [
          _paciente(id: 'pac-1', nombre: 'Con', apellido: 'Plan', conPlan: true),
        ],
        meta: const PageMeta(limit: 100, offset: 0, total: 140, hasMore: true),
      ),
    );

    expect(find.text('Mostrando 1 de 140 pacientes.'), findsOneWidget);
  });
}
