import 'package:flutter/material.dart';

import '../../../../core/theme/app_dimensions.dart';
import 'alta_paciente_borrador.dart';
import 'alta_widgets.dart';

/// Step 4: daily habits and context, plus the free notes the artboard's
/// stepper label ("Hábitos y notas") promises. No artboard draws it, so it
/// reuses the fields of steps 1 and 2: figures in a row of three, text fields
/// below.
class PasoHabitos extends StatelessWidget {
  const PasoHabitos({
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const NotaAlta(
          icono: Icons.info_outline,
          texto: 'Todo en este paso es opcional.',
        ),
        const SizedBox(height: AppDimensions.spaceLg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CampoAlta(
                clave: 'comidasAlDia',
                etiqueta: 'Comidas al día',
                controller: borrador.comidasAlDia,
                error: errores['comidasAlDia'],
                onCambio: onCambio,
                hint: '—',
                entero: true,
              ),
            ),
            const SizedBox(width: AppDimensions.spaceSm),
            Expanded(
              child: CampoAlta(
                clave: 'aguaLitros',
                etiqueta: 'Agua · litros',
                controller: borrador.aguaLitros,
                error: errores['aguaLitros'],
                onCambio: onCambio,
                hint: '—',
                numerico: true,
              ),
            ),
            const SizedBox(width: AppDimensions.spaceSm),
            Expanded(
              child: CampoAlta(
                clave: 'horasSueno',
                etiqueta: 'Sueño · horas',
                controller: borrador.horasSueno,
                error: errores['horasSueno'],
                onCambio: onCambio,
                hint: '—',
                numerico: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spaceMd),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CampoAlta(
                clave: 'alcohol',
                etiqueta: 'Alcohol',
                controller: borrador.alcohol,
                onCambio: onCambio,
                capitalizar: TextCapitalization.sentences,
              ),
            ),
            const SizedBox(width: AppDimensions.spaceSm),
            Expanded(
              child: CampoAlta(
                clave: 'tabaco',
                etiqueta: 'Tabaco',
                controller: borrador.tabaco,
                onCambio: onCambio,
                capitalizar: TextCapitalization.sentences,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spaceMd),
        CampoAlta(
          clave: 'quienCocina',
          etiqueta: 'Quién cocina',
          controller: borrador.quienCocina,
          onCambio: onCambio,
          capitalizar: TextCapitalization.sentences,
        ),
        const SizedBox(height: AppDimensions.spaceMd),
        CampoAlta(
          clave: 'presupuesto',
          etiqueta: 'Presupuesto',
          controller: borrador.presupuesto,
          onCambio: onCambio,
          capitalizar: TextCapitalization.sentences,
        ),
        const SizedBox(height: AppDimensions.spaceMd),
        CampoAlta(
          clave: 'notas',
          etiqueta: 'Notas',
          controller: borrador.notas,
          onCambio: onCambio,
          lineas: 3,
          capitalizar: TextCapitalization.sentences,
        ),
      ],
    );
  }
}
