import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../shared/widgets/app_button.dart';

/// Home placeholder.
///
/// It owns the destination the session will land on and nothing else: the
/// dashboard content arrives with the features it belongs to.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('BaleadaFit')),
      body: ListView(
        padding: AppDimensions.screenPadding,
        children: [
          Text('Inicio', style: textTheme.headlineSmall),
          const SizedBox(height: AppDimensions.spaceSm),
          Text(
            'El panel del usuario se construye sobre esta ruta.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: AppDimensions.spaceLg),
          AppButton(
            label: 'Ver design system',
            icon: Icons.palette_outlined,
            variant: AppButtonVariant.secondary,
            onPressed: () => context.push(AppRoutes.showcase),
          ),
        ],
      ),
    );
  }
}
