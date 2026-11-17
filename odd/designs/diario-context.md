# Contexto del módulo Diario y adherencia (para diseñar)

Todo lo que el rol **nutricionista** puede ver y hacer con el diario de comidas de un paciente y con su adherencia, según el contrato OpenAPI indexado (`baleadafit-api`, 49 endpoints, 90 schemas, indexado el 2026-11-16).

⚠️ **Estado de verificación:** este documento sale del contrato, **no de payloads capturados**. Los tres endpoints no se probaron en esta redacción con un token real. `pacientes-context.md` §3 y §10 registra el estado real de la ficha (`adherencia30d` en `null` con `total: 0`) y el alcance del `PUT`. Donde el spec no define algo lo digo explícitamente: no inventar campos.

Complementa `odd/designs/design-system.md` y `pacientes-context.md`.

## 1. Mapa de endpoints

| Uso | Endpoint | Notas |
|---|---|---|
| Diario | `GET /pacientes/{id}/registros` | Paginada. Filtros `desde`, `hasta`. Por defecto, los últimos 7 días |
| Marcar o corregir una comida | `PUT /pacientes/{id}/registros` | Upsert. La fila queda con `autor: NUTRICIONISTA`. Responde 200 |
| Adherencia | `GET /pacientes/{id}/adherencia` | Un solo objeto, **sin paginar**, con los registros incluidos. Por defecto, los últimos 14 días |

Tres endpoints. No hay endpoint para borrar un registro, ni para listar el diario de **todos** los pacientes, ni adherencia agregada de la cartera de la nutricionista. El paciente tiene su propio camino (`/me/registros`); este documento sólo cubre el de la nutricionista.

**Resuelto (tarjeta `nutricionista-no-puede-registrar-comidas`, ver `nutricionista-escribe-el-diario-y-el-registro-lleva-autor`):** hasta hace poco sólo el paciente podía marcar comidas (`PUT /me/registros`); ahora existe `PUT /pacientes/{id}/registros` y cada fila lleva `autor`. Ya no es un bloqueo de producto.

## 2. El registro de comida

### En la lista del diario (`RegistroComidaConTipoEntity`)

```
id · pacienteId · tiempoComidaId
fecha (date-time, ejemplo 2026-10-28T00:00:00.000Z)
cumplido (bool) · comentario (string | null) · creadoEn (date-time)
autor (PACIENTE | NUTRICIONISTA)
tiempoComida { tipo }     // DESAYUNO | MERIENDA_AM | ALMUERZO | MERIENDA_PM | CENA
```

`tiempoComida` sólo trae `tipo`: **no trae el día de la semana, el plan ni el nombre de los alimentos**. Para saber qué había que comer hay que cruzar `tiempoComidaId` con el detalle del plan (`GET /planes/{id}` → `tiempos[].id`).

### Al marcar (`RegistroComidaEntity`)

Lo mismo **sin** `tiempoComida`: `autor · id · pacienteId · tiempoComidaId · fecha · cumplido · comentario · creadoEn`.

### `autor`

Es **el último actor que escribió la fila**, no una auditoría: no hay historial de cambios. Si el paciente vuelve a marcar una comida que la nutricionista corrigió, `autor` regresa a `PACIENTE`. No dibujar "marcado por X el…" como si fuera un registro permanente.

`cumplido` es sí/no: un registro con `cumplido: false` es "no la comió", **distinto** de "sin registro".

## 3. Marcar una comida (`PUT /pacientes/{id}/registros`)

```json
{
  "tiempoComidaId": "uuid",          // obligatorio
  "cumplido": true,                  // obligatorio
  "fecha": "2026-10-28",             // YYYY-MM-DD; por defecto, hoy
  "comentario": "Lo confirmé en consulta"   // máx. 500
}
```

- **Upsert** sobre (paciente, tiempo de comida, fecha): repetir el PUT corrige, no duplica. Responde **200** también al crear (no 201).
- `tiempoComidaId` es el `id` de un **tiempo de comida del plan**. La descripción del propio spec dice que "viene en `GET /pacientes/{id}/planes`", pero esa lista no trae tiempos: el id sale de `GET /planes/{id}` (`tiempos[].id`). Ver gap 1.
- Errores: **400** `VALIDACION` con `detalles` por campo; **404** "no existe o no pertenece al usuario" (paciente ajeno o inexistente; el spec no dice si un `tiempoComidaId` que no es del paciente también da 404); 401; 403.
- No hay forma de borrar un registro: corregir es volver a hacer el PUT.

⚠️ **Peligros concretos del upsert:**

- **`comentario`**: la tarjeta `no-esta-definido-como-limpiar-un-campo-de-texto` dice que omitir un campo de texto al editar conserva el valor; no está definido cómo borrarlo; habla de **editar**, y no dice si rige también para este upsert (`PUT`). El spec tampoco define `""`. No asumir que un campo vaciado en el formulario **borra** un comentario previo; probar el PUT antes de diseñar "editar comentario". La respuesta puede traer `null`, pero el body sólo admite texto.
- **`fecha`**: el servidor interpreta `"hoy"` con una zona que el contrato no declara. Enviar siempre la `fecha` explícita (día de calendario que la nutricionista eligió), nunca depender del default.
- Corregir una comida que marcó el paciente cambia `autor` a `NUTRICIONISTA` y pisa lo que él puso, incluido su comentario.

## 4. La lista del diario (`GET /pacientes/{id}/registros`)

Paginación estándar: `limit` (20 por defecto, máximo 100) y `offset` (base 0) **o** `cursor` (el `nextCursor` previo); responde `{ok, data: [], meta: {limit, offset, total, hasMore, nextCursor}}`. Mezclar offset y cursor da 400 `VALIDACION`; un cursor ajeno da 400 `CURSOR_INVALIDO`. En modo cursor `meta` no trae `total`.

- Filtros: `desde` y `hasta`, formato `YYYY-MM-DD`. Por defecto `desde` = 7 días atrás y `hasta` = hoy. El contrato no dice si `hasta` es inclusivo.
- Orden: del más reciente al más antiguo; no hay parámetro de orden ni filtro por `cumplido`, `tipo` o `autor`.
- El listado general del contrato ("Paginadas: …") **no nombra** este endpoint aunque acepte `limit`/`offset`/`cursor`: ver gap 8.
- El tamaño de página por defecto es 20: una ventana de 7 días puede necesitar más de una página. Paginar siempre, no asumir que todo cabe.

## 5. La adherencia (`GET /pacientes/{id}/adherencia`)

Query: `desde` y `hasta` (`YYYY-MM-DD`; `hasta` por defecto hoy; `desde` por defecto 14 días atrás). Responde 200 con `AdherenciaEntity`:

```
desde · hasta                       // date-time
totalRegistros                      // número de filas del diario en la ventana
cumplidos                           // las que tienen cumplido: true
adherencia                          // number | null — FRACCIÓN 0..1
registros[]                         // RegistroComidaConTipoEntity, sin paginar
```

### ⚠️ `adherencia` es una fracción, no un porcentaje

El contrato la define como "Cumplidos / total (0–1); null si no hay registros". El ejemplo es `0.8`, que se muestra **80 %**. Dibujar el valor crudo daría "0.8 %" o un anillo casi vacío. Convertir con una sola función compartida y redondear sólo al mostrar.

### ⚠️ El denominador son los registros, no las comidas del plan

`adherencia = cumplidos / totalRegistros`. Una comida **sin marcar no cuenta** como incumplida: un paciente que marcó 1 de 1 tiene `1.0` aunque el plan tenga 35 comidas en la semana. La cifra no equivale a "cuánto del plan siguió"; mide **de lo que se registró, cuánto se cumplió**. Texto de UI honesto: "de las comidas registradas", con `totalRegistros` a la vista. Ver gap 3.

### ⚠️ Mismo número, dos nombres

La ficha del paciente (`GET /pacientes/{id}/ficha`, bloque `adherencia30d`) devuelve `porcentaje` y `total` (también fracción 0..1, `null` sin datos); este endpoint devuelve `adherencia` y `totalRegistros`. Es la misma idea con campos distintos y **ventanas distintas**: la ficha usa 30 días y este endpoint 14 por defecto. Dos pantallas con números distintos para el mismo paciente no son un error si la ventana es distinta; rotular siempre la ventana.

`null` significa **"sin datos"**, no 0 %: se dibuja distinto (ver §7).

La tarjeta `dashboard-ficha-contract-gotchas` registra "campos de cita, fechas y porcentajes que no se deducen del OpenAPI": este documento sale del contrato, así que conviene leer esa tarjeta antes de fiarse de un tipo o de una unidad de esta sección.

## 6. Fechas: el detalle que rompe pantallas

- `fecha` de un registro es un `date-time` que, por el ejemplo del contrato, está a **medianoche UTC** (`2026-10-28T00:00:00.000Z`). Formatearla en `America/Tegucigalpa` (GMT-6) muestra **el día anterior**. Para mostrar el día, usar los componentes UTC (`fecha.toUtc()`), nunca `toLocal()`. Es el mismo defecto que `agenda-context.md` §6 documenta para `proximaCitaSugerida`.
- `creadoEn` sí es un instante: se formatea en la zona del dispositivo. El registro no tiene `actualizadoEn`: **no se sabe cuándo se corrigió por última vez**, y el contrato no dice si `creadoEn` cambia en una corrección.
- `desde`/`hasta` de `AdherenciaEntity` son `date-time` sin ejemplo; no asumir que vienen a medianoche UTC sin probarlo. Los query `desde`/`hasta` sí son `YYYY-MM-DD`.
- Al enviar `fecha` en el PUT, mandar el día de calendario elegido (`YYYY-MM-DD`), sin convertir a UTC.

## 7. Estados de datos que hay que dibujar

| Estado | Cómo se ve |
|---|---|
| **Paciente sin registros** | `data: []`; `adherencia: null`, `totalRegistros: 0`. Es el estado esperable: el plan no genera registros por sí solo (`pacientes-context.md` §9) |
| **Sin datos de adherencia** | `adherencia: null` → "Sin datos", **no** 0 % |
| Comida sin marcar | No hay fila: es un hueco, no un "no cumplido" |
| Comida cumplida | `cumplido: true`, con `comentario` opcional |
| Comida no cumplida | `cumplido: false`: fila explícita, distinta del hueco |
| Marcada por la nutricionista | `autor: NUTRICIONISTA`; por el paciente: `autor: PACIENTE` |
| Corrección pisada | Si el paciente re-marca, `autor` vuelve a `PACIENTE` y el cambio previo no queda visible |
| Ventana larga | Más páginas en el diario; en adherencia, un `registros[]` grande sin paginar |
| Comentario largo | Hasta 500 caracteres |
| Paciente ajeno | 404 en los tres endpoints |
| Validación fallida al marcar | 400 con `detalles` por campo |

## 8. Gaps del contrato (a resolver en el repo del API, no en el diseño)

**Estado en el board:** contrastado con el índice de 20 tarjetas de `baleadafit-api` (se conocen las claves y los títulos, no el cuerpo de cada tarjeta). Marcas: `ya pedido: <clave>` = hay tarjeta que lo pide al BE; `resuelto: <clave>` = había tarjeta y el contrato ya lo resuelve; `nuevo` = no hay tarjeta, hay que pedirlo.

| # | Gap | Board |
|---|---|---|
| 1 | `tiempoComidaId` "viene en `GET /pacientes/{id}/planes`" pero esa lista no trae tiempos: el id está sólo en `GET /planes/{id}` | nuevo |
| 2 | El registro no trae `dia`, `planId` ni el nombre de los alimentos: no se puede dibujar "qué tocaba comer" sin cruzar con el detalle del plan | nuevo |
| 3 | El denominador de `adherencia` son los registros, no las comidas planificadas: no hay un indicador de "cumplimiento del plan completo" | nuevo |
| 4 | Los nombres de la misma métrica difieren entre la ficha (`porcentaje`/`total`, 30 días) y `/adherencia` (`adherencia`/`totalRegistros`, 14 días) | nuevo |
| 5 | `comentario` omitido o `""` en una corrección: el hecho de la tarjeta cubre editar (omitir conserva) y la falta de forma de borrar; no dice si rige para el upsert del PUT | ya pedido: no-esta-definido-como-limpiar-un-campo-de-texto |
| 6 | "Hoy" del default de `fecha` (PUT) y de `hasta` no declara zona horaria | nuevo |
| 7 | El PUT no dice qué pasa con fechas futuras, fechas fuera de la vigencia del plan, un `tiempoComidaId` de otro paciente o de un plan archivado, ni si el día de `fecha` debe coincidir con el `dia` del tiempo | nuevo |
| 8 | `/pacientes/{id}/registros` acepta paginación pero no figura en el listado de endpoints paginados de la introducción; `/pacientes/{id}/adherencia` devuelve `registros[]` sin tope declarado | nuevo |
| 9 | Sin historial ni `actualizadoEn`: no se ve cuándo ni quién corrigió antes del último actor | nuevo |
| 10 | No hay borrado de un registro marcado por error | nuevo |
| 11 | `desde`/`hasta`: no dice si `hasta` es inclusivo; `AdherenciaEntity.desde/hasta` sin ejemplo ni regla de hora | nuevo |
| 12 | No hay filtro por `cumplido`/`tipo`/`autor` ni orden configurable en el diario | nuevo |
| 13 | No hay adherencia por tiempo de comida ni por día de la semana, ni agregada por cartera de pacientes | nuevo |
| 14 | La nutricionista no podía registrar comidas por el paciente: ahora existe `PUT /pacientes/{id}/registros` y la fila lleva `autor` | resuelto: nutricionista-no-puede-registrar-comidas |

## 9. Qué se puede dibujar sin inventar

- El diario de los últimos 7 días del paciente: fecha (en UTC), tipo de comida, cumplido sí/no, comentario y quién lo marcó.
- El botón de marcar o corregir una comida con interruptor de cumplido y comentario de hasta 500 caracteres, enviando la `fecha` elegida.
- Un anillo o barra de adherencia: valor × 100 con la ventana rotulada ("últimos 14 días"), `totalRegistros` visible y "Sin datos" cuando `adherencia` es `null`.
- La lista de registros incluidos en la adherencia con el mismo componente que el diario.
- Estados vacíos: paciente sin registros, ventana sin filas, sin datos de adherencia.
- Un selector de ventana (`desde`/`hasta`) con el default que dice el contrato.

## 10. Lo que NO se puede dibujar todavía

- "% del plan cumplido": el denominador son los registros marcados, no las comidas planificadas.
- Una vista semanal de "lo que tocaba y lo que se marcó" sin cruzar con el detalle del plan.
- Historial de cambios ("corregido por la nutricionista el martes"): sólo hay el último autor.
- Borrar un registro erróneo.
- Adherencia de toda la cartera, ranking de pacientes o alertas de baja adherencia: ningún endpoint lo agrega (las alertas de la ficha son calculadas por el sistema; este endpoint no las expone).
- Tendencias semanales de adherencia: sólo hay un número por ventana pedida.
- Recordatorios al paciente por comidas sin marcar: no hay campos ni endpoint.
