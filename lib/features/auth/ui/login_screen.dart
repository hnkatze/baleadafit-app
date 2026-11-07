import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_divider_label.dart';
import '../../../shared/widgets/app_emblem.dart';
import '../../../shared/widgets/app_pill.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../application/session_controller.dart';
import '../data/auth_failure.dart';

/// Clinician sign-in, drawn from the "Acceso Clínico Profesional" mobile
/// screen in `odd/designs/mobile/01-login.html`.
///
/// The screen only collects credentials and reports failures: navigation is the
/// router's job, driven by the session state.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // A user who is already signed in with Firebase goes straight in, unless
    // they just signed out on purpose.
    if (ref.read(sessionControllerProvider).status == SessionStatus.unknown) {
      unawaited(
        Future.microtask(
          () => ref.read(sessionControllerProvider.notifier).restore(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submitEmail() async {
    if (_isSubmitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await ref
          .read(sessionControllerProvider.notifier)
          .signInWithEmail(
            email: _emailController.text,
            password: _passwordController.text,
          );
    } on AuthFailure catch (failure) {
      if (mounted) setState(() => _error = failure.mensaje);
    } on Object {
      if (mounted) {
        setState(() => _error = 'Algo salió mal. Intentá de nuevo.');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitGoogle() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await ref.read(sessionControllerProvider.notifier).signInWithGoogle();
    } on AuthFailure catch (failure) {
      // Cancelling the sheet is a normal outcome and shows no error.
      if (mounted && failure is! SignInCancelledFailure) {
        setState(() => _error = failure.mensaje);
      }
    } on Object {
      if (mounted) {
        setState(() => _error = 'Algo salió mal. Intentá de nuevo.');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceMd,
            vertical: AppDimensions.spaceXl,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(textTheme: textTheme),
                const SizedBox(height: AppDimensions.spaceLg),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.spaceMd),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppTextField(
                          controller: _emailController,
                          label: 'Correo electrónico',
                          labelIcon: Icons.mail_outline,
                          hint: 'ejemplo@baleadafit.hn',
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.username],
                          enabled: !_isSubmitting,
                          validator: _validateEmail,
                          onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                        ),
                        const SizedBox(height: AppDimensions.spaceMd),
                        AppTextField(
                          controller: _passwordController,
                          focusNode: _passwordFocus,
                          label: 'Contraseña',
                          labelIcon: Icons.lock_outline,
                          hint: '••••••••',
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          enabled: !_isSubmitting,
                          validator: _validatePassword,
                          onFieldSubmitted: (_) => _submitEmail(),
                          trailing: TextButton(
                            onPressed: _showForgotPasswordHint,
                            child: const Text('¿Olvidaste tu clave?'),
                          ),
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword
                                ? 'Mostrar contraseña'
                                : 'Ocultar contraseña',
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: AppDimensions.iconSm,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: AppDimensions.spaceMd),
                          _ErrorBanner(message: _error!),
                        ],
                        if (!Env.hasApiBaseUrl) ...[
                          const SizedBox(height: AppDimensions.spaceMd),
                          _NoticeBanner(
                            message:
                                'Falta API_BASE_URL en el build: corré la app con '
                                'make run para que el login pueda llamar a la API.',
                          ),
                        ],
                        const SizedBox(height: AppDimensions.spaceMd),
                        AppButton(
                          label: 'Ingresar a mi Consultorio',
                          icon: Icons.monitor_heart_outlined,
                          isLoading: _isSubmitting,
                          onPressed: _submitEmail,
                        ),
                        const SizedBox(height: AppDimensions.spaceMd),
                        const AppDividerLabel(label: 'o autenticación rápida'),
                        const SizedBox(height: AppDimensions.spaceMd),
                        AppButton(
                          label: 'Continuar con Google',
                          variant: AppButtonVariant.secondary,
                          onPressed: _isSubmitting ? null : _submitGoogle,
                        ),
                        const SizedBox(height: AppDimensions.spaceMd),
                        Center(
                          child: AppPill(
                            label: 'Conexión cifrada con la API',
                            icon: Icons.verified_user_outlined,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceLg),
                Text(
                  '© 2026 BaleadaFit Pro HN',
                  textAlign: TextAlign.center,
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showForgotPasswordHint() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pedile a la administración que restablezca tu clave.'),
      ),
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Escribí tu correo.';
    if (!email.contains('@') || !email.contains('.')) {
      return 'Revisá el correo: le falta el @ o el dominio.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Escribí tu contraseña.';
    if (password.length < 6) return 'La contraseña tiene al menos 6 caracteres.';
    return null;
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.textTheme});

  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          padding: const EdgeInsets.all(AppDimensions.spaceMd - 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const AppEmblem(),
        ),
        const SizedBox(height: AppDimensions.spaceSm),
        const AppPill(
          label: 'PORTAL CLÍNICO · ESPECIALISTAS HN',
          dotColor: AppColors.primaryContainer,
          pulse: true,
        ),
        const SizedBox(height: AppDimensions.spaceSm),
        Text(
          'Acceso Clínico Profesional',
          textAlign: TextAlign.center,
          style: textTheme.headlineMedium,
        ),
        const SizedBox(height: AppDimensions.spaceXs),
        Text(
          'Ingresa con tus credenciales colegiadas o correo institucional',
          textAlign: TextAlign.center,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceMd - 4),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline,
            size: AppDimensions.iconSm,
            color: AppColors.onErrorContainer,
          ),
          const SizedBox(width: AppDimensions.spaceSm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoticeBanner extends StatelessWidget {
  const _NoticeBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceMd - 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
