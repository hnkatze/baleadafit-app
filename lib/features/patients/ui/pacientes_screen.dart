import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_failure.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_pill.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../data/paciente_resumen.dart';
import '../data/patients_providers.dart';

/// Quiet time after the last keystroke before the server is asked, so typing
/// a name does not fire one request per letter.
const _debounce = Duration(milliseconds: 300);

enum _Filtro { todos, sinPlan, conPlan, dadosDeBaja }

/// The directory of the nutritionist: search, four live filters and one row
/// per patient, from `GET /pacientes`.
///
/// The shell owns the top bar and the drawer, so this screen only draws the
/// body.
class PacientesScreen extends ConsumerStatefulWidget {
  const PacientesScreen({this.onNuevoPaciente, super.key});

  /// Opens the new-patient wizard. Left null, the action is drawn disabled
  /// instead of pointing nowhere (a screen hosted without a router).
  final VoidCallback? onNuevoPaciente;

  @override
  ConsumerState<PacientesScreen> createState() => _PacientesScreenState();
}

class _PacientesScreenState extends ConsumerState<PacientesScreen> {
  final _controller = TextEditingController();
  Timer? _timer;
  String _query = '';
  _Filtro _filtro = _Filtro.todos;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _timer?.cancel();
    _timer = Timer(_debounce, () {
      final query = text.trim();
      if (mounted && query != _query) setState(() => _query = query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final page = ref.watch(pacientesDirectorioProvider(_query));
    final pacientes = page.asData?.value.items;
    final activos = pacientes?.where((p) => p.activo).toList();

    // Without a search, an empty directory means the nutritionist has no
    // patients yet; with one, it only means nothing matched.
    final sinPacientes =
        pacientes != null && pacientes.isEmpty && _query.isEmpty;

    // Transparent Material so fields and chips have an ink surface even when
    // the screen is not hosted by a Scaffold.
    return Material(
      type: MaterialType.transparency,
      child: ListView(
        padding: AppDimensions.screenPadding,
        children: [
          _Encabezado(
            // The empty state owns the action when there is nobody yet, so the
            // header does not offer a second, disabled one.
            mostrarAccion: !sinPacientes,
            onNuevoPaciente: widget.onNuevoPaciente,
          ),
          if (!sinPacientes) ...[
            const SizedBox(height: AppDimensions.spaceMd),
            _Buscador(controller: _controller, onChanged: _onChanged),
            const SizedBox(height: AppDimensions.spaceSm + 4),
            _Filtros(
              actual: _filtro,
              todos: activos?.length,
              sinPlan: activos?.where((p) => !p.tienePlanActivo).length,
              conPlan: activos?.where((p) => p.tienePlanActivo).length,
              onSelected: (filtro) => setState(() => _filtro = filtro),
            ),
            const SizedBox(height: AppDimensions.spaceMd),
          ],
          ...page.when(
            loading: () => const [
              Padding(
                padding: EdgeInsets.symmetric(vertical: AppDimensions.spaceXl),
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
            error: (error, _) => [
              _LoadFailure(
                error: error,
                onRetry: () =>
                    ref.invalidate(pacientesDirectorioProvider(_query)),
              ),
            ],
            data: (data) => sinPacientes
                ? [_SinPacientes(onNuevoPaciente: widget.onNuevoPaciente)]
                : [
                    ..._filas(data.items),
                    // The chip counts are computed over one page, so a
                    // truncated page is stated instead of silently lying.
                    if (data.meta.hasMore)
                      _AvisoTope(
                        mostrados: data.items.length,
                        total: data.meta.total,
                      ),
                  ],
          ),
        ],
      ),
    );
  }

  List<Widget> _filas(List<PacienteResumen> items) {
    final visibles = items.where((p) {
      return switch (_filtro) {
        _Filtro.todos => p.activo,
        _Filtro.sinPlan => p.activo && !p.tienePlanActivo,
        _Filtro.conPlan => p.activo && p.tienePlanActivo,
        _Filtro.dadosDeBaja => !p.activo,
      };
    }).toList();

    if (visibles.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceLg),
          child: Text(
            'No encontramos pacientes.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ];
    }

    return [
      for (final paciente in visibles) ...[
        _FilaPaciente(paciente: paciente),
        const SizedBox(height: AppDimensions.spaceSm),
      ],
    ];
  }
}

/// Says how much of the directory is on screen when the page is truncated.
class _AvisoTope extends StatelessWidget {
  const _AvisoTope({required this.mostrados, required this.total});

  final int mostrados;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppDimensions.spaceSm),
      child: Text(
        'Mostrando $mostrados de $total pacientes.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Title plus the primary action.
///
/// The active count is not repeated here: the filters already carry it, and a
/// number next to the title competed with them for the same information.
class _Encabezado extends StatelessWidget {
  const _Encabezado({
    required this.mostrarAccion,
    required this.onNuevoPaciente,
  });

  final bool mostrarAccion;
  final VoidCallback? onNuevoPaciente;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(child: Text('Mis pacientes', style: textTheme.headlineLarge)),
        // Compact on purpose: the board draws it as a 56pt floating pill, but
        // inline next to a 30pt title that size crowds the row.
        if (mostrarAccion) _NuevoPacienteAction(onPressed: onNuevoPaciente),
      ],
    );
  }
}

class _Buscador extends StatelessWidget {
  const _Buscador({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    // The placeholder says what can be typed; the label is what a screen
    // reader announces.
    return Semantics(
      label: 'Buscar paciente',
      child: AppTextField(
        controller: controller,
        hint: 'Nombre, apellido o correo',
        prefixIcon: Icons.search,
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.search,
        onChanged: onChanged,
      ),
    );
  }
}

class _Filtros extends StatelessWidget {
  const _Filtros({
    required this.actual,
    required this.todos,
    required this.sinPlan,
    required this.conPlan,
    required this.onSelected,
  });

  final _Filtro actual;
  final int? todos;
  final int? sinPlan;
  final int? conPlan;
  final ValueChanged<_Filtro> onSelected;

  @override
  Widget build(BuildContext context) {
    // A count that has not arrived is left out rather than shown as 0.
    String conteo(String label, int? n) => n == null ? label : '$label · $n';

    final etiquetas = {
      _Filtro.todos: conteo('Todos', todos),
      _Filtro.sinPlan: conteo('Sin plan', sinPlan),
      _Filtro.conPlan: conteo('Con plan', conPlan),
      _Filtro.dadosDeBaja: 'De baja',
    };

    // Tighter than the board so the four filters fit one row on a 390pt screen.
    return Wrap(
      spacing: AppDimensions.spaceSm - 2,
      runSpacing: AppDimensions.spaceSm,
      children: [
        for (final entry in etiquetas.entries)
          _FiltroChip(
            label: entry.value,
            selected: entry.key == actual,
            onTap: () => onSelected(entry.key),
          ),
      ],
    );
  }
}

class _FiltroChip extends StatelessWidget {
  const _FiltroChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const shape = StadiumBorder();

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? colors.primary : colors.surfaceContainerLowest,
        shape: selected
            ? shape
            : StadiumBorder(side: BorderSide(color: colors.outlineVariant)),
        child: InkWell(
          customBorder: shape,
          onTap: onTap,
          // Not a Container with `alignment`: inside a Wrap that expands to the
          // full width available, which puts every chip on its own row.
          child: SizedBox(
            height: 36,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Center(
                widthFactor: 1,
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: selected
                        ? colors.onPrimary
                        : colors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FilaPaciente extends StatelessWidget {
  const _FilaPaciente({required this.paciente});

  final PacienteResumen paciente;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final edad = paciente.edad();
    final meta = _metaLabel(paciente.meta);
    final perfil = [if (edad != null) '$edad años', ?meta].join(' · ');
    final medidas = paciente.ultimaMedicion?.resumen;

    final radius = BorderRadius.circular(AppDimensions.radiusMd);

    // Push, not go: the file stacks over the list so back returns to it.
    return Material(
      color: colors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: () => context.push(AppRoutes.paciente(paciente.id)),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceMd),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  paciente.iniciales,
                  style: textTheme.titleSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.spaceSm + 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(paciente.nombreCompleto, style: textTheme.titleMedium),
                    if (perfil.isNotEmpty)
                      Text(
                        perfil,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    if (medidas != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        medidas,
                        style: AppTypography.data(context)
                            .copyWith(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
              if (paciente.tienePlanActivo)
                Align(
                  alignment: Alignment.topCenter,
                  child: AppPill(label: 'Con plan', dotColor: colors.primary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The API sends the goal as a raw enum; the copy is a UI concern.
String? _metaLabel(String? meta) => switch (meta) {
  'BAJAR' => 'Bajar',
  'MANTENER' => 'Mantener',
  'SUBIR' => 'Subir',
  _ => null,
};

class _NuevoPacienteAction extends StatelessWidget {
  const _NuevoPacienteAction({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.person_add, size: AppDimensions.iconSm),
      label: const Text('Nuevo paciente'),
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceSm + 2,
        ),
        textStyle: Theme.of(context).textTheme.labelMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
      ),
    );
  }
}

class _SinPacientes extends StatelessWidget {
  const _SinPacientes({required this.onNuevoPaciente});

  final VoidCallback? onNuevoPaciente;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: AppDimensions.spaceXxl),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: colors.surfaceContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.group_add, size: 36, color: colors.primary),
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          Text(
            'Todavía no tenés pacientes',
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall,
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Text(
              'Agregá el primero con su correo. Cuando inicie sesión con ese '
              'correo, va a ver en su app el plan que le armes.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spaceLg),
          AppButton(
            label: 'Nuevo paciente',
            icon: Icons.person_add,
            expand: false,
            onPressed: onNuevoPaciente,
          ),
        ],
      ),
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
        Text('No pudimos cargar tus pacientes.', style: textTheme.titleMedium),
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
