/// Number formatting of the meal-plan module: one format, the one the patient
/// file already uses. A dot for thousands and for decimals, no space before the
/// `%`, whole numbers without decimals and otherwise one decimal.
///
/// Which helper a field takes is a decision per field, never generic:
/// `pctKcal`, `desviacion` and the generated distributions are **fractions**
/// (`0.25` is 25%) and go through [formatearFraccion] / [formatearDesviacion];
/// `pctGrasa` of a measurement is already a percentage and goes through
/// [formatearPorcentaje].
library;

const _menos = '−';

/// A number rounded to one decimal, so `28.999999999999996` is `29`.
double _aUnDecimal(num valor) => (valor * 10).round() / 10;

/// Whole numbers without decimals, otherwise one: `25`, `93.8`.
String formatearNumero(num valor) {
  final redondeado = _aUnDecimal(valor);
  final texto = redondeado == redondeado.roundToDouble()
      ? redondeado.round().toString()
      : redondeado.toStringAsFixed(1);
  return texto == '-0' ? '0' : texto.replaceFirst('-', _menos);
}

/// Grams: `93.8g`, `100g`.
String formatearGramos(num valor) => '${formatearNumero(valor)}g';

/// Thousands with a dot: `1.500`, `10.542`. A negative uses a real minus.
String formatearKcal(num valor) {
  final redondeado = valor.round();
  final digitos = redondeado.abs().toString();
  final agrupado = StringBuffer();
  for (var i = 0; i < digitos.length; i++) {
    if (i > 0 && (digitos.length - i) % 3 == 0) agrupado.write('.');
    agrupado.write(digitos[i]);
  }
  return '${redondeado < 0 ? _menos : ''}$agrupado';
}

/// Signed kcal: `+300`, `−500`, `0`.
String formatearKcalFirmada(num valor) {
  final redondeado = valor.round();
  if (redondeado == 0) return '0';
  return redondeado < 0
      ? formatearKcal(redondeado)
      : '+${formatearKcal(redondeado)}';
}

/// A value that is **already a percentage**: `19.5%`, `25%`. Not multiplied.
String formatearPorcentaje(num porcentaje) => '${formatearNumero(porcentaje)}%';

/// A **fraction** 0..1 as a percentage: `0.35` → `35%`, `0.195` → `19.5%`.
String formatearFraccion(num fraccion) => formatearPorcentaje(fraccion * 100);

/// A signed **fraction** as a change: `0.004` → `+0.4%`, `-0.008` → `−0.8%`.
/// Always one decimal, and a change that rounds to zero is `0.0%` with no sign,
/// so `-0.0%` never shows.
String formatearDesviacion(num fraccion) {
  final porcentaje = fraccion * 100;
  final texto = porcentaje.abs().toStringAsFixed(1);
  if (texto == '0.0') return '$texto%';
  return '${porcentaje < 0 ? _menos : '+'}$texto%';
}

/// Portions come in multiples of 0.25, so two decimals are kept when needed:
/// `1`, `1.5`, `0.25`.
String formatearPorciones(num porciones) {
  final texto = porciones.toStringAsFixed(2);
  return texto.replaceFirst(RegExp(r'\.?0+$'), '');
}
