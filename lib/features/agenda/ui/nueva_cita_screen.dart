import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/fechas.dart';
import '../../../core/network/api_failure.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_search_select_field.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../patients/data/paciente_resumen.dart';
import '../../patients/data/patients_providers.dart';
import '../data/citas_providers.dart';

/// Programs a new appointment (`POST /citas`).
///
/// The API has no availability endpoint: the only signal of a clash is the 409
/// it answers, so the form does not validate overlaps on its own and, when the
/// 409 arrives, keeps everything written so only the hour has to be corrected.
class NuevaCitaScreen extends ConsumerStatefulWidget {
  const NuevaCitaScreen({super.key, this.dia});

  /// The day the agenda was showing, so the form opens there and not on today.
  final DateTime? dia;

  @override
  ConsumerState<NuevaCitaScreen> createState() => _NuevaCitaScreenState();
}

class _NuevaCitaScreenState extends ConsumerState<NuevaCitaScreen> {
  // Midnight of the local day: the provider family is keyed by the exact
  // DateTime, so a value carrying a time of day would invalidate a different
  // cache entry than the one the agenda is watching.
  late DateTime _fecha = _soloFecha(widget.dia ?? DateTime.now());
  TimeOfDay _hora = const TimeOfDay(hour: 9, minute: 0);
  PacienteResumen? _paciente;

  final _duracion = TextEditingController(text: '45');
  final _motivo = TextEditingController();
  final _notas = TextEditingController();

  String? _error;
  bool _enviando = false;

  @override
  void dispose() {
    _duracion.dispose();
    _motivo.dispose();
    _notas.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(_fecha.year - 1),
      lastDate: DateTime(_fecha.year + 2),
    );
    if (elegida == null || !mounted) return;
    setState(() => _fecha = elegida);
  }

  Future<void> _elegirHora() async {
    final elegida = await showTimePicker(context: context, initialTime: _hora);
    if (elegida == null || !mounted) return;
    setState(() => _hora = elegida);
  }

  Future<void> _programar() async {
    final paciente = _paciente;
    if (paciente == null) {
      setState(() => _error = 'Elegí un paciente');
      return;
    }

    setState(() {
      _enviando = true;
      _error = null;
    });

    final fechaHora = DateTime(
      _fecha.year,
      _fecha.month,
      _fecha.day,
      _hora.hour,
      _hora.minute,
    );

    try {
      await ref
          .read(citasRepositoryProvider)
          .crear(
            pacienteId: paciente.id,
            fechaHora: fechaHora,
            duracionMin: int.tryParse(_duracion.text.trim()) ?? 45,
            motivo: _motivo.text.trim(),
            notas: _notas.text.trim(),
          );
      if (!mounted) return;
      ref.invalidate(agendaDelDiaProvider(_fecha));
      Navigator.of(context).pop();
    } on ApiFailure catch (fallo) {
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _error = fallo.mensaje;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva cita'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Cerrar',
          icon: const Icon(Icons.close),
        ),
      ),
      body: ListView(
        padding: AppDimensions.screenPadding,
        children: [
          AppSearchSelectField<PacienteResumen>(
            key: const Key('paciente'),
            label: 'Paciente',
            hint: 'Buscar paciente',
            valor: _paciente?.nombreCompleto,
            buscar: (consulta) async =>
                (await ref
                        .read(patientsRepositoryProvider)
                        .directorio(q: consulta))
                    .items,
            etiquetaDe: (paciente) => paciente.nombreCompleto,
            onElegido: (paciente) => setState(() => _paciente = paciente),
          ),
          const SizedBox(height: AppDimensions.spaceLg),
          Row(
            children: [
              Expanded(
                child: _BotonCampo(
                  etiqueta: 'Fecha',
                  valor: formatearFecha(_fecha),
                  onTap: _elegirFecha,
                ),
              ),
              const SizedBox(width: AppDimensions.spaceMd),
              Expanded(
                child: _BotonCampo(
                  etiqueta: 'Hora',
                  valor: _hora.format(context),
                  onTap: _elegirHora,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceLg),
          AppTextField(
            key: const Key('duracion'),
            controller: _duracion,
            label: 'Duración · min',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppDimensions.spaceLg),
          AppTextField(
            key: const Key('motivo'),
            controller: _motivo,
            label: 'Motivo',
          ),
          const SizedBox(height: AppDimensions.spaceLg),
          AppTextField(
            key: const Key('notas'),
            controller: _notas,
            label: 'Notas · opcional',
            maxLines: 3,
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
            label: 'Programar cita',
            isLoading: _enviando,
            onPressed: _programar,
          ),
        ],
      ),
    );
  }
}

/// A labelled value that opens a picker instead of typing.
class _BotonCampo extends StatelessWidget {
  const _BotonCampo({
    required this.etiqueta,
    required this.valor,
    required this.onTap,
  });

  final String etiqueta;
  final String valor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: texto.labelMedium),
        const SizedBox(height: AppDimensions.spaceXs),
        InkWell(
          onTap: onTap,
          child: SizedBox(
            height: AppDimensions.fieldHeight,
            child: Align(alignment: Alignment.centerLeft, child: Text(valor)),
          ),
        ),
      ],
    );
  }
}

/// Midnight of the local day, with no time of day attached.
DateTime _soloFecha(DateTime fecha) =>
    DateTime(fecha.year, fecha.month, fecha.day);
