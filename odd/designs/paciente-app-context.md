# Contexto de la app del paciente (para diseñar)

Todo lo que el rol **paciente** puede ver y hacer con sus propios datos (rutas `/me`), según el contrato OpenAPI indexado (`baleadafit-api`, 49 endpoints, 90 schemas, indexado el 2026-11-16). Es **un segundo rol completo** de la misma app: otra navegación, otros datos y casi ninguna escritura.

⚠️ **Estado de verificación:** este documento sale del contrato, **no de payloads capturados**. Los seis endpoints sólo se probaron con el token de la nutricionista y respondieron `403 SIN_PERMISO` (el gating por rol funciona); **nunca se capturó una respuesta de paciente**. Donde el spec no define algo lo digo explícitamente: no inventar campos.

Complementa `odd/designs/design-system.md` y `paciente-context.md`. **Corrige** a `paciente-context.md` en los puntos que éste marcaba como "sin esquema": el contrato ya tipa `GET /me/hoy`, `GET /me/mediciones` y `GET /me/citas` (§3, §6, §7 abajo), y los totales de `GET /me/plan` son los de la **semana**, no los del día.

## 1. Mapa de endpoints

| Pantalla | Endpoint | Notas |
|---|---|---|
| Hoy | `GET /me/hoy?fecha=YYYY-MM-DD` | Un solo día del plan activo, con su registro, comidas cumplidas y próxima cita. No paginado |
| Mi plan | `GET /me/plan` | Plan activo completo, semana entera. No paginado. `null` si no hay |
| Diario | `GET /me/registros?desde&hasta` | Paginada. Por defecto, los últimos 7 días |
| Marcar comida | `PUT /me/registros` | **El único write del paciente** en estos seis. Upsert |
| Progreso | `GET /me/mediciones` | Paginada, **de la más antigua a la más reciente**, con IMC |
| Mis citas | `GET /me/citas` | Paginada, de la más reciente a la más antigua, **todas** |

Seis endpoints. Hay además `GET`/`POST /me/dispositivos` y `DELETE /me/dispositivos/{token}` en el mismo grupo: **no se cubren acá** (sus schemas no se leyeron en esta redacción). **Hecho (tarjeta `push-registra-tokens-pero-no-envia`):** el API guarda tokens de push pero todavía no manda ninguna notificación. No hay perfil propio, adherencia propia, plan anterior ni endpoint para pedir, cancelar o mover una cita.

**Nombre del recurso:** la tarjeta `mi-cuenta-hoy-devuelve-un-dia` nombra el recurso `/mi-cuenta/hoy`; el contrato lo publica como **`/me/hoy`**. Es el mismo endpoint: en este documento se usa siempre la ruta del contrato.

## 2. El rol y el acceso

- `GET /auth/me` es la primera llamada tras el login y decide la navegación: `rol` es `nutricionista`, `paciente` o `sin_perfil`. `perfil` es "nutricionista, o paciente con su nutricionista y restricciones; `null` si no tiene perfil", pero el schema lo declara como **objeto sin campos definidos** (gap 1).
- Un paciente queda vinculado automáticamente al iniciar sesión con el **correo verificado** que registró su nutricionista. Una cuenta sin ese vínculo no tiene perfil (`sin_perfil`); el contrato sólo ofrece a esas cuentas el registro de nutricionista, no un camino propio de paciente.
- Los seis endpoints devuelven **403 `SIN_PERMISO`** si el rol no alcanza (un token de nutricionista) **o** si el correo no está verificado. El `codigo` es el mismo en ambos casos: la UI no puede distinguirlos por código (gap 2).
- Errores comunes: 401 `NO_AUTENTICADO` sin token o inválido. Decidir siempre por `codigo`, no por `mensaje`.

## 3. Hoy (`GET /me/hoy`)

Query opcional `fecha` (`YYYY-MM-DD`, por defecto hoy). Responde `HoyEntity`:

```
fecha (string, ej. "2026-10-28") · dia (string, ej. "MIERCOLES")
plan { id, nombre, kcalObjetivo, totales } | null
tiempos[]       // TiempoHoyEntity
cumplidos       // número
proximaCita { id, estado, fechaHora, duracionMin, motivo } | null
```

- Con un plan **semanal** devuelve **sólo los tiempos del día que corresponde a `fecha`**, y `plan.totales` son los de **ese día**, no los de la semana. Un plan antiguo de un solo día devuelve ese día "sin importar la fecha".
- **Hecho (tarjeta `mi-cuenta-hoy-devuelve-un-dia`):** GET /mi-cuenta/hoy devuelve UN día del plan; con planes anteriores a los semanales devuelve su único día. Hoy es una pantalla **de un día**, no de la semana: la semana vive en `GET /me/plan`.
- `plan` es `null` si el paciente no tiene plan activo.
- `plan` trae sólo `id`, `nombre`, `kcalObjetivo` y `totales`: **no** trae las metas de proteína, carbohidrato y grasa ni `estado`. Esas están en `GET /me/plan`.
- `dia` se declara como `string` (no como el enum de días del plan). Los valores esperables son `LUNES…DOMINGO` sin tilde, pero el spec sólo da el ejemplo `MIERCOLES`.
- `fecha` es texto `YYYY-MM-DD`, **no** un instante: no pasarlo por `DateTime.parse(...).toLocal()`.

### Cada tiempo (`TiempoHoyEntity`)

```
id · planId · dia · tipo (DESAYUNO | MERIENDA_AM | ALMUERZO | MERIENDA_PM | CENA)
orden · pctKcal · kcalMeta · totales · desviacion
items[]      // PlanItemEntity: alimento completo + porciones + versión
registro     // RegistroComidaEntity | null — lo que ya marcó el paciente hoy
```

- `id` es el **`tiempoComidaId`** que pide `PUT /me/registros`.
- `registro: null` = comida sin marcar, **no** "no cumplida". `registro.cumplido: false` es una fila explícita.
- `items[].alimento` trae nombre, `porcionDescripcion`, `porcionGramos`, kcal y macros por porción; `porciones` es el multiplicador (0.25 a 6).
- `pctKcal` y `desviacion` son **fracciones** (ver §9, "⚠️ Fracciones").

`cumplidos` es "comidas cumplidas": el contrato no dice si cuenta sólo `cumplido: true` ni da un total; el total sale de `tiempos.length`.

## 4. Mi plan (`GET /me/plan`)

- Responde el plan **activo** (`PlanDetalleEntity`) o `null` "si la nutricionista aún no activa uno". El schema de respuesta no marca `data` como nulo: **el parser debe tolerar `data: null` con `ok: true`** (gap 3).
- Campos: `id · nombre · estado · origen (MANUAL | REGLAS | IA) · kcalObjetivo · proteinaG · carbohidratoG · grasaG · justificacion (string | null) · creadoEn · aprobadoEn`, más:
  - `tiempos[]`: toda la semana, plano, en orden de día y de tiempo.
  - `dias[]`: los mismos tiempos agrupados por día de lunes a domingo, cada día con sus `totales` y su `desviacion` (contra la meta diaria).
  - `totales` y `desviacion` de la **semana completa** (la desviación es contra `kcalObjetivo × días del plan`).
- Para "mi plan de hoy" usar `GET /me/hoy`; para la semana, `dias`. No reagrupar `tiempos` en el cliente.
- Un plan semanal tiene hasta siete días y cinco tiempos por día; `dias` sólo trae los días que tienen algún tiempo.
- Cada ítem declara la versión del alimento que usó: editar el alimento después **no cambia** el plan del paciente. En ítems anteriores al versionado `alimentoVersionId` viene `null` y se totaliza con el alimento actual.
- `estado` de un plan activo es `ACTIVO`; el paciente **no** ve borradores ni archivados.

## 5. Diario y marcar comidas

### Leer (`GET /me/registros`)

Igual que el diario de la nutricionista: cada fila es `RegistroComidaConTipoEntity`:

```
id · pacienteId · tiempoComidaId · fecha · cumplido · comentario (string | null) · creadoEn
autor (PACIENTE | NUTRICIONISTA)
tiempoComida { tipo }
```

Filtros `desde` y `hasta` (`YYYY-MM-DD`; por defecto 7 días atrás y hoy). Orden, filtros y paginación en §8.

`autor` es **el último actor que escribió la fila**, no una auditoría: si la nutricionista corrigió una comida y el paciente vuelve a marcarla, `autor` regresa a `PACIENTE`. El paciente puede ver `autor: NUTRICIONISTA` en su diario: la pantalla debe poder explicarlo ("registrado por tu nutricionista").

### Marcar (`PUT /me/registros`)

```json
{
  "tiempoComidaId": "uuid",           // obligatorio: tiempos[].id de GET /me/hoy
  "cumplido": true,                   // obligatorio
  "fecha": "2026-10-28",              // YYYY-MM-DD; por defecto, hoy
  "comentario": "Cambié el plátano por yuca"   // máx. 500
}
```

- Marca un tiempo como cumplido o no en una fecha; **si ya existe, lo actualiza** (upsert por paciente, tiempo y fecha). Responde **200** con `RegistroComidaEntity` también al crear.
- Errores: **400** `VALIDACION` con `detalles` por campo; **404** "no existe o no pertenece al usuario"; 401; **403** si el token no es de paciente.
- Es un **toggle con comentario opcional**, no un formulario largo. No hay forma de borrar el registro: desmarcar es volver a hacer el PUT con `cumplido: false`.
- ⚠️ **`comentario`:** la tarjeta `no-esta-definido-como-limpiar-un-campo-de-texto` dice que omitir un campo de texto al editar conserva el valor; no está definido cómo borrarlo; habla de **editar** y no dice si rige para este upsert. El spec tampoco define `""`. No asumir que el comentario se conserva ni que se borra al volver a marcar; probarlo antes de diseñar "editar comentario" o un toggle que reenvíe el body sin comentario.
- ⚠️ **`fecha` por defecto:** el contrato no declara con qué zona horaria se resuelve "hoy" en el servidor. Enviar siempre la `fecha` explícita con el **día de calendario del dispositivo**, para que un paciente en Tegucigalpa (GMT-6) que marca a la noche no caiga en el día siguiente.
- El spec tampoco dice si se puede marcar un día futuro, un día pasado lejano, o un tiempo de un día que no corresponde a la `fecha` (gap 8).

## 6. Progreso (`GET /me/mediciones`)

Cada fila es `MedicionConImcEntity`: los 25 campos de una medición más `imc`:

```
id · pacienteId · fecha · fuente (MANUAL | BASCULA | INBODY | OMRON | OTRO) · creadoEn
pesoKg · tallaCm                                 // obligatorios
pctGrasa · cinturaCm · masaMuscularKg · masaGrasaKg · grasaVisceral (1–20)
aguaIntracelularL · aguaExtracelularL · anguloFase
pliegueTricipitalMm · pliegueSubescapularMm · pliegueSuprailiacoMm · pliegueBicipitalMm
perimetroBrazoCm · perimetroCaderaCm · perimetroMusloCm
presionSistolica · presionDiastolica · notas
imc                                              // calculado por el API
```

Entre los datos clínicos, todo salvo `pesoKg`, `tallaCm` y `imc` puede ser `null`. Los datos reales del lado nutricionista traen casi siempre sólo peso, talla y % grasa: dibujar lo que existe y ocultar lo `null`.

⚠️ **Orden: de la más antigua a la más reciente**, paginado de 20 por defecto (máximo 100), **sin filtro de fechas**. La medición más actual está en la **última** página. En modo offset `meta.total` permite saltar al final (`offset = total − n`); en modo cursor hay que recorrer todas las páginas.

`pctGrasa` es un **porcentaje** (`34` = 34 %) mientras que `pctKcal` del plan es una fracción: ver §9.

## 7. Mis citas (`GET /me/citas`)

Cada fila es `CitaPacienteEntity`:

```
id · fechaHora (ISO con zona) · duracionMin · motivo (string | null)
estado (PROGRAMADA | COMPLETADA | CANCELADA)
nutricionista { nombre }
```

- **Todas** las citas, de la más reciente a la más antigua: las futuras aparecen primero. No hay filtro de `estado`, `desde` ni `hasta`.
- ⚠️ **No es el `CitaEntity` de la agenda de la nutricionista**: el paciente **no** recibe `notas`, los cuatro campos SOAP ni `proximaCitaSugerida`, y de la nutricionista sólo el `nombre` (sin teléfono ni correo). La pantalla no puede mostrar "lo que dijo la nutricionista en la consulta" ni la fecha sugerida de la próxima.
- `estado` tiene tres valores. No existe "en curso", "confirmada" ni "no asistió".
- La `proximaCita` de `GET /me/hoy` es un `{id, estado, fechaHora, duracionMin, motivo}` (sin `nutricionista`); el contrato no dice qué estado ni qué ventana define "próxima" (gap 7).

## 8. Las listas

Los endpoints paginados son `/me/registros`, `/me/mediciones` y `/me/citas`. `limit` (20 por defecto, máximo 100) con `offset` (base 0) **o** `cursor` (el `nextCursor` previo); responden `{ok, data: [], meta: {limit, offset, total, hasMore, nextCursor}}`. Mezclar offset y cursor da 400 `VALIDACION`; un cursor ajeno, 400 `CURSOR_INVALIDO`. En modo cursor `meta` no trae `total`. La app usa scroll infinito: modo cursor.

| Lista | Orden | Filtros |
|---|---|---|
| `/me/registros` | más reciente primero | `desde`, `hasta` (7 días por defecto) |
| `/me/mediciones` | **más antigua primero** | ninguno |
| `/me/citas` | más reciente primero | ninguno |

No hay parámetro de orden en ninguna. `/me/hoy` y `/me/plan` no se paginan.

## 9. Fechas y números: lo que rompe pantallas

- **Calendario a medianoche UTC.** `fecha` de un registro y de una medición es un `date-time` que, por el ejemplo del contrato, viene a medianoche UTC (`2026-10-28T00:00:00.000Z`). Formatearlo en `America/Tegucigalpa` (GMT-6) muestra **el día anterior**. Mostrar el día con componentes UTC; nunca `toLocal()` ni restar horas.
- `fechaHora` de una cita y `creadoEn` son instantes: se formatean en la zona del dispositivo con `toLocal()`.
- `fecha` en `GET /me/hoy` y `fecha` en el body de `PUT /me/registros` son texto `YYYY-MM-DD`: enviar el día de calendario que ve el paciente, sin conversión.
- El **día de la semana lo decide el servidor** a partir de `fecha`: si la app manda otra `fecha` que la que ve el paciente, verá la comida de otro día.
- **⚠️ Fracciones y porcentajes.** `pctKcal` (`0.35` = 35 % de las kcal del día) y `desviacion` (`(real − meta) / meta`, `0.05` = +5 %) son **fracciones**. `pctGrasa` (`34`) es un **porcentaje**. Decidir la conversión por campo.
- `totales` y `desviacion` cambian de alcance según el endpoint: tiempo, día (`/me/hoy`, `dias[]`) o semana (`/me/plan`). Declarar el alcance en la UI.
- Todos los valores nutricionales deben llevar su unidad: kcal, g, mg, cm, kg, %.
- La tarjeta `dashboard-ficha-contract-gotchas` registra "campos de cita, fechas y porcentajes que no se deducen del OpenAPI": este documento sale del contrato, así que conviene leerla antes de fiarse de un tipo o de una unidad de esta sección.

## 10. Estados de datos que hay que dibujar

| Estado | Cómo se ve |
|---|---|
| **Sin plan activo** | `GET /me/hoy`: `plan: null`; `GET /me/plan`: `data: null`. Hoy no tiene comidas; mensaje de que la nutricionista aún no activó uno |
| Día sin tiempos | Plan semanal sin ese día en `dias`: `tiempos: []` esperable, pero el spec no lo garantiza |
| Comida sin marcar | `registro: null` |
| Comida cumplida / no cumplida | `registro.cumplido` `true` / `false` |
| Día sin registrar | `cumplidos: 0` |
| Corrección de la nutricionista | `registro.autor` / fila del diario con `autor: NUTRICIONISTA` |
| Sin próxima cita | `proximaCita: null` |
| Sin historial de citas | `data: []` en `/me/citas`: nunca tuvo cita |
| Primer uso sin mediciones | `data: []` en `/me/mediciones`: sin gráfico |
| Una sola medición | Sin tendencia; el gráfico necesita al menos dos puntos |
| Campos de medición `null` | Ocultar, no mostrar guiones ni 0 |
| `sin_perfil` | La cuenta no tiene perfil (por ejemplo, correo no vinculado a ningún paciente): el contrato no define una pantalla para este caso |
| Token de otro rol / correo sin verificar | 403 `SIN_PERMISO`; por `codigo` no se distinguen |
| Sin conexión / 401 | Mensaje de la API y reintento |
| Validación al marcar | 400 con `detalles` por campo |

## 11. Gaps del contrato (a resolver en el repo del API, no en el diseño)

**Estado en el board:** contrastado con el índice de 20 tarjetas de `baleadafit-api` (se conocen las claves y los títulos, no el cuerpo de cada tarjeta). Marcas: `ya pedido: <clave>` = hay tarjeta que lo pide al BE; `resuelto: <clave>` = había tarjeta y el contrato ya lo resuelve; `nuevo` = no hay tarjeta, hay que pedirlo. Los hechos de las tarjetas que condicionan el diseño están en §1, §3 y §5.

| # | Gap | Board |
|---|---|---|
| 1 | `perfil` de `GET /auth/me` es un objeto sin esquema: no hay nombre del paciente, de su nutricionista ni restricciones tipadas para la cabecera | nuevo |
| 2 | Un 403 `SIN_PERMISO` mezcla "rol equivocado" y "correo sin verificar": no hay código separado | nuevo |
| 3 | `GET /me/plan` documenta `null` pero su schema no lo marca como nulable | nuevo |
| 4 | `HoyEntity.dia` es `string` y no el enum de días | nuevo |
| 5 | `GET /me/hoy`: no define el resultado de una `fecha` inválida ni la `dia` de un plan de un solo día que se devuelve "sin importar la fecha"; no declara 400 | nuevo |
| 6 | No hay endpoint de adherencia del paciente: sólo `cumplidos` de hoy (sin total) y el diario crudo | nuevo |
| 7 | `proximaCita` no define qué estado ni ventana cuenta como "próxima" | nuevo |
| 8a | `PUT /me/registros` no define fechas futuras o muy pasadas, ni la coincidencia entre `fecha` y el `dia` del tiempo | nuevo |
| 8b | `comentario` omitido o `""` al volver a marcar: el hecho de la tarjeta cubre editar (omitir conserva) y la falta de forma de borrar; no dice si rige para el upsert | ya pedido: no-esta-definido-como-limpiar-un-campo-de-texto |
| 9 | `/me/mediciones` no filtra por fecha y va de la más antigua a la más reciente | nuevo |
| 10 | `/me/citas` no filtra, no ordena y no entrega notas ni SOAP ni la fecha sugerida de la próxima | nuevo |
| 11 | "Hoy" del default de `fecha` no declara zona horaria | nuevo |
| 12 | `cumplidos` de `/me/hoy` sin definición exacta (¿sólo `cumplido: true`?) ni total | nuevo |
| 13 | El paciente no puede pedir, cancelar ni mover una cita, ni editar su perfil | nuevo |
| 14 | Sólo existe el plan **activo**: no hay historial de planes del paciente | nuevo |
| 15 | El API guarda tokens de push (`/me/dispositivos`) pero todavía no manda ninguna notificación | ya pedido: push-registra-tokens-pero-no-envia |

## 12. Qué se puede dibujar sin inventar

- **Hoy:** saludo, `cumplidos` sobre `tiempos.length`, la lista de comidas del día con tipo, alimentos y porciones, kcal del tiempo (`kcalMeta`) y un interruptor de cumplido por tiempo; la próxima cita (fecha local, duración, motivo).
- **Mi plan:** kcal y macros objetivo, justificación, semana por día (`dias`), totales y desviación de la semana con su alcance rotulado; origen del plan.
- **Diario:** lista de los últimos 7 días con tipo de comida, cumplido, comentario y `autor`.
- **Progreso:** peso, IMC, % grasa y las medidas que vengan no nulas; gráfico de evolución con fechas en UTC; fuente de cada medición.
- **Mis citas:** lista con fecha local, duración, motivo, estado y nombre de la nutricionista; futuras primero.
- **Estado vacío** para cada caso de §10; en particular "sin plan" y "sin citas", que son los primeros que verá un paciente nuevo.

## 13. Lo que NO se puede dibujar todavía

- Un porcentaje de adherencia del paciente (semanal, mensual, racha): no hay endpoint; sólo `cumplidos` de hoy.
- Las notas, el SOAP o la fecha sugerida de la próxima cita: el paciente no las recibe.
- Pedir, cancelar o reprogramar una cita; ver teléfono o correo de la nutricionista.
- Editar el perfil, el peso o cargar una medición propia: el paciente no tiene ningún write de mediciones.
- Ver planes anteriores o comparar planes.
- "Sustituir un alimento" o lista de compras: no hay endpoint ni campos.
- Notificaciones o recordatorios por comida: el API registra tokens de push pero **todavía no envía ninguna notificación** (tarjeta `push-registra-tokens-pero-no-envia`); no dibujar ajustes de recordatorios.
- Una cabecera con nombre del paciente y de su nutricionista tipada: `perfil` no tiene esquema.
- Borrar un registro o ver el historial de correcciones de una comida.
