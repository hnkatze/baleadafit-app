/// `RestriccionEntity {id, codigo, nombre, descripcion}`: the vocabulary of
/// `Alimento.contiene` and of the `excluir` query of the search.
///
/// The screen draws [nombre]; what travels in `excluir` and what is compared
/// with `contiene` is [codigo]. Independent from the patients' `CatalogoItem`.
class Restriccion {
  const Restriccion({
    required this.id,
    required this.codigo,
    required this.nombre,
    this.descripcion,
  });

  /// A missing `id`, `codigo` or `nombre` throws the `TypeError` that
  /// `ApiClient` reports as an unexpected body.
  factory Restriccion.fromJson(Map<String, dynamic> json) => Restriccion(
    id: json['id']! as String,
    codigo: json['codigo']! as String,
    nombre: json['nombre']! as String,
    descripcion: json['descripcion'] is String
        ? json['descripcion'] as String
        : null,
  );

  final String id;
  final String codigo;
  final String nombre;
  final String? descripcion;
}
