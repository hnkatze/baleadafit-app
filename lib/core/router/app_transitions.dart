import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Page for a route inside the shell: a short fade with a 12 px rise.
///
/// Builds a [NoTransitionPage] when the system asks for less motion.
Page<T> shellPage<T>(BuildContext context, GoRouterState state, Widget child) {
  return _page<T>(
    context,
    state,
    child,
    duration: const Duration(milliseconds: 220),
    rise: 12,
  );
}

/// Page for a full-screen form that covers the shell: fade with a 24 px rise.
///
/// Keeps `fullscreenDialog` semantics like the `MaterialPage` it replaces, and
/// builds a [NoTransitionPage] when the system asks for less motion.
Page<T> formPage<T>(BuildContext context, GoRouterState state, Widget child) {
  return _page<T>(
    context,
    state,
    child,
    duration: const Duration(milliseconds: 260),
    rise: 24,
    fullscreenDialog: true,
  );
}

Page<T> _page<T>(
  BuildContext context,
  GoRouterState state,
  Widget child, {
  required Duration duration,
  required double rise,
  bool fullscreenDialog = false,
}) {
  if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
    return NoTransitionPage<T>(key: state.pageKey, child: child);
  }
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    fullscreenDialog: fullscreenDialog,
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      // SlideTransition works in fractions of the child, so the rise in
      // logical pixels is divided by the height the page is laid out with.
      return LayoutBuilder(
        builder: (context, constraints) {
          final height = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : MediaQuery.sizeOf(context).height;
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset(0, rise / height),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      );
    },
  );
}
