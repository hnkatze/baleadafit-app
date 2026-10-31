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
├── app.dart                      # MaterialApp, tema global y home
├── core/                         # compartido, sin lógica de negocio
│   ├── config/env.dart           # lectura de los --dart-define
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

## Design system

`lib/features/showcase/ui/theme_gallery_screen.dart` renderiza la paleta, la
escala tipográfica y los componentes base. Es la pantalla de arranque temporal:
la reemplaza el router cuando aterrice la navegación por rol.

Paleta principal: verde `#168648` (acción, 4.57:1 sobre blanco), verde claro
`#E9F6EE` (contenedores), mango `#F2A63B` (acento), neutros `#F6F9F7` a
`#1C211E`, y semánticos de éxito, advertencia, error e info.
