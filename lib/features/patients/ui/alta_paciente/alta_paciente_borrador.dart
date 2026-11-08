import 'package:flutter/widgets.dart';

import '../../data/paciente_ficha.dart';

/// Step names, in the order the stepper draws them.
const pasosAlta = ['Identidad', 'Objetivo', 'Clínica', 'Hábitos'];

/// `sexo` of `POST /pacientes`.
enum SexoPaciente {
  femenino('F', 'Femenino'),
  masculino('M', 'Masculino');

  const SexoPaciente(this.codigo, this.etiqueta);

  final String codigo;
  final String etiqueta;
}

/// `meta` with the calorie adjustment the requirement applies to it.
enum MetaPaciente {
  bajar('BAJAR', 'Bajar', '−500 kcal'),
  mantener('MANTENER', 'Mantener', '0 kcal'),
  subir('SUBIR', 'Subir', '+300 kcal');

  const MetaPaciente(this.codigo, this.etiqueta, this.ajuste);

  final String codigo;
  final String etiqueta;
  final String ajuste;
}

/// `nivelActividad` with the factor the requirement multiplies the basal rate by.
enum NivelActividad {
  sedentario('SEDENTARIO', 'Sedentario', '×1.2'),
  ligero('LIGERO', 'Ligero', '×1.375'),
  moderado('MODERADO', 'Moderado', '×1.55'),
  intenso('INTENSO', 'Intenso', '×1.725'),
  muyIntenso('MUY_INTENSO', 'Muy intenso', '×1.9');

  const NivelActividad(this.codigo, this.etiqueta, this.factor);

  final String codigo;
  final String etiqueta;
  final String factor;
}

/// `estadoFisiologico`; pregnancy and lactation change the requirement.
enum EstadoFisiologico {
  ninguno('NINGUNO', 'Ninguno'),
  embarazo('EMBARAZO', 'Embarazo'),
  lactancia('LACTANCIA', 'Lactancia');

  const EstadoFisiologico(this.codigo, this.etiqueta);

  final String codigo;
  final String etiqueta;
}

/// What the wizard has collected so far, across its four steps.
///
/// The edit form is the same draft in [esEdicion] mode, prefilled by
/// [AltaPacienteBorrador.desdeFicha]: validation and body building are shared,
/// so the two flows cannot drift apart.
///
/// It lives above the steps (not in them) so going back, or a step being
/// rebuilt, never loses what was typed. Text controllers are named after the
/// `POST /pacientes` field they feed, so the body is built without a second
/// mapping that could drift.
class AltaPacienteBorrador {
  AltaPacienteBorrador() : esEdicion = false, _fechaObjetivoOriginal = '';

  /// Prefills every field from the ficha the screen already holds.
  AltaPacienteBorrador.desdeFicha(PacienteFicha ficha)
    : esEdicion = true,
      _fechaObjetivoOriginal = _fecha(ficha.paciente.fechaObjetivo) {
    final paciente = ficha.paciente;
    nombre.text = paciente.nombre ?? '';
    apellido.text = paciente.apellido ?? '';
    correo.text = paciente.correo ?? '';
    telefono.text = paciente.telefono ?? '';
    fechaNacimiento.text = _fecha(paciente.fechaNacimiento);
    sexo = SexoPaciente.values
        .where((valor) => valor.codigo == paciente.sexo)
        .firstOrNull;
    // A value the app does not know keeps the wizard default instead of
    // failing, so the form always opens.
    meta =
        MetaPaciente.values
            .where((valor) => valor.codigo == paciente.meta)
            .firstOrNull ??
        meta;
    nivelActividad =
        NivelActividad.values
            .where((valor) => valor.codigo == paciente.nivelActividad)
            .firstOrNull ??
        nivelActividad;
    estadoFisiologico =
        EstadoFisiologico.values
            .where((valor) => valor.codigo == paciente.estadoFisiologico)
            .firstOrNull ??
        estadoFisiologico;
    pesoObjetivoKg.text = _numero(paciente.pesoObjetivoKg);
    fechaObjetivo.text = _fechaObjetivoOriginal;
    notas.text = paciente.notas ?? '';

    final situacion = ficha.situacion;
    condiciones.addAll(situacion.condiciones);
    restricciones.addAll(situacion.restricciones);
    alergias.text = situacion.alergias ?? '';
    cirugias.text = situacion.cirugias ?? '';
    suplementos.text = situacion.suplementos ?? '';
    // The ficha repeats it in both blocks; the record is the source.
    motivoConsulta.text =
        paciente.motivoConsulta ?? situacion.motivoConsulta ?? '';

    final habitos = ficha.habitos;
    comidasAlDia.text = _numero(habitos.comidasAlDia);
    aguaLitros.text = _numero(habitos.aguaLitros);
    horasSueno.text = _numero(habitos.horasSueno);
    alcohol.text = habitos.alcohol ?? '';
    tabaco.text = habitos.tabaco ?? '';
    quienCocina.text = habitos.quienCocina ?? '';
    presupuesto.text = habitos.presupuesto ?? '';
  }

  /// True when the draft edits an existing patient (`PATCH`) instead of
  /// creating one (`POST`).
  final bool esEdicion;

  // Kept to let an unchanged goal date that already passed through: the
  // nutritionist is fixing something else, not setting a new date.
  final String _fechaObjetivoOriginal;

  final nombre = TextEditingController();
  final apellido = TextEditingController();
  final correo = TextEditingController();
  final telefono = TextEditingController();
  final fechaNacimiento = TextEditingController();
  SexoPaciente? sexo;

  // The artboard draws these three already chosen, so the wizard starts there.
  MetaPaciente meta = MetaPaciente.bajar;
  NivelActividad nivelActividad = NivelActividad.sedentario;
  EstadoFisiologico estadoFisiologico = EstadoFisiologico.ninguno;
  final pesoObjetivoKg = TextEditingController();
  final fechaObjetivo = TextEditingController();

  /// Catalogue codes, not names: that is what the API stores.
  final condiciones = <String>{};
  final restricciones = <String>{};
  final alergias = TextEditingController();
  final cirugias = TextEditingController();
  final suplementos = TextEditingController();
  final motivoConsulta = TextEditingController();

  final comidasAlDia = TextEditingController();
  final aguaLitros = TextEditingController();
  final horasSueno = TextEditingController();
  final alcohol = TextEditingController();
  final tabaco = TextEditingController();
  final quienCocina = TextEditingController();
  final presupuesto = TextEditingController();
  final notas = TextEditingController();

  void dispose() {
    for (final controller in [
      nombre,
      apellido,
      correo,
      telefono,
      fechaNacimiento,
      pesoObjetivoKg,
      fechaObjetivo,
      alergias,
      cirugias,
      suplementos,
      motivoConsulta,
      comidasAlDia,
      aguaLitros,
      horasSueno,
      alcohol,
      tabaco,
      quienCocina,
      presupuesto,
      notas,
    ]) {
      controller.dispose();
    }
  }

  /// Errors of [paso] keyed by the field name; empty when the step can advance.
  ///
  /// The same keys name the inputs, so each message lands under its own field.
  Map<String, String> validar(int paso, {DateTime? hoy}) {
    final ahora = hoy ?? DateTime.now();
    final dia = DateTime(ahora.year, ahora.month, ahora.day);
    final errores = <String, String>{};

    switch (paso) {
      case 0:
        if (nombre.text.trim().isEmpty) {
          errores['nombre'] = 'Ingresá el nombre';
        }
        if (apellido.text.trim().isEmpty) {
          errores['apellido'] = 'Ingresá el apellido';
        }
        final mail = correo.text.trim();
        if (mail.isEmpty) {
          errores['correo'] = 'Ingresá el correo';
        } else if (!_correoValido.hasMatch(mail)) {
          errores['correo'] = 'Revisá el correo';
        }
        if (sexo == null) errores['sexo'] = 'Elegí el sexo';
        final nacimiento = fechaNacimiento.text.trim();
        if (nacimiento.isEmpty) {
          errores['fechaNacimiento'] = 'Ingresá la fecha de nacimiento';
        } else {
          final fecha = leerFecha(nacimiento);
          if (fecha == null || fecha.year < 1900) {
            errores['fechaNacimiento'] = 'Usá el formato dd/mm/aaaa';
          } else if (fecha.isAfter(dia)) {
            errores['fechaNacimiento'] = 'La fecha no puede ser futura';
          }
        }
      case 1:
        _rango(errores, 'pesoObjetivoKg', pesoObjetivoKg, 20, 400);
        final objetivo = fechaObjetivo.text.trim();
        if (objetivo.isNotEmpty) {
          final fecha = leerFecha(objetivo);
          if (fecha == null) {
            errores['fechaObjetivo'] = 'Usá el formato dd/mm/aaaa';
          } else if (fecha.isBefore(dia) &&
              objetivo != _fechaObjetivoOriginal) {
            errores['fechaObjetivo'] = 'Elegí una fecha futura';
          }
        }
      case 3:
        _rango(errores, 'comidasAlDia', comidasAlDia, 1, 10, entero: true);
        _rango(errores, 'aguaLitros', aguaLitros, 0, 10);
        _rango(errores, 'horasSueno', horasSueno, 0, 24);
    }
    return errores;
  }

  /// The body of `POST /pacientes` (or `PATCH /pacientes/{id}` in
  /// [esEdicion]): only documented fields, only filled ones.
  ///
  /// Empty text is left out instead of sent as `""`, and the numeric fields go
  /// as numbers because that is how the API types them. Empty selections are
  /// left out when creating, but an edit always sends both lists whole: the
  /// API replaces them wholesale, so omitting one is not "unchanged" and a
  /// diff would drop what the nutritionist never touched.
  Map<String, Object?> cuerpo() {
    final cuerpo = <String, Object?>{};
    void texto(String clave, TextEditingController controller) {
      final valor = controller.text.trim();
      if (valor.isNotEmpty) cuerpo[clave] = valor;
    }

    void numero(
      String clave,
      TextEditingController controller, {
      bool entero = false,
    }) {
      final valor = _leerNumero(controller, entero: entero);
      if (valor != null) cuerpo[clave] = valor;
    }

    texto('nombre', nombre);
    texto('apellido', apellido);
    texto('correo', correo);
    texto('telefono', telefono);
    cuerpo['sexo'] = sexo?.codigo;
    cuerpo['fechaNacimiento'] = _fechaIso(leerFecha(fechaNacimiento.text)!);
    cuerpo['nivelActividad'] = nivelActividad.codigo;
    cuerpo['meta'] = meta.codigo;
    numero('pesoObjetivoKg', pesoObjetivoKg);
    final objetivo = leerFecha(fechaObjetivo.text);
    if (objetivo != null) cuerpo['fechaObjetivo'] = _fechaIso(objetivo);
    cuerpo['estadoFisiologico'] = estadoFisiologico.codigo;
    if (esEdicion || condiciones.isNotEmpty) {
      cuerpo['condiciones'] = condiciones.toList();
    }
    if (esEdicion || restricciones.isNotEmpty) {
      cuerpo['restricciones'] = restricciones.toList();
    }
    texto('alergias', alergias);
    texto('cirugias', cirugias);
    texto('suplementos', suplementos);
    texto('motivoConsulta', motivoConsulta);
    texto('notas', notas);
    texto('presupuesto', presupuesto);
    texto('quienCocina', quienCocina);
    texto('alcohol', alcohol);
    texto('tabaco', tabaco);
    numero('comidasAlDia', comidasAlDia, entero: true);
    numero('aguaLitros', aguaLitros);
    numero('horasSueno', horasSueno);
    return cuerpo;
  }

  void _rango(
    Map<String, String> errores,
    String clave,
    TextEditingController controller,
    num min,
    num max, {
    bool entero = false,
  }) {
    final valor = _leerNumero(controller, entero: entero);
    if (valor == null) return;
    if (valor.isNaN || valor < min || valor > max) {
      errores[clave] = 'Entre $min y $max';
    }
  }
}

final _correoValido = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

/// Parses a field the way an es-HN keyboard types it (a comma is a decimal
/// separator too). Null when empty; NaN when there is text that is no number,
/// so validation can tell "left blank" from "typed nonsense".
num? _leerNumero(TextEditingController controller, {bool entero = false}) {
  final texto = controller.text.trim().replaceAll(',', '.');
  if (texto.isEmpty) return null;
  if (entero) return int.tryParse(texto) ?? double.nan;
  return double.tryParse(texto) ?? double.nan;
}

/// `dd/mm/aaaa` to a date, or null when it is incomplete or not a real day
/// (`31/02/2020` would otherwise silently roll over to March).
DateTime? leerFecha(String texto) {
  final partes = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(texto.trim());
  if (partes == null) return null;
  final dia = int.parse(partes[1]!);
  final mes = int.parse(partes[2]!);
  final anio = int.parse(partes[3]!);
  final fecha = DateTime(anio, mes, dia);
  if (fecha.year != anio || fecha.month != mes || fecha.day != dia) return null;
  return fecha;
}

String formatearFecha(DateTime fecha) {
  String dos(int n) => n.toString().padLeft(2, '0');
  return '${dos(fecha.day)}/${dos(fecha.month)}/${fecha.year}';
}

String _fechaIso(DateTime fecha) {
  String dos(int n) => n.toString().padLeft(2, '0');
  return '${fecha.year}-${dos(fecha.month)}-${dos(fecha.day)}';
}

/// A stored date as the form types it. The API sends midnight UTC, so the
/// date is read from its own fields: converting to local time would show the
/// previous day west of Greenwich.
String _fecha(DateTime? fecha) => fecha == null ? '' : formatearFecha(fecha);

/// `62.0` reads as `62`, since that is how it was typed.
String _numero(num? valor) {
  if (valor == null) return '';
  return valor == valor.truncate() ? valor.toInt().toString() : '$valor';
}
