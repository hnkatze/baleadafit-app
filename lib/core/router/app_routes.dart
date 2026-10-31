/// Every location the router knows about.
///
/// Screens and tests use these constants instead of string literals, so a
/// renamed path breaks the build instead of failing at navigation time.
abstract final class AppRoutes {
  /// Entry point of the app: the app is auth-gated, so the first screen is the
  /// login form until the session redirect lands (issue #4).
  static const String login = '/login';

  /// Patient or nutritionist dashboard once the session is resolved.
  static const String home = '/home';

  /// Design-system gallery. Development aid, not part of the product flow.
  static const String showcase = '/showcase';
}
