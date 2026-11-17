# Contexto del módulo Planes (para diseñar)

Todo lo que el rol **nutricionista** puede ver y hacer con los planes alimenticios de un paciente, según el contrato OpenAPI indexado (`baleadafit-api`, 49 endpoints, 90 schemas, indexado el 2026-11-16).

⚠️ **Estado de verificación:** este documento sale del contrato, **no de payloads capturados**. Lo único observado contra la API real es la generación y activación de un plan de prueba, registrada en `pacientes-context.md` §9, y es **anterior** a que el contrato incorporara `dia` y `dias` (el plan pasó a ser semanal). Donde el spec no define algo lo digo explícitamente: no inventar campos.

Complementa `odd/designs/design-system.md` y `pacientes-context.md`.

## 1. Mapa de endpoints

| Uso | Endpoint | Notas |
|---|---|---|
| Listar planes del paciente | `GET /pacientes/{id}/planes` | Paginada, del más reciente al más antiguo, **sin detalle** (`PlanEntity`) |
| Generar | `POST /pacientes/{id}/planes/generar` | Crea un plan en `BORRADOR`. Requiere al menos una medición del paciente. Responde 201 con el detalle |
| Detalle | `GET /planes/{id}` | Tiempos, alimentos, totales y desviación (`PlanDetalleEntity`) |
| Editar datos | `PATCH /planes/{id}` | Nombre, metas y justificación. No permitido en planes archivados |
| Activar | `POST /planes/{id}/activar` | Pasa a `ACTIVO` y el anterior activo pasa a `ARCHIVADO`. Responde 201 con el detalle |
| Reemplazar alimentos | `PUT /planes/{id}/tiempos/{dia}/{tipo}/items` | Reemplaza la lista **completa** de un tiempo de comida de un día |
| Eliminar | `DELETE /planes/{id}` | Solo `BORRADOR`. Responde 204 sin cuerpo |

⛔ `PUT /planes/{id}/tiempos/{tipo}/items` (sin `dia`) está **obsoleto**: el contrato dice que equivale a `dia = LUNES`. El plan es **semanal**; no usar esa ruta ni diseñar una edición que asuma un solo día.

Siete operaciones vigentes. No hay endpoint para crear un plan a mano (vacío), duplicar uno, reactivar uno archivado ni desactivar el activo.

## 2. El plan

### En la lista (`PlanEntity`)

```
id · pacienteId · nutricionistaId · nombre
estado (BORRADOR | ACTIVO | ARCHIVADO) · origen (MANUAL | REGLAS | IA)
kcalObjetivo · proteinaG · carbohidratoG · grasaG
justificacion (string | null) · creadoEn · aprobadoEn (date-time | null)
```

La lista **no trae** tiempos, alimentos ni totales. Para una tarjeta de plan alcanza con nombre, estado, origen, `kcalObjetivo` y macros objetivo; para cualquier número "real" hay que pedir el detalle.

### En el detalle (`PlanDetalleEntity`)

Todo lo anterior más:

```
tiempos[]   // TiempoComidaEntity: toda la semana, plano, en orden de día y de tiempo
dias[]      // DiaPlanEntity: los mismos tiempos agrupados por día, de lunes a domingo
totales     // TotalesEntity: totales de la SEMANA completa
desviacion  // contra la meta semanal (kcalObjetivo × días del plan)
```

`tiempos` y `dias` son **la misma información en dos formas**: usar `dias` para dibujar una semana por columnas y no reagrupar `tiempos` en el cliente.

### El día (`DiaPlanEntity`)

```
dia (LUNES | MARTES | MIERCOLES | JUEVES | VIERNES | SABADO | DOMINGO)
tiempos[] · totales (del día) · desviacion (contra kcalObjetivo, que es diaria)
```

Los valores de `dia` van **sin tilde** (`MIERCOLES`, `SABADO`): son códigos, la etiqueta con tilde la pone la UI. `dias` trae sólo "los días que tienen algún tiempo de comida": un plan puede tener menos de siete.

No confundir con el SOAP de la consulta: el campo `plan` de una cita se rotula **`Plan de la consulta`** (tarjeta `citas-sin-get-por-id`) para que no se lea como el plan de comidas de este módulo.

### El tiempo de comida (`TiempoComidaEntity`)

```
id · planId · dia · tipo (DESAYUNO | MERIENDA_AM | ALMUERZO | MERIENDA_PM | CENA)
orden · pctKcal · kcalMeta · totales · desviacion
items[]   // PlanItemEntity
```

Un plan semanal tiene **cinco tiempos por día** (hasta 35 en la semana). El `id` del tiempo es el que usa el diario para marcar una comida (ver `diario-context.md`).

### El alimento del plan (`PlanItemEntity`)

```
id · tiempoComidaId · alimentoId · porciones
alimento { …AlimentoEntity completo: nombre, porcionDescripcion, porcionGramos, kcal, macros, micronutrientes, categoria, tiposComida, contiene, esTipicoHn, activo… }
alimentoVersionId (string | null) · alimentoVersion (AlimentoVersionEntity | null)
```

Los totales salen de `alimentoVersion`, **no** del alimento vivo: editar un alimento del catálogo **no cambia** un plan existente. En los ítems anteriores al versionado `alimentoVersionId` y `alimentoVersion` vienen `null` y esos ítems **sí** totalizan con el alimento actual: dos ítems iguales en pantalla pueden estar calculados con valores distintos.

La versión del alimento es **plana** (tarjeta `alimento-version-es-plana`: la versión de la tabla nutricional es plana): `kcal`, macros y micronutrientes viven al mismo nivel que `version` y `tabla`, no anidados. Los micronutrientes aparecen declarados en el contrato porque la tarjeta `alimento-no-devuelve-micronutrientes` ya está corregida (el JSON los traía, faltaba declararlos en el esquema).

### Totales (`TotalesEntity`)

Once números, todos obligatorios: `kcal`, `proteinaG`, `carbohidratoG`, `grasaG`, `fibraG`, `sodioMg`, `potasioMg`, `fosforoMg`, `azucaresG`, `grasasSatG`, `cargaGlucemica`. Se repite igual en el tiempo, el día y la semana: **el alcance cambia, la forma no**. Declarar siempre el alcance en la UI ("del día", "de la semana").

### ⚠️ Fracciones y porcentajes: el contrato mezcla convenciones

| Campo | Qué es | Ejemplo del spec |
|---|---|---|
| `pctKcal` | **fracción** 0..1 de las kcal del día (pese al nombre `pct`) | `0.35` = 35 % |
| `desviacion` | **fracción con signo**: `(real − meta) / meta` | `0.05` = +5 %; `0.004` = +0,4 % |
| `distribucionMacros.*`, `distribucionTiempos.*` (al generar) | **fracciones** 0..1, aunque su descripción habla en "25 %" | `0.3` |
| `porciones` | número de porciones, 0.25 a 6 | `1.5` |

Para contraste: en las mediciones `pctGrasa` es un **porcentaje** (`34` = 34 %). Multiplicar por 100 un `pctKcal` y no un `pctGrasa` es una decisión por campo, nunca genérica. Un `0.35` dibujado como "0 %" o un `0.004` como "0.004 %" son los errores esperables.

## 3. Generar (`POST /pacientes/{id}/planes/generar`)

Body, todos los campos opcionales:

```json
{
  "nombre": "Plan inicial",              // máx. 120; por defecto "Plan YYYY-MM-DD"
  "usarIa": true,                        // por defecto true; false = sólo reglas
  "kcalObjetivo": 1600,                  // 1000–5000; sobrescribe el cálculo Mifflin-St Jeor
  "distribucionMacros": { "proteina": 0.3, "carbohidrato": 0.45, "grasa": 0.25 },
  "distribucionTiempos": { "DESAYUNO": 0.3, "MERIENDA_AM": 0, "ALMUERZO": 0.4, "MERIENDA_PM": 0.1, "CENA": 0.2 },
  "indicaciones": "Prefiere desayunos rápidos y cenas sin frituras."   // máx. 500, para la IA
}
```

- Rangos de `distribucionMacros`: proteína 0.1–0.5, carbohidrato 0.2–0.7, grasa 0.1–0.5 (los tres obligatorios si se envía el objeto). `distribucionTiempos`: cada tiempo 0–1.
- Por defecto, macros 25 / 50 / 25 y tiempos 25 / 10 / 35 / 10 / 20 %.
- Pasos del recomendador según el contrato: calcula kcal y macros, filtra el catálogo por las restricciones del paciente, si `usarIa` Bedrock propone, el backend descarta alimentos inexistentes y ajusta porciones a **±10 % por tiempo de comida**, y si la IA no está disponible cae a reglas (`origen = REGLAS`).
- **Requiere al menos una medición.** El spec no dice qué código devuelve si no la hay: sólo declara 400/401/403/404 genéricos. La UI debería comprobar `ultimaMedicion` del paciente antes de ofrecer el botón.
- **Hecho (tarjeta `ficha-sin-mediciones-devuelve-requerimiento-null`):** la ficha devuelve requerimiento null y evolucion [] sin mediciones. Es la señal para deshabilitar "Generar plan" desde la ficha sin llamar antes.
- 201 con el plan completo en `BORRADOR`. Errores: 400 (`VALIDACION`, con `detalles` por campo), 401, 403, 404 (paciente inexistente o ajeno).
- `usarIa` es `true` por defecto, pero eso no garantiza que el resultado sea de IA: la pantalla debe leer `origen` (`IA` o `REGLAS`) y `justificacion`.
- **Hecho (tarjeta `plan-generado-hoy-es-por-reglas`):** en producción POST /pacientes/{id}/planes/generar devuelve planes con `origen: REGLAS`; el recomendador con IA no está activo. Hoy un plan generado **no tiene IA detrás**: ninguna pantalla debe prometerla. Coincide con la corrida real de `pacientes-context.md` §9, cuya justificación dice que la IA no estaba disponible.
- **Hecho (tarjeta `recomendador-costo-y-latencia-reales`):** plan semanal US$0.06–0.11 y 23–25 s medidos; la primera corrida es la cara (caché de prompt). Si el recomendador con IA se activa, el paso de generar es una **espera de 23–25 s**: la pantalla necesita un estado de carga largo y no puede ser un botón que "responde al instante". El costo por plan es un dato de operación, no de pantalla; la tarjeta no da tiempos para `REGLAS`.
- **Hecho (tarjeta `recomendador-esquema-del-prompt-va-con-el-parser`):** si el esquema del prompt y el parser se desalinean, todo el plan cae a reglas y sale con `origen: IA` sin error ni log. Consecuencia para el diseño: `origen: IA` por sí solo **no prueba** que el contenido lo haya propuesto la IA; la pantalla no debe presentar `origen` como garantía de calidad ni de método.

## 4. Editar datos (`PATCH /planes/{id}`)

```json
{
  "nombre": "Plan noviembre",    // máx. 120
  "kcalObjetivo": 1500,          // 1000–5000
  "proteinaG": 95,               // ≥ 0
  "carbohidratoG": 180,          // ≥ 0
  "grasaG": 45,                  // ≥ 0
  "justificacion": "…"           // máx. 4000
}
```

Todos opcionales; responde 200 con el **detalle completo**. Errores: 400, 401, 403, 404. **No permitido en planes archivados**: el spec no dice con qué status ni código responde esa violación (no declara 409).

Peligros concretos de este PATCH:

- **No hay `estado`, `origen`, distribución ni `pctKcal` editables.** El PATCH no cambia qué porcentaje del día ocupa cada tiempo ni los alimentos: eso sólo se toca con el PUT de ítems.
- Las cuatro metas numéricas son **independientes**: el contrato no dice que se valide que las kcal coincidan con los macros, ni que cambiar `kcalObjetivo` reescale las porciones. Cambiar una meta mueve `desviacion` sin tocar un solo alimento.
- `justificacion` es `null` o texto en la respuesta, pero el body sólo admite texto. **Hecho (tarjeta `no-esta-definido-como-limpiar-un-campo-de-texto`):** omitir un campo de texto al editar conserva el valor; no está definido cómo borrarlo. Para `justificacion`: omitirla conserva el valor; no hay forma definida de vaciarla. No prometer un botón "borrar justificación" ni asumir que `""` limpia.
- Editar un plan **activo** no está prohibido por el contrato, y ese plan es el que ve el paciente (§5).

## 5. Activar (`POST /planes/{id}/activar`)

- El plan queda `ACTIVO` y "visible en la app del paciente"; el activo anterior pasa a `ARCHIVADO`. Es la acción que **publica**: merece confirmación y una frase que diga qué plan deja de estar vigente.
- 201 con el detalle; `aprobadoEn` se llena (observado en `pacientes-context.md` §9).
- Errores: 400, 401, 403, 404. El spec no dice cuándo da 400 (por ejemplo, activar uno ya activo o archivado).
- **No hay vuelta atrás declarada:** no existe "desactivar" ni "desarchivar". La única forma de volver a un plan previo es activar otro (el contrato no dice si un `ARCHIVADO` se puede activar de nuevo).

## 6. Reemplazar alimentos (`PUT /planes/{id}/tiempos/{dia}/{tipo}/items`)

```json
{ "items": [ { "alimentoId": "uuid", "porciones": 1.5 } ] }
```

- Ruta: `dia` en `LUNES…DOMINGO`, `tipo` en `DESAYUNO…CENA`. Un PUT toca **un tiempo de un día**; llenar una semana son hasta 35 llamadas.
- ⚠️ **Reemplaza la lista completa** del tiempo. Enviar un solo alimento deja ese tiempo con un solo alimento; no agrega. La pantalla debe mandar siempre el estado final del tiempo, no el cambio.
- Máximo **12** ítems. `porciones`: 0.25 a 6, "múltiplos de 0.25 recomendados" (recomendados, no exigidos por el contrato). `alimentoId` viene de `GET /alimentos`.
- Los ítems nuevos quedan atados a la versión vigente de cada alimento. El contrato no dice si un ítem que se reenvía sin cambios conserva su versión o pasa a la vigente (gap 8).
- Responde 200 con el **plan completo** (`PlanDetalleEntity`): reemplazar la fuente de verdad local con esa respuesta, no parchear a mano.
- Errores: 400, 401, 403, 404. El schema no impone mínimo de ítems; si `items: []` vacía el tiempo, el spec no lo dice.

## 7. Eliminar (`DELETE /planes/{id}`)

Sólo `BORRADOR`; 204 sin cuerpo. Es el único borrado real de este módulo (los planes activos y archivados no se eliminan). Errores: 400, 401, 403, 404. Un plan no borrador devuelve un error que el spec no distingue: decidir por `codigo`, no por texto.

## 8. La lista (`GET /pacientes/{id}/planes`)

Paginación estándar: `limit` (20 por defecto, máximo 100) y `offset` (base 0) **o** `cursor`; responde `{ok, data: [], meta: {limit, offset, total, hasMore, nextCursor}}`. Offset y cursor **juntos** dan 400 `VALIDACION`; un cursor que no es de esta lista da 400 `CURSOR_INVALIDO` (según la introducción del contrato). En modo cursor `meta` no trae `total`.

Del más reciente al más antiguo; no hay parámetro de orden ni filtro por `estado`. Para encontrar el plan activo hay que leer `estado` en cada fila: el contrato no garantiza que esté primero. Un solo ACTIVO a la vez por paciente se deduce de "el anterior pasa a ARCHIVADO", no de una regla escrita.

## 9. Fechas

- `creadoEn` y `aprobadoEn` son instantes ISO con zona: se formatean en la zona del dispositivo (`toLocal()`).
- Los planes **no tienen fecha de inicio ni de fin**: no hay `desde`/`hasta` en el plan. La semana se identifica por `dia` (`LUNES…DOMINGO`), no por fecha de calendario.
- Las fechas de calendario del resto de la API (registros, mediciones) se guardan a **medianoche UTC**: mostrarlas en `America/Tegucigalpa` (GMT-6) da el **día anterior**. No aplica a los campos de este módulo, pero sí al cruzar un tiempo del plan con el diario.

## 10. Estados de datos que hay que dibujar

| Estado | Cómo se ve |
|---|---|
| **Paciente sin planes** | `data: []`, `total: 0`. Es el caso del paciente nuevo; la acción siguiente es generar |
| Sin medición | No se puede generar (§3): dar el camino a "nueva medición" en vez de un error crudo |
| `BORRADOR` | Editable y eliminable; todavía invisible al paciente |
| `ACTIVO` | Visible al paciente; el único con `aprobadoEn` esperable |
| `ARCHIVADO` | Sólo lectura: el PATCH no se permite |
| `origen` `REGLAS` / `IA` / `MANUAL` | Tres etiquetas distintas; ver gap 5 sobre `MANUAL` |
| Plan con menos de 7 días | `dias` sólo trae los que tienen tiempos: no dibujar columnas fantasma |
| Tiempo sin ítems | `items: []`; el contrato no dice qué valen sus `totales` ni su `desviacion` |
| Ítem sin versión | `alimentoVersionId: null`: totaliza con el alimento actual (§2) |
| Alimento inactivo en un plan | el schema permite `alimento.activo: false` dentro de un ítem; el contrato no dice si ocurre ni cómo mostrarlo |
| `justificacion: null` | Plan sin explicación: ocultar el bloque |
| Generación en curso | El contrato sólo define la respuesta final (201): no hay estado intermedio. Con IA se midieron 23–25 s (tarjeta `recomendador-costo-y-latencia-reales`): estado de carga largo sin progreso |

## 11. Gaps del contrato (a resolver en el repo del API, no en el diseño)

**Estado en el board:** contrastado con el índice de 20 tarjetas de `baleadafit-api` (se conocen las claves y los títulos, no el cuerpo de cada tarjeta). Marcas: `ya pedido: <clave>` = hay tarjeta que lo pide al BE; `resuelto: <clave>` = había tarjeta y el contrato ya lo resuelve; `nuevo` = no hay tarjeta, hay que pedirlo. Los hechos de las tarjetas que condicionan el diseño están en §2 y §3, no en esta tabla.

| # | Gap | Board |
|---|---|---|
| 1 | `generar` no declara cuántos días produce ni si siempre son siete; `dias` sólo dice "los que tienen algún tiempo" | nuevo |
| 2 | `distribucionTiempos` y `distribucionMacros`: no dice si deben sumar 1, ni qué pasa con un tiempo en `0` (el propio ejemplo pone `MERIENDA_AM: 0`): ¿el tiempo se omite o queda vacío? | nuevo |
| 3 | Sin medición, `generar` falla con un código no declarado (sólo 400/404 genéricos) | nuevo |
| 4 | Violaciones de estado (PATCH en archivado, DELETE en no borrador, activar inválido) sin código propio: ningún endpoint de planes declara 409 | nuevo |
| 5 | Existe `origen: MANUAL`, pero no hay endpoint que cree un plan manual; no se dice si editar ítems cambia el `origen` | nuevo |
| 6 | `PATCH` permite metas independientes: no dice si se valida kcal contra macros ni si reescala porciones | nuevo |
| 7 | `justificacion` es `string \| null` en la salida y `string` en el body: omitirla conserva el valor (hecho de la tarjeta), pero no hay forma declarada de limpiarla | ya pedido: no-esta-definido-como-limpiar-un-campo-de-texto |
| 8 | Editar ítems de un plan **activo** no está prohibido ni advertido; no dice si `tiempos[].id` se conserva (de ello depende el diario), qué pasa con los registros ya marcados, ni si un ítem reenviado sin cambios conserva su versión de alimento | nuevo |
| 9 | `items: []` es válido por schema (sin `minItems`): efecto no definido | nuevo |
| 10 | La descripción de `PUT /pacientes/{id}/registros` dice que `tiempoComidaId` "viene en `GET /pacientes/{id}/planes`", pero esa lista devuelve `PlanEntity` **sin tiempos**: el id está en `GET /planes/{id}` (`tiempos[].id`) | nuevo |
| 11 | `TotalesEntity` no admite nulos pero varios campos del alimento sí (`sodioMg`, `fibraG`…): no dice si un nulo cuenta como 0 y subestima el total | nuevo |
| 12 | La lista no filtra por `estado` ni marca cuál es el activo | nuevo |
| 13 | No hay copiar día, duplicar plan, reactivar archivado, desactivar ni cambiar `pctKcal` de un tiempo después de generar | nuevo |
| 14 | El 400 de `activar` no se explica | nuevo |

## 12. Qué se puede dibujar sin inventar

- La lista de planes del paciente con nombre, estado, origen, `kcalObjetivo`, macros objetivo y fecha de creación, y el estado vacío con la acción "Generar plan".
- La semana: `dias` en orden, cada día con sus cinco tiempos, los alimentos (`alimento.nombre`, `porciones`, `porcionDescripcion`), los totales del día y su desviación.
- Totales de la semana y de cada tiempo, con la desviación en % (fracción × 100) y signo.
- El formulario de generación (nombre, kcal, macros, distribución de tiempos, indicaciones, interruptor de IA) con los rangos del contrato.
- Edición de un tiempo con buscador de alimentos (`GET /alimentos`), porciones de 0.25 a 6 y tope de 12 ítems; guardado con el estado final del tiempo.
- Edición de nombre, metas y justificación de un plan que no esté archivado.
- Acciones de activar (con confirmación) y eliminar borrador.
- Etiqueta de origen y la `justificacion` del recomendador tal como llega.

## 13. Lo que NO se puede dibujar todavía

- "Plan generado por IA" como promesa: hoy producción devuelve `origen: REGLAS` (tarjeta `plan-generado-hoy-es-por-reglas`) y aun con `origen: IA` el contenido puede haber caído a reglas sin aviso.
- Copiar un día a otro o "repetir lunes toda la semana" con una acción: no existe; son PUT por tiempo.
- Arrastrar para reordenar tiempos o cambiar el porcentaje de un tiempo: ningún DTO lo permite después de generar.
- Duplicar un plan, crear uno vacío, reactivar uno archivado o desactivar el activo.
- Historial o comparación entre planes, versiones de un mismo plan o quién cambió qué.
- Fechas de vigencia ("plan de noviembre a diciembre"): el plan no las tiene.
