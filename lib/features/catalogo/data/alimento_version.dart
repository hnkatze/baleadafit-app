/// `AlimentoVersionEntity`: the nutrient values a food had over a period.
///
/// Flat: nutrients live at the same level as [version] and [tabla]. A change of
/// nutrients creates a new version, and the history is the proof of which
/// values a plan was built with. Reading is as defensive as `Alimento`.
class AlimentoVersion {
  const AlimentoVersion({
    required this.id,
    required this.version,
    this.tabla,
    this.fuente,
    this.porcionDescripcion,
    this.porcionGramos,
    this.vigenteDesde,
    this.vigenteHasta,
    this.kcal,
    this.proteinaG,
    this.carbohidratoG,
    this.grasaG,
    this.fibraG,
    this.sodioMg,
    this.potasioMg,
    this.fosforoMg,
    this.azucaresG,
    this.grasasSatG,
    this.indiceGlucemico,
  });

  /// A missing `id` or `version` throws the `TypeError` that `ApiClient`
  /// reports as an unexpected body. The entity carries no `alimentoId`: the
  /// food is named by the route (`/alimentos/{id}/versiones`).
  factory AlimentoVersion.fromJson(Map<String, dynamic> json) =>
      AlimentoVersion(
        id: json['id']! as String,
        version: (json['version']! as num).toInt(),
        tabla: json['tabla'] is String ? json['tabla'] as String : null,
        fuente: json['fuente'] is String ? json['fuente'] as String : null,
        porcionDescripcion: json['porcionDescripcion'] is String
            ? json['porcionDescripcion'] as String
            : null,
        porcionGramos: _numero(json['porcionGramos']),
        vigenteDesde: _instante(json['vigenteDesde']),
        vigenteHasta: _instante(json['vigenteHasta']),
        kcal: _numero(json['kcal']),
        proteinaG: _numero(json['proteinaG']),
        carbohidratoG: _numero(json['carbohidratoG']),
        grasaG: _numero(json['grasaG']),
        fibraG: _numero(json['fibraG']),
        sodioMg: _numero(json['sodioMg']),
        potasioMg: _numero(json['potasioMg']),
        fosforoMg: _numero(json['fosforoMg']),
        azucaresG: _numero(json['azucaresG']),
        grasasSatG: _numero(json['grasasSatG']),
        indiceGlucemico: _numero(json['indiceGlucemico']),
      );

  final String id;

  /// Consecutive number, starting at 1.
  final int version;
  final String? tabla;

  /// Table revision and portion of that version: a food can change them too,
  /// and the history keeps what they were when a plan was built.
  final String? fuente;
  final String? porcionDescripcion;
  final double? porcionGramos;

  final DateTime? vigenteDesde;

  /// Null in the current version.
  final DateTime? vigenteHasta;

  final double? kcal;
  final double? proteinaG;
  final double? carbohidratoG;
  final double? grasaG;
  final double? fibraG;
  final double? sodioMg;
  final double? potasioMg;
  final double? fosforoMg;
  final double? azucaresG;
  final double? grasasSatG;
  final double? indiceGlucemico;

  /// A null `vigenteHasta` means this is the current version.
  bool get vigente => vigenteHasta == null;
}

double? _numero(Object? valor) => valor is num ? valor.toDouble() : null;

DateTime? _instante(Object? valor) =>
    valor is String ? DateTime.tryParse(valor) : null;
