import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_failure.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_pill.dart';
import '../data/paciente_ficha.dart';
import '../data/patients_providers.dart';
import 'evolucion_chart.dart';
import 'paciente_menu.dart';

/// The file of one patient, from `GET /pacientes/{id}/ficha`: who they are,
/// their body composition, daily requirement, plan, appointments and last
/// measurement.
///
/// The shell owns the top bar and the drawer, so this screen only draws the
/// `Ficha` row the artboard puts under them (back and overflow) and the body.
class PacienteFichaScreen extends ConsumerWidget {
  const PacienteFichaScreen({
    required this.pacienteId,
    required this.onBack,
    this.onNuevaMedicion,
    this.onEditarDatos,
    this.onMedicamentos,
    this.onVerHistorial,
    super.key,
  });

  final String pacienteId;

  /// The screen cannot know whether it was pushed or deep-linked, so the
  /// router decides where back goes.
  final VoidCallback onBack;

  /// Opens the measurement form. The router owns it, like every other
  /// navigation of the module; without it the CTAs are disabled.
  final VoidCallback? onNuevaMedicion;

  /// Opens the edit form. The router owns it; without it the menu entry is
  /// drawn but does nothing.
  final VoidCallback? onEditarDatos;

  /// Opens the medication list. Null until it exists, like [onEditarDatos].
  final VoidCallback? onMedicamentos;

  /// Opens the measurement history. Null until that list exists.
  final VoidCallback? onVerHistorial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ficha = ref.watch(pacienteFichaProvider(pacienteId));

    // Transparent Material so buttons have an ink surface even when the screen
    // is not hosted by a Scaffold.
    return Material(
      type: MaterialType.transparency,
      child: Column(
        children: [
          // Drawn in every state so the user can always leave the screen.
          _Cabecera(
            onBack: onBack,
            onMasOpciones: () => mostrarMenuPaciente(
              context,
              ref,
              pacienteId: pacienteId,
              onEditarDatos: onEditarDatos,
              onMedicamentos: onMedicamentos,
              onDadoDeBaja: onBack,
            ),
          ),
          Expanded(
            child: ficha.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ListView(
                padding: AppDimensions.screenPadding,
                children: [
                  _LoadFailure(
                    error: error,
                    onRetry: () =>
                        ref.invalidate(pacienteFichaProvider(pacienteId)),
                  ),
                ],
              ),
              data: (data) => _Contenido(
                ficha: data,
                onNuevaMedicion: onNuevaMedicion,
                onVerHistorial: onVerHistorial,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Body once the ficha arrived: the scrolling blocks plus the pinned action.
class _Contenido extends StatelessWidget {
  const _Contenido({
    required this.ficha,
    required this.onNuevaMedicion,
    required this.onVerHistorial,
  });

  final PacienteFicha ficha;
  final VoidCallback? onNuevaMedicion;
  final VoidCallback? onVerHistorial;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final conMediciones = ficha.tieneMediciones;
    final plan = ficha.planActivo;
    final proxima = ficha.consultas.proximas.firstOrNull;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: AppDimensions.screenPadding,
            children: [
              _Hero(ficha: ficha),
              // Without a plan the system raises an alert; the board draws it
              // before any other block.
              if (plan == null) _SinPlanAlerta(alertas: ficha.alertas),
              // With no measurement there is nothing to calculate from, so
              // the BMI, composition and requirement blocks are not drawn at
              // all rather than drawn as zeros.
              if (!conMediciones)
                const _SinMediciones()
              else ...[
                if (ficha.cabecera.imc != null)
                  _CardImc(cabecera: ficha.cabecera),
                if (ficha.progreso.pesoActual != null)
                  _CardPeso(progreso: ficha.progreso),
                if (ficha.requerimiento != null)
                  _Requerimiento(
                    requerimiento: ficha.requerimiento!,
                    paciente: ficha.paciente,
                  ),
              ],
              if (plan != null)
                _PlanYAdherencia(
                  plan: plan,
                  adherencia: ficha.adherencia,
                  entroALaApp: ficha.paciente.entroALaApp,
                ),
              _ProximaConsulta(consulta: proxima),
              if (conMediciones)
                _Mediciones(ficha: ficha, onVerHistorial: onVerHistorial),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.spaceMd,
            AppDimensions.spaceSm + 4,
            AppDimensions.spaceMd,
            AppDimensions.spaceMd,
          ),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(top: BorderSide(color: colors.outlineVariant)),
          ),
          child: SafeArea(
            top: false,
            // FilledButton.icon lets the label wrap on a narrow screen or a large
            // font scale, where AppButton's fixed row would overflow.
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onNuevaMedicion,
                icon: const Icon(Icons.add, size: AppDimensions.iconSm),
                label: Text(
                  conMediciones
                      ? 'Nueva medición'
                      : 'Registrar primera medición',
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The `Ficha` row: back, title and overflow.
class _Cabecera extends StatelessWidget {
  const _Cabecera({required this.onBack, required this.onMasOpciones});

  final VoidCallback onBack;
  final VoidCallback onMasOpciones;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceXs),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Volver a Mis pacientes',
            icon: const Icon(Icons.arrow_back, size: AppDimensions.iconMd),
            onPressed: onBack,
          ),
          Expanded(
            child: Text('Ficha', style: Theme.of(context).textTheme.titleLarge),
          ),
          IconButton(
            tooltip: 'Más opciones',
            icon: const Icon(Icons.more_vert, size: AppDimensions.iconMd),
            onPressed: onMasOpciones,
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.ficha});

  final PacienteFicha ficha;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final paciente = ficha.paciente;
    final cabecera = ficha.cabecera;

    final perfil = [
      ?_sexoLabel(paciente.sexo),
      if (cabecera.edad != null) '${cabecera.edad} años',
      if (cabecera.tallaCm != null) '${_entero(cabecera.tallaCm!)} cm',
    ].join(' · ');
    final meta = _metaLabel(paciente.meta);
    final nombre = paciente.nombreCompleto;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Text(
                paciente.iniciales,
                style: textTheme.titleLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.24,
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nombre.isEmpty ? 'Paciente' : nombre,
                    style: textTheme.headlineSmall,
                  ),
                  if (perfil.isNotEmpty)
                    Text(
                      perfil,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spaceSm + 4),
        Wrap(
          spacing: AppDimensions.spaceSm,
          runSpacing: AppDimensions.spaceSm,
          children: [
            if (ficha.planActivo != null)
              AppPill(label: 'Con plan', dotColor: colors.primary)
            else
              // A grey dot: "no plan" is a state to notice, not a success.
              AppPill(label: 'Sin plan', dotColor: colors.outline),
            if (meta != null) AppPill(label: 'Meta: ${meta.$1}', icon: meta.$2),
            if (!paciente.entroALaApp) const _InsigniaSinApp(),
          ],
        ),
      ],
    );
  }
}

/// Neutral badge: it informs, it does not warn. The patient simply has not
/// signed in with the mail of the file yet.
class _InsigniaSinApp extends StatelessWidget {
  const _InsigniaSinApp();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceMd - 4,
        vertical: AppDimensions.spaceXs,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.link_off, size: 14, color: colors.onSurfaceVariant),
          const SizedBox(width: AppDimensions.spaceSm - 2),
          Flexible(
            child: Text(
              'Sin entrar a la app',
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _SinPlanAlerta extends StatelessWidget {
  const _SinPlanAlerta({required this.alertas});

  final List<AlertaFicha> alertas;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    // The server words the alert; the fallback keeps the screen honest when a
    // payload without alerts still has no active plan.
    final detalle =
        alertas
            .where((a) => a.tipo == 'SIN_PLAN_ACTIVO')
            .map((a) => a.detalle)
            .nonNulls
            .firstOrNull ??
        'El paciente no tiene un plan activo.';

    return Padding(
      padding: const EdgeInsets.only(top: AppDimensions.spaceMd),
      child: Semantics(
        container: true,
        liveRegion: true,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceMd,
            vertical: AppDimensions.spaceSm + 4,
          ),
          decoration: BoxDecoration(
            color: colors.errorContainer,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error, size: 20, color: colors.onErrorContainer),
              const SizedBox(width: AppDimensions.spaceSm + 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sin plan activo',
                      style: textTheme.titleMedium?.copyWith(
                        color: colors.onErrorContainer,
                      ),
                    ),
                    Text(
                      detalle,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.onErrorContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SinMediciones extends StatelessWidget {
  const _SinMediciones();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: AppDimensions.spaceLg),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceMd,
          vertical: AppDimensions.spaceLg,
        ),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: colors.outline),
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colors.surfaceContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.monitor_weight_outlined,
                size: 28,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceMd),
            Text(
              'Todavía no hay mediciones',
              textAlign: TextAlign.center,
              style: textTheme.titleLarge,
            ),
            const SizedBox(height: AppDimensions.spaceXs),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 290),
              child: Text(
                'Con la primera medición aparecen el IMC, la composición '
                'corporal y el requerimiento calórico.',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card shell shared by the blocks: white surface, hairline border.
class _Tarjeta extends StatelessWidget {
  const _Tarjeta({
    required this.child,
    this.radius = AppDimensions.radiusMd,
    this.color,
    this.bordered = true,
  });

  final Widget child;
  final double radius;
  final Color? color;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spaceMd),
      decoration: BoxDecoration(
        color: color ?? colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(radius),
        border: bordered ? Border.all(color: colors.outlineVariant) : null,
      ),
      child: child,
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion(this.titulo);

  final String titulo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppDimensions.spaceLg,
        bottom: AppDimensions.spaceSm,
      ),
      child: Text(titulo, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _CardImc extends StatelessWidget {
  const _CardImc({required this.cabecera});

  final FichaCabecera cabecera;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final imc = cabecera.imc!;
    final clasificacion = _clasificacionLabel(cabecera.clasificacionImc);
    final normal = cabecera.clasificacionImc == 'NORMAL';

    return Padding(
      padding: const EdgeInsets.only(top: AppDimensions.spaceLg),
      child: _Tarjeta(
        radius: AppDimensions.radiusLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'ÍNDICE DE MASA CORPORAL',
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.primary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                if (clasificacion != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: AppDimensions.spaceXs,
                    ),
                    decoration: BoxDecoration(
                      // Only the healthy range is green: any other class is
                      // information, but it should not read as "all good".
                      color: normal
                          ? colors.secondaryContainer
                          : colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusFull,
                      ),
                    ),
                    child: Text(
                      clasificacion,
                      style: textTheme.labelSmall?.copyWith(
                        color: normal
                            ? colors.onPrimaryContainer
                            : colors.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppDimensions.spaceXs),
            Text(_uno(imc), style: textTheme.displayLarge),
            const SizedBox(height: AppDimensions.spaceSm),
            _EscalaImc(imc: imc),
            if (cabecera.pctGrasa != null || cabecera.masaMagraKg != null) ...[
              const SizedBox(height: AppDimensions.spaceSm + 4),
              Container(
                padding: const EdgeInsets.only(top: AppDimensions.spaceSm + 4),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: colors.surfaceContainer),
                  ),
                ),
                child: Row(
                  children: [
                    if (cabecera.pctGrasa != null)
                      Expanded(
                        child: _Cifra(
                          etiqueta: '% grasa',
                          valor: _uno(cabecera.pctGrasa!),
                          unidad: '%',
                        ),
                      ),
                    if (cabecera.masaMagraKg != null)
                      Expanded(
                        child: _Cifra(
                          etiqueta: 'Masa magra',
                          valor: _uno(cabecera.masaMagraKg!),
                          unidad: 'kg',
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Label, big figure and a smaller unit beside it.
class _Cifra extends StatelessWidget {
  const _Cifra({
    required this.etiqueta,
    required this.valor,
    required this.unidad,
  });

  final String etiqueta;
  final String valor;
  final String unidad;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          style: textTheme.labelMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(valor, style: textTheme.headlineSmall),
            const SizedBox(width: 2),
            Text(
              unidad,
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// WHO range bar: four segments (under, normal, over, obese) with the marker
/// where the patient falls.
///
/// Drawn with widgets and not a painter so the 18.5 / 25 / 30 marks stay real
/// text: they scale with the user's font settings and a screen reader or test
/// can find them. Coordinates are the artboard's 326pt viewBox, scaled to the
/// card width.
class _EscalaImc extends StatelessWidget {
  const _EscalaImc({required this.imc});

  final num imc;

  static const _ancho = 326.0;
  static const _segmentos = [
    (0.0, 64.0),
    (67.0, 105.0),
    (175.0, 76.0),
    (254.0, 72.0),
  ];
  static const _marcas = [(65.5, '18.5'), (173.5, '25'), (252.5, '30')];

  /// Position of the marker. Linear inside each WHO band, so the normal range
  /// keeps the room the artboard gives it.
  static double _posicion(num imc) {
    if (imc < 18.5) return (65.5 * (imc - 10) / 8.5).clamp(0, 65.5);
    if (imc < 25) return 65.5 + (imc - 18.5) / 6.5 * 108;
    if (imc < 30) return 173.5 + (imc - 25) / 5 * 79;
    return (252.5 + (imc - 30) / 10 * 73.5).clamp(252.5, _ancho);
  }

  static int _activo(num imc) => imc < 18.5
      ? 0
      : imc < 25
      ? 1
      : imc < 30
      ? 2
      : 3;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final marca = AppTypography.data(context)
        .copyWith(fontSize: 10, color: colors.onSurfaceVariant);
    final activo = _activo(imc);

    return Semantics(
      label: 'IMC ${_uno(imc)}',
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final escala = constraints.maxWidth / _ancho;
            final x = _posicion(imc) * escala;

            return SizedBox(
              height: 40,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (final (i, (inicio, ancho)) in _segmentos.indexed)
                    Positioned(
                      left: inicio * escala,
                      top: 10,
                      width: ancho * escala,
                      height: 8,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: i == activo
                              ? colors.primaryContainer
                              : colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusXs,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    left: x - 1,
                    top: 2,
                    width: 2,
                    height: 24,
                    child: ColoredBox(color: colors.onSurface),
                  ),
                  Positioned(
                    left: x - 3,
                    top: -1,
                    width: 6,
                    height: 6,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.onSurface,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  for (final (posicion, texto) in _marcas)
                    Positioned(
                      left: posicion * escala - 20,
                      top: 26,
                      width: 40,
                      child: Text(
                        texto,
                        textAlign: TextAlign.center,
                        style: marca,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CardPeso extends StatelessWidget {
  const _CardPeso({required this.progreso});

  final FichaProgreso progreso;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    final resumen = [
      if (progreso.pesoInicial != null)
        'inicial ${_uno(progreso.pesoInicial!)}',
      if (progreso.deltaKg != null) 'Δ ${_delta(progreso.deltaKg!)} kg',
    ].join(' · ');

    // With a single measurement the API sends no pace; saying so is more useful
    // than an empty chart. Only the weekly pace is shown: the projection of the
    // artboard was never designed, and a forecast is the kind of number that
    // should not be invented.
    final ritmo = progreso.ritmoKgSemana;
    final tendencia = ritmo == null
        ? 'La tendencia y la proyección aparecen con la segunda medición.'
        : '${_delta(ritmo)} kg/semana';

    return Padding(
      padding: const EdgeInsets.only(top: AppDimensions.spaceSm),
      child: _Tarjeta(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('Peso', style: textTheme.titleMedium),
                if (resumen.isNotEmpty)
                  Flexible(
                    child: Text(
                      resumen,
                      style: AppTypography.data(context)
                          .copyWith(color: colors.onSurfaceVariant),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppDimensions.spaceXs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _uno(progreso.pesoActual!),
                  style: textTheme.headlineMedium,
                ),
                const SizedBox(width: AppDimensions.spaceXs),
                Text(
                  'kg',
                  style: textTheme.titleMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spaceSm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.show_chart,
                  size: 18,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: AppDimensions.spaceSm),
                Expanded(
                  child: Text(
                    tendencia,
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Requerimiento extends StatelessWidget {
  const _Requerimiento({required this.requerimiento, required this.paciente});

  final RequerimientoFicha requerimiento;
  final PacienteDetalle paciente;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final r = requerimiento;
    final actividad = _actividadLabel(paciente.nivelActividad);
    final meta = _metaLabel(paciente.meta)?.$1;

    // Each row is left out when the API did not calculate it, never zeroed.
    final filas = [
      if (r.tmb != null) ('Metabolismo basal (TMB)', '${_miles(r.tmb!)} kcal'),
      if (r.factorActividad != null)
        (
          actividad == null ? '× Actividad' : '× Actividad $actividad',
          r.factorActividad.toString(),
        ),
      if (r.gastoTotal != null)
        ('= Gasto total', '${_miles(r.gastoTotal!)} kcal'),
      if (r.ajusteMeta != null)
        (
          meta == null ? 'Ajuste por meta' : 'Ajuste por meta ($meta)',
          '${_firmado(r.ajusteMeta!)} kcal',
        ),
    ];
    final macros = [
      if (r.proteinaG != null) ('PROTEÍNA', r.proteinaG!),
      if (r.carbohidratoG != null) ('CARBOS', r.carbohidratoG!),
      if (r.grasaG != null) ('GRASAS', r.grasaG!),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Seccion('Requerimiento diario'),
        _Tarjeta(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, (etiqueta, valor)) in filas.indexed) ...[
                if (i > 0) const SizedBox(height: AppDimensions.spaceSm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        etiqueta,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spaceMd),
                    Text(valor, style: AppTypography.data(context)),
                  ],
                ),
              ],
              if (r.kcalObjetivo != null) ...[
                const SizedBox(height: AppDimensions.spaceSm + 4),
                Container(
                  padding: const EdgeInsets.only(
                    top: AppDimensions.spaceSm + 4,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: colors.outlineVariant),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('Objetivo', style: textTheme.titleMedium),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _miles(r.kcalObjetivo!),
                            style: textTheme.headlineMedium,
                          ),
                          const SizedBox(width: AppDimensions.spaceXs),
                          Text(
                            'kcal',
                            style: textTheme.titleMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              if (macros.isNotEmpty) ...[
                const SizedBox(height: AppDimensions.spaceSm + 4),
                Row(
                  children: [
                    for (final (i, (etiqueta, gramos)) in macros.indexed) ...[
                      if (i > 0) const SizedBox(width: AppDimensions.spaceSm),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: AppDimensions.spaceSm,
                          ),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusSm,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                etiqueta,
                                style: textTheme.labelSmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                '${_uno(gramos)} g',
                                style: AppTypography.data(context)
                                    .copyWith(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PlanYAdherencia extends StatelessWidget {
  const _PlanYAdherencia({
    required this.plan,
    required this.adherencia,
    required this.entroALaApp,
  });

  final PlanFicha plan;
  final AdherenciaFicha adherencia;
  final bool entroALaApp;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    final detalle = [
      ?_estadoPlanLabel(plan.estado),
      ?_origenPlanLabel(plan.origen),
      if (plan.aprobadoEn != null)
        'aprobado el ${_diaMes(plan.aprobadoEn!.toLocal())}',
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Seccion('Plan y adherencia'),
        _Tarjeta(
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.restaurant_menu,
                  size: 20,
                  color: colors.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: AppDimensions.spaceSm + 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plan.nombre ?? 'Plan', style: textTheme.titleMedium),
                    if (detalle.isNotEmpty)
                      Text(
                        detalle,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              // No chevron: the plan screen does not exist yet, and an arrow
              // that does nothing reads as a broken tap.
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.spaceSm),
        _Adherencia(adherencia: adherencia, entroALaApp: entroALaApp),
      ],
    );
  }
}

class _Adherencia extends StatelessWidget {
  const _Adherencia({required this.adherencia, required this.entroALaApp});

  final AdherenciaFicha adherencia;
  final bool entroALaApp;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final sinDatos = adherencia.sinDatos;

    // "No records" is not 0%: nothing to divide by says nothing about effort.
    final titulo = sinDatos
        ? 'Adherencia · sin registros'
        : 'Adherencia · últimos 30 días';
    // Only the two facts that come from the API are written: the design draws
    // the empty state and nothing else, so the populated block stays a number
    // and a count instead of prose nobody designed.
    final texto = sinDatos
        ? (entroALaApp
              ? 'Todavía no hay comidas marcadas.'
              : 'El paciente todavía no entró a la app. Cuando inicie sesión '
                    'con el correo de su ficha, va a poder marcar sus comidas '
                    'y acá vas a ver su avance de 30 días.')
        : '${adherencia.cumplidos ?? 0} de ${adherencia.total} comidas';
    // The API sends `porcentaje` as a fraction (0..1), not as 0..100, so it is
    // scaled before it reaches the label; the fallback below already computes a
    // percentage and must not be scaled twice.
    final porcentaje = adherencia.porcentaje == null
        ? ((adherencia.cumplidos ?? 0) * 100 / (adherencia.total ?? 1))
        : adherencia.porcentaje! * 100;

    return _Tarjeta(
      color: colors.surfaceContainerLow,
      bordered: false,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            sinDatos ? Icons.hourglass_empty : Icons.check_circle_outline,
            size: 22,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(width: AppDimensions.spaceSm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: textTheme.titleMedium),
                if (!sinDatos)
                  Text(
                    '${_entero(porcentaje)}%',
                    style: textTheme.headlineSmall,
                  ),
                const SizedBox(height: 2),
                Text(
                  texto,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProximaConsulta extends StatelessWidget {
  const _ProximaConsulta({required this.consulta});

  final ConsultaFicha? consulta;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final cuando = consulta?.fechaHora?.toLocal();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Seccion('Próximas consultas'),
        if (consulta == null)
          _Tarjeta(
            color: colors.surfaceContainerLow,
            bordered: false,
            child: Text(
              'Sin consultas programadas.',
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          )
        else
          _Tarjeta(
            color: colors.surface,
            child: Row(
              children: [
                if (cuando != null) ...[
                  SizedBox(
                    width: 44,
                    child: Column(
                      children: [
                        Text(
                          _meses[cuando.month - 1].toUpperCase(),
                          style: textTheme.labelSmall?.copyWith(
                            color: colors.primary,
                          ),
                        ),
                        Text('${cuando.day}', style: textTheme.headlineSmall),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spaceMd),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        consulta!.motivo ?? 'Consulta',
                        style: textTheme.titleMedium,
                      ),
                      if (_cuandoLinea(consulta!) case final linea?)
                        Text(
                          linea,
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Mediciones extends StatelessWidget {
  const _Mediciones({required this.ficha, required this.onVerHistorial});

  final PacienteFicha ficha;
  final VoidCallback? onVerHistorial;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    // The evolution is oldest first, so the last entry is the latest.
    final ultima = ficha.evolucion.last;
    final peso = ultima.pesoKg ?? ficha.progreso.pesoActual;
    final talla = ultima.tallaCm ?? ficha.cabecera.tallaCm;
    final grasa = ultima.pctGrasa ?? ficha.cabecera.pctGrasa;

    final celdas = [
      ('PESO', peso == null ? '—' : '${_uno(peso)} kg'),
      ('TALLA', talla == null ? '—' : '${_entero(talla)} cm'),
      ('% GRASA', grasa == null ? '—' : '${_uno(grasa)}%'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: AppDimensions.spaceLg,
            bottom: AppDimensions.spaceSm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Mediciones', style: textTheme.titleMedium),
              TextButton(
                onPressed: onVerHistorial,
                child: Text('Ver historial · ${ficha.evolucion.length}'),
              ),
            ],
          ),
        ),
        _Tarjeta(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  for (final (etiqueta, valor) in celdas)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            etiqueta,
                            style: textTheme.labelSmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          Text(valor, style: AppTypography.data(context)),
                        ],
                      ),
                    ),
                ],
              ),
              // The chart draws itself only from the second measurement.
              if (ficha.evolucion.length >= 2) ...[
                const SizedBox(height: AppDimensions.spaceMd),
                EvolucionChart(mediciones: ficha.evolucion),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _LoadFailure extends StatelessWidget {
  const _LoadFailure({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final failure = error;
    final detail = failure is ApiFailure
        ? failure.mensaje
        : 'Revisá tu conexión e intentá de nuevo.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('No pudimos cargar la ficha.', style: textTheme.titleMedium),
        const SizedBox(height: AppDimensions.spaceXs),
        Text(detail, style: textTheme.bodyMedium),
        const SizedBox(height: AppDimensions.spaceMd),
        AppButton(
          label: 'Reintentar',
          icon: Icons.refresh,
          variant: AppButtonVariant.secondary,
          onPressed: onRetry,
        ),
      ],
    );
  }
}

// The API sends raw enums and ISO dates; the copy is a UI concern. `intl` is
// not a dependency, and these few Spanish names do not justify adding it.

String? _sexoLabel(String? sexo) => switch (sexo) {
  'M' => 'Masculino',
  'F' => 'Femenino',
  _ => null,
};

/// Lowercase label and icon of the goal, e.g. `Meta: bajar`.
(String, IconData)? _metaLabel(String? meta) => switch (meta) {
  'BAJAR' => ('bajar', Icons.trending_down),
  'MANTENER' => ('mantener', Icons.trending_flat),
  'SUBIR' => ('subir', Icons.trending_up),
  _ => null,
};

/// The API has only shown `NORMAL`; an unknown class is shown as sent, in a
/// readable form, instead of hiding a clinical fact.
String? _clasificacionLabel(String? clasificacion) {
  if (clasificacion == null) return null;
  final text = clasificacion.toLowerCase().replaceAll('_', ' ');
  return text[0].toUpperCase() + text.substring(1);
}

String? _actividadLabel(String? nivel) => switch (nivel) {
  'SEDENTARIO' => 'sedentaria',
  'LIGERO' => 'ligera',
  'MODERADO' => 'moderada',
  'INTENSO' => 'intensa',
  'MUY_INTENSO' => 'muy intensa',
  _ => null,
};

String? _estadoPlanLabel(String? estado) => switch (estado) {
  'ACTIVO' => 'Activo',
  'BORRADOR' => 'Borrador',
  _ => null,
};

String? _origenPlanLabel(String? origen) => switch (origen) {
  'REGLAS' => 'generado por reglas',
  _ => null,
};

const _meses = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

const _dias = [
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
];

String _diaMes(DateTime fecha) => '${fecha.day} ${_meses[fecha.month - 1]}';

/// `Viernes · 09:00 · 45 min`, leaving out the parts the payload lacks.
String? _cuandoLinea(ConsultaFicha consulta) {
  final fecha = consulta.fechaHora?.toLocal();
  final partes = [
    if (fecha != null) _dias[fecha.weekday - 1],
    if (fecha != null)
      '${fecha.hour.toString().padLeft(2, '0')}:'
          '${fecha.minute.toString().padLeft(2, '0')}',
    if (consulta.duracionMin != null) '${consulta.duracionMin} min',
  ];
  return partes.isEmpty ? null : partes.join(' · ');
}

/// One decimal, as the artboard writes clinical figures: `72.4`, `93.8`.
String _uno(num value) => value.toStringAsFixed(1);

/// A whole number without decimals, otherwise one: `174`, `60.5`.
String _entero(num value) =>
    value == value.roundToDouble() ? value.round().toString() : _uno(value);

/// Thousands with a dot, the way the artboard writes calories: `1.662`.
String _miles(num value) {
  final digits = value.round().abs().toString();
  final grouped = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) grouped.write('.');
    grouped.write(digits[i]);
  }
  return '${value.round() < 0 ? '−' : ''}$grouped';
}

/// Signed calories with a real minus sign (U+2212): `−500`, `+300`, `0`.
String _firmado(num value) {
  final rounded = value.round();
  if (rounded == 0) return '0';
  return rounded < 0 ? _miles(rounded) : '+${_miles(rounded)}';
}

/// Signed one-decimal change: `0.0`, `−0.8`, `+0.4`. A change that rounds to
/// zero is written without a sign so `-0.0` never shows.
String _delta(num value) {
  final text = value.abs().toStringAsFixed(1);
  if (text == '0.0') return text;
  return value < 0 ? '−$text' : '+$text';
}
