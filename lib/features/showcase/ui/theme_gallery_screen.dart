import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_text_field.dart';

/// Temporary home screen: renders the palette, the type scale and the base
/// components, so every change to the design tokens is visible in one place.
///
/// The router replaces it as home once feature #1 (navegación) lands.
class ThemeGalleryScreen extends StatelessWidget {
  const ThemeGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final typeSamples = <({String name, TextStyle? style})>[
      (name: 'displaySmall', style: textTheme.displaySmall),
      (name: 'headlineMedium', style: textTheme.headlineMedium),
      (name: 'headlineSmall', style: textTheme.headlineSmall),
      (name: 'titleLarge', style: textTheme.titleLarge),
      (name: 'titleMedium', style: textTheme.titleMedium),
      (name: 'bodyLarge', style: textTheme.bodyLarge),
      (name: 'bodyMedium', style: textTheme.bodyMedium),
      (name: 'bodySmall', style: textTheme.bodySmall),
      (name: 'labelLarge', style: textTheme.labelLarge),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('BaleadaFit · Design system')),
      body: ListView(
        padding: AppDimensions.screenPadding,
        children: [
          const _SectionTitle('Paleta'),
          const SizedBox(height: AppDimensions.spaceSm),
          _PaletteGrid(swatches: _swatches),
          const SizedBox(height: AppDimensions.spaceXl),

          const _SectionTitle('Tipografía'),
          const SizedBox(height: AppDimensions.spaceSm),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final sample in typeSamples)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppDimensions.spaceXs,
                    ),
                    child: Text(
                      '${sample.name} · ${sample.style?.fontSize?.toInt()}px',
                      style: sample.style,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spaceXl),

          const _SectionTitle('Botones'),
          const SizedBox(height: AppDimensions.spaceSm),
          const AppButton(label: 'Acción principal', onPressed: _noop),
          const SizedBox(height: AppDimensions.spaceSm),
          const AppButton(
            label: 'Acción secundaria',
            variant: AppButtonVariant.secondary,
            onPressed: _noop,
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          const AppButton(
            label: 'Acción terciaria',
            variant: AppButtonVariant.text,
            onPressed: _noop,
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          const AppButton(label: 'Cargando', isLoading: true, onPressed: _noop),
          const SizedBox(height: AppDimensions.spaceSm),
          const AppButton(label: 'Deshabilitado'),
          const SizedBox(height: AppDimensions.spaceXl),

          const _SectionTitle('Tarjetas'),
          const SizedBox(height: AppDimensions.spaceSm),
          AppCard(
            child: Row(
              children: [
                Icon(Icons.restaurant_menu, color: AppColors.green600),
                const SizedBox(width: AppDimensions.spaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Plan de hoy', style: textTheme.titleMedium),
                      const SizedBox(height: AppDimensions.spaceXs),
                      Text(
                        '1 850 kcal · 120 g de proteína',
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          AppCard(
            onTap: _noop,
            child: Row(
              children: [
                Text('Tarjeta con onTap', style: textTheme.titleMedium),
                const Spacer(),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spaceXl),

          const _SectionTitle('Campos de texto'),
          const SizedBox(height: AppDimensions.spaceSm),
          const AppTextField(
            label: 'Correo',
            hint: 'tu@correo.com',
            prefixIcon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          const AppTextField(
            label: 'Contraseña',
            obscureText: true,
            prefixIcon: Icons.lock_outline,
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          const AppTextField(
            label: 'Peso (kg)',
            helperText: 'Con un decimal, por ejemplo 72.4',
            errorText: 'Ingresá un peso válido',
          ),
          const SizedBox(height: AppDimensions.spaceXl),

          const _SectionTitle('Espaciado'),
          const SizedBox(height: AppDimensions.spaceSm),
          const _SpacingScale(),
          const SizedBox(height: AppDimensions.spaceXl),
        ],
      ),
    );
  }
}

void _noop() {}

const List<({String name, Color color})> _swatches = [
  (name: 'primary', color: AppColors.primary),
  (name: 'primaryContainer', color: AppColors.primaryContainer),
  (name: 'green300', color: AppColors.green300),
  (name: 'accent', color: AppColors.accent),
  (name: 'accentContainer', color: AppColors.accentContainer),
  (name: 'success', color: AppColors.success),
  (name: 'warning', color: AppColors.warning),
  (name: 'error', color: AppColors.error),
  (name: 'info', color: AppColors.info),
  (name: 'neutral50', color: AppColors.neutral50),
  (name: 'neutral200', color: AppColors.neutral200),
  (name: 'neutral500', color: AppColors.neutral500),
  (name: 'neutral700', color: AppColors.neutral700),
  (name: 'neutral900', color: AppColors.neutral900),
];

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.headlineSmall);
  }
}

class _PaletteGrid extends StatelessWidget {
  const _PaletteGrid({required this.swatches});

  final List<({String name, Color color})> swatches;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Wrap(
      spacing: AppDimensions.spaceSm,
      runSpacing: AppDimensions.spaceSm,
      children: [
        for (final swatch in swatches)
          SizedBox(
            width: 104,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: swatch.color,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    border: Border.all(color: AppColors.neutral200),
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceXs),
                Text(swatch.name, style: textTheme.labelSmall),
                Text(_hex(swatch.color), style: textTheme.bodySmall),
              ],
            ),
          ),
      ],
    );
  }

  String _hex(Color color) {
    final argb = color.toARGB32().toRadixString(16).padLeft(8, '0');
    return '#${argb.substring(2).toUpperCase()}';
  }
}

class _SpacingScale extends StatelessWidget {
  const _SpacingScale();

  static const List<({String name, double value})> _steps = [
    (name: 'xs', value: AppDimensions.spaceXs),
    (name: 'sm', value: AppDimensions.spaceSm),
    (name: 'md', value: AppDimensions.spaceMd),
    (name: 'lg', value: AppDimensions.spaceLg),
    (name: 'xl', value: AppDimensions.spaceXl),
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        for (final step in _steps)
          Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.spaceSm),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Text(step.name, style: textTheme.labelMedium),
                ),
                Container(
                  width: step.value * 4,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.green200,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  ),
                ),
                const SizedBox(width: AppDimensions.spaceSm),
                Text('${step.value.toInt()}px', style: textTheme.bodySmall),
              ],
            ),
          ),
      ],
    );
  }
}
