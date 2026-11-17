/// `estado` of a plan. Only `BORRADOR` is editable; the app reads it from the
/// payload and never infers it from the content.
enum EstadoPlan {
  borrador('BORRADOR', 'Borrador'),
  activo('ACTIVO', 'Activo'),
  archivado('ARCHIVADO', 'Archivado');

  const EstadoPlan(this.codigo, this.etiqueta);

  final String codigo;
  final String etiqueta;

  /// Reads the `estado` of a payload. An unknown value falls back to
  /// [archivado], the read-only state, so a new server value can neither blank
  /// a screen nor open editing actions the contract never declared.
  static EstadoPlan desdeApi(Object? valor) => values.firstWhere(
    (estado) => estado.codigo == valor,
    orElse: () => archivado,
  );
}

/// `origen` of a plan: who proposed its content.
///
/// `IA` is **not** proof that the AI proposed it (the contract documents a
/// silent fallback), so the label is never a guarantee of method or quality.
enum OrigenPlan {
  manual('MANUAL', 'Manual'),
  reglas('REGLAS', 'Por reglas'),
  ia('IA', 'IA');

  const OrigenPlan(this.codigo, this.etiqueta);

  final String codigo;
  final String etiqueta;

  /// An unknown value falls back to [manual], the one that claims nothing
  /// about how the plan was produced.
  static OrigenPlan desdeApi(Object? valor) => values.firstWhere(
    (origen) => origen.codigo == valor,
    orElse: () => manual,
  );
}

/// `dia` of a plan: the week is identified by the day, never by a date.
///
/// The codes carry no accent (`MIERCOLES`, `SABADO`); the labels do.
enum DiaSemana {
  lunes('LUNES', 'Lunes', 'LUN'),
  martes('MARTES', 'Martes', 'MAR'),
  miercoles('MIERCOLES', 'Miércoles', 'MIE'),
  jueves('JUEVES', 'Jueves', 'JUE'),
  viernes('VIERNES', 'Viernes', 'VIE'),
  sabado('SABADO', 'Sábado', 'SAB'),
  domingo('DOMINGO', 'Domingo', 'DOM');

  const DiaSemana(this.codigo, this.etiqueta, this.abreviatura);

  final String codigo;
  final String etiqueta;
  final String abreviatura;

  /// An unknown value falls back to [lunes], the day the contract itself uses
  /// as the default for the deprecated route.
  static DiaSemana desdeApi(Object? valor) =>
      values.firstWhere((dia) => dia.codigo == valor, orElse: () => lunes);
}

/// `tipo` of a meal time, declared in the order of the day.
enum TipoComida {
  desayuno('DESAYUNO', 'Desayuno'),
  meriendaAm('MERIENDA_AM', 'Merienda · mañana'),
  almuerzo('ALMUERZO', 'Almuerzo'),
  meriendaPm('MERIENDA_PM', 'Merienda · tarde'),
  cena('CENA', 'Cena');

  const TipoComida(this.codigo, this.etiqueta);

  final String codigo;
  final String etiqueta;

  /// An unknown value falls back to [desayuno] so the row still draws.
  static TipoComida desdeApi(Object? valor) =>
      values.firstWhere((tipo) => tipo.codigo == valor, orElse: () => desayuno);
}

/// `TotalesEntity`: eleven numbers that keep their shape at every scope (a meal
/// time, a day, the week); only the scope changes.
///
/// The contract declares all eleven required, so one missing from a payload is
/// read as `0` instead of failing the whole plan.
class Totales {
  const Totales({
    this.kcal = 0,
    this.proteinaG = 0,
    this.carbohidratoG = 0,
    this.grasaG = 0,
    this.fibraG = 0,
    this.sodioMg = 0,
    this.potasioMg = 0,
    this.fosforoMg = 0,
    this.azucaresG = 0,
    this.grasasSatG = 0,
    this.cargaGlucemica = 0,
  });

  factory Totales.fromJson(Map<String, dynamic> json) => Totales(
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
    cargaGlucemica: _numero(json['cargaGlucemica']),
  );

  final double kcal;
  final double proteinaG;
  final double carbohidratoG;
  final double grasaG;
  final double fibraG;
  final double sodioMg;
  final double potasioMg;
  final double fosforoMg;
  final double azucaresG;
  final double grasasSatG;
  final double cargaGlucemica;
}

/// The food nested in a plan item, as the **live** food: its figures are **per
/// portion** and are not what the plan totals with (that is the item's
/// `alimentoVersion`).
///
/// Only the fields the contract names are read. Its macros and micronutrients
/// are declared "per portion" but their keys are not spelled out in the
/// documents the module was designed from, so they are left out.
class AlimentoPlan {
  const AlimentoPlan({
    required this.nombre,
    this.porcionDescripcion = '',
    this.porcionGramos,
    this.kcal,
    this.categoria,
    this.contiene = const [],
  });

  factory AlimentoPlan.fromJson(Map<String, dynamic> json) => AlimentoPlan(
    nombre: _texto(json['nombre']),
    porcionDescripcion: _texto(json['porcionDescripcion']),
    porcionGramos: (json['porcionGramos'] as num?)?.toDouble(),
    kcal: (json['kcal'] as num?)?.toDouble(),
    categoria: json['categoria'] is String ? json['categoria'] as String : null,
    contiene: json['contiene'] is List
        ? (json['contiene'] as List).whereType<String>().toList(growable: false)
        : const [],
  );

  final String nombre;

  /// The portion in words, `1 taza`.
  final String porcionDescripcion;
  final double? porcionGramos;

  /// kcal **per portion**. Never multiplied by `porciones` in the app.
  final double? kcal;
  final String? categoria;
  final List<String> contiene;
}

/// One food of a meal time (`PlanItemEntity`).
class PlanItem {
  const PlanItem({
    required this.id,
    required this.alimentoId,
    required this.porciones,
    this.tiempoComidaId,
    this.alimento,
    this.alimentoVersionId,
    this.tieneVersion = false,
  });

  factory PlanItem.fromJson(Map<String, dynamic> json) {
    final alimento = json['alimento'];
    final versionId = json['alimentoVersionId'];
    return PlanItem(
      id: _texto(json['id']),
      alimentoId: _texto(json['alimentoId']),
      porciones: _numero(json['porciones']),
      tiempoComidaId: json['tiempoComidaId'] is String
          ? json['tiempoComidaId'] as String
          : null,
      alimento: alimento is Map<String, dynamic>
          ? AlimentoPlan.fromJson(alimento)
          : null,
      alimentoVersionId: versionId is String ? versionId : null,
      tieneVersion: json['alimentoVersion'] is Map,
    );
  }

  final String id;
  final String alimentoId;

  /// Multiples of 0.25 (0.25 to 6).
  final double porciones;
  final String? tiempoComidaId;
  final AlimentoPlan? alimento;

  /// `null` on items older than versioning: those total with the current food,
  /// not with a frozen version.
  final String? alimentoVersionId;

  /// Whether the payload carried an `alimentoVersion`, the figures the totals
  /// really come from. Its own fields are not modelled.
  final bool tieneVersion;
}

/// One meal time of one day (`TiempoComidaEntity`).
class TiempoComida {
  const TiempoComida({
    required this.id,
    required this.planId,
    required this.dia,
    required this.tipo,
    this.orden = 0,
    this.items = const [],
    this.kcalMeta = 0,
    this.pctKcal = 0,
    this.desviacion,
    this.totales,
  });

  factory TiempoComida.fromJson(Map<String, dynamic> json) => TiempoComida(
    id: _texto(json['id']),
    planId: _texto(json['planId']),
    dia: DiaSemana.desdeApi(json['dia']),
    tipo: TipoComida.desdeApi(json['tipo']),
    orden: (json['orden'] as num?)?.toInt() ?? 0,
    items: _lista(json['items'], PlanItem.fromJson),
    kcalMeta: _numero(json['kcalMeta']),
    pctKcal: _numero(json['pctKcal']),
    desviacion: (json['desviacion'] as num?)?.toDouble(),
    totales: _totales(json['totales']),
  );

  final String id;
  final String planId;
  final DiaSemana dia;
  final TipoComida tipo;
  final int orden;
  final List<PlanItem> items;

  /// The target kcal of this meal time: a goal, not what was eaten.
  final double kcalMeta;

  /// A **fraction** 0..1 of the day's kcal (`0.25` is 25%), despite the name.
  final double pctKcal;

  /// A **fraction** with sign, `(real − meta) / meta`. `null` when the payload
  /// brings none: the contract does not say what an empty time carries.
  final double? desviacion;
  final Totales? totales;
}

/// One day of the plan (`DiaPlanEntity`). Only days with at least one meal time
/// exist, so a plan can have fewer than seven.
class DiaPlan {
  const DiaPlan({
    required this.dia,
    this.tiempos = const [],
    this.totales,
    this.desviacion,
  });

  factory DiaPlan.fromJson(Map<String, dynamic> json) => DiaPlan(
    dia: DiaSemana.desdeApi(json['dia']),
    tiempos: _lista(json['tiempos'], TiempoComida.fromJson),
    totales: _totales(json['totales']),
    desviacion: (json['desviacion'] as num?)?.toDouble(),
  );

  final DiaSemana dia;
  final List<TiempoComida> tiempos;

  /// The totals of this day.
  final Totales? totales;

  /// A **fraction** with sign of the day against the daily `kcalObjetivo`.
  final double? desviacion;
}

/// A plan as the list returns it (`PlanEntity`): no meal times, no totals.
class Plan {
  const Plan({
    required this.id,
    required this.nombre,
    required this.estado,
    required this.origen,
    this.pacienteId = '',
    this.nutricionistaId = '',
    this.kcalObjetivo = 0,
    this.proteinaG = 0,
    this.carbohidratoG = 0,
    this.grasaG = 0,
    this.justificacion,
    this.creadoEn,
    this.aprobadoEn,
  });

  factory Plan.fromJson(Map<String, dynamic> json) => Plan(
    id: _texto(json['id']),
    nombre: _texto(json['nombre']),
    estado: EstadoPlan.desdeApi(json['estado']),
    origen: OrigenPlan.desdeApi(json['origen']),
    pacienteId: _texto(json['pacienteId']),
    nutricionistaId: _texto(json['nutricionistaId']),
    kcalObjetivo: _numero(json['kcalObjetivo']),
    proteinaG: _numero(json['proteinaG']),
    carbohidratoG: _numero(json['carbohidratoG']),
    grasaG: _numero(json['grasaG']),
    justificacion: json['justificacion'] is String
        ? json['justificacion'] as String
        : null,
    creadoEn: _instante(json['creadoEn']),
    aprobadoEn: _instante(json['aprobadoEn']),
  );

  final String id;
  final String nombre;
  final EstadoPlan estado;
  final OrigenPlan origen;
  final String pacienteId;
  final String nutricionistaId;

  /// The **daily** kcal goal.
  final double kcalObjetivo;
  final double proteinaG;
  final double carbohidratoG;
  final double grasaG;

  /// `null` hides the block: a plan with no explanation.
  final String? justificacion;

  /// An instant, UTC as the API sends it: format it after `toLocal()`.
  final DateTime? creadoEn;

  /// An instant, UTC as the API sends it: format it after `toLocal()`. Only an
  /// activated plan carries one.
  final DateTime? aprobadoEn;
}

/// `PlanDetalleEntity`: the plan with its week.
///
/// [dias] and [tiempos] are the same meal times in two shapes: draw the week
/// from [dias] and do not regroup [tiempos] on the client.
class PlanDetalle extends Plan {
  const PlanDetalle({
    required super.id,
    required super.nombre,
    required super.estado,
    required super.origen,
    super.pacienteId,
    super.nutricionistaId,
    super.kcalObjetivo,
    super.proteinaG,
    super.carbohidratoG,
    super.grasaG,
    super.justificacion,
    super.creadoEn,
    super.aprobadoEn,
    this.dias = const [],
    this.tiempos = const [],
    this.totales,
    this.desviacion,
  });

  factory PlanDetalle.fromJson(Map<String, dynamic> json) {
    final plan = Plan.fromJson(json);
    return PlanDetalle(
      id: plan.id,
      nombre: plan.nombre,
      estado: plan.estado,
      origen: plan.origen,
      pacienteId: plan.pacienteId,
      nutricionistaId: plan.nutricionistaId,
      kcalObjetivo: plan.kcalObjetivo,
      proteinaG: plan.proteinaG,
      carbohidratoG: plan.carbohidratoG,
      grasaG: plan.grasaG,
      justificacion: plan.justificacion,
      creadoEn: plan.creadoEn,
      aprobadoEn: plan.aprobadoEn,
      dias: _lista(json['dias'], DiaPlan.fromJson),
      tiempos: _lista(json['tiempos'], TiempoComida.fromJson),
      totales: _totales(json['totales']),
      desviacion: (json['desviacion'] as num?)?.toDouble(),
    );
  }

  /// Only the days that have a meal time, Monday first.
  final List<DiaPlan> dias;

  /// The whole week, flat, ordered by day and then by meal time.
  final List<TiempoComida> tiempos;

  /// The totals of the **week**.
  final Totales? totales;

  /// A **fraction** with sign of the week against `kcalObjetivo × dias.length`.
  final double? desviacion;
}

String _texto(Object? valor) => valor is String ? valor : '';

double _numero(Object? valor) => valor is num ? valor.toDouble() : 0;

/// An instant (`creadoEn`, `aprobadoEn`), kept as the API sends it.
DateTime? _instante(Object? valor) =>
    valor is String ? DateTime.tryParse(valor) : null;

Totales? _totales(Object? valor) =>
    valor is Map<String, dynamic> ? Totales.fromJson(valor) : null;

List<T> _lista<T>(
  Object? valor,
  T Function(Map<String, dynamic> json) fromJson,
) => valor is List
    ? valor
          .whereType<Map<String, dynamic>>()
          .map(fromJson)
          .toList(growable: false)
    : const [];
