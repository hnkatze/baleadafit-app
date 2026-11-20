/// One active food of the catalogue (`AlimentoEntity`), as the meal-time editor
/// needs it: the id the `PUT` carries and what the row says about the portion.
///
/// Only the fields the picker and the row draw are read. `kcal` is **per
/// portion**, like in a plan, so nothing here is ever multiplied by the number
/// of portions.
class AlimentoCatalogo {
  const AlimentoCatalogo({
    required this.id,
    required this.nombre,
    this.porcionDescripcion = '',
    this.porcionGramos,
    this.kcal,
  });

  factory AlimentoCatalogo.fromJson(Map<String, dynamic> json) =>
      AlimentoCatalogo(
        id: json['id'] is String ? json['id'] as String : '',
        nombre: json['nombre'] is String ? json['nombre'] as String : '',
        porcionDescripcion: json['porcionDescripcion'] is String
            ? json['porcionDescripcion'] as String
            : '',
        porcionGramos: (json['porcionGramos'] as num?)?.toDouble(),
        kcal: (json['kcal'] as num?)?.toDouble(),
      );

  final String id;
  final String nombre;

  /// The portion in words, `1 taza`. May be empty: the row then draws only the
  /// kcal, and never a line that starts with a separator.
  final String porcionDescripcion;
  final double? porcionGramos;

  /// kcal **per portion**.
  final double? kcal;
}
