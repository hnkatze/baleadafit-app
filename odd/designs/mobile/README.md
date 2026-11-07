# Mobile screens from Stitch (reference)

Source: Stitch project `projects/15920435902002365733` — "BaleadaFit Nutrition Portal".
Design system: **Clinical Mint Precision** (see `stitch-design-system.json`).
Exported 2026-11-07 as static HTML so the team can open them without Stitch access.

These files are **reference for what we draw**, not code: the app re-creates them with
Flutter widgets and the tokens in `lib/core/theme/`. When the design and the app
disagree, the design wins for layout, copy and spacing — the app wins for behavior.

| # | File | Stitch screen | Device | What it defines |
|---|------|---------------|--------|-----------------|
| 01 | `01-login.html` | `4c993085…` Acceso Clínico - Login Mobile | 780×1852 | Emblem, institutional pill, title, white card with email + password (visibility toggle, "¿Olvidaste tu clave?"), primary CTA, biometric + Google buttons, security pill, legal footnote |
| 02 | `02-inicio-clinico.html` | `56ff95ba…` Inicio Clínico - Mobile | 780×2928 | Clinician home: greeting, day summary, next appointments, shortcuts |
| 03 | `03-directorio-pacientes.html` | `5eaed93b…` Directorio de Pacientes - Mobile | 780×3534 | Patient directory: search, filters, patient rows with status |
| 04 | `04-agenda-citas.html` | `28bcf179…` Agenda de Citas - Mobile | 780×2794 | Agenda: date strip, appointment cards, states |
| 05 | `05-disenador-dietas.html` | `c0985fe9…` Diseñador de Dietas HN - Mobile | 780×4354 | Diet builder: meal slots, food search, macros |
| 06 | `06-catalogo-alimentos.html` | `c217a171…` Catálogo Alimentos TCA-HN - Mobile | 780×3542 | Food catalogue: categories, nutrient chips, food rows |

## Tokens used by every screen

- Fonts: **Plus Jakarta Sans** (display 800, headlines 700/600, body 400); `code-data` uses JetBrains Mono.
- Primary `#006c49`, primary-container `#10b981`, secondary-container `#a6f2d1`,
  surface `#f9f9ff`, on-surface `#111c2d`, outline `#6c7a71`, error `#ba1a1a`.
- Radius: 4 / 8 / 12 / full. Spacing: 4, 8, 16, 24, 32, 48. Screen margin 16.

## Regenerating a screen

Screens are pulled from Stitch with `mcp__stitch__list_screens` → `get_screen` →
`download_file` (the stored HTML). The Stitch download URL requires OAuth, so the MCP
tool is the only path.
