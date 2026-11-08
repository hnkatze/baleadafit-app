# Mis pacientes (BO)

Feature: the nutritionist's patient module in the Flutter app — directory, patient
file, measurement capture, deactivate, and the new-patient wizard. Drawn against the
API in `odd/designs/pacientes-context.md`; the artboards live in
`odd/designs/mis-pacientes/`.

## Specs

**S1 — Scope.** The module is the BO ("Mis pacientes"), not the patient app: directory,
ficha, nueva medición, alta y baja. The 8 `Mp*` artboards of the board are the source of
layout and copy; `Paciente*` artboards are out of scope.

**S2 — Directorio copy (verbatim from `MpDirectorio.html`).** Title `Mis pacientes`, search field whose visible placeholder is `Nombre, apellido o correo` (its
accessible label is `Buscar paciente`), chips `Todos · 2`, `Sin plan · 0`,
`Con plan · 2`, and the inactive filter (that one carries no count; the board reads
`Dados de baja` but the human shortened it to `De baja` so the four fit one row), primary action
`Nuevo paciente` (inline next to the title, not as the board's floating pill; the header
does not repeat the `2 activos` count the board draws there, because the filters carry it).
A row reads: initials avatar, `Paciente De Prueba`, `31 años · Bajar`,
`72.4 kg · 19.5% grasa`, plan pill `Con plan`. The chip counts are live, not hardcoded.

**S3 — Directorio vacío (verbatim from `MpDirectorioVacio.html`).** `Todavía no tenés
pacientes` and `Agregá el primero con su correo. Cuando inicie sesión con ese correo, va a
ver en su app el plan que le armes.` with the `Nuevo paciente` action.

**S4 — Ficha copy (verbatim from `MpFicha.html`).** Header `Ficha` with back and overflow.
Hero: `Paciente De Prueba`, `Masculino · 31 años · 174 cm`, pill `Con plan`, `Meta: bajar`
and the app-link badge `Sin entrar a la app`. Blocks: `ÍNDICE DE MASA CORPORAL` with
`Normal`, `23.9` and the scale marks `18.5` `25` `30`; `% grasa` `19.5`; `Masa magra`
`58.3`; `Peso` `inicial 72.4 · Δ 0.0 kg`; with a single measurement the trend line reads
`La tendencia y la proyección aparecen con la segunda medición.`; `Requerimiento diario`
with rows `Metabolismo basal (TMB)`, `Actividad sedentaria` `×1.2`, `Gasto total`,
`Ajuste por meta (bajar)` `−500 kcal`, `Objetivo` and the macros `PROTEÍNA` `CARBOS`
`GRASAS`; `Plan y adherencia` with `Plan 2026-11-07` and `Activo · generado por reglas ·
aprobado el 7 nov`; `Adherencia · sin registros` with `El paciente todavía no entró a la
app. Cuando inicie sesión con el correo de su ficha, va a poder marcar sus comidas y acá
vas a ver su avance de 30 días.`; `Próximas consultas` with a `NOV 7` chip, `Revisión de
mediciones`, `Viernes · 09:00 · 45 min`; `Mediciones` with `Ver historial · 1`, the cells
`PESO` `TALLA` `% GRASA` and `Nueva medición`.

**S5 — Ficha sin mediciones (verbatim from `MpFichaSinMediciones.html`).** When there is no
measurement and no plan: `Sin plan`, pill `Sin plan activo`, alert `El paciente no tiene
un plan activo.`, `Todavía no hay mediciones`, `Con la primera medición aparecen el IMC,
la composición corporal y el requerimiento calórico.`, `Sin consultas programadas.` and the
action `Registrar primera medición`. No BMI, composition or requirement block is drawn
with no data.

**S6 — Nueva medición copy (verbatim from `MpMedicion.html`).** Header `Nueva medición` with
close, patient name, `Fecha`, `Fuente` `Manual`. Sections `Básicos` (Peso · kg, Talla · cm,
% grasa, each with an `antes <valor>` hint), `Composición corporal · opcional` (cintura,
masa muscular, masa grasa, grasa visceral `1–20`, agua intra/extracelular, ángulo de fase),
`Pliegues · 4 campos · mm`, `Perímetros · 3 campos · cm`, `Tensión arterial · 2 campos ·
mmHg`, `Notas`, and the submit `Guardar medición`.

**S7 — Alta, paso 1 (verbatim from `MpAltaIdentidad.html`).** Header `Nuevo paciente`,
`PASO 1 DE 4`, stepper `Identidad` `Objetivo` `Clínica` `Hábitos`. Fields `Nombre`,
`Apellido`, `Correo` with the note `Con este correo el paciente entra a su app y ve su
plan. Usá el que va a usar para iniciar sesión.`, `Teléfono · opcional`, `Sexo` as
`Femenino` | `Masculino`, `Fecha de nacimiento` with `Con ella se calculan la edad y el
requerimiento.`, and `Siguiente`.

**S8 — Alta, paso 2 (verbatim from `MpAltaObjetivo.html`).** `PASO 2 DE 4`. `Meta` as
`Bajar −500 kcal`, `Mantener 0 kcal`, `Subir +300 kcal`. `Peso objetivo · kg`, `Para
cuándo`, `Nivel de actividad` with the five levels and their factors `×1.2`, `×1.375`,
`×1.55`, `×1.725`, `×1.9`, `Estado fisiológico` as `Ninguno` | `Embarazo` | `Lactancia`
with `Embarazo y lactancia cambian el requerimiento calórico.`, and `Siguiente`.

**S9 — Baja (verbatim from `MpBaja.html`).** The ficha overflow menu offers `Editar datos`,
`Medicamentos` and the destructive item. Confirmation title `¿Dar de baja a Paciente De
Prueba?` (the patient's name), body `Deja de aparecer en tus pacientes activos. Su ficha,
mediciones y planes se conservan, y lo encontrás en el filtro «Dados de baja».`, actions
`Cancelar` and `Dar de baja`. The API call is `DELETE /pacientes/{id}`, which is a logical
deletion (`activo: false`): no copy may say "borrar".

**S10 — Data.** Nothing is invented: the directory reads `GET /pacientes`, the ficha reads
`GET /pacientes/{id}/ficha` (11 pre-calculated blocks, one call), a new measurement posts
`POST /pacientes/{id}/mediciones`, the wizard posts `POST /pacientes`, and deactivate calls
`DELETE /pacientes/{id}`. Where the API returns no schema the client tolerates the gap
instead of guessing.

**S12 — Edit a patient (issue #8).** The same four-step form the wizard uses, prefilled from
`GET /pacientes/{id}/ficha`, saving with `PATCH /pacientes/{id}`. The `Editar datos` entry of the
file's menu opens it. `PATCH` replaces `condiciones` and `restricciones` wholesale when they are
sent, so the form must always send the complete selection. The issue's own criteria are already
met by the create path; the edit closes it.

**S13 — Weight and body-fat chart (issue #9).** The evolution block draws the series in
`evolucion` — weight and body fat — oldest to newest. The x axis is the **measurement order**,
not elapsed time: every entry may share the same date. Fewer than two measurements draws no
chart, which is the state the artboard already covers with its "second measurement" line. No new
dependency: the segment is drawn with `CustomPainter`, as the home already does for its pulse.

**S11 — House rules.** Feature-first layout under `lib/features/patients/`, `ApiClient` for
transport, Riverpod for state, tokens from `lib/core/theme/` (no `GoogleFonts`), Material
Symbols equivalents from `Icons`. Each task lands with its tests and its docs.

## Tasks

| ID | S# | Task | Where | Evidence |
|---|---|---|---|---|
| T1 | S10, S4 | Ficha data layer: model, repository and provider for `GET /pacientes/{id}/ficha` | `lib/features/patients/data/` | done — 11 tests green, `analyze` clean, uncommitted |
| T2 | S2, S3 | Rebuild the directory: search, four live filter chips, patient rows, empty state | `lib/features/patients/ui/pacientes_screen.dart` | done — 6 widget tests green, suite 123 green, uncommitted |
| T3 | S4, S5 | Ficha screen at `/pacientes/:id` with every block and both empty states | `lib/features/patients/ui/paciente_ficha_screen.dart` | pending |
| T4 | S6 | Nueva medición form, posting `POST /pacientes/{id}/mediciones` | `lib/features/patients/ui/nueva_medicion_screen.dart` | done — 165 green at the time, uncommitted |
| T5 | S9 | Ficha overflow menu and the deactivate confirmation over `DELETE /pacientes/{id}` | `lib/features/patients/ui/paciente_menu.dart` | done — 172 green, uncommitted |
| T6 | S7, S8 | New-patient wizard, all four steps (3 and 4 designed without an artboard, by human decision) | `lib/features/patients/ui/alta_paciente/` | in progress |
| T8 | S12 | Edit an existing patient from the file's menu over `PATCH /pacientes/{id}` | `lib/features/patients/ui/alta_paciente/` | pending |
| T9 | S13 | Weight and body-fat chart in the file's evolution block | `lib/features/patients/ui/` | pending |
| T7 | S11 | Close the two consistency debts: the measurement form becomes a `go_router` route, and `ApiClient` owns the writes instead of each repository reaching into `dio` | `lib/core/network/`, `lib/core/router/` | pending |

## Delivery

The module is far past a single reviewable slice, so it lands as a chain of commits on
`feat/mis-pacientes`, in dependency order, each one carrying its own tests:

| # | Commit | Holds |
|---|---|---|
| 1 | `docs(design)` | the eight artboards, the module contract docs and this file |
| 2 | `feat(network)` | `ApiClient` writes and the unpaged list read |
| 3 | `fix(shell)` | section label and drawer highlight on child routes |
| 4 | `fix(home)` | day card width and the metric icon on the value line |
| 5 | `feat(patients)` data | ficha model, catalogue item, repository and providers |
| 6 | `feat(patients)` directory | routes for the list, the directory screen and its navigation |
| 7 | `feat(patients)` ficha | the patient file screen |
| 8 | `feat(patients)` measurement | the form and its route |
| 9 | `feat(patients)` deactivation | the menu and the confirmation |
| 10 | `feat(patients)` wizard | the four-step alta, the catalogues read and the router wiring |

Only the last commit is verified end to end: the split is retrospective, for review, so an
intermediate commit may reference a route that the next one adds.

## Log

**L1 — Request (verbatim).** `na deja la cards, asi, que podemos hacer ahora, ? avanzamos
con el modulo del paciente, ? tengo el desing ya`

**L2 — Decisions.** The board card for the BE request stays as it is (do not republish it).
The module is "Mis pacientes completo (BO)", not the patient app. The design is the board
at `/Users/katze/Downloads/Design.html`; its 8 `Mp*` artboards were extracted and versioned
in `odd/designs/mis-pacientes/`.

**L3 — Known gap.** The wizard announces four steps but only Identidad and Objetivo were
drawn; Clínica and Hábitos have no design. T6 covers steps 1–2 only and the remaining two
stop for a design decision.

**L4 — API evidence.** `baleadafit-api` re-indexed 2026-11-07: 45 endpoints, 84 schemas,
`VALID: 0 violations`. `GET`/`PUT /pacientes/{id}/registros` landed and resolve the meal
diary blocker documented in `odd/designs/pacientes-context.md` §10.

**L5 — T1 narrowed.** The ficha data layer covers `GET /pacientes/{id}/ficha` only. The
meal diary (`GET /pacientes/{id}/registros`) is not wired yet: the ficha draws adherence in
its "sin registros" state and no artboard shows the populated version, so wiring it now
would mean inventing a screen. It reopens with a design.

**L6 — Parsing decision.** `paciente_ficha.dart` parses by hand instead of using
`json_serializable`: the OpenAPI types every block of that payload as `object` without a
schema, so generated casts would add no validation. A missing block reads as null, a
malformed row is skipped, and no field is invented.

**L7 — T2 evidence.** Directory screen green: 6 widget tests, full suite 123 passing,
`flutter analyze` clean. Decisions taken inside the task: the four chip counts come from a
single `incluirInactivos: true, limit: 100` page filtered locally (there is no server-side
plan filter), `Nuevo paciente` renders disabled because the wizard route arrives in T6, and
rows do not navigate yet because `/pacientes/:id` arrives in T3.

**L9 — Filter copy shortened (human decision).** The board's `Dados de baja` chip does not
fit one row at 390pt next to the three counted ones, so it reads `De baja`, with chip padding
10 and gap 6. This intentionally deviates from the artboard copy.

**L10 — Header carries the action (human decision).** The `2 activos` count was removed from
the title row and the `Nuevo paciente` action moved into it, replacing the floating pill. The
active count already lives in the `Todos` filter, and the empty state keeps its own button so
the action is never duplicated.

**L11 — Write path debt (T4).** `ApiClient` only exposes `get`/`getPaged`, so the two new
writes (`registrarMedicion`, `darDeBaja`) call `_api.dio` directly and map the envelope by
hand. The form also opens through `Navigator.push` (`abrirNuevaMedicion`) instead of a router
route, because the router was outside that worker's allowed surfaces. Both are consistency
debts, not behaviour bugs: T7 closes them.

**L12 — Menu shape (T5).** The artboard draws the overflow menu and the confirmation in one
bottom sheet and leaves the destructive entry unlabelled. The implementation uses a bottom
sheet with three entries plus a separate `AlertDialog`, labelling the entry `Dar de baja` in
the error colour. `Editar datos` and `Medicamentos` render inert until they have a screen.
`DELETE /pacientes/{id}` answers `200` with the whole patient and `activo: false`.

**L13 — Formatting discipline.** A worker ran `dart format` over the whole repo on T4 and
buried real changes in formatting noise; the parent restored those files to `HEAD` and
re-applied only the semantic edits. Every later task states explicitly that only the files
it touches may be formatted.

**L17 — Adherence percentage was shown raw.** `adherencia30d.porcentaje` arrives as a fraction
(0..1) and the file multiplied only in the fallback branch, so a real value painted `0.75%`
instead of `75%`. Fixed with its test, and the older test that had encoded the bug in its fixture
was corrected.

**L14 — Wizard goes to four steps (human decision).** The artboard only draws Identidad and
Objetivo; the human chose to complete the wizard, so Clínica and Hábitos are designed in the
same visual language using only documented API fields. S7/S8 no longer describe two steps.

**L15 — Copy decisions on the ficha (human, delegated to the agent).** The trend line shows
only the weekly pace: the projection was never designed and a forecast should not be invented.
The adherence block keeps the artboard's empty state; once there is data it reads
`N de M comidas` next to the percentage, and the "entered but marked nothing" state reads
`Todavía no hay comidas marcadas.` instead of the longer invented sentence.

**L16 — Pagination: the endpoint is NOT filtered.** Re-indexed 2026-11-07: `GET /pacientes`
still accepts only `q`, `incluirInactivos`, `limit`, `offset` and `cursor` (45 endpoints,
84 schemas). There is no plan filter, so `Con plan` and `Sin plan` can only be counted over
the loaded page. The truncation notice is in place
(`Mostrando N de M pacientes.`) and the filter was requested to the BE as the board card
`pacientes-sin-filtro-por-plan` in `baleadafit-api/pacientes`.

**L8 — Copy to confirm.** With a search that matches nobody the artboards define nothing, so
the screen shows `No encontramos pacientes.` That string is not from the design and needs a
yes/no from the human.
