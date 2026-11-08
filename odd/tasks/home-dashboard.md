# Home con datos reales

Dashboard de la nutricionista alimentado por `GET /dashboard`, más la capa HTTP tipada que pide cada feature.
Branch `feat/home-dashboard`. Route: inline.

## Specs

**S1 — Home con datos de la API.** La pantalla de inicio muestra lo que devuelve `GET /dashboard`: `pacientesActivos`, `planesEnBorrador` y `citasHoy`. Texto del usuario: "podriamos ir por el home, tenemos datos en el api".

**S2 — Una sola capa HTTP, tipada.** Se pide el método y el tipo esperado; el transporte, el sobre de la API y el mapeo de errores viven en un solo lugar. Texto: "que construyamos un api services, que maneje las peticiones, con el manejo de errores y eso del api ya que el api tiene un wrapper, de esa forma en los servicios de los features solo pedimos el metodo y el objeto que esperamos".

**S3 — Sin capa duplicada.** No se agrega un segundo "servicio global" encima de `ApiClient`: ya es esa capa. Un wrapper nuevo duplicaría el manejo de errores y obligaría a testear dos veces lo mismo.

**S4 — Repositorios por feature.** Cada feature expone un repositorio que devuelve modelos de dominio. Texto: "siempre repositorios y esas cosas pls".

**S5 — Riverpod siempre.** El estado de la pantalla se lee de providers, con overrides en tests. Texto: "igual riverpood, siempre tambien".

**S6 — Código limpio.** Nombres en inglés, comentarios solo donde explican el porqué, sin números mágicos.

**S7 — TDD.** Test que falla primero, después la implementación.

**S8 — ODD.** Este documento, la lista de tareas y commits por unidad de trabajo.

**S9 — No inventar datos.** El mockup muestra InBody BLE, bot de WhatsApp, adherencia 94.2% y "8 citas programadas"; la API no expone nada de eso, así que no se dibuja. Igual criterio que en `odd/tasks/app-shell.md`.

## Tasks

| ID | Spec | Qué | Estado |
|----|------|-----|--------|
| T1 | S2, S3 | `ApiClient.get<T>` genérico con `fromJson`; `AuthRepository` pasa a usarlo | hecho (6561757) |
| T2 | S1, S4 | Modelos de `/dashboard` con `json_serializable` + `DashboardRepository` | hecho (6561757) |
| T3 | S5 | Providers del repositorio y del resumen (`AsyncValue` para loading/error/data) | hecho (6561757) |
| T4 | S1, S6, S9 | Home con saludo de la sesión, KPIs y citas de hoy; estados de carga, error con reintento y vacío | hecho (6561757 + fix de alturas) |
| T5 | S7 | Tests de las tres capas antes de implementarlas | hecho |
| T6 | S1, S6 | KPIs como franja con divisores (una superficie, sin cajas con hueco) | hecho, sin commit |
| T7 | S1 | Tarjeta de "Próxima cita" derivada de `citasHoy` | hecho, sin commit |
| T8 | S2 | `ApiClient.getPaged` + `PageMeta`: los endpoints de lista traen `data` como array y `meta` | hecho, sin commit |
| T9 | S1, S4 | Sección "Tus pacientes" con `GET /pacientes?limit=4` (peso y plan de cada uno) | hecho, sin commit |
| T10 | S6 | Fuentes empaquetadas de verdad: declaradas en `pubspec.yaml` como `fonts`, tema sin `google_fonts` | hecho, sin commit |
| T11 | — | Citas ficticias creadas en la API para ver la pantalla con datos | hecho (4 citas) |
| T12 | — | `odd/designs/home-context.md` y `odd/designs/design-system.md` | hecho |

## Log

**L1 (usuario, verbatim):** "ya merged, con que seguiriamos, podriamos ir por el home, tenemos datos en el api, una cosa, nose si valdria la pena que construuyamos un api services, que maneje las peticiones, con el manejo de errores y eso del api ya que el apo tiene un wrapper, de esa forma en los servicios de los features solo pedimos el metodo y el objeto que esperamos, y asi ese servicio global maneja los errores, seria cool, nose que patron estamos usando, pero siempre repositorios y esas cosas pls, igual riverpood, siempre tambien, codigo limpio siempre y tdd y odd, claros ahi creo"

**L2 (evidencia):** `GET /dashboard` devuelve `{pacientesActivos: number, planesEnBorrador: number, citasHoy: CitaEntity[]}`; cada cita trae `id`, `fechaHora`, `duracionMin`, `motivo`, `estado` y `paciente {id, nombre, apellido, telefono}`. El endpoint ya excluye las canceladas.

**L3 (decisión de arquitectura):** `ApiClient` es la capa única (S3). Se le agrega decodificación genérica en vez de crear un servicio nuevo.

**L4 (evidencia, dispositivo):** en el iPhone la home muestra "Hola, Lic. Camilo Henriquez", `pacientesActivos: 2`, `planesEnBorrador: 0` y cero citas hoy, leídos de `GET /dashboard` con el token real. La primera captura mostró las tarjetas KPI con alturas distintas (la etiqueta "Planes en borrador" ocupa dos líneas); se corrigió con `IntrinsicHeight` + `stretch` y se volvió a verificar en el dispositivo.

**L5 (decisión, Riverpod 3):** los providers reintentan solos un future fallido. Se desactivó para el home (`retry: (_, _) => null`) porque la pantalla muestra el error con un botón "Reintentar" y un reintento silencioso escondería el fallo.

**L6 (tamaño):** el commit del home son 653 líneas con tests y documento; el código de producción son ~350.

**L7 (evidencia con la cuenta real, `playercamiloh504@gmail.com`):** `GET /dashboard` devuelve `{pacientesActivos: 2, planesEnBorrador: 0, citasHoy: []}` y nada más; `GET /citas` está vacío. `GET /pacientes` trae por paciente `ultimaMedicion` (peso, %grasa, talla, fecha) y `planActivo`. La data rica existe, pero **fuera** de `/dashboard`.

**L8 (defecto encontrado):** los endpoints de lista responden `{ok, data: [...], meta: {limit, offset, total, hasMore, nextCursor}}`. `ApiClient` solo aceptaba `data` como objeto y descartaba `meta`, así que ninguna lista podía leerse. Se agregó `getPaged` + `PageMeta`/`Paged`.

**L9 (criterio de diseño del usuario):** "creo que tenemos que tener cierto criterio al momento de disenar aunque tenemos un diseno, mira las cards, tiene un enorme espacio a la derecha... tenemos el icono, el valor y pacientes activos, uno debajo del otro... es un poco grosero". Se reemplazaron las tres cajas por una franja única con divisores y valores que se ajustan (`FittedBox`), sin íconos decorativos.

**L10 (decisión):** la home hace **dos** llamadas (`/dashboard` y `/pacientes?limit=4`), no N. La adherencia global y el "seguimiento prioritario" del mockup no existen como consulta: si se quieren, se piden como endpoint nuevo en el repo del API.

**L11 (regla del usuario):** "los commits y los push cuando yo pruebe y yo determine que está listo el cambio". Nada de commit ni push hasta su validación; los cambios quedan en el working tree.

**L12 (defecto de fuentes):** los `.ttf` estaban en `assets/fonts/` pero declarados como `assets`, no como `fonts`, y el tema seguía usando `GoogleFonts`, que descarga en runtime. En tests y sin red se caía a la fuente del sistema. Se declararon las familias (`PlusJakartaSans` 400/600/700/800 y `JetBrainsMono` 500) y el tema ya no depende de `google_fonts`. Efecto colateral: con la fuente real el login creció y un test tocaba un botón fuera del viewport; se corrigió con `ensureVisible` (era un defecto latente del test, no del layout).

**L13 (datos de prueba):** `POST /citas` responde 201 con `estado: "PROGRAMADA"`. Se crearon cuatro citas (dos con fecha del 7/11 y dos del 6/11). Solo las del 7 aparecen en `citasHoy`, porque el servidor corta "hoy" en UTC: una cita local del 6 a las 20:00 cae en el 7 UTC. Anotado como pregunta abierta en `home-context.md`.

**L14 (documentos de diseño):** `odd/designs/home-context.md` describe datos reales, estados, restricciones y dónde el mock tiene margen; `odd/designs/design-system.md` documenta tokens, componentes, anti-patrones y gaps. El usuario pasa el mockup después.
