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
| T5 | S7 | Tests de las tres capas antes de implementarlas | hecho: 96 pasan, 1 skip |

## Log

**L1 (usuario, verbatim):** "ya merged, con que seguiriamos, podriamos ir por el home, tenemos datos en el api, una cosa, nose si valdria la pena que construuyamos un api services, que maneje las peticiones, con el manejo de errores y eso del api ya que el apo tiene un wrapper, de esa forma en los servicios de los features solo pedimos el metodo y el objeto que esperamos, y asi ese servicio global maneja los errores, seria cool, nose que patron estamos usando, pero siempre repositorios y esas cosas pls, igual riverpood, siempre tambien, codigo limpio siempre y tdd y odd, claros ahi creo"

**L2 (evidencia):** `GET /dashboard` devuelve `{pacientesActivos: number, planesEnBorrador: number, citasHoy: CitaEntity[]}`; cada cita trae `id`, `fechaHora`, `duracionMin`, `motivo`, `estado` y `paciente {id, nombre, apellido, telefono}`. El endpoint ya excluye las canceladas.

**L3 (decisión de arquitectura):** `ApiClient` es la capa única (S3). Se le agrega decodificación genérica en vez de crear un servicio nuevo.

**L4 (evidencia, dispositivo):** en el iPhone la home muestra "Hola, Lic. Camilo Henriquez", `pacientesActivos: 2`, `planesEnBorrador: 0` y cero citas hoy, leídos de `GET /dashboard` con el token real. La primera captura mostró las tarjetas KPI con alturas distintas (la etiqueta "Planes en borrador" ocupa dos líneas); se corrigió con `IntrinsicHeight` + `stretch` y se volvió a verificar en el dispositivo.

**L5 (decisión, Riverpod 3):** los providers reintentan solos un future fallido. Se desactivó para el home (`retry: (_, _) => null`) porque la pantalla muestra el error con un botón "Reintentar" y un reintento silencioso escondería el fallo.

**L6 (tamaño):** el commit del home son 653 líneas con tests y documento; el código de producción son ~350.
