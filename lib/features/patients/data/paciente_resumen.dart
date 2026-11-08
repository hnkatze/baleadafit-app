import 'package:json_annotation/json_annotation.dart';

part 'paciente_resumen.g.dart';

/// The part of a patient that a list shows.
///
/// `GET /pacientes` already nests the last measurement and the active plan, so
/// a list needs no extra call per row.
@JsonSerializable(createToJson: false)
class PacienteResumen {
  const PacienteResumen({
    required this.id,
    required this.nombre,
    required this.apellido,
    this.fechaNacimiento,
    this.meta,
    this.activo = true,
    this.ultimaMedicion,
    this.planActivo,
  });

  factory PacienteResumen.fromJson(Map<String, dynamic> json) =>
      _$PacienteResumenFromJson(json);

  final String id;
  final String nombre;
  final String apellido;

  /// Birth date: the list derives the age from it.
  final DateTime? fechaNacimiento;

  /// `BAJAR`, `MANTENER` or `SUBIR`. The label itself is copy, so the screen
  /// maps it instead of the model.
  final String? meta;

  /// Logical deletion: `DELETE /pacientes/{id}` only flips this to false, so the
  /// list shows those patients under "Dados de baja" instead of dropping them.
  final bool activo;

  final UltimaMedicion? ultimaMedicion;

  /// Raw `planActivo`: the API sends the plan or null; only its presence matters.
  final Object? planActivo;

  String get nombreCompleto => '$nombre $apellido'.trim();

  bool get tienePlanActivo => planActivo != null;

  /// Whole years between [fechaNacimiento] and [hoy], or null when the API did
  /// not send a birth date: the row then omits the age instead of a gap.
  int? edad([DateTime? hoy]) {
    final nacimiento = fechaNacimiento;
    if (nacimiento == null) return null;
    final referencia = hoy ?? DateTime.now();
    var years = referencia.year - nacimiento.year;
    final cumplio =
        referencia.month > nacimiento.month ||
        (referencia.month == nacimiento.month &&
            referencia.day >= nacimiento.day);
    if (!cumplio) years -= 1;
    return years.isNegative ? null : years;
  }

  /// The two letters of the avatar, e.g. `PD`.
  String get iniciales {
    final first = _firstLetter(nombre);
    final last = _firstLetter(apellido);
    final initials = [?first, ?last];
    return initials.isEmpty ? '?' : initials.join().toUpperCase();
  }
}

String? _firstLetter(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? null : trimmed.substring(0, 1);
}

@JsonSerializable(createToJson: false)
class UltimaMedicion {
  const UltimaMedicion({required this.fecha, this.pesoKg, this.pctGrasa});

  factory UltimaMedicion.fromJson(Map<String, dynamic> json) =>
      _$UltimaMedicionFromJson(json);

  final DateTime fecha;

  /// `num` because the API sends whole kilos without decimals.
  final num? pesoKg;
  final num? pctGrasa;

  /// One readable line for the list, skipping what the record does not have.
  String? get resumen {
    final parts = [
      if (pesoKg != null) '${pesoKg!.toStringAsFixed(1)} kg',
      if (pctGrasa != null) '${pctGrasa!.toStringAsFixed(1)}% grasa',
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }
}
