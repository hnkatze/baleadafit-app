# BaleadaFit

App móvil de nutrición para pacientes y nutricionistas. Flutter, solo iOS y
Android.

## Stack

| Área | Paquete |
|---|---|
| Navegación | `go_router` |
| Estado | `flutter_riverpod` |
| HTTP | `dio` |
| Modelos tipados | `json_annotation` + `json_serializable` + `build_runner` |
| Auth y backend | `firebase_core` + `firebase_auth` |

## Estructura

```
lib/
├── main.dart                     # arranque: Firebase + ProviderScope
├── app.dart                      # MaterialApp.router, tema global y router
├── core/                         # compartido, sin lógica de negocio
│   ├── config/env.dart           # lectura de los --dart-define
│   ├── router/                   # rutas y GoRouter
│   │   ├── app_routes.dart       # constantes de location
│   │   └── app_router.dart       # createAppRouter + routerProvider
│   └── theme/                    # tokens de diseño
│       ├── app_colors.dart       # paleta
│       ├── app_dimensions.dart   # espaciado, radios, alturas
│       ├── app_typography.dart   # escala tipográfica
│       └── app_theme.dart        # ThemeData de la app
├── shared/widgets/               # componentes base reutilizables
│   ├── app_button.dart
│   ├── app_card.dart
│   └── app_text_field.dart
└── features/<feature>/
    ├── data/                     # repositorios y servicios
    └── ui/                       # pantallas, widgets y notifiers
```

Features actuales: `auth` (formulario de login, sin lógica todavía), `home`
(placeholder del panel) y `showcase` (galería del design system).

## Navegación

`go_router` con las rutas declaradas en `AppRoutes` y un único router expuesto
por `routerProvider` (Riverpod). `MaterialApp.router` lo consume, así que un
provider de sesión puede reconstruirlo sin tocar `lib/app.dart`.

| Ruta | Pantalla | Estado |
|---|---|---|
| `/login` | `features/auth/ui/login_screen.dart` | entrada de la app |
| `/home` | `features/home/ui/home_screen.dart` | placeholder |
| `/showcase` | `features/showcase/ui/theme_gallery_screen.dart` | galería, herramienta de desarrollo |

Cualquier otra location cae en `NotFoundScreen`, que muestra la ruta pedida.
El redirect por sesión y por rol llega con el issue #4; hasta entonces la app
arranca siempre en `/login`.

Regla: las pantallas nunca hardcodean colores, tamaños ni estilos. Todo sale de
`Theme.of(context)` y de `AppDimensions`.

## Configuración

La configuración entra en tiempo de compilación con `--dart-define-from-file`
(no hay assets ni `rootBundle`). El único archivo versionado es la plantilla
`config/env.example.json`:

```json
{
  "APP_ENV": "dev",
  "API_BASE_URL": "https://api-pro.baleadafit.com"
}
```

Los archivos reales (`config/env.dev.json`, `config/env.pro.json`) están en
`.gitignore`; creá el tuyo con `make setup` (copia la plantilla) y editá los
valores. `Env` (`lib/core/config/env.dart`) es el único lector:
`Env.environment`, `Env.hasApiBaseUrl` y `Env.apiBaseUrl`, que lanza
`EnvException` si el define falta o está vacío.

Un define ausente no falla: llega como string vacío. Por eso todos los comandos
del `Makefile` pasan `--dart-define-from-file`, y `Env.apiBaseUrl` explota en
vez de devolver `""`. Si corrés `flutter` a mano, acordate del flag:

```bash
flutter run --dart-define-from-file=config/env.dev.json
```

Nunca pongas credenciales, tokens ni claves privadas en `config/*.json`.

## Archivos de Google (no versionados)

Estos archivos son configuración de cliente por desarrollador/integración y no
se commitean. Se regeneran con:

```bash
flutterfire configure --project=baleadafit --platforms=android,ios
```

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `lib/firebase_options.dart`

Un clon nuevo **no compila** hasta correr ese comando (o copiar los archivos
que te pasen por un canal privado). Verificá que sigan en `.gitignore` antes de
agregar nada: `git status` no debe listarlos.

## Comandos

```bash
flutter pub get
make setup                   # crea config/env.dev.json desde la plantilla
make analyze                 # flutter analyze
make test                    # flutter test
make run                     # flutter run con el env file
make build-apk
make build-ios               # --no-codesign
```

`make test-defines` corre los tests con un `--dart-define` real para probar el
camino de configuración compilada.

Para modelos con `json_serializable`:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Autenticación

El login es por Firebase Auth (correo + contraseña, o Google) y el rol lo
decide la API, nunca la app: después de iniciar sesión se llama
`GET /auth/me` con el ID token y la respuesta (`nutricionista`, `paciente` o
`sin_perfil`) define a dónde navega el router. Sin sesión, cualquier ruta
distinta de `/login` vuelve al login.

Capas: `features/auth/data` (gateway de Firebase, repositorio, fallos con
mensaje en español), `features/auth/application` (estado de sesión y reglas de
redirección) y `features/auth/ui` (pantalla). Los tests no tocan plugins: usan
`AuthGateway` y un adaptador HTTP falsos.

### Google Sign-In

Los botones y el flujo ya están implementados, pero el proveedor tiene que
existir en el proyecto de Firebase:

1. Firebase console → Authentication → Sign-in method → habilitar **Google**.
2. Android: registrar la huella **SHA-1** del keystore de debug y de release
   (`cd android && ./gradlew signingReport`), y volver a bajar
   `google-services.json`.
3. Copiar el **Web client ID** (el OAuth client de tipo web del proyecto) en
   `config/env.dev.json` como `GOOGLE_SERVER_CLIENT_ID`. Android lo necesita para
   devolver un `idToken`; ese archivo no se versiona.
4. iOS: agregar el `REVERSED_CLIENT_ID` de `GoogleService-Info.plist` como URL
   scheme en `ios/Runner/Info.plist`. Ese valor tampoco se versiona: se agrega
   localmente.

## Diseños

Las seis pantallas mobile con las que se dibuja la app están en
`odd/designs/mobile/` (HTML exportado de Stitch, más el design system en
`stitch-design-system.json`) y las marcas en `odd/designs/brand/`. El documento
de la feature, con specs y tareas, vive en `odd/tasks/`.

## Design system

`lib/features/showcase/ui/theme_gallery_screen.dart` renderiza la paleta, la
escala tipográfica y los componentes base. Se abre desde home en `/showcase` y
no forma parte del flujo del producto.

Los tokens son los del design system **Clinical Mint Precision** con el que
están dibujadas las pantallas: primario `#006C49`, contenedor primario
`#10B981`, superficie `#F9F9FF`, texto `#111C2D`, borde `#6C7A71`, y semánticos
de error `#BA1A1A`. La tipografía es **Plus Jakarta Sans** (display 800,
headlines 700/600, body 400) y los números clínicos usan **JetBrains Mono**;
ambas se empaquetan en `assets/fonts/` para que la app no dependa de la red y
los tests no descarguen nada.
