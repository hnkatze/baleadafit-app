import 'package:flutter/material.dart';

import '../../../core/theme/app_dimensions.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_text_field.dart';

/// Login form shell.
///
/// Renders the base inputs so the route, the layout and the design tokens are
/// settled. The submit action stays disabled until issue #4 wires Firebase
/// Authentication, so the screen never fakes a session.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppDimensions.screenPadding,
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('BaleadaFit', style: textTheme.headlineMedium),
                  const SizedBox(height: AppDimensions.spaceXs),
                  Text(
                    'Entrá con tu cuenta para continuar.',
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppDimensions.spaceLg),
                  const AppTextField(
                    label: 'Correo',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    prefixIcon: Icons.mail_outline,
                  ),
                  const SizedBox(height: AppDimensions.spaceMd),
                  const AppTextField(
                    label: 'Contraseña',
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    prefixIcon: Icons.lock_outline,
                  ),
                  const SizedBox(height: AppDimensions.spaceLg),
                  const AppButton(label: 'Iniciar sesión', onPressed: null),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
