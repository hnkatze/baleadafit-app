import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/paged.dart';
import '../../auth/data/auth_providers.dart';
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
