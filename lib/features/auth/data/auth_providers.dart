import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/auth_interceptor.dart';
import 'auth_gateway.dart';
import 'auth_repository.dart';

/// Firebase Auth singleton.
final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

/// Bearer token source for API calls: the auth gateway also issues tokens.
final tokenSourceProvider = Provider<TokenSource>(
  (ref) => ref.watch(authGatewayProvider),
);

/// HTTP client for the BaleadaFit API.
///
/// Reads the base URL lazily: a build without `API_BASE_URL` fails on first use
/// with [EnvException] instead of at startup, so the app still opens.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
    ),
  );
  dio.interceptors.add(
    AuthInterceptor(ref.watch(tokenSourceProvider), baseUrl: Env.apiBaseUrl),
  );
  return dio;
});

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(ref.watch(dioProvider)),
);

final authGatewayProvider = Provider<AuthGateway>(
  (ref) => FirebaseAuthGateway(
    ref.watch(firebaseAuthProvider),
    googleServerClientId: Env.googleServerClientId,
  ),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(authGatewayProvider),
    ref.watch(apiClientProvider),
  ),
);
