// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paciente_resumen.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PacienteResumen _$PacienteResumenFromJson(Map<String, dynamic> json) =>
    PacienteResumen(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      apellido: json['apellido'] as String,
      fechaNacimiento: json['fechaNacimiento'] == null
          ? null
          : DateTime.parse(json['fechaNacimiento'] as String),
      meta: json['meta'] as String?,
      activo: json['activo'] as bool? ?? true,
      ultimaMedicion: json['ultimaMedicion'] == null
          ? null
          : UltimaMedicion.fromJson(
              json['ultimaMedicion'] as Map<String, dynamic>,
            ),
      planActivo: json['planActivo'],
    );

UltimaMedicion _$UltimaMedicionFromJson(Map<String, dynamic> json) =>
    UltimaMedicion(
      fecha: DateTime.parse(json['fecha'] as String),
      pesoKg: json['pesoKg'] as num?,
      pctGrasa: json['pctGrasa'] as num?,
    );
