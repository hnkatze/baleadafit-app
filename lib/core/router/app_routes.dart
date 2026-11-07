/// Locations of the app. Every route name lives here so no screen writes a
/// string literal.
abstract final class AppRoutes {
  static const login = '/login';
  static const home = '/home';
  static const pacientes = '/pacientes';
  static const dietas = '/dietas';
  static const catalogo = '/catalogo';
  static const agenda = '/agenda';
  static const configuracion = '/configuracion';
  static const showcase = '/showcase';

  /// Routes of the authenticated shell, in drawer order.
  static const shellRoutes = <String>[
    home,
    pacientes,
    dietas,
    catalogo,
    agenda,
    configuracion,
  ];
}
