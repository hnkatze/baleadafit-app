import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Runs before every test file in this suite.
///
/// The binding is initialized and font fetching is disabled, so fonts fall back
/// to the platform family instead of being fetched over the network: the suite
/// stays hermetic and does not depend on connectivity.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  await testMain();
}
