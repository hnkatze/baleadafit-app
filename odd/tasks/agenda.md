# Agenda de citas (BO)

Feature: the nutritionist's agenda in the Flutter app — day view, programar cita,
reprogramar / completar / cancelar, and the SOAP note that lives inside the appointment.
Drawn against the OpenAPI contract (`baleadafit-api`, 49 endpoints, 90 schemas, reindexado
el 2026-11-16) and `odd/designs/agenda-context.md`. **No artboards exist for this module.**

## Specs

**S1 — Alcance.** Solo el BO: `GET /citas`, `POST /citas`, `PATCH /citas/{id}`. El lado
paciente (`GET /me/citas`, `GET /me/hoy`) queda fuera. No se toca el home: sus widgets de
citas son privados de `home_screen.dart` y asumen un solo día, así que la agenda dibuja su
propia línea del día en lugar de extraer la del home (extraerla obligaría a tocar código que
el pedido no menciona).

**S2 — Sin artboards, copy autorada.** No existe tablero para agenda: el artboard de Stitch
que hay es previo al design system. El layout sale de `odd/designs/design-system.md` y de las
convenciones del módulo de pacientes; los widgets de `lib/shared/widgets/` se reusan tal
cual. **Toda etiqueta nueva está marcada `C#` abajo y la valida el humano antes de considerarse
verbatim.**

**S3 — Navegación.** `/agenda` ya está declarada (`app_routes.dart`), ya figura en
`shellRoutes` y ya tiene su entrada en `app_sections.dart` con la etiqueta
`Agenda de citas`. La tarea es reemplazar el `FeaturePlaceholder` de `app_router.dart:171`
por la pantalla real. La sección se resalta en rutas hijas vía `sectionOwnsLocation`. El test
`test/core/router/app_router_test.dart:221` afirma hoy el texto del placeholder: se actualiza
a la pantalla nueva, no se borra.

**S4 — Vista del día, copy.** (C1) Título de la barra: `Agenda de citas` — ya existe en
`app_sections.dart`. (C2) El día se navega con anterior / siguiente / `Hoy`. (C3) Día con
citas: cada cita se dibuja sobre la línea del día dimensionada por `duracionMin`, más una
lista debajo con hora, paciente y motivo. (C4) Día sin citas: `Sin citas este día` con la
acción `Programar cita`. (C5) Carga: spinner. (C6) Fallo: el `mensaje` del `ApiFailure` y un
botón de reintento que invalida el provider.

**S5 — La cita dibujada.** Campos que se muestran: hora local (`fechaHora.toLocal()`,
`HH:mm`), nombre completo (`paciente.nombre` + `paciente.apellido`), `paciente.telefono`,
`motivo`, `duracionMin`, y `estado` como pill: `PROGRAMADA` | `COMPLETADA` | `CANCELADA`.
(C7) `CANCELADA` no se borra: sigue en la lista si el rango la incluye.
(C8) `duracionMin` por defecto es 45 cuando el API no lo manda.

**S6 — Programar (`POST /citas`).** Campos: paciente (buscado con `GET /pacientes`, sin
inventar un selector nuevo), fecha, hora, `duracionMin`, `motivo`, `notas`. (C9) Botón
`Programar cita`. (C10) El 409 por traslape es el único camino de error real: se muestra el
`mensaje` del API y se deja corregir la hora sin perder lo escrito. No hay endpoint de
disponibilidad, así que la UI **no** dibuja huecos libres ni valida choques por su cuenta.

**S7 — Detalle y nota SOAP.** La cita es a la vez evento y nota clínica: cuatro bloques
`Subjetivo` (S), `Objetivo` (O), `Análisis` (A), `Plan` (P) más `Notas` y
`Próxima cita sugerida`. (C11) `proximaCitaSugerida` es **solo fecha**: se lee de sus propios
campos y se envía `YYYY-MM-DD`.

**S8 — Acciones sobre una cita.** Las tres van por el mismo `PATCH /citas/{id}`:
reprogramar (manda `fechaHora`), completar (manda `estado: COMPLETADA` con el SOAP cargado) y
cancelar (manda `estado: CANCELADA`). No hay endpoint aparte para la nota: se guarda con ese
mismo PATCH, así que la respuesta actualizada de la cita es lo que refresca la UI.

**S9 — Fechas.** Los instantes se formatean con `.toLocal()` en el render. Las fechas de
calendario se leen de sus propios campos y **nunca** se convierten a local: el API las guarda
a medianoche UTC y al oeste de Greenwich se vería el día anterior. `desde` y `hasta` viajan
como `YYYY-MM-DD`. El rango del día se calcula en el cliente, porque `GET /citas` no tiene
filtro "hoy" ni orden configurable.

**S10 — No-goals (de `agenda-context.md` §10).** No se dibuja: calendario con huecos libres,
arrastrar para reprogramar, sugerencia de horarios, recordatorios o WhatsApp, confirmación del
paciente, estado "no asistió", totales de ocupación. Tampoco se ofrece más de un `estado` a la
vez ni orden propio: el contrato no lo permite.

**S11 — Tests.** Repositorio con `test/support/fake_http_adapter.dart`; providers con
`overrideWith`; pantalla con `pumpStable`. Cada test de pantalla cubre carga, error, datos y
vacío. El contrato que se prueba es el del API, no el interno.

**S12 — Commits.** Conventional Commits en inglés, sin atribución de IA. Push solo cuando el
humano lo valide en el dispositivo.

## Tasks

| ID | Specs | Tarea | Superficie | Estado |
|----|-------|-------|-----------|--------|
| T1 | S9, S11 | Helpers de fecha compartidos en `lib/core/format/fechas.dart` (extraídos de `alta_paciente_borrador.dart` sin cambiar comportamiento) y `ApiClient.patch<T>` | `lib/core/` | done — 239 tests, comprobación diferencial contra `main`: las tres funciones son idénticas |
| T2 | S1, S5, S9, S11 | `Cita` + `CitasRepository` + providers (día, filtro por estado) | `lib/features/agenda/data/` | done — 15 tests |
| T3 | S3, S4, S5, S10, S11 | Pantalla de agenda del día sobre la ruta existente, con navegación de día y los cuatro estados | `lib/features/agenda/ui/`, `lib/core/router/app_router.dart` | done — 261 tests, router test actualizado |
| T4 | S6, S11 | Formulario de programación con recuperación del 409 | `lib/features/agenda/ui/` | done — 265 tests |
| T5 | S7, S8, S11 | Detalle con nota SOAP y las tres acciones | `lib/features/agenda/ui/` | done — 272 tests, 1 skip preexistente |
| T6 | S12 | Índice de copy en este documento; slices de commit pendientes de la validación en el dispositivo | — | in progress |

## Copy autorada (C#)

No hay artboard de agenda: estas cadenas las escribí yo y **las valida el humano**.

| # | Dónde | Cadena |
|---|-------|--------|
| C1 | barra | `Agenda de citas` — ya existía en `app_sections.dart` |
| C2 | navegación de día | `Día anterior`, `Día siguiente`, `Hoy` |
| C3 | estado vacío | `Sin citas este día` |
| C4 | acción | `Programar cita` |
| C5 | error de carga | `Reintentar` |
| C6 | formulario | `Nueva cita`, `Cerrar`, `Paciente`, `Fecha`, `Hora`, `Duración · min`, `Motivo`, `Notas · opcional` |
| C6b | selector de paciente | `Buscar paciente`, `Escribí al menos 2 letras`, `Sin resultados`, `No pudimos buscar.` |
| C7 | validación | `Elegí un paciente` |
| C8 | píldoras de estado | `Programada`, `Completada`, `Cancelada` |
| C9 | fila | `N min`, `Paciente sin nombre` |
| C10 | detalle | `Cita`, `Volver`, `Teléfono`, `Notas`, `Motivo`, `Próxima cita sugerida` |
| C11 | nota SOAP | `Subjetivo`, `Objetivo`, `Análisis`, **`Plan de la consulta`** |
| C12 | acciones | `Guardar nota y completar`, `Reprogramar`, `Cancelar cita` |
| C13 | confirmación | `¿Cancelar esta cita?`, `Sí, cancelar`, `No` |
| C14 | franja del mes | `Mes anterior`, `Mes siguiente`, iniciales `L M M J V S D`, y el rótulo semántico `N citas` / `1 cita` |

`Plan de la consulta` no es una licencia de estilo: la tarjeta `citas-sin-get-por-id` del board pide
exactamente ese rótulo para que el campo SOAP no se lea como el plan de comidas.

## Entrega

Rama `feat/agenda`, base `main` (`d7e05c9`). El total del cambio pasa holgadamente el umbral de
revisión de un solo PR, así que se entrega **encadenado en tres**, no en un bloque. Cada commit
compila por separado y trae sus tests; ninguno deja el árbol roto.

| PR | Commits | Entrega | Por qué se corta ahí |
|----|---------|---------|----------------------|
| 1 | `13491eb`, `597203a` | Helpers de fecha compartidos, `ApiClient.patch<T>`, `AppSearchSelectField` y `AppRefresh` | Cimientos sin comportamiento visible: no queda nada de la agenda a medio construir |
| 2 | `96a0b6d`, `536af08`, `130fe68`, `0ddfe9e` | Capa de datos, formulario, detalle con nota SOAP y pantalla del día con la franja del mes | Es el módulo que se revisa como una cosa; cada commit es una parte que se puede leer sola |
| 3 | `6caf2c5` + docs | Refresh por deslizamiento en home, directorio y ficha, más los seis documentos | Es transversal al resto de la app, no a la agenda: quien revise la agenda no tiene por qué cargar con esto |

Verificación al cerrar el último commit de código: `flutter analyze` sin issues, `flutter test` con
298 pasando y 1 skip preexistente, y la suite de agenda también verde bajo
`TZ=America/Tegucigalpa` (el conteo por día local no se puede probar en una máquina en UTC).

Los slices de commit son unidades de revisión, no de entrega: el orden de los PR ya está dado por
las dependencias, porque el 2 usa lo que introduce el 1 y el 3 envuelve pantallas que el 2 toca.

## Log

**L1 — Pedido original (verbatim).** «y tenemos bastantes cosas que el be tiene listo, que
podemos ir abordando, estamos contra el tiempo, nos falta planes, que ya el be los tiene
listos, citas y nose que mas»

**L2 — Decisión de orden (humano).** Arrancar por Agenda / citas: es la entrega más rápida y
la de valor diario más obvio. Planes, catálogo, diario, medicamentos y la app del paciente
quedan para después, cada uno con su propio documento.

**L3 — Decisión de diseño.** Sin pasada de artboards: el contrato de diseño ya está escrito
(`agenda-context.md` §9/§10) y el design system fija el resto; el artboard de Stitch es previo
al design system. La copy autorada va marcada `C#` en las specs.

**L4 — Evidencia del contrato.** Reindexado el spec el 2026-11-16: 49 endpoints, 90 esquemas
(antes 45/84). `desde` y `hasta` siguen declarados como `string` sin formato; `PATCH
/citas/{id}` acepta `pacienteId`, los cuatro campos SOAP, `estado` y `proximaCitaSugerida`.
`proximaCitaSugerida` se declara `date-time` en la respuesta pero `YYYY-MM-DD` en el pedido:
inconsistencia conocida, se maneja como fecha de calendario.

**L5 — PR #25.** Ya estaba mergeado (`d7e05c9`, base `main`); no hubo nada que mergear.
La rama de trabajo es `feat/agenda`, creada desde `main`.

**L6 — Lo que el board ya dice de esta pantalla.** La tarjeta `citas-sin-get-por-id` confirma que
no hay `GET /citas/{id}` y que la edición se arma con la fila del listado: T5 la respeta. La misma
tarjeta pide rotular el campo SOAP `plan` como `Plan de la consulta` para no confundirlo con el plan
de comidas; el detalle lo hace así. La tarjeta `agenda-sin-disponibilidad-y-sin-no-asistio` cubre
los dos gaps del contrato que la pantalla no puede resolver sola.

**L7 — Copy pendiente de validación.** El índice de C1–C13 existe porque no hay artboard. Si el
humano cambia una cadena, se cambia en el código, en su test y acá, en ese orden.

**L8 — Comprobación diferencial de T1.** La regla del repo pide verificar el código compartido que
el pedido no menciona. Las tres funciones movidas (`leerFecha`, `formatearFecha`, `fechaIso`) se
compararon cuerpo a cuerpo contra `main:lib/features/patients/ui/alta_paciente/alta_paciente_borrador.dart`
en un directorio temporal, normalizando el renombre `_fechaIso` → `fechaIso`: **idénticas**, y la
suite completa del módulo de pacientes sigue verde.

**L9 — El selector de paciente (defecto encontrado en el dispositivo).** El formulario arrancaba
con `busqueda = ''` observando el directorio, o sea que abrirlo pedía cientos de pacientes y pintaba
cinco desconocidos de golpe. La corrección no fue un dropdown —la lista no tiene tope— sino
`lib/shared/widgets/app_search_select_field.dart`: un selector con búsqueda en bottom sheet que **no
consulta nada hasta la segunda letra** y debounce de 300 ms. Es genérico en `T` porque el catálogo y
el editor de planes necesitan lo mismo para elegir alimento. Efecto colateral: se fue la cadena
`Cambiar`, porque el campo se reabre con solo tocarlo.

**L10 — El rango de fechas estaba mal (defecto encontrado en el dispositivo).** Una cita recién
creada no aparecía en el día. Causa: el API hace `gte: new Date(desde)` / `lte: new Date(hasta)`, y
una fecha sin hora es medianoche UTC, así que `hasta=2026-11-16` cortaba el rango **antes** de que
empezara el día y dejaba fuera toda cita del día. El repositorio manda ahora el primer y el último
instante del día local como ISO con zona; el test falla si alguien vuelve a mandar `yyyy-MM-dd`. De
paso se normalizó la fecha del formulario a medianoche, porque el family de providers está keyed por
el `DateTime` exacto y un valor con hora invalidaba otra entrada de caché.

**L11 — Franja del mes y refresh.** La franja mensual sale de un request por mes (`citasDelMesProvider`,
tope conocido de 100 citas) y agrupa con `fechaHora.toLocal()`: probado también con
`TZ=America/Tegucigalpa`, no solo en una máquina en UTC. El refresh por deslizamiento es transversal
y vive en `AppRefresh`; cada pantalla decide qué invalida y `onRefresh` espera el valor nuevo, no la
invalidación.
