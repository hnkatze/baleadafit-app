import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/paged.dart';
import '../../auth/data/auth_providers.dart';
import 'cita.dart';
import 'citas_repository.dart';

final citasRepositoryProvider = Provider<CitasRepository>(
  (ref) => CitasRepository(ref.watch(apiClientProvider)),
);

/// The agenda of one day, keyed by the day itself.
///
/// The day is normalised to midnight so a screen that carries a time of day
/// still hits the same cache entry; `GET /citas` has no "today" filter, so the
/// range is always computed here.
final agendaDelDiaProvider = FutureProvider.autoDispose
    .family<Paged<Cita>, DateTime>((ref, dia) {
      final normalizado = DateTime(dia.year, dia.month, dia.day);
      return ref
          .watch(citasRepositoryProvider)
          .listar(desde: normalizado, hasta: normalizado);
    }, retry: (_, _) => null);

/// The appointments of one month and how many fall on each local day.
class CitasDelMes {
  CitasDelMes(this.citas) : _porDia = _agrupar(citas);

  final List<Cita> citas;
  final Map<DateTime, int> _porDia;

  /// How many appointments fall on [dia], by its local calendar day.
  int cuantasEl(DateTime dia) =>
      _porDia[DateTime(dia.year, dia.month, dia.day)] ?? 0;

  /// Grouped by the **local** day of `fechaHora`, never by its UTC day: an
  /// appointment at 21:00 local west of Greenwich is already tomorrow in UTC.
  static Map<DateTime, int> _agrupar(List<Cita> citas) {
    final cuenta = <DateTime, int>{};
    for (final cita in citas) {
      final local = cita.fechaHora.toLocal();
      final dia = DateTime(local.year, local.month, local.day);
      cuenta[dia] = (cuenta[dia] ?? 0) + 1;
    }
    return cuenta;
  }
}

/// The agenda of one month, keyed by any date of that month (normalised to its
/// first day so every day of the month shares one cache entry).
///
/// `limit` caps the month at 100 appointments. That is fine for one
/// nutritionist but it is a known ceiling: past it, the strip would undercount.
final citasDelMesProvider = FutureProvider.autoDispose
    .family<CitasDelMes, DateTime>((ref, mes) async {
      final primero = DateTime(mes.year, mes.month);
      final ultimo = DateTime(mes.year, mes.month + 1, 0);
      final page = await ref
          .watch(citasRepositoryProvider)
          .listar(desde: primero, hasta: ultimo);
      return CitasDelMes(page.items);
    }, retry: (_, _) => null);
