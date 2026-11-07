import 'package:flutter/material.dart';

import '../../core/theme/app_dimensions.dart';

/// Small rounded label used for institutional tags and status hints.
///
/// Optionally shows a leading dot (statically or pulsing) or an icon.
class AppPill extends StatefulWidget {
  const AppPill({
    required this.label,
    this.dotColor,
    this.icon,
    this.pulse = false,
    super.key,
  });

  final String label;

  /// Colors the 8pt leading dot. No dot is drawn when both [dotColor] and
  /// [icon] are null.
  final Color? dotColor;
  final IconData? icon;

  /// Makes the dot breathe, to signal a live/active state.
  final bool pulse;

  @override
  State<AppPill> createState() => _AppPillState();
}

class _AppPillState extends State<AppPill> with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.pulse) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1400),
      )..repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AppPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulse && _controller == null) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1400),
      )..repeat(reverse: true);
    } else if (!widget.pulse && _controller != null) {
      _controller!.dispose();
      _controller = null;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dotColor = widget.dotColor;
    final icon = widget.icon;

    final leading = icon != null
        ? Icon(
            icon,
            size: AppDimensions.iconSm,
            color: colorScheme.primary,
          )
        : dotColor != null
        ? _Dot(color: dotColor, controller: _controller)
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceMd - 4,
        vertical: AppDimensions.spaceXs,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[
            leading,
            const SizedBox(width: AppDimensions.spaceSm - 2),
          ],
          Flexible(
            child: Text(
              widget.label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, this.controller});

  final Color color;
  final AnimationController? controller;

  @override
  Widget build(BuildContext context) {
    final dot = SizedBox.square(
      dimension: AppDimensions.spaceSm,
      child: DecoratedBox(
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
    final controller = this.controller;

    if (controller == null || MediaQuery.maybeDisableAnimationsOf(context) == true) {
      return dot;
    }

    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0.35).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      ),
      child: dot,
    );
  }
}
