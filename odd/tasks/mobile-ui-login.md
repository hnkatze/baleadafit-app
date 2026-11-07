# Mobile UI foundation + login

Feature branch `feat/mobile-login`. Trae los diseños mobile de Stitch al repo, construye los componentes compartidos que definen y deja el login clínico funcionando contra la API real.
Route: inline (parent). High risk: item 2 (security — auth, tokens, session).

## Specs

**S1 — Diseños versionados en `odd/`.** Las pantallas mobile de Stitch viven dentro del repo, en `odd/designs/mobile/`, como referencia de lo que hay que dibujar. Texto del usuario: "podemos traerlos, dejarlos en odd para ya tener lo que vamos a dibujar".

**S2 — Componentes desde esos diseños.** Los widgets compartidos se construyen a partir de lo que muestran esos diseños (botón, campo de texto, card, avatar, chips, etc.). Texto del usuario: "y empezamos a hacer componentes".

**S3 — Login funcional con credenciales reales.** El login de la app autentica contra Firebase Auth (email + contraseña), obtiene el ID token y llama `GET /auth/me` en `https://api-pro.baleadafit.com`; la app navega según el `rol` devuelto. Texto del usuario: "y el login, ya tenemos credenciales entonces podemos ir probando".

**S4 — Ninguna credencial en el repo.** Ni contraseñas ni archivos de servicio se versionan; las credenciales de prueba viven fuera de git. Texto del usuario (regla vigente): "las credenciales y ficheros de google no se van al repo pls".

**S5 — Copy de UI en español, artefactos técnicos en inglés.** El texto visible sigue los diseños (español); código, comentarios, tests y commits en inglés (regla global del proyecto).

**S6 — Errores visibles, nunca silenciosos.** Credenciales inválidas, red caída y `rol` no reconocido muestran un mensaje en la pantalla de login; el botón vuelve a estar habilitado y no se navega.

**S7 — Verificación.** `flutter analyze` sin issues y `flutter test` verde; el camino real se prueba contra la API con credenciales del usuario, y un verificador independiente revisa el manejo de tokens (riesgo: seguridad).

## Tasks

| ID | Spec | Qué | Route | Commit |
|----|------|-----|-------|--------|
| T1 | S1 | Descargar las 6 pantallas MOBILE de Stitch a `odd/designs/mobile/` + índice que mapea id de Stitch → archivo → qué dibuja | inline | `chore(design): import the stitch mobile screens as reference` |
| T2 | S2 | Tokens: contrastar con el design system de Stitch ("Clinical Mint Precision") y completar lo que falte en `lib/core/theme/` | inline | `feat(theme): align tokens with the clinical mint design` |
| T3 | S2 | Componentes compartidos que exige el login + tests de widget | inline | `feat(shared): add the components the mobile login needs` |
| T4 | S3, S6 | Capa de datos: `AuthRepository` (Firebase Auth email/password + ID token), `Dio` con interceptor Bearer, modelo de `GET /auth/me`, errores tipados + tests | inline | `feat(auth): authenticate with firebase and read the role from the api` |
| T5 | S3, S6 | Pantalla de login según el diseño: estados loading/error, validación, sin navegación en fallo | inline | `feat(auth): build the login screen from the mobile design` |
| T6 | S3 | Sesión en Riverpod + redirect por `rol` en el router y logout | inline | `feat(auth): route by role after login and allow signing out` |
| T7 | S7 | `flutter analyze`, `flutter test`, prueba real con credenciales, verificación independiente | inline | `test: verify the login flow end to end` |

## Log

**L1 (usuario, verbatim):** "tenemos algunos disenos en stich para la version mobile, podemos traerlos, dejarlos en odd para ya tener lo que vamos a dibujar, y empezamos a hacer componentes y el login, ya tenemos credenciales entonces podemos ir probando"

**L2 (evidencia):** Proyecto Stitch `projects/15920435902002365733` ("BaleadaFit Nutrition Portal"), design system "Clinical Mint Precision". Pantallas MOBILE: Acceso Clínico - Login Mobile (`4c993085…`), Inicio Clínico - Mobile (`56ff95ba…`), Directorio de Pacientes - Mobile (`5eaed93b…`), Agenda de Citas - Mobile (`28bcf179…`), Diseñador de Dietas HN - Mobile (`c0985fe9…`), Catálogo Alimentos TCA-HN - Mobile (`c217a171…`).

**L3 (evidencia):** API viva `https://api-pro.baleadafit.com` sin `AUTH_DEV_BYPASS` (`Bearer dev:…` responde 401), así que la prueba real necesita un usuario Firebase. `GET /auth/me` responde 401 `NO_AUTENTICADO` sin token.
