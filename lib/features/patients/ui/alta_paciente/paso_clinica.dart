import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../data/catalogo_item.dart';
import 'alta_paciente_borrador.dart';
import 'alta_widgets.dart';

/// Step 3: the clinical picture. No artboard exists for it, so it follows the
/// language of steps 1 and 2: a legend over each group, chips for the two
/// catalogues, then the free-text fields.
class PasoClinica extends StatelessWidget {
  const PasoClinica({
    required this.borrador,
    required this.condiciones,
    required this.restricciones,
    required this.onReintentarCondiciones,
    required this.onReintentarRestricciones,
    required this.onCambio,
    super.key,
  });

  final AltaPacienteBorrador borrador;

  /// Each catalogue loads, fails and retries on its own: one failing must not
  /// hide the other.
  final AsyncValue<List<CatalogoItem>> condiciones;
  final AsyncValue<List<CatalogoItem>> restricciones;
  final VoidCallback onReintentarCondiciones;
  final VoidCallback onReintentarRestricciones;
  final AltaCambio onCambio;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Nothing here is required, and saying so avoids a stuck feeling when
        // a catalogue fails to load.
        const NotaAlta(
          icono: Icons.info_outline,
          texto: 'Todo en este paso es opcional.',
        ),
        const SizedBox(height: AppDimensions.spaceLg),
        _SeccionCatalogo(
          titulo: 'Condiciones',
          catalogo: condiciones,
          elegidos: borrador.condiciones,
          onCambio: onCambio,
          onReintentar: onReintentarCondiciones,
        ),
        const SizedBox(height: AppDimensions.spaceLg),
        _SeccionCatalogo(
          titulo: 'Restricciones',
          catalogo: restricciones,
          elegidos: borrador.restricciones,
          onCambio: onCambio,
          onReintentar: onReintentarRestricciones,
        ),
        const SizedBox(height: AppDimensions.spaceLg),
        CampoAlta(
          clave: 'alergias',
          etiqueta: 'Alergias',
          controller: borrador.alergias,
          onCambio: onCambio,
          lineas: 2,
          capitalizar: TextCapitalization.sentences,
        ),
        const SizedBox(height: AppDimensions.spaceMd),
        CampoAlta(
          clave: 'cirugias',
          etiqueta: 'Cirugías',
          controller: borrador.cirugias,
          onCambio: onCambio,
          lineas: 2,
          capitalizar: TextCapitalization.sentences,
        ),
        const SizedBox(height: AppDimensions.spaceMd),
        CampoAlta(
          clave: 'suplementos',
          etiqueta: 'Suplementos',
          controller: borrador.suplementos,
          onCambio: onCambio,
          lineas: 2,
          capitalizar: TextCapitalization.sentences,
        ),
        const SizedBox(height: AppDimensions.spaceMd),
        CampoAlta(
          clave: 'motivoConsulta',
          etiqueta: 'Motivo de la consulta',
          controller: borrador.motivoConsulta,
          onCambio: onCambio,
          lineas: 3,
          capitalizar: TextCapitalization.sentences,
        ),
      ],
    );
  }
}

/// A legend over the chips of one catalogue, or its loading / failure state.
class _SeccionCatalogo extends StatelessWidget {
  const _SeccionCatalogo({
    required this.titulo,
    required this.catalogo,
    required this.elegidos,
    required this.onCambio,
    required this.onReintentar,
  });

  final String titulo;
  final AsyncValue<List<CatalogoItem>> catalogo;
  final Set<String> elegidos;
  final AltaCambio onCambio;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LeyendaAlta(titulo),
        // Keep the previous list on screen while a retry loads, instead of
        // flashing a spinner over chips the nutritionist already picked.
        if (catalogo.hasValue)
          _Chips(
            items: catalogo.requireValue,
            elegidos: elegidos,
            onCambio: onCambio,
          )
        else if (catalogo.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppDimensions.spaceSm),
            child: Center(
              child: SizedBox.square(
                dimension: AppDimensions.iconMd,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else
          _FallaDeCatalogo(error: catalogo.error!, onReintentar: onReintentar),
      ],
    );
  }
}

class _Chips extends StatelessWidget {
  const _Chips({
    required this.items,
    required this.elegidos,
    required this.onCambio,
  });

  final List<CatalogoItem> items;
  final Set<String> elegidos;
  final AltaCambio onCambio;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (items.isEmpty) {
      return Text(
        'No hay opciones disponibles.',
        style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
      );
    }

    return Wrap(
      spacing: AppDimensions.spaceSm,
      runSpacing: AppDimensions.spaceSm,
      children: [
        for (final item in items)
          _chip(context, item, selected: elegidos.contains(item.codigo)),
      ],
    );
  }

  Widget _chip(
    BuildContext context,
    CatalogoItem item, {
    required bool selected,
  }) {
    final colors = Theme.of(context).colorScheme;
    final chip = FilterChip(
      label: Text(item.nombre),
      selected: selected,
      showCheckmark: false,
      backgroundColor: colors.surfaceContainerLowest,
      selectedColor: colors.surfaceContainer,
      labelStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: selected ? colors.primary : colors.onSurfaceVariant,
      ),
      side: BorderSide(
        color: selected ? colors.primary : colors.outlineVariant,
        width: selected ? 1.6 : 1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      ),
      onSelected: (value) {
        if (value) {
          elegidos.add(item.codigo);
        } else {
          elegidos.remove(item.codigo);
        }
        onCambio();
      },
    );

    // The catalogue describes the conditions; a long press reveals it without
    // turning twenty chips into twenty paragraphs.
    final descripcion = item.descripcion;
    if (descripcion == null || descripcion.isEmpty) return chip;
    return Tooltip(message: descripcion, child: chip);
  }
}

class _FallaDeCatalogo extends StatelessWidget {
  const _FallaDeCatalogo({required this.error, required this.onReintentar});

  final Object error;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final mensaje = error is ApiFailure
        ? (error as ApiFailure).mensaje
        : 'Algo salió mal. Intentá de nuevo.';

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceSm + 4),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            size: AppDimensions.iconSm,
            color: colors.onErrorContainer,
          ),
          const SizedBox(width: AppDimensions.spaceSm),
          Expanded(
            child: Text(
              mensaje,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: colors.onErrorContainer),
            ),
          ),
          TextButton(
            onPressed: onReintentar,
            style: TextButton.styleFrom(
              foregroundColor: colors.onErrorContainer,
            ),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
