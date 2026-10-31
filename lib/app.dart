import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/showcase/ui/theme_gallery_screen.dart';

/// Root widget: owns the app-wide theme and, until the router lands, the
/// temporary design-system gallery as the home screen.
class BaleadaFitApp extends StatelessWidget {
  const BaleadaFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BaleadaFit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const ThemeGalleryScreen(),
    );
  }
}
