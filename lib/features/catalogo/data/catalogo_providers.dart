import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_providers.dart';
import 'catalogo_repository.dart';
import 'restriccion.dart';

final catalogoRepositoryProvider = Provider<CatalogoRepository>(
  (ref) => CatalogoRepository(ref.watch(apiClientProvider)),
);

/// The restriction vocabulary (`GET /restricciones`) that fills `Excluir`,
/// `Contiene` and the form. Never hardcoded.
final restriccionesCatalogoProvider =
    FutureProvider.autoDispose<List<Restriccion>>(
      (ref) => ref.watch(catalogoRepositoryProvider).restricciones(),
    );
