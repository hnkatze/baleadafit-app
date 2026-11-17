import 'package:flutter/material.dart';

/// Pull-to-refresh wrapper in the brand colour.
///
/// It only wraps [child] in a [RefreshIndicator]; the scrollable belongs to the
/// screen. Two rules cannot be enforced here, so each screen must respect them:
///
/// * The wrapped scrollable needs
///   `physics: const AlwaysScrollableScrollPhysics()`. Without it a list that
///   fits the viewport does not scroll, and the gesture dies exactly on the
///   empty screens where it matters most.
/// * [onRefresh] must complete when the **data is fresh**, not when the
///   invalidation was dispatched. Await the new value
///   (`await ref.refresh(xProvider.future)`); never return after a bare
///   `ref.invalidate`, or the spinner vanishes while the request is in flight.
class AppRefresh extends StatelessWidget {
  const AppRefresh({super.key, required this.onRefresh, required this.child});

  /// Reloads what [child] draws; the spinner lasts until it completes.
  final Future<void> Function() onRefresh;

  /// The screen's scrollable.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: colors.primary,
      backgroundColor: colors.surface,
      child: child,
    );
  }
}
