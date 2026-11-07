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
    this.ultimaMedicion,
    this.planActivo,
  });

  factory PacienteResumen.fromJson(Map<String, dynamic> json) =>
      _$PacienteResumenFromJson(json);

  final String id;
  final String nombre;
  final String apellido;
  final UltimaMedicion? ultimaMedicion;

  /// Raw `planActivo`: the API sends the plan or null; only its presence matters.
  final Object? planActivo;

  String get nombreCompleto => '$nombre $apellido'.trim();

  bool get tienePlanActivo => planActivo != null;
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
