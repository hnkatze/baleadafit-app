import 'package:baleadafit/core/theme/app_theme.dart';
import 'package:baleadafit/features/auth/application/session_controller.dart';
import 'package:baleadafit/features/auth/data/auth_gateway.dart';
import 'package:baleadafit/features/auth/data/auth_providers.dart';
import 'package:baleadafit/features/auth/data/user_role.dart';
import 'package:baleadafit/features/auth/ui/login_screen.dart';
import 'package:baleadafit/shared/widgets/app_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_http_adapter.dart';
import '../../../support/pump.dart';

class _FakeGateway implements AuthGateway {
  _FakeGateway({this.token = 'token-1', this.signInError});

  String? token;
  Object? signInError;
  int emailCalls = 0;
  int googleCalls = 0;

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    emailCalls++;
    if (signInError != null) throw signInError!;
  }

  @override
  Future<void> signInWithGoogle() async {
    googleCalls++;
    if (signInError != null) throw signInError!;
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<String?> idToken({bool forceRefresh = false}) async => token;
}

Map<String, Object?> _me(String rol) => {
  'ok': true,
  'data': {
    'rol': rol,
    'perfil': {'nombre': 'Sofía Herrera'},
  },
};

final _submit = find.widgetWithText(AppButton, 'Ingresar a mi Consultorio');

Future<ProviderContainer> _pumpLogin(
  WidgetTester tester, {
  required _FakeGateway gateway,
  required FakeHttpAdapter adapter,
}) async {
  late ProviderContainer container;

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authGatewayProvider.overrideWithValue(gateway),
        dioProvider.overrideWithValue(dioWith(adapter)),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) {
            container = ProviderScope.containerOf(context);
            return const LoginScreen();
          },
        ),
      ),
    ),
  );
  await pumpStable(tester);
  return container;
}

void main() {
  testWidgets('renders the copy of the mobile design', (tester) async {
    await _pumpLogin(
      tester,
      gateway: _FakeGateway(token: null),
      adapter: FakeHttpAdapter((_) async => jsonBody(_me('nutricionista'))),
    );

    expect(find.text('Acceso Clínico Profesional'), findsOneWidget);
    expect(find.text('PORTAL CLÍNICO · ESPECIALISTAS HN'), findsOneWidget);
    expect(find.text('Correo electrónico'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(_submit, findsOneWidget);
    expect(find.text('Continuar con Google'), findsOneWidget);
  });

  testWidgets('rejects an empty form without calling the API', (tester) async {
    final gateway = _FakeGateway(token: null);
    final adapter = FakeHttpAdapter((_) async => jsonBody(_me('nutricionista')));

    await _pumpLogin(tester, gateway: gateway, adapter: adapter);
    await tester.tap(_submit);
    await pumpStable(tester);

    expect(find.text('Escribí tu correo.'), findsOneWidget);
    expect(find.text('Escribí tu contraseña.'), findsOneWidget);
    expect(gateway.emailCalls, 0);
    expect(adapter.requests, isEmpty);
  });

  testWidgets('rejects a malformed email', (tester) async {
    await _pumpLogin(
      tester,
      gateway: _FakeGateway(token: null),
      adapter: FakeHttpAdapter((_) async => jsonBody(_me('nutricionista'))),
    );

    await tester.enterText(
      find.byType(TextFormField).first,
      'sofia.sindominio',
    );
    await tester.tap(_submit);
    await pumpStable(tester);

    expect(find.textContaining('Revisá el correo'), findsOneWidget);
  });

  testWidgets('shows the message of a rejected sign-in and stays put', (
    tester,
  ) async {
    final gateway = _FakeGateway(
      token: null,
      signInError: FirebaseAuthException(code: 'wrong-password'),
    );

    final container = await _pumpLogin(
      tester,
      gateway: gateway,
      adapter: FakeHttpAdapter((_) async => jsonBody(_me('nutricionista'))),
    );

    await tester.enterText(find.byType(TextFormField).first, 'sofia@demo.hn');
    await tester.enterText(find.byType(TextFormField).last, 'clave-mala');
    await tester.tap(_submit);
    await pumpStable(tester);

    expect(
      find.text('El correo o la contraseña no son correctos.'),
      findsOneWidget,
    );
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(container.read(sessionControllerProvider).isAuthenticated, isFalse);
  });

  testWidgets('signs in with valid credentials and stores the session', (
    tester,
  ) async {
    final adapter = FakeHttpAdapter(
      (_) async => jsonBody(_me('nutricionista')),
    );

    final gateway = _FakeGateway(token: null);
    final container = await _pumpLogin(
      tester,
      gateway: gateway,
      adapter: adapter,
    );
    // The initial restore found no session; signing in issues the token.
    gateway.token = 'token-1';

    await tester.enterText(find.byType(TextFormField).first, 'sofia@demo.hn');
    await tester.enterText(find.byType(TextFormField).last, 'clave-buena');
    await tester.tap(_submit);
    await pumpStable(tester);

    final state = container.read(sessionControllerProvider);
    expect(state.isAuthenticated, isTrue);
    expect(state.session?.rol, UserRole.nutricionista);
    expect(adapter.requests.single.path, '/auth/me');
  });

  testWidgets('asks the gateway to sign in with Google', (tester) async {
    final gateway = _FakeGateway(token: null);

    final container = await _pumpLogin(
      tester,
      gateway: gateway,
      adapter: FakeHttpAdapter((_) async => jsonBody(_me('paciente'))),
    );
    gateway.token = 'token-1';

    await tester.tap(find.widgetWithText(AppButton, 'Continuar con Google'));
    await pumpStable(tester);

    expect(gateway.googleCalls, 1);
    expect(container.read(sessionControllerProvider).session?.rol,
        UserRole.paciente);
  });

  testWidgets('toggles the password visibility', (tester) async {
    await _pumpLogin(
      tester,
      gateway: _FakeGateway(token: null),
      adapter: FakeHttpAdapter((_) async => jsonBody(_me('paciente'))),
    );

    EditableText passwordField() =>
        tester.widget<EditableText>(find.byType(EditableText).last);

    expect(passwordField().obscureText, isTrue);

    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await pumpStable(tester);

    expect(passwordField().obscureText, isFalse);
  });
}
