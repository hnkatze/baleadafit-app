/// What `GET /pacientes/{id}/ficha` answers.
///
/// The OpenAPI types every block in this payload as `object` without a schema
/// (see `odd/designs/pacientes-context.md` §3), so this model coerces each leaf
/// defensively instead of trusting generated casts: a block that is missing or
/// carries an unexpected type reads as null and the ficha simply does not draw
/// it. No field here is invented — the shapes come from payloads captured
/// against the real API.
///
/// Only the blocks the ficha draws are modelled. `situacion` and `habitos`
/// arrive in the payload but no artboard shows them yet, so they are ignored
/// until a screen needs them.
class PacienteFicha {
  const PacienteFicha({
    required this.paciente,
    required this.cabecera,
    required this.progreso,
    required this.adherencia,
    required this.requerimiento,
    required this.alertas,
    required this.evolucion,
    required this.consultas,
    required this.planes,
  });

  factory PacienteFicha.fromJson(Map<String, dynamic> json) {
    final requerimiento = _map(json['requerimiento']);
    return PacienteFicha(
      paciente: PacienteDetalle.fromJson(_map(json['paciente'])),
      cabecera: FichaCabecera.fromJson(_map(json['cabecera'])),
      progreso: FichaProgreso.fromJson(_map(json['progreso'])),
      adherencia: AdherenciaFicha.fromJson(_map(json['adherencia30d'])),
      requerimiento: requerimiento == null
          ? null
          : RequerimientoFicha.fromJson(requerimiento),
      alertas: _list(json['alertas'], AlertaFicha.fromJson),
      evolucion: _list(json['evolucion'], MedicionFicha.fromJson),
      consultas: ConsultasFicha.fromJson(_map(json['consultas'])),
      planes: _list(json['planes'], PlanFicha.fromJson),
    );
  }

  final PacienteDetalle paciente;
  final FichaCabecera cabecera;
  final FichaProgreso progreso;
  final AdherenciaFicha adherencia;

  /// Null when the API could not calculate it (no measurement, or no
  /// requirement yet), which is a real state and not an error.
  final RequerimientoFicha? requerimiento;

  final List<AlertaFicha> alertas;

  /// Measurements, oldest first, as the API sends them.
  final List<MedicionFicha> evolucion;

  final ConsultasFicha consultas;
  final List<PlanFicha> planes;

  bool get tieneMediciones => evolucion.isNotEmpty;

  /// The plan the ficha shows first: the active one, or null when there is none.
  PlanFicha? get planActivo {
    for (final plan in planes) {
      if (plan.estado == 'ACTIVO') return plan;
    }
    return null;
  }
}

/// The patient record as the ficha receives it.
class PacienteDetalle {
  const PacienteDetalle({
    this.id,
    this.nombre,
    this.apellido,
    this.sexo,
    this.fechaNacimiento,
    this.correo,
    this.telefono,
    this.meta,
    this.nivelActividad,
    this.estadoFisiologico,
    this.pesoObjetivoKg,
    this.fechaObjetivo,
    this.motivoConsulta,
    this.activo,
    this.firebaseUid,
  });

  factory PacienteDetalle.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PacienteDetalle();
    return PacienteDetalle(
      id: _string(json['id']),
      nombre: _string(json['nombre']),
      apellido: _string(json['apellido']),
      sexo: _string(json['sexo']),
      fechaNacimiento: _date(json['fechaNacimiento']),
      correo: _string(json['correo']),
      telefono: _string(json['telefono']),
      meta: _string(json['meta']),
      nivelActividad: _string(json['nivelActividad']),
      estadoFisiologico: _string(json['estadoFisiologico']),
      pesoObjetivoKg: _number(json['pesoObjetivoKg']),
      fechaObjetivo: _date(json['fechaObjetivo']),
      motivoConsulta: _string(json['motivoConsulta']),
      activo: _boolean(json['activo']),
      firebaseUid: _string(json['firebaseUid']),
    );
  }

  final String? id;
  final String? nombre;
  final String? apellido;

  /// `M` or `F`.
  final String? sexo;
  final DateTime? fechaNacimiento;
  final String? correo;
  final String? telefono;

  /// `BAJAR`, `MANTENER` or `SUBIR`.
  final String? meta;
  final String? nivelActividad;

  /// `NINGUNO`, `EMBARAZO` or `LACTANCIA`.
  final String? estadoFisiologico;
  final num? pesoObjetivoKg;
  final DateTime? fechaObjetivo;
  final String? motivoConsulta;
  final bool? activo;

  /// Null until the patient signs in with the mail of this file: the API links
  /// it at that moment. The ficha reads this as "sin entrar a la app".
  final String? firebaseUid;

  String get nombreCompleto => [nombre, apellido].nonNulls.join(' ').trim();

  bool get entroALaApp => firebaseUid != null;

  /// The two letters of the avatar, e.g. `PD`.
  String get iniciales {
    final first = _firstLetter(nombre);
    final last = _firstLetter(apellido);
    final initials = [?first, ?last];
    return initials.isEmpty ? '?' : initials.join().toUpperCase();
  }
}

String? _firstLetter(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? null : trimmed.substring(0, 1);
}

/// The calculated header: BMI, composition and age.
class FichaCabecera {
  const FichaCabecera({
    this.edad,
    this.imc,
    this.clasificacionImc,
    this.pctGrasa,
    this.masaMagraKg,
    this.masaGrasaKg,
    this.masaMuscularKg,
    this.grasaVisceral,
    this.objetivo,
    this.composicionFecha,
    this.tallaCm,
  });

  factory FichaCabecera.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const FichaCabecera();
    final ultima = _map(json['ultimaMedicion']);
    return FichaCabecera(
      edad: _integer(json['edad']),
      imc: _number(json['imc']),
      clasificacionImc: _string(json['clasificacionImc']),
      pctGrasa: _number(json['pctGrasa']),
      masaMagraKg: _number(json['masaMagraKg']),
      masaGrasaKg: _number(json['masaGrasaKg']),
      masaMuscularKg: _number(json['masaMuscularKg']),
      grasaVisceral: _number(json['grasaVisceral']),
      objetivo: _string(json['objetivo']),
      composicionFecha: _date(json['composicionFecha']),
      tallaCm: ultima == null ? null : _number(ultima['tallaCm']),
    );
  }

  final int? edad;
  final num? imc;

  /// `NORMAL` was the only value observed; new ones must not break the screen.
  final String? clasificacionImc;
  final num? pctGrasa;
  final num? masaMagraKg;
  final num? masaGrasaKg;
  final num? masaMuscularKg;
  final num? grasaVisceral;

  /// The patient goal as the header repeats it, e.g. `BAJAR`.
  final String? objetivo;
  final DateTime? composicionFecha;

  /// Height of the last measurement: it is the only place the ficha has it.
  final num? tallaCm;

  bool get tieneComposicion => imc != null || pctGrasa != null;
}

/// Weight course against the starting point.
class FichaProgreso {
  const FichaProgreso({
    this.pesoInicial,
    this.pesoActual,
    this.deltaKg,
    this.ritmoKgSemana,
    this.proyeccionKg,
  });

  factory FichaProgreso.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const FichaProgreso();
    return FichaProgreso(
      pesoInicial: _number(json['pesoInicial']),
      pesoActual: _number(json['pesoActual']),
      deltaKg: _number(json['deltaKg']),
      ritmoKgSemana: _number(json['ritmoKgSemana']),
      proyeccionKg: _number(json['proyeccionKg']),
    );
  }

  final num? pesoInicial;
  final num? pesoActual;
  final num? deltaKg;

  /// Only with two measurements: with one there is no course to project.
  final num? ritmoKgSemana;
  final num? proyeccionKg;

  bool get hayTendencia => ritmoKgSemana != null || proyeccionKg != null;
}

/// The calorie requirement the API already calculated.
class RequerimientoFicha {
  const RequerimientoFicha({
    this.edad,
    this.tmb,
    this.factorActividad,
    this.gastoTotal,
    this.ajusteMeta,
    this.kcalObjetivo,
    this.proteinaG,
    this.carbohidratoG,
    this.grasaG,
  });

  factory RequerimientoFicha.fromJson(Map<String, dynamic> json) {
    return RequerimientoFicha(
      edad: _integer(json['edad']),
      tmb: _number(json['tmb']),
      factorActividad: _number(json['factorActividad']),
      gastoTotal: _number(json['gastoTotal']),
      ajusteMeta: _number(json['ajusteMeta']),
      kcalObjetivo: _number(json['kcalObjetivo']),
      proteinaG: _number(json['proteinaG']),
      carbohidratoG: _number(json['carbohidratoG']),
      grasaG: _number(json['grasaG']),
    );
  }

  final int? edad;

  /// Basal metabolism, in kcal.
  final num? tmb;
  final num? factorActividad;

  /// Basal metabolism times the activity factor, in kcal.
  final num? gastoTotal;

  /// The goal adjustment, usually negative when the goal is to lose weight.
  final num? ajusteMeta;
  final num? kcalObjetivo;
  final num? proteinaG;
  final num? carbohidratoG;
  final num? grasaG;
}

/// Adherence over the last 30 days.
class AdherenciaFicha {
  const AdherenciaFicha({this.porcentaje, this.cumplidos, this.total});

  factory AdherenciaFicha.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AdherenciaFicha();
    return AdherenciaFicha(
      porcentaje: _number(json['porcentaje']),
      cumplidos: _integer(json['cumplidos']),
      total: _integer(json['total']),
    );
  }

  /// Null when there is nothing to divide: "sin registros", never 0%.
  final num? porcentaje;
  final int? cumplidos;
  final int? total;

  bool get sinDatos => (total ?? 0) == 0;

  int get pendientes => ((total ?? 0) - (cumplidos ?? 0)).clamp(0, 1 << 30);
}

/// A system-calculated warning, e.g. a patient without an active plan.
class AlertaFicha {
  const AlertaFicha({this.tipo, this.severidad, this.detalle});

  factory AlertaFicha.fromJson(Map<String, dynamic> json) {
    return AlertaFicha(
      tipo: _string(json['tipo']),
      severidad: _string(json['severidad']),
      detalle: _string(json['detalle']),
    );
  }

  /// Only `SIN_PLAN_ACTIVO` was observed: new types must not break the screen.
  final String? tipo;
  final String? severidad;
  final String? detalle;
}

/// One measurement of the evolution list.
class MedicionFicha {
  const MedicionFicha({
    this.id,
    this.fecha,
    this.pesoKg,
    this.tallaCm,
    this.pctGrasa,
    this.imc,
    this.masaMuscularKg,
    this.masaGrasaKg,
    this.grasaVisceral,
  });

  factory MedicionFicha.fromJson(Map<String, dynamic> json) {
    return MedicionFicha(
      id: _string(json['id']),
      fecha: _date(json['fecha']),
      pesoKg: _number(json['pesoKg']),
      tallaCm: _number(json['tallaCm']),
      pctGrasa: _number(json['pctGrasa']),
      imc: _number(json['imc']),
      masaMuscularKg: _number(json['masaMuscularKg']),
      masaGrasaKg: _number(json['masaGrasaKg']),
      grasaVisceral: _number(json['grasaVisceral']),
    );
  }

  final String? id;
  final DateTime? fecha;
  final num? pesoKg;
  final num? tallaCm;
  final num? pctGrasa;
  final num? imc;
  final num? masaMuscularKg;
  final num? masaGrasaKg;
  final num? grasaVisceral;
}

/// Appointments of the file: the upcoming ones and the past ones with their SOAP.
class ConsultasFicha {
  const ConsultasFicha({this.proximas = const [], this.pasadas = const []});

  factory ConsultasFicha.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ConsultasFicha();
    return ConsultasFicha(
      proximas: _list(json['proximas'], ConsultaFicha.fromJson),
      pasadas: _list(json['pasadas'], ConsultaFicha.fromJson),
    );
  }

  final List<ConsultaFicha> proximas;
  final List<ConsultaFicha> pasadas;
}

/// An appointment as the file receives it. Deliberately not the home model: the
/// ficha asks for the whole record and the home for the day, and neither should
/// drag the other's fields along.
class ConsultaFicha {
  const ConsultaFicha({
    this.id,
    this.fechaHora,
    this.duracionMin,
    this.motivo,
    this.estado,
  });

  factory ConsultaFicha.fromJson(Map<String, dynamic> json) {
    return ConsultaFicha(
      id: _string(json['id']),
      fechaHora: _date(json['fechaHora']),
      duracionMin: _integer(json['duracionMin']),
      motivo: _string(json['motivo']),
      estado: _string(json['estado']),
    );
  }

  final String? id;
  final DateTime? fechaHora;
  final int? duracionMin;
  final String? motivo;
  final String? estado;
}

/// One plan of the file.
class PlanFicha {
  const PlanFicha({
    this.id,
    this.nombre,
    this.estado,
    this.origen,
    this.aprobadoEn,
    this.kcalObjetivo,
  });

  factory PlanFicha.fromJson(Map<String, dynamic> json) {
    return PlanFicha(
      id: _string(json['id']),
      nombre: _string(json['nombre']),
      estado: _string(json['estado']),
      origen: _string(json['origen']),
      aprobadoEn: _date(json['aprobadoEn']),
      kcalObjetivo: _number(json['kcalObjetivo']),
    );
  }

  final String? id;
  final String? nombre;

  /// `BORRADOR` or `ACTIVO`.
  final String? estado;

  /// `REGLAS` today: the AI recommender is disabled in this environment.
  final String? origen;
  final DateTime? aprobadoEn;
  final num? kcalObjetivo;
}

Map<String, dynamic>? _map(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : null;

String? _string(Object? value) =>
    value is String && value.trim().isNotEmpty ? value.trim() : null;

num? _number(Object? value) {
  if (value is num) return value;
  if (value is String) return num.tryParse(value.trim());
  return null;
}

int? _integer(Object? value) {
  final number = _number(value);
  return number?.toInt();
}

bool? _boolean(Object? value) => value is bool ? value : null;

DateTime? _date(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;

/// Reads a list of objects, skipping entries that are not objects: a malformed
/// row must not take the whole screen down.
List<T> _list<T>(Object? value, T Function(Map<String, dynamic>) fromJson) {
  if (value is! List) return <T>[];
  final items = <T>[];
  for (final item in value) {
    final map = _map(item);
    if (map != null) items.add(fromJson(map));
  }
  return items;
}
