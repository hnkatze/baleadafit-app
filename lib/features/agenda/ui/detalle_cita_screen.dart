import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/fechas.dart';
import '../../../core/network/api_failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_pill.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../data/cita.dart';
import '../data/citas_providers.dart';

/// One appointment and its SOAP note, with the three actions of the agenda.
///
/// The API has no `GET /citas/{id}`: the cita arrives already loaded inside the
/// list, so this screen is handed the object and never fetches it again. That
/// is also why it is pushed with a plain [MaterialPageRoute] and not a router
/// location: a cita cannot be deep-linked.
///
/// Reprogram, complete and cancel are all `PATCH /citas/{id}`. A failure keeps
/// the form as it is and shows the API message inline.
class DetalleCitaScreen extends ConsumerStatefulWidget {
  const DetalleCitaScreen({required this.cita, required this.dia, super.key});

  final Cita cita;

  /// The day the agenda was showing, so its cache is refreshed on the way back.
  final DateTime dia;

  @override
  ConsumerState<DetalleCitaScreen> createState() => _DetalleCitaScreenState();
}

class _DetalleCitaScreenState extends ConsumerState<DetalleCitaScreen> {
  late final _subjetivo = TextEditingController(text: widget.cita.subjetivo);
  late final _objetivo = TextEditingController(text: widget.cita.objetivo);
  late final _analisis = TextEditingController(text: widget.cita.analisis);
  late final _plan = TextEditingController(text: widget.cita.plan);

  /// A calendar date: built from its own fields, never converted to local.
  late DateTime? _proxima = _soloFecha(widget.cita.proximaCitaSugerida);

  String? _error;
  bool _enviando = false;

  @override
  void dispose() {
    _subjetivo.dispose();
    _objetivo.dispose();
    _analisis.dispose();
    _plan.dispose();
    super.dispose();
  }

  static DateTime? _soloFecha(DateTime? fecha) =>
      fecha == null ? null : DateTime(fecha.year, fecha.month, fecha.day);

  /// Runs one PATCH. On success refreshes the affected days and pops; on an
  /// [ApiFailure] shows its message and leaves the form untouched.
  Future<void> _enviar(
    Future<void> Function() patch, {
    DateTime? tambienDia,
  }) async {
    setState(() {
      _enviando = true;
      _error = null;
    });

    try {
      await patch();
      if (!mounted) return;
      ref.invalidate(agendaDelDiaProvider(widget.dia));
      ref.invalidate(
        agendaDelDiaProvider(_soloFecha(widget.cita.fechaHora.toLocal())!),
      );
      if (tambienDia != null) {
        ref.invalidate(agendaDelDiaProvider(_soloFecha(tambienDia)!));
      }
      Navigator.of(context).pop();
    } on ApiFailure catch (fallo) {
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _error = fallo.mensaje;
      });
    }
  }

  Future<void> _elegirProxima() async {
    final base = _proxima ?? _soloFecha(widget.cita.fechaHora.toLocal())!;
    final elegida = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(base.year - 1),
      lastDate: DateTime(base.year + 3),
    );
    if (elegida == null || !mounted) return;
    setState(() => _proxima = _soloFecha(elegida));
  }

  Future<void> _completar() => _enviar(
    () => ref
        .read(citasRepositoryProvider)
        .actualizar(
          widget.cita.id,
          estado: EstadoCita.completada,
          subjetivo: _subjetivo.text.trim(),
          objetivo: _objetivo.text.trim(),
          analisis: _analisis.text.trim(),
          plan: _plan.text.trim(),
          proximaCitaSugerida: _proxima,
        ),
  );

  Future<void> _reprogramar() async {
    final actual = widget.cita.fechaHora.toLocal();
    final fecha = await showDatePicker(
      context: context,
      initialDate: actual,
      firstDate: DateTime(actual.year - 1),
      lastDate: DateTime(actual.year + 2),
    );
    if (fecha == null || !mounted) return;
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(actual),
    );
    if (hora == null || !mounted) return;

    final nueva = DateTime(
      fecha.year,
      fecha.month,
      fecha.day,
      hora.hour,
      hora.minute,
    );
    await _enviar(
      () => ref
          .read(citasRepositoryProvider)
          .actualizar(widget.cita.id, fechaHora: nueva),
      tambienDia: nueva,
    );
  }

  Future<void> _cancelar() async {
    final confirmada = await showDialog<bool>(
      context: context,
      builder: (context) {
        final colors = Theme.of(context).colorScheme;
        return AlertDialog(
          // Same way out as the plan confirmations: only the red cross in the
          // corner, never a second button beside the action.
          title: Row(
            children: [
              const Expanded(child: Text('¿Cancelar esta cita?')),
              IconButton(
                key: const Key('cerrar-dialogo'),
                tooltip: 'No',
                onPressed: () => Navigator.of(context).pop(false),
                icon: Icon(Icons.close, size: 28, color: colors.error),
              ),
            ],
          ),
          actions: [
            // Cancelling an appointment is destructive: the action says so.
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colors.error,
                foregroundColor: colors.onError,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sí, cancelar'),
            ),
          ],
        );
      },
    );
    if (confirmada != true || !mounted) return;

    await _enviar(
      () => ref
          .read(citasRepositoryProvider)
          .actualizar(widget.cita.id, estado: EstadoCita.cancelada),
    );
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final cita = widget.cita;
    final telefono = cita.paciente?.telefono ?? '';
    final dia = cita.fechaHora.toLocal();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cita'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Volver',
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: ListView(
        padding: AppDimensions.screenPadding,
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        cita.pacienteNombre,
                        style: texto.titleMedium,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spaceSm),
                    AppPill(
                      label: cita.estado.etiqueta,
                      dotColor: _colorDe(cita.estado),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spaceSm),
                Text(
                  '${formatearFecha(dia)} · ${cita.hora}',
                  style: AppTypography.data(context),
                ),
                Text('${cita.duracionMin} min', style: texto.bodySmall),
                if (cita.motivo.isNotEmpty)
                  _Dato(etiqueta: 'Motivo', valor: cita.motivo),
                if (cita.notas.isNotEmpty)
                  _Dato(etiqueta: 'Notas', valor: cita.notas),
                if (telefono.isNotEmpty)
                  _Dato(etiqueta: 'Teléfono', valor: telefono),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spaceLg),
          _CampoSoap(
            campo: const Key('subjetivo'),
            etiqueta: 'Subjetivo',
            controller: _subjetivo,
          ),
          _CampoSoap(
            campo: const Key('objetivo'),
            etiqueta: 'Objetivo',
            controller: _objetivo,
          ),
          _CampoSoap(
            campo: const Key('analisis'),
            etiqueta: 'Análisis',
            controller: _analisis,
          ),
          _CampoSoap(
            campo: const Key('plan'),
            // `plan` of the SOAP note, not the meal plan: the board card
            // `citas-sin-get-por-id` asks for exactly this wording so the two
            // are never confused on screen.
            etiqueta: 'Plan de la consulta',
            controller: _plan,
          ),
          Text('Próxima cita sugerida', style: texto.labelMedium),
          const SizedBox(height: AppDimensions.spaceXs),
          InkWell(
            key: const Key('proxima'),
            onTap: _enviando ? null : _elegirProxima,
            child: SizedBox(
              height: AppDimensions.fieldHeight,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _proxima == null ? 'Sin fecha' : formatearFecha(_proxima!),
                ),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppDimensions.spaceMd),
            Text(
              _error!,
              style: texto.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: AppDimensions.spaceLg),
          AppButton(
            label: 'Guardar nota y completar',
            isLoading: _enviando,
            onPressed: _completar,
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          AppButton(
            label: 'Reprogramar',
            variant: AppButtonVariant.secondary,
            onPressed: _enviando ? null : _reprogramar,
          ),
          if (cita.estado != EstadoCita.cancelada) ...[
            const SizedBox(height: AppDimensions.spaceSm),
            AppButton(
              label: 'Cancelar cita',
              variant: AppButtonVariant.text,
              onPressed: _enviando ? null : _cancelar,
            ),
          ],
        ],
      ),
    );
  }
}

Color _colorDe(EstadoCita estado) => switch (estado) {
  EstadoCita.programada => AppColors.primary,
  EstadoCita.completada => AppColors.tertiary,
  EstadoCita.cancelada => AppColors.outline,
};

class _Dato extends StatelessWidget {
  const _Dato({required this.etiqueta, required this.valor});

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(top: AppDimensions.spaceSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(etiqueta, style: texto.labelMedium),
          Text(valor, style: texto.bodyMedium),
        ],
      ),
    );
  }
}

class _CampoSoap extends StatelessWidget {
  const _CampoSoap({
    required this.campo,
    required this.etiqueta,
    required this.controller,
  });

  final Key campo;
  final String etiqueta;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppDimensions.spaceLg),
    child: AppTextField(
      key: campo,
      controller: controller,
      label: etiqueta,
      maxLines: 4,
    ),
  );
}
