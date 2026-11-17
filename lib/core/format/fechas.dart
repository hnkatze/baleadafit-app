/// Date formatting shared by the forms, the screens and the request bodies.
///
/// The API stores calendar dates (birth date, target date, suggested next
/// appointment) at midnight UTC. Those values are read from their **own**
/// fields and never converted with `toLocal()`, or they would show the previous
/// day west of Greenwich. Instants (`fechaHora`) are a different thing: those
/// are formatted after `toLocal()` at the render site.
library;

/// `dd/mm/aaaa` to a date, or null when it is incomplete or not a real day
/// (`31/02/2020` would otherwise silently roll over to March).
DateTime? leerFecha(String texto) {
  final partes = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(texto.trim());
  if (partes == null) return null;
  final dia = int.parse(partes[1]!);
  final mes = int.parse(partes[2]!);
  final anio = int.parse(partes[3]!);
  final fecha = DateTime(anio, mes, dia);
  if (fecha.year != anio || fecha.month != mes || fecha.day != dia) return null;
  return fecha;
}

/// A date as the forms type it: `dd/mm/aaaa`.
String formatearFecha(DateTime fecha) {
  String dos(int n) => n.toString().padLeft(2, '0');
  return '${dos(fecha.day)}/${dos(fecha.month)}/${fecha.year}';
}

/// A date as the API wants it in a request body: `yyyy-MM-dd`.
String fechaIso(DateTime fecha) {
  String dos(int n) => n.toString().padLeft(2, '0');
  return '${fecha.year}-${dos(fecha.month)}-${dos(fecha.day)}';
}

const _diasSemana = <String>[
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
];

const _meses = <String>[
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

/// A day as a heading: `Viernes, 7 de noviembre`.
String fechaLarga(DateTime fecha) =>
    '${_diasSemana[fecha.weekday - 1]}, ${fecha.day} de '
    '${_meses[fecha.month - 1]}';

/// The month alone, capitalised: `Noviembre`.
String mesLargo(DateTime fecha) {
  final mes = _meses[fecha.month - 1];
  return '${mes[0].toUpperCase()}${mes.substring(1)}';
}

/// The month with its year, as the month strip labels it: `Noviembre 2026`.
String mesYAnio(DateTime fecha) => '${mesLargo(fecha)} ${fecha.year}';

/// The months as the plan screens abbreviate them: `ene`, `feb`, …
const mesesCortos = <String>[
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

/// A day with its abbreviated month, from an instant converted to the device's
/// time zone: `7 nov`.
String diaYMes(DateTime instante) {
  final local = instante.toLocal();
  return '${local.day} ${mesesCortos[local.month - 1]}';
}
