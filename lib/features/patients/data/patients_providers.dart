import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/paged.dart';
import '../../auth/data/auth_providers.dart';
import 'catalogo_item.dart';
import 'paciente_ficha.dart';
import 'paciente_resumen.dart';
import 'patients_repository.dart';

final patientsRepositoryProvider = Provider<PatientsRepository>(
  (ref) => PatientsRepository(ref.watch(apiClientProvider)),
);

/// Patients of the signed-in nutritionist, newest first.
final pacientesRecientesProvider =
    FutureProvider.autoDispose<Paged<PacienteResumen>>(
      (ref) => ref.watch(patientsRepositoryProvider).recientes(),
      retry: (_, _) => null,
    );

/// The directory for a search text; the empty string lists everyone.
final pacientesDirectorioProvider = FutureProvider.autoDispose
    .family<Paged<PacienteResumen>, String>(
      (ref, query) =>
          ref.watch(patientsRepositoryProvider).directorio(q: query),
      retry: (_, _) => null,
    );

/// The whole file of one patient, keyed by patient id.
final pacienteFichaProvider = FutureProvider.autoDispose
    .family<PacienteFicha, String>(
      (ref, pacienteId) =>
          ref.watch(patientsRepositoryProvider).ficha(pacienteId),
      retry: (_, _) => null,
    );

/// Conditions catalogue for the new-patient wizard.
final condicionesProvider = FutureProvider.autoDispose<List<CatalogoItem>>(
  (ref) => ref.watch(patientsRepositoryProvider).condiciones(),
  retry: (_, _) => null,
);

/// Restrictions catalogue for the new-patient wizard.
final restriccionesProvider = FutureProvider.autoDispose<List<CatalogoItem>>(
  (ref) => ref.watch(patientsRepositoryProvider).restricciones(),
  retry: (_, _) => null,
);
