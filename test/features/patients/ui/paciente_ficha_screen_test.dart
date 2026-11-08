import 'package:baleadafit/core/network/api_failure.dart';
import 'package:baleadafit/core/theme/app_theme.dart';
import 'package:baleadafit/features/patients/data/paciente_ficha.dart';
import 'package:baleadafit/features/patients/data/patients_providers.dart';
import 'package:baleadafit/features/patients/ui/evolucion_chart.dart';
import 'package:baleadafit/features/patients/ui/paciente_ficha_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The payload of the `MpFicha` artboard: one measurement, an active plan from
/// the rules engine and a patient who never signed in. Dates carry no zone so
/// the wall-clock times are the same on any machine; 2025-11-07 is a Friday,
/// which keeps the board's `NOV 7` chip and its `Viernes` line consistent.
Map<String, Object?> _conMediciones({Map<String, Object?>? progreso}) => {
  'paciente': {
    'id': 'pac-1',
    'nombre': 'Paciente',
    'apellido': 'De Prueba',
    'sexo': 'M',
    'meta': 'BAJAR',
    'nivelActividad': 'SEDENTARIO',
    'activo': true,
    'firebaseUid': null,
  },
  'cabecera': {
    'edad': 31,
    'imc': 23.9,
    'clasificacionImc': 'NORMAL',
    'pctGrasa': 19.5,
    'masaMagraKg': 58.3,
    'ultimaMedicion': {'tallaCm': 174},
  },
  'progreso':
      progreso ?? {'pesoInicial': 72.4, 'pesoActual': 72.4, 'deltaKg': 0},
  'requerimiento': {
    'tmb': 1662,
    'factorActividad': 1.2,
    'gastoTotal': 1994,
    'ajusteMeta': -500,
    'kcalObjetivo': 1500,
    'proteinaG': 93.8,
    'carbohidratoG': 187.5,
    'grasaG': 41.7,
  },
  'adherencia30d': {'porcentaje': null, 'cumplidos': 0, 'total': 0},
  'alertas': <Object?>[],
  'evolucion': [
    {
      'id': 'med-1',
      'fecha': '2025-11-07T08:00:00',
      'pesoKg': 72.4,
      'tallaCm': 174,
      'pctGrasa': 19.5,
    },
  ],
  'consultas': {
    'proximas': [
      {
        'id': 'cita-1',
        'fechaHora': '2025-11-07T09:00:00',
        'duracionMin': 45,
        'motivo': 'Revisión de mediciones',
        'estado': 'PROGRAMADA',
      },
    ],
  },
  'planes': [
    {
      'id': 'plan-1',
      'nombre': 'Plan 2026-11-07',
      'estado': 'ACTIVO',
      'origen': 'REGLAS',
      'aprobadoEn': '2025-11-07T10:00:00',
    },
  ],
};

/// The payload of the `MpFichaSinMediciones` artboard.
Map<String, Object?> _sinMediciones() => {
  'paciente': {
    'id': 'pac-2',
    'nombre': 'Ana',
    'apellido': 'Martínez',
    'sexo': 'F',
    'meta': 'MANTENER',
    'activo': true,
    'firebaseUid': 'uid-ana',
  },
  'cabecera': {'edad': 28},
  'progreso': <String, Object?>{},
  'requerimiento': null,
  'adherencia30d': {'porcentaje': null, 'cumplidos': 0, 'total': 0},
  'alertas': [
    {
      'tipo': 'SIN_PLAN_ACTIVO',
      'severidad': 'alta',
      'detalle': 'El paciente no tiene un plan activo.',
    },
  ],
  'evolucion': <Object?>[],
  'consultas': {'proximas': <Object?>[]},
  'planes': <Object?>[],
};

Future<void> _pump(
  WidgetTester tester, {
  required Future<PacienteFicha> Function() ficha,
  VoidCallback? onNuevaMedicion,
  VoidCallback? onBack,
}) async {
  tester.view.physicalSize = const Size(390, 2200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [pacienteFichaProvider.overrideWith((ref, id) => ficha())],
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: PacienteFichaScreen(
            pacienteId: 'pac-1',
            onBack: onBack ?? () {},
            onNuevaMedicion: onNuevaMedicion,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<PacienteFicha> Function() _de(Map<String, Object?> json) =>
    () async => PacienteFicha.fromJson(json);

void main() {
  testWidgets('the hero reads name, profile, plan, goal and the app link', (
    tester,
  ) async {
    await _pump(tester, ficha: _de(_conMediciones()));

    expect(find.text('Ficha'), findsOneWidget);
    expect(find.text('PD'), findsOneWidget);
    expect(find.text('Paciente De Prueba'), findsOneWidget);
    expect(find.text('Masculino · 31 años · 174 cm'), findsOneWidget);
    expect(find.text('Con plan'), findsOneWidget);
    expect(find.text('Meta: bajar'), findsOneWidget);
    expect(find.text('Sin entrar a la app'), findsOneWidget);
  });

  testWidgets('the app-link badge is left out once the patient signed in', (
    tester,
  ) async {
    final json = _conMediciones();
    (json['paciente']! as Map<String, Object?>)['firebaseUid'] = 'uid-1';
    await _pump(tester, ficha: _de(json));

    expect(find.text('Sin entrar a la app'), findsNothing);
  });

  testWidgets('the profile line omits the parts the payload lacks', (
    tester,
  ) async {
    final json = _conMediciones();
    (json['paciente']! as Map<String, Object?>)['sexo'] = null;
    (json['cabecera']! as Map<String, Object?>).remove('ultimaMedicion');
    await _pump(tester, ficha: _de(json));

    expect(find.text('31 años'), findsOneWidget);
  });

  testWidgets('draws the BMI block with its scale and the composition', (
    tester,
  ) async {
    await _pump(tester, ficha: _de(_conMediciones()));

    expect(find.text('ÍNDICE DE MASA CORPORAL'), findsOneWidget);
    expect(find.text('Normal'), findsOneWidget);
    expect(find.text('23.9'), findsOneWidget);
    expect(find.text('18.5'), findsOneWidget);
    expect(find.text('25'), findsOneWidget);
    expect(find.text('30'), findsOneWidget);
    expect(find.text('% grasa'), findsOneWidget);
    expect(find.text('19.5'), findsOneWidget);
    expect(find.text('Masa magra'), findsOneWidget);
    expect(find.text('58.3'), findsOneWidget);
  });

  testWidgets('the weight reads from the start and says the trend is missing', (
    tester,
  ) async {
    await _pump(tester, ficha: _de(_conMediciones()));

    expect(find.text('Peso'), findsOneWidget);
    expect(find.text('inicial 72.4 · Δ 0.0 kg'), findsOneWidget);
    expect(
      find.text(
        'La tendencia y la proyección aparecen con la segunda medición.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('with a trend the missing-trend line is gone', (tester) async {
    await _pump(
      tester,
      ficha: _de(
        _conMediciones(
          progreso: {
            'pesoInicial': 72.4,
            'pesoActual': 71.6,
            'deltaKg': -0.8,
            'ritmoKgSemana': -0.4,
            'proyeccionKg': 68.0,
          },
        ),
      ),
    );

    expect(
      find.text(
        'La tendencia y la proyección aparecen con la segunda medición.',
      ),
      findsNothing,
    );
    expect(find.text('inicial 72.4 · Δ −0.8 kg'), findsOneWidget);
  });

  testWidgets('draws the daily requirement as the artboard rows', (
    tester,
  ) async {
    await _pump(tester, ficha: _de(_conMediciones()));

    expect(find.text('Requerimiento diario'), findsOneWidget);
    expect(find.text('Metabolismo basal (TMB)'), findsOneWidget);
    expect(find.text('1.662 kcal'), findsOneWidget);
    expect(find.text('× Actividad sedentaria'), findsOneWidget);
    expect(find.text('1.2'), findsOneWidget);
    expect(find.text('= Gasto total'), findsOneWidget);
    expect(find.text('1.994 kcal'), findsOneWidget);
    expect(find.text('Ajuste por meta (bajar)'), findsOneWidget);
    expect(find.text('−500 kcal'), findsOneWidget);
    expect(find.text('Objetivo'), findsOneWidget);
    expect(find.text('1.500'), findsOneWidget);
    expect(find.text('PROTEÍNA'), findsOneWidget);
    expect(find.text('93.8 g'), findsOneWidget);
    expect(find.text('CARBOS'), findsOneWidget);
    expect(find.text('187.5 g'), findsOneWidget);
    expect(find.text('GRASAS'), findsOneWidget);
    expect(find.text('41.7 g'), findsOneWidget);
  });

  testWidgets('the plan card and the empty adherence follow the artboard', (
    tester,
  ) async {
    await _pump(tester, ficha: _de(_conMediciones()));

    expect(find.text('Plan y adherencia'), findsOneWidget);
    expect(find.text('Plan 2026-11-07'), findsOneWidget);
    expect(
      find.text('Activo · generado por reglas · aprobado el 7 nov'),
      findsOneWidget,
    );
    expect(find.text('Adherencia · sin registros'), findsOneWidget);
    expect(
      find.text(
        'El paciente todavía no entró a la app. Cuando inicie sesión con el '
        'correo de su ficha, va a poder marcar sus comidas y acá vas a ver su '
        'avance de 30 días.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('adherence with records shows the share, not the empty state', (
    tester,
  ) async {
    final json = _conMediciones();
    // A fraction, as the API sends it: 0.75 is 75%.
    json['adherencia30d'] = {'porcentaje': 0.75, 'cumplidos': 15, 'total': 20};
    await _pump(tester, ficha: _de(json));

    expect(find.text('Adherencia · sin registros'), findsNothing);
    expect(find.text('75%'), findsOneWidget);
  });

  testWidgets('draws the first upcoming appointment', (tester) async {
    await _pump(tester, ficha: _de(_conMediciones()));

    expect(find.text('Próximas consultas'), findsOneWidget);
    expect(find.text('NOV'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('Revisión de mediciones'), findsOneWidget);
    expect(find.text('Viernes · 09:00 · 45 min'), findsOneWidget);
  });

  testWidgets('draws the measurements summary and the action', (tester) async {
    await _pump(tester, ficha: _de(_conMediciones()));

    expect(find.text('Mediciones'), findsOneWidget);
    expect(find.text('Ver historial · 1'), findsOneWidget);
    expect(find.text('PESO'), findsOneWidget);
    expect(find.text('72.4 kg'), findsOneWidget);
    expect(find.text('TALLA'), findsOneWidget);
    expect(find.text('174 cm'), findsOneWidget);
    expect(find.text('% GRASA'), findsOneWidget);
    expect(find.text('19.5%'), findsOneWidget);
    expect(find.text('Nueva medición'), findsOneWidget);
  });

  testWidgets('the measurement action calls back when one is given', (
    tester,
  ) async {
    var taps = 0;
    await _pump(
      tester,
      ficha: _de(_conMediciones()),
      onNuevaMedicion: () => taps++,
    );

    await tester.tap(find.text('Nueva medición'));

    expect(taps, 1);
  });

  testWidgets('the back arrow leaves through the given callback', (
    tester,
  ) async {
    var backs = 0;
    await _pump(tester, ficha: _de(_conMediciones()), onBack: () => backs++);

    await tester.tap(find.byTooltip('Volver a Mis pacientes'));

    expect(backs, 1);
  });

  group('without measurements', () {
    testWidgets('explains the gap and draws no BMI, composition or '
        'requirement block', (tester) async {
      await _pump(tester, ficha: _de(_sinMediciones()));

      expect(find.text('Todavía no hay mediciones'), findsOneWidget);
      expect(
        find.text(
          'Con la primera medición aparecen el IMC, la composición corporal y '
          'el requerimiento calórico.',
        ),
        findsOneWidget,
      );
      expect(find.text('Registrar primera medición'), findsOneWidget);

      // Absent, not zeroed.
      expect(find.text('ÍNDICE DE MASA CORPORAL'), findsNothing);
      expect(find.text('% grasa'), findsNothing);
      expect(find.text('Masa magra'), findsNothing);
      expect(find.text('Peso'), findsNothing);
      expect(find.text('Requerimiento diario'), findsNothing);
      expect(find.text('Mediciones'), findsNothing);
      expect(find.text('Nueva medición'), findsNothing);
      expect(find.textContaining('0.0'), findsNothing);
    });

    testWidgets('without a plan it raises the alert and the pill', (
      tester,
    ) async {
      await _pump(tester, ficha: _de(_sinMediciones()));

      expect(find.text('AM'), findsOneWidget);
      expect(find.text('Ana Martínez'), findsOneWidget);
      expect(find.text('Femenino · 28 años'), findsOneWidget);
      expect(find.text('Sin plan'), findsOneWidget);
      expect(find.text('Meta: mantener'), findsOneWidget);
      expect(find.text('Sin plan activo'), findsOneWidget);
      expect(find.text('El paciente no tiene un plan activo.'), findsOneWidget);
      expect(find.text('Plan y adherencia'), findsNothing);
      expect(find.text('Con plan'), findsNothing);
      expect(find.text('Sin entrar a la app'), findsNothing);
    });

    testWidgets('says there are no appointments', (tester) async {
      await _pump(tester, ficha: _de(_sinMediciones()));

      expect(find.text('Próximas consultas'), findsOneWidget);
      expect(find.text('Sin consultas programadas.'), findsOneWidget);
    });
  });

  testWidgets('shows a spinner while the ficha loads', (tester) async {
    tester.view.physicalSize = const Size(390, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pacienteFichaProvider.overrideWith(
            (ref, id) => Future<PacienteFicha>.delayed(
              const Duration(seconds: 5),
              () => PacienteFicha.fromJson(_conMediciones()),
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: PacienteFichaScreen(pacienteId: 'pac-1', onBack: () {}),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('a failure offers a retry that asks again', (tester) async {
    var calls = 0;
    await _pump(
      tester,
      ficha: () async {
        calls++;
        if (calls == 1) throw const ApiFailure(mensaje: 'Servidor caído');
        return PacienteFicha.fromJson(_conMediciones());
      },
    );

    expect(find.text('No pudimos cargar la ficha.'), findsOneWidget);
    expect(find.text('Servidor caído'), findsOneWidget);

    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(calls, 2);
    expect(find.text('Paciente De Prueba'), findsOneWidget);
  });

  testWidgets('reads the adherence fraction as a percentage', (tester) async {
    // The API sends adherencia30d.porcentaje as a fraction 0..1, not 0..100.
    final json = _conMediciones();
    json['adherencia30d'] = {'porcentaje': 0.75, 'cumplidos': 3, 'total': 4};

    await _pump(tester, ficha: _de(json));

    expect(find.text('75%'), findsOneWidget);
    expect(find.text('0.75%'), findsNothing);
  });

  group('the weight and body-fat chart', () {
    Map<String, Object?> conEvolucion(List<Map<String, Object?>> evolucion) => {
      ..._conMediciones(),
      'evolucion': evolucion,
    };

    List<PuntoEvolucion> puntos(WidgetTester tester, String clave) {
      final pintura = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byKey(Key(clave)),
          matching: find.byType(CustomPaint),
        ),
      );
      return (pintura.painter! as EvolucionPainter).puntos;
    }

    testWidgets('draws both series from two measurements in order', (
      tester,
    ) async {
      await _pump(
        tester,
        ficha: _de(
          conEvolucion([
            {'fecha': '2025-11-07T08:00:00', 'pesoKg': 72.4, 'pctGrasa': 19.5},
            // Same date on purpose: the axis is the order, not the time.
            {'fecha': '2025-11-07T09:00:00', 'pesoKg': 71.8, 'pctGrasa': 19.1},
          ]),
        ),
      );

      expect(find.byKey(const Key('evolucion-grafico')), findsOneWidget);
      expect(puntos(tester, 'evolucion-peso').map((p) => p.valor), [
        72.4,
        71.8,
      ]);
      expect(puntos(tester, 'evolucion-grasa').map((p) => p.valor), [
        19.5,
        19.1,
      ]);
      expect(puntos(tester, 'evolucion-peso').map((p) => p.orden), [0, 1]);
    });

    testWidgets('draws no chart with one measurement and keeps the line', (
      tester,
    ) async {
      await _pump(tester, ficha: _de(_conMediciones()));

      expect(find.byKey(const Key('evolucion-grafico')), findsNothing);
      expect(
        find.text(
          'La tendencia y la proyección aparecen con la segunda medición.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('skips a null weight instead of drawing it as zero', (
      tester,
    ) async {
      await _pump(
        tester,
        ficha: _de(
          conEvolucion([
            {'fecha': '2025-11-07T08:00:00', 'pesoKg': 72.4, 'pctGrasa': 19.5},
            {'fecha': '2025-11-08T08:00:00', 'pesoKg': null, 'pctGrasa': 19.0},
            {'fecha': '2025-11-09T08:00:00', 'pesoKg': 71.0, 'pctGrasa': 18.6},
          ]),
        ),
      );

      final peso = puntos(tester, 'evolucion-peso');
      expect(peso.map((p) => p.valor), [72.4, 71.0]);
      // The gap keeps its slot, so the third measurement stays third.
      expect(peso.map((p) => p.orden), [0, 2]);
      expect(puntos(tester, 'evolucion-grasa'), hasLength(3));
    });
  });
}
