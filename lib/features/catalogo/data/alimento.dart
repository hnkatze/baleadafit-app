/// `AlimentoEntity`, the 21 fields the list, the detail, the `POST` and the
/// `PATCH` return. Every nutrient is **per portion**.
///
/// The contract is indexed, not captured from real payloads, so reading is
/// defensive: a nutrient that is absent or of the wrong type is `null`, never
/// `0`. A real `0` stays `0`. That matters most for [indiceGlucemico], which is
/// null in foods without carbohydrates and must read as "sin dato".
class Alimento {
  const Alimento({
    required this.id,
    required this.nombre,
    this.categoria,
    this.porcionDescripcion,
    this.porcionGramos,
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
    this.esTipicoHn = false,
    this.tiposComida = const [],
    this.contiene = const [],
    this.fuente,
    this.activo = true,
  });

  /// A missing or mistyped `id` or `nombre` throws the `TypeError` that
  /// `ApiClient` reports as an unexpected body: without them there is no row to
  /// draw. Use [tryFromJson] to skip such an entry instead.
  factory Alimento.fromJson(Map<String, dynamic> json) => Alimento(
    id: json['id']! as String,
    nombre: json['nombre']! as String,
    categoria: _texto(json['categoria']),
    porcionDescripcion: _texto(json['porcionDescripcion']),
    porcionGramos: _numero(json['porcionGramos']),
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
    esTipicoHn: json['esTipicoHn'] == true,
    tiposComida: _etiquetas(json['tiposComida']),
    contiene: _etiquetas(json['contiene']),
    fuente: _texto(json['fuente']),
    // Active unless the payload says otherwise: the catalogue lists only the
    // active ones.
    activo: json['activo'] != false,
  );

  /// [fromJson] that answers `null` instead of throwing.
  static Alimento? tryFromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    try {
      return Alimento.fromJson(json);
    } on TypeError {
      return null;
    }
  }

  final String id;
  final String nombre;

  /// Raw enum code (`PLATO_TIPICO`, `PROTEINA`…); the label is copy of the app.
  final String? categoria;
  final String? porcionDescripcion;
  final double? porcionGramos;

  final double? kcal;
  final double? proteinaG;
  final double? carbohidratoG;
  final double? grasaG;
  final double? fibraG;

  /// Documented as an estimate ("verificar con INCAP").
  final double? sodioMg;
  final double? potasioMg;
  final double? fosforoMg;
  final double? azucaresG;
  final double? grasasSatG;

  /// Null in foods without carbohydrates: "sin dato", never `0`.
  final double? indiceGlucemico;

  final bool esTipicoHn;

  /// Raw `TipoComida` codes the food is meant for.
  final List<String> tiposComida;

  /// Restriction codes, matched against `GET /restricciones`.
  final List<String> contiene;

  /// Free text (INCAP, USDA, the product label…).
  final String? fuente;
  final bool activo;
}

double? _numero(Object? valor) => valor is num ? valor.toDouble() : null;

String? _texto(Object? valor) => valor is String ? valor : null;

/// Keeps only the strings of a list; anything else reads as empty.
List<String> _etiquetas(Object? valor) => valor is List
    ? valor.whereType<String>().toList(growable: false)
    : const [];
