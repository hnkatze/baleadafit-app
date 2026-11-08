/// One row of `GET /condiciones` or `GET /restricciones`.
///
/// The wizard sends the [codigo], never the name: the patient record stores
/// catalogue codes. Only the conditions carry a [descripcion].
class CatalogoItem {
  const CatalogoItem({
    required this.codigo,
    required this.nombre,
    this.descripcion,
  });

  /// Hand-written instead of generated: three fields do not justify another
  /// `build_runner` output, and a missing key throws the `TypeError` that
  /// `ApiClient` reports as an unexpected body.
  factory CatalogoItem.fromJson(Map<String, dynamic> json) => CatalogoItem(
    codigo: json['codigo']! as String,
    nombre: json['nombre']! as String,
    descripcion: json['descripcion'] as String?,
  );

  final String codigo;
  final String nombre;
  final String? descripcion;
}
