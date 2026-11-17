import '../format/fechas.dart';

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

  /// Path segment under a patient file that opens the edit form.
  static const editarSegment = 'editar';

  /// Location of the edit form of one patient.
  static String editarPaciente(String id) => '${paciente(id)}/$editarSegment';

  /// Path segment under a patient file that holds the plans of that patient.
  /// A plan belongs to a patient, so it has no top-level destination.
  static const planesSegment = 'planes';

  /// Location of the plans of one patient (the list lands in a later task).
  static String planesDe(String pacienteId) =>
      '${paciente(pacienteId)}/$planesSegment';

  /// Path segment under the plans of a patient that opens the generator. It is
  /// declared before the `:planId` route so it is not read as a plan id.
  static const generarPlanSegment = 'generar';

  /// Location of the plan generator of one patient.
  static String generarPlan(String pacienteId) =>
      '${planesDe(pacienteId)}/$generarPlanSegment';

  /// Path parameter that names one plan under the plans of a patient.
  static const planIdParam = 'planId';

  /// Location of the weekly detail of one plan of one patient.
  static String plan(String pacienteId, String planId) =>
      '${planesDe(pacienteId)}/${Uri.encodeComponent(planId)}';

  /// Path segment under [agenda] that opens the new-appointment form.
  static const nuevaCitaSegment = 'nueva';

  /// Location of the new-appointment form, opened on [dia] when the agenda was
  /// showing a day other than today.
  static String nuevaCita({DateTime? dia}) => dia == null
      ? '$agenda/$nuevaCitaSegment'
      : '$agenda/$nuevaCitaSegment?dia=${fechaIso(dia)}';

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
