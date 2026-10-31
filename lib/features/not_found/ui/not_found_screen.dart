import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../shared/widgets/app_button.dart';

/// Destination for locations the router does not know.
///
/// It names the requested location so a broken deep link is debuggable instead
/// of looking like a blank screen.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({required this.location, super.key});

  final String location;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('BaleadaFit')),
      body: ListView(
        padding: AppDimensions.screenPadding,
        children: [
          Text('Ruta no encontrada', style: textTheme.headlineSmall),
          const SizedBox(height: AppDimensions.spaceSm),
          Text(location, style: textTheme.bodySmall),
          const SizedBox(height: AppDimensions.spaceLg),
          AppButton(
            label: 'Volver al inicio',
            onPressed: () => context.go(AppRoutes.login),
          ),
        ],
      ),
    );
  }
}
