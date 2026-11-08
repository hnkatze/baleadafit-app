# Mis pacientes — artboards del BO (reference)

Source: design board `~/Downloads/Design.html`, exported 2026-11-07 as a bundled
Claude canvas. The board had 17 artboards; the 8 `Mp*` ones are this module and the
`Paciente*` ones belong to the patient app (not this module).

These files are **reference for what we draw**, not code: the app re-creates them with
Flutter widgets and the tokens in `lib/core/theme/`. When the design and the app
disagree, the design wins for layout, copy and spacing — the app wins for behavior.

The module contract they are drawn against is `odd/designs/pacientes-context.md`.
The API is documented in `odd/designs/pacientes-context.md` §1 and indexed in the
`swagger-mcp` store as `baleadafit-api`.

| File | Artboard | What it defines |
|---|---|---|
| `MpDirectorio.html` | Mis pacientes · Directorio | Search field, four filter chips with counts, patient rows (initials avatar, age · goal, weight · body fat, plan pill), `Nuevo paciente` action |
| `MpDirectorioVacio.html` | Mis pacientes · Sin pacientes | Empty state with the "add the first one with their email" explainer |
| `MpFicha.html` | Mis pacientes · Ficha | The central screen: hero, BMI scale, body composition, calorie requirement, plan + adherence, next appointments, measurements |
| `MpFichaSinMediciones.html` | Mis pacientes · Ficha sin mediciones | Same shell with no measurements and no plan |
| `MpMedicion.html` | Mis pacientes · Nueva medición | Measurement form: date, source, basics, optional body composition, skinfolds, perimeters, blood pressure, notes |
| `MpAltaIdentidad.html` | Nuevo paciente · Identidad | Wizard step 1 of 4 |
| `MpAltaObjetivo.html` | Nuevo paciente · Objetivo | Wizard step 2 of 4 |
| `MpBaja.html` | Mis pacientes · Dar de baja | Overflow menu (edit, medication, deactivate) and the deactivate confirmation |

## Known gaps in the artboards

- The wizard announces **4 steps** (Identidad, Objetivo, Clínica, Hábitos) but only the
  first two were drawn. Steps 3 and 4 have no design yet.
- The ficha draws the adherence block in its empty state ("sin registros"). The
  nutritionist path that feeds it (`GET`/`PUT /pacientes/{id}/registros`) exists in the
  API since 2026-11-07 but no artboard shows the populated version.
