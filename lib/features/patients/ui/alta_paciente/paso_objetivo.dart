import 'package:flutter/material.dart';

import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import 'alta_paciente_borrador.dart';
import 'alta_widgets.dart';

/// Step 2, from `MpAltaObjetivo.html`: the goal, the pace and the data the
/// calorie requirement is computed from.
class PasoObjetivo extends StatelessWidget {
  const PasoObjetivo({
    required this.borrador,
    required this.errores,
    required this.onCambio,
    super.key,
  });

  final AltaPacienteBorrador borrador;
  final Map<String, String> errores;
  final AltaCambio onCambio;

  @override
  Widget build(BuildContext context) {
    final hoy = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const LeyendaAlta('Meta'),
        OpcionesAlta<MetaPaciente>(
          opciones: MetaPaciente.values,
          valor: borrador.meta,
          etiqueta: (meta) => meta.etiqueta,
          detalle: (meta) => meta.ajuste,
          alto: 64,
          onElegir: (meta) {
            borrador.meta = meta;
            onCambio();
          },
        ),
        const SizedBox(height: AppDimensions.spaceMd),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CampoAlta(
                clave: 'pesoObjetivoKg',
                etiqueta: 'Peso objetivo · kg',
                controller: borrador.pesoObjetivoKg,
                error: errores['pesoObjetivoKg'],
                onCambio: onCambio,
                hint: '—',
                numerico: true,
              ),
            ),
            const SizedBox(width: AppDimensions.spaceSm),
            Expanded(
              child: CampoFecha(
                clave: 'fechaObjetivo',
                etiqueta: 'Para cuándo',
                controller: borrador.fechaObjetivo,
                error: errores['fechaObjetivo'],
                onCambio: onCambio,
                primera: DateTime(hoy.year, hoy.month, hoy.day),
                ultima: DateTime(hoy.year + 5, hoy.month, hoy.day),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spaceLg),
        const LeyendaAlta('Nivel de actividad'),
        _NivelesDeActividad(
          valor: borrador.nivelActividad,
          onElegir: (nivel) {
            borrador.nivelActividad = nivel;
            onCambio();
          },
        ),
        const SizedBox(height: AppDimensions.spaceLg),
        const LeyendaAlta('Estado fisiológico'),
        OpcionesAlta<EstadoFisiologico>(
          opciones: EstadoFisiologico.values,
          valor: borrador.estadoFisiologico,
          etiqueta: (estado) => estado.etiqueta,
          onElegir: (estado) {
            borrador.estadoFisiologico = estado;
            onCambio();
          },
        ),
        const SizedBox(height: AppDimensions.spaceXs + 2),
        const AyudaAlta(
          'Embarazo y lactancia cambian el requerimiento calórico.',
        ),
      ],
    );
  }
}

/// The five activity levels as one bordered list with a radio per row and the
/// factor the requirement multiplies by on the right.
class _NivelesDeActividad extends StatelessWidget {
  const _NivelesDeActividad({required this.valor, required this.onElegir});

  final NivelActividad valor;
  final ValueChanged<NivelActividad> onElegir;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Column(
        children: [
          for (final (i, nivel) in NivelActividad.values.indexed)
            Semantics(
              button: true,
              selected: nivel == valor,
              inMutuallyExclusiveGroup: true,
              child: Material(
                color: nivel == valor
                    ? colors.surfaceContainer
                    : colors.surfaceContainerLowest,
                child: InkWell(
                  onTap: () => onElegir(nivel),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 52),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spaceMd,
                    ),
                    decoration: BoxDecoration(
                      border: i == 0
                          ? null
                          : Border(
                              top: BorderSide(color: colors.surfaceContainer),
                            ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          nivel == valor
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          size: 20,
                          color: nivel == valor
                              ? colors.primary
                              : colors.outline,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            nivel.etiqueta,
                            style: nivel == valor
                                ? textTheme.titleMedium
                                : textTheme.bodyMedium,
                          ),
                        ),
                        Text(
                          nivel.factor,
                          style: AppTypography.data(context)
                              .copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
