/// One medication of the patient's chart.
///
/// The API has no `GET` of medications: the list arrives inside
/// `situacion.medicacion` of the ficha, and it is written through
/// `POST /pacientes/{id}/medicamentos`, `PATCH /medicamentos/{id}` and the
/// logical `DELETE`, which answers 200 with the entity and `activo: false`.
class Medicamento {
  const Medicamento({
    required this.id,
    required this.nombre,
    this.pacienteId,
    this.dosis,
    this.frecuencia,
    this.activo = true,
    this.creadoEn,
    this.actualizadoEn,
  });

  /// Reads one entry of `situacion.medicacion`. Returns null when it carries no
  /// id or no name: such an entry cannot be opened nor edited, so the list skips
  /// it instead of drawing a row that goes nowhere.
  static Medicamento? tryFromJson(Map<String, dynamic> json) {
    final id = _texto(json['id']);
    final nombre = _texto(json['nombre']);
    if (id == null || nombre == null) return null;

    return Medicamento(
      id: id,
      nombre: nombre,
      pacienteId: _texto(json['pacienteId']),
      dosis: _texto(json['dosis']),
      frecuencia: _texto(json['frecuencia']),
      activo: json['activo'] != false,
      creadoEn: _fecha(json['creadoEn']),
      actualizadoEn: _fecha(json['actualizadoEn']),
    );
  }

  /// Reads an entity the API just answered. The id and the name are there by
  /// contract, so a missing one is a malformed answer, not a skippable row.
  factory Medicamento.fromJson(Map<String, dynamic> json) {
    final medicamento = tryFromJson(json);
    if (medicamento == null) {
      throw const FormatException('medicamento sin id o sin nombre');
    }
    return medicamento;
  }

  final String id;
  final String nombre;
  final String? pacienteId;

  /// Free text ("500 mg"): the contract does not split amount and unit, so the
  /// app never parses nor compares it.
  final String? dosis;

  /// Free text ("Cada 12 horas con comida").
  final String? frecuencia;

  /// Logical deletion: the medication leaves the active chart and the clinical
  /// history keeps it. Nothing in the contract reactivates it.
  final bool activo;

  final DateTime? creadoEn;
  final DateTime? actualizadoEn;

  /// `dosis · frecuencia` built from what exists, or null when neither does: a
  /// row then draws no second line at all — never "·", "null" or a dash.
  String? get composicion {
    final partes = [dosis, frecuencia].whereType<String>().toList();
    return partes.isEmpty ? null : partes.join(' · ');
  }
}

/// Another active medication with the same normalized name, reported by the
/// registration (`duplicadoDe`). The registration is saved anyway.
class DuplicadoMedicamento {
  const DuplicadoMedicamento({required this.id, required this.nombre});

  /// Null when the answer carries no usable `id` and `nombre`: the warning
  /// needs the name, so a half-formed entry is treated as no duplicate.
  static DuplicadoMedicamento? tryFromJson(Object? json) {
    if (json is! Map) return null;
    final id = _texto(json['id']);
    final nombre = _texto(json['nombre']);
    if (id == null || nombre == null) return null;
    return DuplicadoMedicamento(id: id, nombre: nombre);
  }

  final String id;
  final String nombre;
}

/// `MedicamentoCreadoEntity`: the created medication plus `duplicadoDe`.
class MedicamentoCreado {
  const MedicamentoCreado({required this.medicamento, this.duplicadoDe});

  factory MedicamentoCreado.fromJson(Map<String, dynamic> json) =>
      MedicamentoCreado(
        medicamento: Medicamento.fromJson(json),
        duplicadoDe: DuplicadoMedicamento.tryFromJson(json['duplicadoDe']),
      );

  final Medicamento medicamento;
  final DuplicadoMedicamento? duplicadoDe;
}

String? _texto(Object? value) =>
    value is String && value.trim().isNotEmpty ? value.trim() : null;

DateTime? _fecha(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
