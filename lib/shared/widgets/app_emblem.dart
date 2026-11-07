import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';

/// The brand mark: a crescent (the folded baleada) crossed by a clinical pulse.
///
/// Drawn as a vector so it stays crisp at every size and needs no image asset.
/// Geometry comes from the reference mark in `odd/designs/brand/`.
class AppEmblem extends StatelessWidget {
  const AppEmblem({
    this.size = 56,
    this.background,
    this.stroke,
    this.accent,
    super.key,
  });

  final double size;

  /// When set, the mark sits on a rounded square of this color and the crescent
  /// switches to the on-primary color for contrast.
  final Color? background;
  final Color? stroke;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final background = this.background;
    final strokeColor =
        stroke ?? (background != null ? colorScheme.onPrimary : colorScheme.primary);
    final accentColor = accent ?? AppColors.primaryFixedDim;

    final painter = CustomPaint(
      painter: _EmblemPainter(stroke: strokeColor, accent: accentColor),
    );

    if (background == null) {
      return SizedBox.square(dimension: size, child: painter);
    }

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.18),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: painter,
    );
  }
}

class _EmblemPainter extends CustomPainter {
  const _EmblemPainter({required this.stroke, required this.accent});

  final Color stroke;
  final Color accent;

  /// Stroke weight of the reference mark inside its 400x400 viewBox.
  ///
  /// The reference draws at 12/400, which reads as a hairline at the 56pt the
  /// screens use, so the app draws it heavier to keep the mark legible.
  static const double _viewBox = 400;
  static const double _strokeWidth = 17;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / _viewBox;
    canvas.save();
    canvas.scale(scale);
    canvas.translate(_viewBox / 2, _viewBox / 2);

    final arc = Path()
      ..moveTo(-90, -10)
      ..cubicTo(-90, -75, 90, -75, 90, -10)
      ..cubicTo(90, 50, -90, 50, -90, -10)
      ..close();

    canvas.drawPath(
      arc,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final pulse = Path()
      ..moveTo(-65, -10)
      ..lineTo(-25, -10)
      ..lineTo(-10, -42)
      ..lineTo(10, 24)
      ..lineTo(25, -10)
      ..lineTo(65, -10);

    canvas.drawPath(
      pulse,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(_EmblemPainter oldDelegate) =>
      oldDelegate.stroke != stroke || oldDelegate.accent != accent;
}
