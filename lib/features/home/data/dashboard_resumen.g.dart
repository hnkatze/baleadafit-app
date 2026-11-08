// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_resumen.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DashboardResumen _$DashboardResumenFromJson(Map<String, dynamic> json) =>
    DashboardResumen(
      pacientesActivos: (json['pacientesActivos'] as num).toInt(),
      planesEnBorrador: (json['planesEnBorrador'] as num).toInt(),
      citasHoy: (json['citasHoy'] as List<dynamic>)
          .map((e) => CitaResumen.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

CitaResumen _$CitaResumenFromJson(Map<String, dynamic> json) => CitaResumen(
  id: json['id'] as String,
  fechaHora: DateTime.parse(json['fechaHora'] as String),
  duracionMin: (json['duracionMin'] as num).toInt(),
  motivo: json['motivo'] as String,
  paciente: json['paciente'] == null
      ? null
      : PacienteBreve.fromJson(json['paciente'] as Map<String, dynamic>),
);

PacienteBreve _$PacienteBreveFromJson(Map<String, dynamic> json) =>
    PacienteBreve(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      apellido: json['apellido'] as String,
    );
