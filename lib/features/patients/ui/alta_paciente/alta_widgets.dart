import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import 'alta_paciente_borrador.dart';

/// Tells the wizard a field changed: with a [clave] the error of that field
/// is cleared (the nutritionist is already fixing it); without one, only the
/// screen is redrawn (a choice was made).
typedef AltaCambio = void Function([String? clave]);

/// A label above its input, like the other mobile forms (no floating label).
class EtiquetaAlta extends StatelessWidget {
  const EtiquetaAlta({
    required this.etiqueta,
    required this.child,
    this.icono,
    super.key,
  });

  final String etiqueta;
  final Widget child;

  /// Drawn at 18pt in the primary color before the label.
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (icono != null) ...[
              Icon(icono, size: AppDimensions.iconSm, color: colors.primary),
              const SizedBox(width: AppDimensions.spaceXs + 2),
            ],
            Expanded(
              child: Text(
                etiqueta,
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: colors.onSurfaceVariant),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spaceXs + 2),
        child,
      ],
    );
  }
}

/// A labelled text input. [clave] is the `POST /pacientes` field it feeds and
/// also its widget key, so tests and the error map speak the same name.
class CampoAlta extends StatelessWidget {
  const CampoAlta({
    required this.clave,
    required this.etiqueta,
    required this.controller,
    required this.onCambio,
    this.error,
    this.hint,
    this.icono,
    this.teclado,
    this.capitalizar = TextCapitalization.none,
    this.lineas = 1,
    this.numerico = false,
    this.entero = false,
    super.key,
  });

  final String clave;
  final String etiqueta;
  final TextEditingController controller;
  final AltaCambio onCambio;
  final String? error;
  final String? hint;
  final IconData? icono;
  final TextInputType? teclado;
  final TextCapitalization capitalizar;
  final int lineas;

  /// Figures are tabular mono so a column of readings lines up.
  final bool numerico;

  /// Whole numbers only; implies [numerico].
  final bool entero;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final esNumero = numerico || entero;

    return EtiquetaAlta(
      etiqueta: etiqueta,
      icono: icono,
      child: TextField(
        key: ValueKey(clave),
        controller: controller,
        minLines: lineas,
        maxLines: lineas,
        keyboardType:
            teclado ??
            (esNumero
                ? TextInputType.numberWithOptions(decimal: !entero)
                : TextInputType.text),
        textCapitalization: capitalizar,
        inputFormatters: esNumero
            ? [
                FilteringTextInputFormatter.allow(
                  entero ? RegExp(r'\d') : RegExp(r'[\d.,]'),
                ),
              ]
            : null,
        onChanged: (_) => onCambio(clave),
        style: esNumero
            ? AppTypography.data(context)
                  .copyWith(fontSize: 15, color: colors.onSurface)
            : Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: colors.onSurface),
        decoration: InputDecoration(
          hintText: hint,
          errorText: error,
          errorMaxLines: 2,
        ),
      ),
    );
  }
}

/// A `dd/mm/aaaa` input with the calendar as a shortcut: typing is quicker for
/// a birth date decades back, the picker for a date next month.
class CampoFecha extends StatelessWidget {
  const CampoFecha({
    required this.clave,
    required this.etiqueta,
    required this.controller,
    required this.onCambio,
    required this.primera,
    required this.ultima,
    this.error,
    super.key,
  });

  final String clave;
  final String etiqueta;
  final TextEditingController controller;
  final AltaCambio onCambio;
  final String? error;
  final DateTime primera;
  final DateTime ultima;

  Future<void> _elegir(BuildContext context) async {
    // Clamped, because showDatePicker asserts on an initial date outside range.
    var inicial = leerFecha(controller.text) ?? DateTime.now();
    if (inicial.isBefore(primera)) inicial = primera;
    if (inicial.isAfter(ultima)) inicial = ultima;
    final elegida = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: primera,
      lastDate: ultima,
    );
    if (elegida == null) return;
    controller.text = formatearFecha(elegida);
    onCambio(clave);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return EtiquetaAlta(
      etiqueta: etiqueta,
      child: TextField(
        key: ValueKey(clave),
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [_FormatoFecha()],
        onChanged: (_) => onCambio(clave),
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: colors.onSurface),
        decoration: InputDecoration(
          hintText: 'dd/mm/aaaa',
          errorText: error,
          errorMaxLines: 2,
          suffixIcon: IconButton(
            tooltip: 'Elegir fecha',
            icon: Icon(
              Icons.calendar_today,
              size: 20,
              color: colors.onSurfaceVariant,
            ),
            onPressed: () => _elegir(context),
          ),
        ),
      ),
    );
  }
}

/// Keeps only digits and puts the slashes back, so the nutritionist types
/// `15031994` or `15/03/1994` and the field reads the same.
class _FormatoFecha extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitos = newValue.text.replaceAll(RegExp(r'\D'), '');
    final corto = digitos.length > 8 ? digitos.substring(0, 8) : digitos;
    final texto = StringBuffer();
    for (var i = 0; i < corto.length; i++) {
      if (i == 2 || i == 4) texto.write('/');
      texto.write(corto[i]);
    }
    final formateado = texto.toString();
    return TextEditingValue(
      text: formateado,
      selection: TextSelection.collapsed(offset: formateado.length),
    );
  }
}

/// A group title, as the artboard draws `Meta` and `Nivel de actividad`.
class LeyendaAlta extends StatelessWidget {
  const LeyendaAlta(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spaceSm),
      child: Text(texto, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

/// A short remark under a field, in the muted body color.
class AyudaAlta extends StatelessWidget {
  const AyudaAlta(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontSize: 12,
        height: 1.33,
      ),
    );
  }
}

/// The tinted note box of the artboard: an icon and a sentence.
class NotaAlta extends StatelessWidget {
  const NotaAlta({required this.icono, required this.texto, super.key});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 16, color: colors.primary),
          const SizedBox(width: AppDimensions.spaceSm),
          Expanded(
            child: Text(
              texto,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onPrimaryContainer,
                fontSize: 12,
                height: 1.33,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Exclusive choice drawn as equal buttons side by side (`Sexo`, `Meta`,
/// `Estado fisiológico`). [detalle] is the mono line under the label.
class OpcionesAlta<T> extends StatelessWidget {
  const OpcionesAlta({
    required this.opciones,
    required this.valor,
    required this.etiqueta,
    required this.onElegir,
    this.detalle,
    this.alto = AppDimensions.fieldHeight,
    super.key,
  });

  final List<T> opciones;
  final T? valor;
  final String Function(T opcion) etiqueta;
  final String Function(T opcion)? detalle;
  final ValueChanged<T> onElegir;
  final double alto;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        for (final (i, opcion) in opciones.indexed) ...[
          if (i > 0) const SizedBox(width: AppDimensions.spaceSm),
          Expanded(
            child: Builder(
              builder: (context) {
                final elegida = opcion == valor;
                final color = elegida
                    ? colors.primary
                    : colors.onSurfaceVariant;

                return Semantics(
                  button: true,
                  selected: elegida,
                  inMutuallyExclusiveGroup: true,
                  child: Material(
                    color: elegida
                        ? colors.surfaceContainer
                        : colors.surfaceContainerLowest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusSm,
                      ),
                      side: BorderSide(
                        color: elegida ? colors.primary : colors.outlineVariant,
                        width: elegida ? 1.6 : 1,
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusSm,
                      ),
                      onTap: () => onElegir(opcion),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: alto),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              etiqueta(opcion),
                              textAlign: TextAlign.center,
                              style: textTheme.titleMedium?.copyWith(
                                color: color,
                              ),
                            ),
                            if (detalle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                detalle!(opcion),
                                style: AppTypography.data(context)
                                    .copyWith(fontSize: 12, color: color),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

/// The error of a group of buttons, which has no input to carry it.
class ErrorAlta extends StatelessWidget {
  const ErrorAlta(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: AppDimensions.spaceXs + 2),
      child: Text(
        texto,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: colors.error),
      ),
    );
  }
}
