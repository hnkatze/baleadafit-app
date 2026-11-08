import 'package:flutter/material.dart';

import '../../../../core/theme/app_dimensions.dart';
import 'alta_paciente_borrador.dart';
import 'alta_widgets.dart';

/// Step 1, from `MpAltaIdentidad.html`: who the patient is and the email that
/// links them to their app.
class PasoIdentidad extends StatelessWidget {
  const PasoIdentidad({
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CampoAlta(
                clave: 'nombre',
                etiqueta: 'Nombre',
                controller: borrador.nombre,
                error: errores['nombre'],
                onCambio: onCambio,
                capitalizar: TextCapitalization.words,
              ),
            ),
            const SizedBox(width: AppDimensions.spaceSm),
            Expanded(
              child: CampoAlta(
                clave: 'apellido',
                etiqueta: 'Apellido',
                controller: borrador.apellido,
                error: errores['apellido'],
                onCambio: onCambio,
                capitalizar: TextCapitalization.words,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spaceMd),
        CampoAlta(
          clave: 'correo',
          etiqueta: 'Correo',
          icono: Icons.mail_outline,
          controller: borrador.correo,
          error: errores['correo'],
          onCambio: onCambio,
          hint: 'nombre@correo.com',
          teclado: TextInputType.emailAddress,
        ),
        const SizedBox(height: AppDimensions.spaceSm - 2),
        const NotaAlta(
          icono: Icons.link,
          texto:
              'Con este correo el paciente entra a su app y ve su plan. '
              'Usá el que va a usar para iniciar sesión.',
        ),
        const SizedBox(height: AppDimensions.spaceMd),
        CampoAlta(
          clave: 'telefono',
          etiqueta: 'Teléfono · opcional',
          controller: borrador.telefono,
          onCambio: onCambio,
          hint: '+504',
          teclado: TextInputType.phone,
        ),
        const SizedBox(height: AppDimensions.spaceMd),
        EtiquetaAlta(
          etiqueta: 'Sexo',
          child: OpcionesAlta<SexoPaciente>(
            opciones: SexoPaciente.values,
            valor: borrador.sexo,
            etiqueta: (sexo) => sexo.etiqueta,
            onElegir: (sexo) {
              borrador.sexo = sexo;
              onCambio('sexo');
            },
          ),
        ),
        if (errores['sexo'] case final error?) ErrorAlta(error),
        const SizedBox(height: AppDimensions.spaceMd),
        CampoFecha(
          clave: 'fechaNacimiento',
          etiqueta: 'Fecha de nacimiento',
          controller: borrador.fechaNacimiento,
          error: errores['fechaNacimiento'],
          onCambio: onCambio,
          primera: DateTime(1900),
          ultima: DateTime(hoy.year, hoy.month, hoy.day),
        ),
        const SizedBox(height: AppDimensions.spaceXs + 2),
        const AyudaAlta('Con ella se calculan la edad y el requerimiento.'),
      ],
    );
  }
}
