import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import 'alimento_detalle_screen.dart';
import 'alimento_form_screen.dart';
import 'alimento_historial_screen.dart';
import 'catalogo_busqueda_screen.dart';

/// The catalogue screens wired to the router.
///
/// Every screen takes its data and its exits by constructor, so navigation and
/// provider invalidation live here and nowhere else. `go` is used instead of
/// `pop` on purpose: a deep link has nothing to pop to, and rebuilding the
/// previous screen from its route is what refreshes a list after a write.
class CatalogoBusquedaRoute extends StatelessWidget {
  const CatalogoBusquedaRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return CatalogoBusquedaScreen(
      onAgregar: () => context.go(AppRoutes.nuevoAlimento),
      onAbrir: (alimento) => context.go(AppRoutes.alimento(alimento.id)),
    );
  }
}

class AlimentoDetalleRoute extends ConsumerWidget {
  const AlimentoDetalleRoute({required this.alimentoId, super.key});

  final String alimentoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlimentoDetalleScreen(
      alimentoId: alimentoId,
      onVolver: () => context.go(AppRoutes.catalogo),
      onEditar: () => context.go(AppRoutes.editarAlimento(alimentoId)),
      onVerHistorial: () => context.go(AppRoutes.historialAlimento(alimentoId)),
      onDadoDeBaja: () {
        // The food left the catalogue: its detail and history stop being valid,
        // and the list below is rebuilt when the route changes.
        ref.invalidate(alimentoDetalleProvider(alimentoId));
        ref.invalidate(alimentoVersionesProvider(alimentoId));
        ref.invalidate(resultadosCatalogoProvider);
        ref.invalidate(totalCatalogoProvider);
        context.go(AppRoutes.catalogo);
      },
    );
  }
}

class AlimentoFormRoute extends ConsumerWidget {
  const AlimentoFormRoute({this.alimentoId, super.key});

  /// Null on the registration route, where there is nothing to load.
  final String? alimentoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = alimentoId;
    if (id == null) {
      return AlimentoFormScreen(
        onCerrar: () => context.go(AppRoutes.catalogo),
        onGuardado: (_) {
          // A new food changes the list below; the header count too.
          ref.invalidate(resultadosCatalogoProvider);
          ref.invalidate(totalCatalogoProvider);
          context.go(AppRoutes.catalogo);
        },
      );
    }

    final alimento = ref.watch(alimentoDetalleProvider(id));
    final guardado = alimento.value;

    // An error that is already retrying still has to offer the exit and a way
    // to ask again, so the failure is checked before the spinner.
    if (guardado == null && alimento.hasError) {
      return _FalloFormulario(
        onCerrar: () => context.go(AppRoutes.alimento(id)),
        onReintentar: () => ref.invalidate(alimentoDetalleProvider(id)),
      );
    }
    if (guardado == null) {
      return _CargandoFormulario(
        onCerrar: () => context.go(AppRoutes.alimento(id)),
      );
    }

    return AlimentoFormScreen(
      alimento: guardado,
      onCerrar: () => context.go(AppRoutes.alimento(id)),
      onGuardado: (_) {
        ref.invalidate(alimentoDetalleProvider(id));
        ref.invalidate(alimentoVersionesProvider(id));
        ref.invalidate(resultadosCatalogoProvider);
        ref.invalidate(totalCatalogoProvider);
        context.go(AppRoutes.alimento(id));
      },
    );
  }
}

class AlimentoHistorialRoute extends ConsumerWidget {
  const AlimentoHistorialRoute({required this.alimentoId, super.key});

  final String alimentoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The name is only the header of the history: it is read from the detail
    // that reaching this screen already loaded, so a deep link shows the list
    // while the name arrives instead of blocking on a spinner.
    final nombre =
        ref.watch(alimentoDetalleProvider(alimentoId)).value?.nombre ?? '';

    return AlimentoHistorialScreen(
      alimentoId: alimentoId,
      alimentoNombre: nombre,
      onVolver: () => context.go(AppRoutes.alimento(alimentoId)),
    );
  }
}

/// Exit-only screen while the food of an edit route loads.
class _CargandoFormulario extends StatelessWidget {
  const _CargandoFormulario({required this.onCerrar});

  final VoidCallback onCerrar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Cerrar',
          onPressed: onCerrar,
          icon: const Icon(Icons.close),
        ),
      ),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}

/// Same exit, plus a way to ask again, when the food could not be read.
class _FalloFormulario extends StatelessWidget {
  const _FalloFormulario({required this.onCerrar, required this.onReintentar});

  final VoidCallback onCerrar;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Cerrar',
          onPressed: onCerrar,
          icon: const Icon(Icons.close),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'No pudimos cargar el alimento.',
                style: textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onReintentar,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
