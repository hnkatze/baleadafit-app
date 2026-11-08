import 'package:flutter/material.dart';

import '../../core/router/app_routes.dart';

/// One entry of the authenticated navigation, shared by the drawer and the
/// top bar so the label of a route is written once.
class AppSection {
  const AppSection({
    required this.label,
    required this.route,
    required this.icon,
    this.group = 'Navegación clínica',
  });

  final String label;
  final String route;
  final IconData icon;
  final String group;
}

const List<AppSection> appSections = [
  AppSection(label: 'Inicio', route: AppRoutes.home, icon: Icons.dashboard_outlined),
  AppSection(label: 'Pacientes', route: AppRoutes.pacientes, icon: Icons.groups_outlined),
  AppSection(
    label: 'Diseñador de dietas',
    route: AppRoutes.dietas,
    icon: Icons.restaurant_menu,
  ),
  AppSection(
    label: 'Catálogo de alimentos',
    route: AppRoutes.catalogo,
    icon: Icons.menu_book_outlined,
  ),
  AppSection(
    label: 'Agenda de citas',
    route: AppRoutes.agenda,
    icon: Icons.calendar_today_outlined,
  ),
  AppSection(
    label: 'Configuración',
    route: AppRoutes.configuracion,
    icon: Icons.settings_outlined,
    group: 'Administración HN',
  ),
];

/// Whether [section] owns [location].
///
/// A section owns its own route and every child path below it, so a detail
/// screen like `/pacientes/:id` keeps the label and the drawer highlight of the
/// list it belongs to. The slash is required so a route that only shares a
/// prefix (`/pacientes-archivados`) is not swallowed.
bool sectionOwnsLocation(AppSection section, String location) =>
    location == section.route || location.startsWith('${section.route}/');

/// The section that owns [location], if any.
AppSection? sectionForLocation(String location) {
  for (final section in appSections) {
    if (sectionOwnsLocation(section, location)) return section;
  }
  return null;
}

/// Label of the section that owns [location], for the top bar.
String sectionLabelFor(String location) =>
    sectionForLocation(location)?.label ?? 'BaleadaFit';
