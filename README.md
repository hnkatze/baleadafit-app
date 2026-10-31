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
├── main.dart                     # arranque: Env + Firebase + ProviderScope
├── app.dart                      # MaterialApp, tema global y home
├── core/                         # compartido, sin lógica de negocio
│   ├── config/env.dart           # lectura de config/env.json
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

`config/env.json` es un asset versionado, sin secretos, con la configuración
por entorno:

```json
{
  "APP_ENV": "dev",
  "API_BASE_URL": ""
}
```

Se lee con `Env` (`lib/core/config/env.dart`): `Env.apiBaseUrl` lanza
`EnvException` con un mensaje claro si el valor está vacío. Nunca pongas
credenciales, tokens ni claves privadas en ese archivo.

Firebase está configurado para Android e iOS con
`flutterfire configure --project=baleadafit --platforms=android,ios`. Regenerá
los archivos con ese mismo comando si cambia el proyecto.

## Comandos

```bash
flutter pub get
flutter analyze
flutter test
flutter run                  # elegí un dispositivo iOS o Android
flutter build apk --debug
flutter build ipa            # requiere firma
```

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
