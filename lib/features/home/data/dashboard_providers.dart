import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_providers.dart';
import 'dashboard_repository.dart';
import 'dashboard_resumen.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepository(ref.watch(apiClientProvider)),
);

/// Home summary as [AsyncValue]: the screen reads loading, error and data from
/// here and retries by invalidating this provider.
final dashboardProvider = FutureProvider.autoDispose<DashboardResumen>(
  (ref) => ref.watch(dashboardRepositoryProvider).resumen(),
  // Riverpod retries failed futures on its own; the screen shows the failure
  // and offers an explicit retry, so a silent second attempt is not wanted.
  retry: (_, _) => null,
);
