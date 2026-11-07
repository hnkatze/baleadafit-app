import 'package:flutter/material.dart';

import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/app_sections.dart';
import '../../../shared/widgets/app_top_bar.dart';

/// Shell of the authenticated area: it owns the drawer and the top bar so the
/// screens inside only render their own content.
class AppShell extends StatelessWidget {
  const AppShell({required this.location, required this.child, super.key});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(section: sectionLabelFor(location)),
      drawer: AppDrawer(activeRoute: location),
      body: child,
    );
  }
}
