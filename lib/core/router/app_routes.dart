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

  /// Path segment under [pacientes] that names one patient file.
  static const pacienteIdParam = 'id';

  /// Path segment under [pacientes] that opens the new-patient wizard. It is
  /// declared before the `:id` route so it is not read as a patient id.
  static const nuevoPacienteSegment = 'nuevo';

  /// Location of the new-patient wizard.
  static const nuevoPaciente = '$pacientes/$nuevoPacienteSegment';

  /// Location of the file of one patient.
  static String paciente(String id) => '$pacientes/${Uri.encodeComponent(id)}';

  /// Path segment under a patient file that opens the measurement form.
  static const medicionSegment = 'medicion';

  /// Location of the measurement form of one patient.
  static String nuevaMedicion(String id) => '${paciente(id)}/$medicionSegment';

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
