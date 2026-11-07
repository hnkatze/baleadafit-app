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
| T1 | S1 | Descargar las 6 pantallas MOBILE de Stitch a `odd/designs/mobile/` + índice que mapea id de Stitch → archivo → qué dibuja | inline | `8dcba98` chore(design): import the stitch mobile screens as reference |
| T2 | S2 | Tokens: adoptar el design system de Stitch ("Clinical Mint Precision"), Plus Jakarta Sans y las alturas del mockup | inline | `2922fd3` feat(theme): adopt the clinical mint tokens and the brand fonts |
| T3 | S2 | Componentes compartidos que exige el login (text field con label arriba, botón tonal, emblema, pill, divisor) + tests | inline (el worker falló por auth) | `749f369` feat(shared): add the components the mobile login needs |
| T4 | S3, S6 | Capa de datos: `AuthRepository` (Firebase Auth email/password + Google), `Dio` con interceptor Bearer, modelo de `GET /auth/me`, errores tipados + tests | inline (el worker falló por auth) | `599a3ef` feat(auth): read the session from the api with a firebase id token |
| T5 | S3, S6 | Pantalla de login según el diseño: estados loading/error, validación, sin navegación en fallo | inline | `38633fe` feat(auth): sign in from the mobile design and route by role |
| T6 | S3 | Sesión en Riverpod + redirect por `rol` en el router y logout | inline | `38633fe` feat(auth): sign in from the mobile design and route by role |
| T7 | S7 | `flutter analyze`, `flutter test`, build de Android, prueba real con credenciales, verificación independiente | inline | en curso |

## Log

**L1 (usuario, verbatim):** "tenemos algunos disenos en stich para la version mobile, podemos traerlos, dejarlos en odd para ya tener lo que vamos a dibujar, y empezamos a hacer componentes y el login, ya tenemos credenciales entonces podemos ir probando"

**L2 (evidencia):** Proyecto Stitch `projects/15920435902002365733` ("BaleadaFit Nutrition Portal"), design system "Clinical Mint Precision". Pantallas MOBILE: Acceso Clínico - Login Mobile (`4c993085…`), Inicio Clínico - Mobile (`56ff95ba…`), Directorio de Pacientes - Mobile (`5eaed93b…`), Agenda de Citas - Mobile (`28bcf179…`), Diseñador de Dietas HN - Mobile (`c0985fe9…`), Catálogo Alimentos TCA-HN - Mobile (`c217a171…`).

**L3 (evidencia):** API viva `https://api-pro.baleadafit.com` sin `AUTH_DEV_BYPASS` (`Bearer dev:…` responde 401), así que la prueba real necesita un usuario Firebase. `GET /auth/me` responde 401 `NO_AUTENTICADO` sin token.

**L4 (decisión del usuario):** el diseño manda sobre la paleta existente — se adopta "Clinical Mint Precision" y Plus Jakarta Sans.

**L5 (decisión del usuario):** Google Sign-In entra en esta entrega, no queda como pendiente.

**L6 (decisión del usuario):** la prueba con credenciales reales la hace el usuario en el simulador; los tests automáticos usan un auth falso.

**L7 (evidencia — desvío técnico de L4):** `google_fonts` con descarga en runtime revienta la suite (con `allowRuntimeFetching = false` lanza si la fuente no está en assets) y deja la app sin tipografía en el primer arranque sin red. Se mantiene `google_fonts` pero con las fuentes **empaquetadas** en `assets/fonts/`: mismo paquete, sin red, tests herméticos.

**L8 (evidencia — copy del mockup):** el login de Stitch incluye "Cifrado HIPAA & Conexión Segura HL7/FHIR" y "Sistema Homologado". No hay certificación que sostenga esas afirmaciones, así que no se copian literalmente: el pie queda en copyright y verificación de conexión, y la afirmación regulatoria se deja fuera hasta que exista.

**L9 (evidencia — delegación caída):** los dos `gentle-ai-worker` fallaron con `assistant reported an error (auth)` sin escribir nada, así que T3 y T4 se hicieron inline. Los tests de esos dos units se escribieron después del código (no hubo RED observado) por esa razón; el resto de units sí se probaron contra tests que fallaban antes.

**L10 (evidencia — verificación):** `flutter analyze` sin issues y `flutter test` 74 pass + 1 skip (el skip es el test de `--dart-define`, se corre con `make test-defines`). Pendiente: build de Android y la prueba con credenciales reales en el simulador, que hace el usuario.
