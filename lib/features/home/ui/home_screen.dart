import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_pill.dart';
import '../../auth/application/session_controller.dart';
import '../../auth/data/user_role.dart';

/// Home placeholder.
///
/// It shows who the session belongs to (which is also the proof that
/// `GET /auth/me` answered); the shell owns the bar and the drawer.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final session = ref.watch(sessionControllerProvider).session;
    final roleLabel = switch (session?.rol) {
      UserRole.nutricionista => 'Nutricionista',
      UserRole.paciente => 'Paciente',
      UserRole.sinPerfil => 'Sin perfil',
      null => 'Sesión activa',
    };
    final greeting = session?.displayName == null
        ? 'Inicio'
        : 'Hola, ${session!.displayName}';

    return ListView(
      padding: AppDimensions.screenPadding,
      children: [
        Text(greeting, style: textTheme.headlineSmall),
        const SizedBox(height: AppDimensions.spaceSm),
        AppPill(label: roleLabel, dotColor: Theme.of(context).colorScheme.primary),
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
    );
  }
}
