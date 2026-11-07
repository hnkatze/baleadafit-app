import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../features/auth/application/session_controller.dart';
import 'app_emblem.dart';

/// Top bar of the authenticated area: drawer handle, brand, current section and
/// the account avatar.
class AppTopBar extends ConsumerWidget implements PreferredSizeWidget {
  const AppTopBar({required this.section, super.key});

  final String section;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final name = ref.watch(sessionControllerProvider).session?.displayName;

    return AppBar(
      toolbarHeight: 64,
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leadingWidth: 56,
      leading: IconButton(
        tooltip: 'Abrir menú',
        icon: const Icon(Icons.menu, size: 24),
        onPressed: () => Scaffold.of(context).openDrawer(),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          const AppEmblem(size: 30),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'BaleadaFit Pro',
                  style: textTheme.titleSmall?.copyWith(color: AppColors.primary, letterSpacing: -0.2),
                ),
                Text(
                  section,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (name != null)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _AccountAvatar(initials: initialsOf(name)),
          ),
      ],
    );
  }

  /// First letters of the first and last name, skipping honorifics such as
  /// "Lic." or "Dra.": "Lic. Camilo Henriquez" -> "CH".
  static String initialsOf(String name) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty && !w.endsWith('.'))
        .toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) return words.first.characters.first.toUpperCase();
    return (words.first.characters.first + words.last.characters.first).toUpperCase();
  }
}

class _AccountAvatar extends StatelessWidget {
  const _AccountAvatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
      child: Text(
        initials,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.onPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
