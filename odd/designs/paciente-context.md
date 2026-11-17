# Contexto del paciente (para diseñar)

Todo lo que el rol **paciente** puede ver y hacer en la API, con los contratos tal como están documentados hoy y el resultado de haberlos probado. Complementa `odd/designs/home-context.md` (lado nutricionista) y `odd/designs/design-system.md`.

> **Documento de contexto original.** El detalle por pantalla (campos, orden, fechas, estados de datos, gaps numerados) vive en `odd/designs/paciente-app-context.md`; el plan semanal, en `odd/designs/planes-context.md`. Acá queda el mapa del contrato, el estado de verificación y los puntos de contacto con el lado nutricionista (§9). Si algo choca con `paciente-app-context.md`, manda ese.

## 1. Estado de verificación (importante antes de dibujar)

Probé los seis endpoints con un token **real** de la cuenta `playercamiloh504@gmail.com` (rol `nutricionista`):

```
GET  /me/hoy        → 403  {codigo: "SIN_PERMISO", mensaje: "No tienes permiso para este recurso."}
GET  /me/plan       → 403
GET  /me/mediciones → 403
GET  /me/registros  → 403
PUT  /me/registros  → 403
GET  /me/citas      → 403
```

Conclusión: **el gating por rol funciona** (el paciente no puede tocar endpoints de nutricionista y viceversa), pero **no pude capturar payloads reales del paciente**. Lo que sigue sale del contrato OpenAPI, no de una respuesta observada. Para cerrar esa brecha hace falta una de estas dos cosas:

1. Credenciales de un paciente con usuario de Firebase, o
2. Activar `prueba.qa@baleadafit.hn` como usuario (hoy su `firebaseUid` es `null`, no puede entrar).

Nota: el nutricionista ya tiene su propio camino para las comidas (`GET`/`PUT /pacientes/{id}/registros`, ver `pacientes-context.md` §10) y esos dos endpoints sí le responden. El 403 de `/me/*` sigue siendo el contrato correcto, no un bloqueo pendiente.

Contrato indexado: `baleadafit-api` (49 endpoints, 90 schemas, 2026-11-16). Donde el spec no define algo, lo marco explícitamente: **no inventar campos**. Los `/me/*` que antes figuraban "sin esquema" (`plan`, `proximaCita`, `tiempos`, mediciones) **ya están tipados**: ver §3.

## 2. Los seis endpoints

| Pantalla | Endpoint | Datos |
|---|---|---|
| Hoy | `GET /me/hoy?fecha=YYYY-MM-DD` | **un solo día** del plan activo con su registro, cumplidos y próxima cita. No paginado |
| Mi plan | `GET /me/plan` | plan activo completo, **semana entera**, con totales semanales; `null` si no hay. No paginado |
| Progreso | `GET /me/mediciones` | mediciones con IMC, de la más antigua a la más reciente |
| Diario | `GET /me/registros?desde&hasta` | comidas registradas; por defecto los últimos 7 días |
| Marcar comida | `PUT /me/registros` | el **único** write del paciente en estos seis |
| Mis citas | `GET /me/citas` | todas las citas, de la más reciente a la más antigua |

Las tres listas (`/me/registros`, `/me/mediciones`, `/me/citas`) usan la misma paginación: `limit` (default 20, máx 100), `offset` (base 0) **o** `cursor` (opaco, es el `nextCursor` previo), y responden `{ok, data: [], meta: {limit, offset, total, hasMore, nextCursor}}`. `meta` sólo garantiza `limit` y `hasMore`; en modo cursor no trae `total`. `/me/hoy` y `/me/plan` no se paginan. Mezclar offset y cursor da `400 VALIDACION`; un cursor ajeno, `400 CURSOR_INVALIDO`.

Hay además `GET`/`POST /me/dispositivos` y `DELETE /me/dispositivos/{token}` (registro de push), fuera de este documento. Ver `paciente-app-context.md` §1.

## 3. Contratos

Resumen. El detalle campo a campo está en `paciente-app-context.md` (§3 a §7).

### `GET /me/hoy` — pantalla Hoy

Query opcional `fecha` (`YYYY-MM-DD`, por defecto hoy). Responde `HoyEntity`:

```
data:
  fecha: string            // YYYY-MM-DD, texto, no instante
  dia: string              // día de la semana de `fecha` ("MIERCOLES"); aquí es string, no enum
  plan: { id, nombre, kcalObjetivo, totales } | null   // PlanHoyEntity; null si no hay plan activo
  tiempos: TiempoHoyEntity[]  // sólo los tiempos de ESE día
  cumplidos: number        // comidas cumplidas del día
  proximaCita: { id, estado, fechaHora, duracionMin, motivo } | null   // CitaAgendaEntity
```

- **Devuelve un solo día del plan**, el que corresponde a `fecha`; `plan.totales` son los de **ese día**, no los de la semana. Con un plan anterior a los semanales (de un solo día) devuelve ese único día, sin importar la fecha. La semana vive en `GET /me/plan`.
- `TiempoHoyEntity`: `id` (es el **`tiempoComidaId`** de `PUT /me/registros`), `planId`, `dia` (`DiaSemana`), `tipo`, `orden`, `pctKcal` (fracción), `kcalMeta`, `totales`, `desviacion` (fracción), `items[]` (`PlanItemEntity`) y `registro` (`RegistroComidaEntity | null`: lo que ya marcó el paciente).
- `tipo` es uno de `DESAYUNO · MERIENDA_AM · ALMUERZO · MERIENDA_PM · CENA`. `dia`, en `TiempoHoyEntity` y en `dias[]` de `/me/plan`, es uno de `LUNES · MARTES · MIERCOLES · JUEVES · VIERNES · SABADO · DOMINGO` (sin tilde).
- Errores declarados: 401, 403. **No declara 400** (una `fecha` inválida queda indefinida).

### `GET /me/plan` — Mi plan activo

Responde `PlanDetalleEntity` o `null` si la nutricionista aún no activa uno (el schema no marca `data` como nulo: el parser debe tolerar `data: null`).

```
data:
  id, nombre, nutricionistaId, pacienteId
  estado: BORRADOR | ACTIVO | ARCHIVADO     // el paciente sólo ve ACTIVO
  origen: MANUAL | REGLAS | IA
  justificacion: string | null // resumen del recomendador o notas de la nutricionista
  kcalObjetivo: number         // meta DIARIA
  proteinaG, carbohidratoG, grasaG: number   // metas diarias
  creadoEn: date-time, aprobadoEn: date-time | null
  tiempos: TiempoComidaEntity[]  // toda la semana, plano, en orden de día y de tiempo
  dias: DiaPlanEntity[]          // {dia, tiempos, totales, desviacion}, lunes a domingo; sólo días con tiempos
  totales: {                     // totales de la SEMANA completa
    kcal, proteinaG, carbohidratoG, grasaG, grasasSatG,
    fibraG, azucaresG, sodioMg, potasioMg, fosforoMg, cargaGlucemica
  }
  desviacion: number             // de la semana: contra kcalObjetivo × días del plan (fracción)
```

- Los `totales` y la `desviacion` de nivel raíz son **semanales**, no del día. Los del día están en cada `dias[]` (y en `plan.totales` de `/me/hoy`). La UI debe rotular el alcance.
- `kcalObjetivo` y las metas de macros siguen siendo diarias: no compararlas directo con `totales`.
- Cada ítem declara la versión del alimento que usó (`alimentoVersionId`, `null` en ítems previos al versionado): editar el alimento después no cambia el plan. Más en `planes-context.md`.

### `GET /me/mediciones` — Progreso

`data: MedicionConImcEntity[]` y `meta`. Cada fila trae la medición completa más `imc` (**calculado por el API**, ya viene en el campo):

```
id, pacienteId, fecha, fuente (MANUAL | BASCULA | INBODY | OMRON | OTRO), creadoEn
pesoKg, tallaCm, imc                    // siempre presentes
pctGrasa, cinturaCm, masaMuscularKg, masaGrasaKg, grasaVisceral (1-20)   // pueden ser null
aguaIntracelularL, aguaExtracelularL, anguloFase
pliegueTricipitalMm, pliegueSubescapularMm, pliegueSuprailiacoMm, pliegueBicipitalMm
perimetroBrazoCm, perimetroCaderaCm, perimetroMusloCm
presionSistolica, presionDiastolica, notas
```

Orden: **de la más antigua a la más reciente**, sin filtro de fechas: la más actual está en la última página. `fecha` viene a medianoche UTC: mostrar el día con componentes UTC.

### `PUT /me/registros` — el único formulario del paciente

```
tiempoComidaId: string (required)  // tiempos[].id de GET /me/hoy
cumplido: boolean (required)
fecha: string YYYY-MM-DD           // por defecto hoy
comentario: string                 // máx. 500
```

Responde **200** con `RegistroComidaEntity` `{id, pacienteId, tiempoComidaId, fecha, cumplido, comentario | null, creadoEn, autor}` (`autor`: `PACIENTE | NUTRICIONISTA`, el último actor que escribió la fila). Es un upsert por (paciente, tiempo, fecha): si ya existe, lo actualiza; también responde 200 al crear. Errores: `400 VALIDACION` con `detalles: []` (lista de textos), `401`, `403`, `404 NO_ENCONTRADO` ("No existe o no pertenece al usuario.").

Diseño: es un **toggle con comentario opcional**, no un formulario largo. Un tap marca/desmarca; no hay forma de borrar el registro.

⚠️ **Comentario:** la tarjeta `no-esta-definido-como-limpiar-un-campo-de-texto` dice que omitir un campo de texto opcional al editar **conserva** el valor guardado y que el contrato no define cómo vaciarlo. Para el upsert no está dicho si rige: no asumir que volver a marcar sin `comentario` lo borra ni que lo conserva; probarlo antes de diseñar "editar comentario".

### `GET /me/citas` — Mis citas

Devuelve `CitaPacienteEntity`, **no** `CitaEntity`:

```
id, fechaHora (date-time), duracionMin, motivo (string | null)
estado: PROGRAMADA | COMPLETADA | CANCELADA
nutricionista: { nombre }
```

**Sin SOAP:** el paciente no recibe `notas`, `subjetivo`, `objetivo`, `analisis`, `plan` (el campo SOAP, que en cualquier UI se rotula `Plan de la consulta`), `proximaCitaSugerida`, `paciente` ni `pacienteId`. De la nutricionista, sólo el `nombre`. Esos campos son del `CitaEntity` de la agenda (`agenda-context.md`).

## 4. Tablas y listas: qué columnas salen de la API

| Lista | Columnas defendibles con la API |
|---|---|
| Comidas de hoy | tipo de tiempo (5 valores), alimentos y porciones, `kcalMeta`, `registro.cumplido` (bool), `registro.comentario` |
| Mi plan | kcal objetivo, proteína, carbohidrato, grasa (diarios), estado, origen, justificación; semana por `dias` |
| Totales del plan | 11 números de la **semana**: kcal, P, C, G, saturadas, fibra, azúcares, sodio, potasio, fósforo, carga glucémica (los del día, en `dias[].totales`) |
| Progreso | fecha, peso, talla, IMC, % grasa, masa muscular, masa grasa, fuente (`imc` viene del API) |
| Mis citas | fecha/hora, duración, motivo, estado, nombre de la nutricionista |

Unidades que la UI debe declarar siempre: `kcal`, `g`, `mg`, `cm`, `kg`, `%`. `pctKcal` y `desviacion` son **fracciones** (`0.35` = 35 %); `pctGrasa` es un **porcentaje** (`34`).

## 5. Enums y códigos

| Enum | Valores |
|---|---|
| Estado de plan | `BORRADOR`, `ACTIVO`, `ARCHIVADO` |
| Origen del plan | `MANUAL`, `REGLAS`, `IA` |
| Tiempo de comida | `DESAYUNO`, `MERIENDA_AM`, `ALMUERZO`, `MERIENDA_PM`, `CENA` |
| Día de la semana | `LUNES`, `MARTES`, `MIERCOLES`, `JUEVES`, `VIERNES`, `SABADO`, `DOMINGO` |
| Estado de cita | `PROGRAMADA`, `COMPLETADA`, `CANCELADA` |
| Fuente de medición | `MANUAL`, `BASCULA`, `INBODY`, `OMRON`, `OTRO` |
| Autor del registro | `PACIENTE`, `NUTRICIONISTA` |
| Códigos de falla | `VALIDACION`, `NO_AUTENTICADO`, `SIN_PERMISO`, `NO_ENCONTRADO`, `CONFLICTO`, `CURSOR_INVALIDO`, `ERROR_HTTP`, `ERROR_INTERNO` |

`SIN_PERMISO` (403) es lo que devuelve un rol equivocado **o un correo sin verificar** (mismo código, no se distinguen); `NO_AUTENTICADO` (401), falta de token. El paciente **no** puede escribir nada más que su registro de comida: plan, mediciones y citas son de lectura.

## 6. Estados vacíos que el diseño debe resolver

| Caso | Situación real |
|---|---|
| `plan: null` en `/me/hoy` | La nutricionista no activó plan: Hoy no tiene comidas |
| `data: null` en `/me/plan` | Lo mismo, en la pantalla del plan |
| `proximaCita: null` | Sin cita programada |
| `registro: null` en un tiempo | Comida sin marcar (no es "no cumplida") |
| `cumplidos: 0` | Día sin registrar |
| `data: []` en mediciones | Primer uso, sin historial: no hay gráfico |
| `data: []` en citas | Nunca tuvo cita |
| Sin conexión / 401 | Mensaje de la API + reintento |

El catálogo completo de estados está en `paciente-app-context.md` §10.

## 7. Gaps del contrato (a resolver en el repo del API, no en el diseño)

La lista numerada y vigente es `paciente-app-context.md` §11. Resueltos desde la versión anterior de este documento: tipado de `plan`, `proximaCita`, `tiempos` y del ítem de `/me/mediciones` (incluye `imc`). Siguen abiertos, entre otros:

1. `perfil` de `GET /auth/me` no tiene esquema: no hay nombre del paciente ni de su nutricionista para la cabecera. No hay `GET /me/perfil`; los datos personales viven en el expediente del nutricionista.
2. `HoyEntity.dia` es `string` y no el enum `DiaSemana`.
3. `GET /me/plan` documenta `null` pero no lo marca como nulable en el schema.
4. `GET /me/hoy` no declara 400 ni la zona horaria con la que resuelve "hoy".
5. `/me/mediciones` y `/me/citas` no filtran por fecha ni por estado; `/me/citas` no entrega notas ni SOAP.
6. No hay endpoint de adherencia del paciente (sí lo hay para la nutricionista: `GET /pacientes/{id}/adherencia`).

## 8. Qué necesito de vos para pasar de contrato a pantalla

- Credenciales de un paciente (o activar la cuenta de prueba) para capturar los payloads reales de `/me/hoy`, `/me/mediciones` y `/me/registros`.
- Decisión de qué cuatro pantallas entran primero: **Hoy** es la que justifica la app del paciente; Progreso y Mis citas son lectura pura.
- Si el rediseño del login define un selector de rol o dos apps separadas: el API ya resuelve el rol en `GET /auth/me` (`nutricionista` | `paciente` | `sin_perfil`), así que un login único es suficiente.

## 9. Lo mismo, visto desde la ficha del nutricionista

Lo que el paciente ve en `/me/*` es una versión reducida de lo que la nutricionista tiene en la ficha. Puntos que condicionan ambos lados (detalle en `pacientes-context.md`, `planes-context.md` y `agenda-context.md`):

- **Registros:** `GET`/`PUT /pacientes/{id}/registros` es el mismo upsert que `PUT /me/registros`, pero deja `autor: "NUTRICIONISTA"`; el diario del paciente puede mostrar esas correcciones.
- **Plan:** el paciente sólo ve el plan `ACTIVO`; borradores y archivados están en `GET /pacientes/{id}/planes`. La edición manual va por `PUT /planes/{id}/tiempos/{dia}/{tipo}/items` (máximo 12 ítems por tiempo); `PUT /planes/{id}/tiempos/{tipo}/items` está **obsoleta** y equivale a `dia = LUNES`.
- **Citas:** no existe `GET /citas/{id}` (tarjeta `citas-sin-get-por-id`): sólo `GET /citas` (agenda), `POST /citas` y `PATCH /citas/{id}`. El campo SOAP `plan` se rotula `Plan de la consulta` en cualquier UI, para no confundirlo con el plan de alimentación. Cancelar es `PATCH` con `estado: "CANCELADA"`.
- **Ficha sin mediciones:** `GET /pacientes/{id}/ficha` devuelve `requerimiento: null` y `evolucion: []` (tarjeta `ficha-sin-mediciones-devuelve-requerimiento-null`); el paciente en esa situación también tendrá `data: []` en `/me/mediciones`.
- **Forma de dashboard y ficha:** `GET /dashboard` y `GET /pacientes/{id}/ficha` tienen campos de cita, fechas y porcentajes que **no se deducen del OpenAPI** (tarjeta `dashboard-ficha-contract-gotchas`); leerla antes de fiarse de un tipo o de una unidad.
- **Baja y reactivación:** `DELETE /pacientes/{id}` es una baja lógica (`activo = false`, el historial se conserva); `PATCH /pacientes/{id}` con `{"activo": true}` la deshace (tarjeta `pacientes-baja-reactivable`). `GET /pacientes` oculta a los inactivos salvo `?incluirInactivos=true`.
- **Editar texto:** omitir un campo de texto opcional al editar conserva el valor guardado; el contrato no define cómo vaciarlo (tarjeta `no-esta-definido-como-limpiar-un-campo-de-texto`). Vale para `PATCH /pacientes/{id}`, y es el mismo hueco de `comentario` en §3.
- **Catálogos:** `GET /restricciones` y `GET /condiciones` alimentan los campos que `PATCH /pacientes/{id}` reemplaza completos (`restricciones` y `condiciones`); `GET /alimentos` y sus versiones alimentan los planes.
