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

  /// Path segment under one plan that names its meal times.
  static const tiemposSegment = 'tiempos';

  /// Path parameter of the day of a meal time (`LUNES`…`DOMINGO`, no accent)
  /// and of the meal time itself (`DESAYUNO`…`CENA`): the route carries the
  /// codes the contract uses and the router maps them back to its enums.
  static const diaParam = 'dia';
  static const tipoParam = 'tipo';

  /// Location of the editor of one meal time of one day of one plan.
  static String editarTiempo(
    String pacienteId,
    String planId,
    String dia,
    String tipo,
  ) =>
      '${plan(pacienteId, planId)}/$tiemposSegment/'
      '${Uri.encodeComponent(dia)}/${Uri.encodeComponent(tipo)}';

  /// Path segment under a patient file that holds the medication of that
  /// patient. Like a plan, a medication belongs to a patient.
  static const medicacionSegment = 'medicacion';

  /// Location of the medication list of one patient.
  static String medicacion(String pacienteId) =>
      '${paciente(pacienteId)}/$medicacionSegment';

  /// Path segment under the medication list that opens the registration form.
  /// It is declared before the `:medicamentoId` route so it is not read as an
  /// id.
  static const nuevaMedicacionSegment = 'nueva';

  /// Location of the registration form of one patient's medication.
  static String nuevaMedicacion(String pacienteId) =>
      '${medicacion(pacienteId)}/$nuevaMedicacionSegment';

  /// Path parameter that names one medication under the medication list.
  static const medicamentoIdParam = 'medicamentoId';

  /// Location of the editor of one medication of one patient.
  static String medicamento(String pacienteId, String medicamentoId) =>
      '${medicacion(pacienteId)}/${Uri.encodeComponent(medicamentoId)}';

  /// Path segment under [agenda] that opens the new-appointment form.
  static const nuevaCitaSegment = 'nueva';

  /// Location of the new-appointment form, opened on [dia] when the agenda was
  /// showing a day other than today.
  static String nuevaCita({DateTime? dia}) => dia == null
      ? '$agenda/$nuevaCitaSegment'
      : '$agenda/$nuevaCitaSegment?dia=${fechaIso(dia)}';

  /// Path segment under [catalogo] that opens the new-food form. It is
  /// declared before the `:alimentoId` route so it is not read as a food id.
  static const nuevoAlimentoSegment = 'nueva';

  /// Location of the new-food form.
  static const nuevoAlimento = '$catalogo/$nuevoAlimentoSegment';

  /// Path parameter that names one food under [catalogo].
  static const alimentoIdParam = 'alimentoId';

  /// Location of the detail of one food.
  static String alimento(String id) => '$catalogo/${Uri.encodeComponent(id)}';

  /// Location of the edit form of one food.
  static const editarAlimentoSegment = editarSegment;
  static String editarAlimento(String id) =>
      '${alimento(id)}/$editarAlimentoSegment';

  /// Path segment under one food that opens its version history.
  static const historialAlimentoSegment = 'historial';

  /// Location of the version history of one food.
  static String historialAlimento(String id) =>
      '${alimento(id)}/$historialAlimentoSegment';

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
