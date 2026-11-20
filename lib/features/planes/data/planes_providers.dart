import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/paged.dart';
import '../../auth/data/auth_providers.dart';
import 'alimentos_repository.dart';
import 'plan.dart';
import 'planes_repository.dart';

final planesRepositoryProvider = Provider<PlanesRepository>(
  (ref) => PlanesRepository(ref.watch(apiClientProvider)),
);

/// The food catalogue, only for the picker of the meal-time editor.
final alimentosRepositoryProvider = Provider<AlimentosRepository>(
  (ref) => AlimentosRepository(ref.watch(apiClientProvider)),
);

/// The plans of one patient, keyed by patient id, in the order of the API
/// (newest first). It asks for the largest page the API allows (100) so the
/// list does not need to paginate.
final planesDePacienteProvider = FutureProvider.autoDispose
    .family<Paged<Plan>, String>(
      (ref, pacienteId) =>
          ref.watch(planesRepositoryProvider).listar(pacienteId, limit: 100),
      retry: (_, _) => null,
    );

/// One plan with its week, keyed by plan id.
final planDetalleProvider = FutureProvider.autoDispose
    .family<PlanDetalle, String>(
      (ref, planId) => ref.watch(planesRepositoryProvider).detalle(planId),
      retry: (_, _) => null,
    );
