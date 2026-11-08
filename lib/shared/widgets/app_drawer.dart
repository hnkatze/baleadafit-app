import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../features/auth/application/session_controller.dart';
import '../../features/auth/data/user_role.dart';
import 'app_emblem.dart';
import 'app_sections.dart';

/// Side navigation of the authenticated area: brand header, profile card,
/// grouped sections and the sign-out action.
class AppDrawer extends ConsumerWidget {
  const AppDrawer({required this.activeRoute, super.key});

  final String activeRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider).session;
    final groups = <String, List<AppSection>>{};
    for (final section in appSections) {
      groups.putIfAbsent(section.group, () => []).add(section);
    }

    return Drawer(
      width: 290,
      backgroundColor: AppColors.surfaceContainerLowest,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(context),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: _profile(
                context,
                name: session?.displayName ?? 'Sesión activa',
                role: _roleLabel(session?.rol),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  for (final entry in groups.entries)
                    ..._group(context, entry.key, entry.value),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(8),
              child: TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  ref.read(sessionControllerProvider.notifier).signOut();
                },
                icon: const Icon(Icons.logout, size: 20),
                label: const Text('Cerrar sesión'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) => SizedBox(
    height: 64,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const AppEmblem(size: 28),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'BaleadaFit Pro',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Cerrar menú',
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    ),
  );

  Widget _profile(BuildContext context, {required String name, required String role}) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            child: const Icon(Icons.medical_services_outlined, size: 20, color: AppColors.onPrimary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(color: AppColors.onSurface),
                ),
                Text(role, style: textTheme.labelSmall?.copyWith(color: AppColors.primary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _group(BuildContext context, String label, List<AppSection> sections) {
    final textTheme = Theme.of(context).textTheme;
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
        child: Text(
          label.toUpperCase(),
          style: textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant, letterSpacing: 0.8),
        ),
      ),
      for (final section in sections) _item(context, section),
    ];
  }

  Widget _item(BuildContext context, AppSection section) {
    final isActive = sectionOwnsLocation(section, activeRoute);
    final color = isActive ? AppColors.primary : AppColors.onSurfaceVariant;
    final radius = BorderRadius.circular(AppDimensions.radiusSm);

    return Semantics(
      selected: isActive,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Material(
          color: isActive ? AppColors.secondaryContainer.withValues(alpha: 0.5) : Colors.transparent,
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: () {
              Navigator.of(context).pop();
              if (!isActive) context.go(section.route);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(section.icon, size: 22, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      section.label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: color,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _roleLabel(UserRole? role) => switch (role) {
    UserRole.nutricionista => 'Nutricionista',
    UserRole.paciente => 'Paciente',
    UserRole.sinPerfil => 'Sin perfil',
    null => 'Sin sesión',
  };
}
