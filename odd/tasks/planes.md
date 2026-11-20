# Planes alimenticios (BO)

Feature: los planes de comidas de un paciente en la app Flutter del nutricionista — lista, estado
vacío, generador, detalle semanal del borrador (con activar y eliminar) y editor de un tiempo de
comida. Dibujado contra cinco artboards (`odd/designs/planes/`, export de `BaleadaFit Ideas-2.html`)
y contrastado con el contrato OpenAPI (`baleadafit-api`, 49 endpoints, 90 schemas, indexado el
2026-11-16) en `odd/designs/planes-context.md`. **La copy sale de `odd/designs/planes/README.md`,
verbatim.** Lo que ese inventario no trae y la pantalla necesita está marcado `C#` y lo valida el humano.

## Specs

**S1 — Alcance.** Las siete operaciones vigentes del contrato, solo del lado BO: `GET
/pacientes/{id}/planes`, `POST /pacientes/{id}/planes/generar`, `GET /planes/{id}`, `POST
/planes/{id}/activar`, `PUT /planes/{id}/tiempos/{dia}/{tipo}/items`, `DELETE /planes/{id}` y
`PATCH /planes/{id}`. **`PATCH` no tiene pantalla**: ningún artboard dibuja editar nombre, metas ni
justificación, así que no entra en esta entrega aunque el contrato lo permita. Fuera también: el lado
paciente y el diario.

**S2 — Lo que el contrato impone.**
(a) `generar` **requiere al menos una medición** del paciente.
(b) Un plan nace en `BORRADOR`: `generar` responde 201 con el detalle y el plan sigue invisible al
paciente.
(c) Activar es `POST /planes/{id}/activar`; responde 201 con el detalle y el activo anterior pasa a
`ARCHIVADO`.
(d) Reemplazar alimentos es **por día Y por tiempo de comida**: `PUT
/planes/{id}/tiempos/{dia}/{tipo}/items`, con `dia` en `LUNES…DOMINGO` (sin tilde: son códigos) y
`tipo` en `DESAYUNO | MERIENDA_AM | ALMUERZO | MERIENDA_PM | CENA`. **Nunca** la ruta obsoleta
`PUT /planes/{id}/tiempos/{tipo}/items`, que equivale a `dia = LUNES`.
(e) El PUT **reemplaza la lista completa**: se manda siempre el estado final del tiempo, no el
cambio. Responde 200 con el plan completo y esa respuesta reemplaza lo que la pantalla tiene.
(f) `DELETE` solo existe para `BORRADOR` y responde 204 sin cuerpo.

**S3 — Fracciones y porcentajes, campo por campo.** `desviacion` y `pctKcal` son **fracciones** 0..1
(`0.004` = +0.4%, `0.35` = 35%) y se multiplican por 100 para mostrarse. `pctGrasa` (mediciones)
es un **porcentaje** y **no** se multiplica. `distribucionMacros.*` y `distribucionTiempos.*` también
viajan como fracciones aunque el formulario las muestre como porcentaje. La conversión es una decisión
por campo, nunca genérica. Un `0.35` pintado como `0%` o un `0.004` como `0.004%` es el defecto a
evitar y el test lo cubre.

**S4 — Formato numérico del módulo (decisión del humano).** Un solo formato, el que la app ya usa en
`paciente_ficha_screen.dart`: `19.5%`, **sin espacio** antes del signo y **punto** como separador
decimal; enteros sin decimales y, si no, un decimal (`25%`, `19.5%`, `100g`, `93.8g`); cambios con
signo explícito y un decimal (`+0.4%`, `−0.8%`, `0.0%`). Las kcal llevan punto de millar (`1.500`,
`10.542`), como ya las escribe la ficha. El export mezcla `25%` (generador) con `25 %` (detalle y
editor) y `+0.4 %`: las cadenas de abajo se citan **verbatim del inventario** y la pantalla las dibuja
con este formato, sin el espacio. Es una desviación deliberada del artboard, no un descuido.

**S5 — Lista, copy.** Barra: `Planes`, con el nombre del paciente debajo (el ejemplo es `Paciente De
Prueba`) y la flecha de volver a la ficha. Cada plan es una tarjeta: nombre del plan, insignia de
estado (`ACTIVO` | `ARCHIVADO`), etiqueta de origen (`Por reglas`), cuatro métricas rotuladas
`KCAL`, `PROT`, `CARB`, `GRASA` (de `kcalObjetivo`, `proteinaG`, `carbohidratoG`, `grasaG`, con `g`
en los macros) y una línea de fecha: `Activo el 7 nov` para el activo, `Creado el 20 oct · solo
lectura` para el archivado. Botón fijo inferior: `Generar plan`.

**S6 — Lista, comportamiento.** Cada tarjeta abre el detalle de ese plan. El **estado se lee fila por
fila** (`estado`): el contrato no filtra por estado ni garantiza que el activo vaya primero, y la
pantalla respeta el orden del API (más reciente primero) sin reordenar por su cuenta. El archivado se
atenúa. Las fechas salen de `creadoEn` / `aprobadoEn` con `.toLocal()`. La paginación es la estándar
del API (`limit`, `offset`, `meta.hasMore`); un cursor y un offset nunca viajan juntos.

**S7 — Estado vacío.** Cuando `data` viene `[]` y `total` es 0: título `Todavía no tiene un plan`,
texto `Generá el primero con sus metas y restricciones. Va a quedar en borrador hasta que lo revisés
y lo activés.` y el botón `Generar plan`. Es la siguiente acción, no un KPI repetido.

**S8 — Sin medición.** El contrato exige una medición y **no declara el código** con que `generar`
falla sin ella. La pantalla no espera ese error: lee la ficha del paciente (requerimiento `null` y
evolución `[]` sin mediciones, hecho de la tarjeta `ficha-sin-mediciones-devuelve-requerimiento-null`),
**deshabilita** `Generar plan` y ofrece el camino a la nueva medición que ya existe
(`AppRoutes.nuevaMedicion`). El artboard no dibuja este estado: su copy es autorada (C1).

**S9 — Generador, copy.** Barra `Generar plan` con el nombre del paciente y `Cerrar sin generar`
(icono `close`, sin guardar). Campos y rótulos, en orden:
`Nombre` (valor inicial `Plan 2026-11-16`: el contrato lo da por defecto como «Plan YYYY-MM-DD»,
máx. 120); `Kcal objetivo · opcional` (placeholder `Calculado automáticamente`, ayuda `1.000 a 5.000. Si
lo dejás vacío, se calcula con Mifflin-St Jeor y la meta del paciente.`); `Distribución de macros` con
`Proteína` `25%`, `Carbohidrato` `50%`, `Grasa` `25%` y la nota `Rangos: proteína 10–50 %, carbohidrato
20–70 %, grasa 10–50 %. Los tres son obligatorios si se cambia uno.`; `Distribución por tiempo de
comida` con `Desayuno` `25%`, `Merienda · mañana` `10%`, `Almuerzo` `35%`, `Merienda · tarde` `10%`,
`Cena` `20%`; `Indicaciones para el recomendador · opcional` (placeholder `Prefiere desayunos rápidos
y cenas sin frituras`, máx. 500); interruptor `Usar IA` con `Si no está disponible, cae a reglas
automáticamente.`; botón fijo `Generar plan` y, debajo, `Con IA puede tardar hasta 25 segundos. El
plan queda en borrador.` Los valores `25%` etc. son los valores iniciales de los campos y coinciden
con los defectos del contrato (macros 25/50/25, tiempos 25/10/35/10/20).

**S10 — Generador, lo que viaja.** Todos los campos del body son opcionales. Se manda `nombre`,
`kcalObjetivo` (1000–5000, solo si se escribió), `distribucionMacros` (proteína 0.1–0.5, carbohidrato
0.2–0.7, grasa 0.1–0.5; **los tres juntos** o ninguno), `distribucionTiempos` (cada tiempo 0–1),
`indicaciones` y `usarIa`. La pantalla aplica los rangos que el contrato declara y **no inventa una
regla de suma**: el contrato no dice si las distribuciones deben sumar 1 ni qué pasa con un tiempo en
`0` (gap 2). Un 400 `VALIDACION` se muestra con el `mensaje` del API y sus `detalles` por campo.

**S11 — La IA es real, y el origen se muestra (decisión del humano).** El interruptor `Usar IA` manda
`usarIa` y arranca **encendido** (`true` es el defecto del contrato). La pantalla muestra siempre el
`origen` que el API devolvió. **Si el pedido pidió IA y la respuesta trae `origen: REGLAS`, lo dice**
(C2): el contrato documenta ese fallback y producción devuelve hoy planes por reglas
(tarjeta `plan-generado-hoy-es-por-reglas`). Lo contrario no se afirma: un `origen: IA` **no prueba**
que la IA propuso el contenido (tarjeta `recomendador-esquema-del-prompt-va-con-el-parser`), así que la
etiqueta no se presenta como garantía de calidad ni de método. La nota interna del artboard (`Hoy el
recomendador en producción devuelve resultados por reglas, con o sin este interruptor. No hay forma de
prometerle IA al plan todavía.`) es anotación de diseño: **no entra en la UI**.

**S12 — Generación en curso.** El contrato solo define la respuesta final y con IA se midieron 23–25 s.
Mientras espera, el botón `Generar plan` muestra `isLoading`, el formulario no se edita y no hay barra de
progreso (el API no emite ninguno). La nota `Con IA puede tardar hasta 25 segundos.` ya explica la
espera. No hay cancelación dibujada y no se inventa una. Al responder 201 la pantalla abre el detalle del
borrador recién creado, con el aviso de S11 cuando corresponda.

**S13 — Detalle, copy de cabecera.** Barra: nombre del plan (`Plan 2026-11-07`) y, para el borrador,
`Borrador · sin publicar`, más la flecha de volver a la lista. Tarjeta de estado: `BORRADOR`, el origen
(`Por reglas`) y las metas `KCAL / DÍA`, `PROT`, `CARB`, `GRASA` (`1.500`, `93.8g`, `187.5g`, `41.7g` en
el ejemplo). Debajo, la `justificacion` tal como llega (`Generado por reglas: no había medición de grasa
corporal, se usó el peso y la talla para estimar el gasto.` es el ejemplo); con `justificacion: null` el
bloque **se oculta**. Tarjeta `Totales de la semana`: la desviación (`+0.4%`) y `10.542 kcal reales de
10.500 kcal meta (7 días)`, donde el número de días es **el de `dias` del plan** y la meta es `kcalObjetivo`
× esos días (así lo define el contrato); el alcance de cada total se declara siempre («de la semana», «del
día»).

**S14 — Los días que el plan tiene (decisión del humano).** El diseño es semanal y el contrato
multi-día: `dias` solo trae los días con algún tiempo de comida. La tira dibuja **únicamente los días que
`dias` trae**, mapeados por `DiaSemana`, con las etiquetas `LUN`, `MAR`, `MIE`, `JUE`, `VIE`, `SAB`,
`DOM` bajo el rótulo `DÍA`. **No hay chips vacíos inventados ni columnas fantasma.** Se expande un día a
la vez, el primero que el plan tenga; el título del día es `Lunes` en el ejemplo y los demás se escriben
con tilde en la UI (C3). Cada día muestra `1.506 kcal · +0.4%` (totales del día y su `desviacion`) y sus
tiempos en el orden del API.

**S15 — Fila de tiempo de comida.** Cada tiempo es una fila con nombre (`Desayuno`, `Merienda ·
mañana`, `Almuerzo`, `Merienda · tarde`, `Cena`) y la línea `25 % · 375 kcal · 2 alimentos` (con el
formato de S4: `25% · 375 kcal · 2 alimentos`), singular `1 alimento`. El porcentaje es `pctKcal × 100`
(`pctKcal` es fracción 0..1, no 25) y la cifra de kcal es **`kcalMeta`**, la meta del tiempo. Como el
artboard la deja sin rótulo y se lee como consumido, **la UI la rotula como meta** (C9):
`25% · meta 375 kcal · 2 alimentos`, con el mismo patrón `meta … kcal` que ya usa el editor.
El `Almuerzo` del ejemplo muestra además los alimentos en una línea (`Arroz blanco · 1 porción · Pollo a
la plancha · 1.5 porciones · Ensalada verde · 1 porción`): se dibuja **la lista de alimentos de cualquier
tiempo que los tenga**, no solo la del almuerzo; el artboard dibujó una por limitación de la pieza, no por
regla. Un tiempo con `items: []` (válido, S20) se dibuja con `25% · meta 375 kcal` y la copy `Sin
alimentos` (C11) en lugar de la línea de alimentos; no se inventan totales para él.

**S16 — Solo el borrador se edita (decisión del humano).** `BORRADOR` es el único estado editable:
muestra el chevron de cada fila (que abre el editor, S20), `Activar plan` y el menú de eliminar.
**`ACTIVO` y `ARCHIVADO` abren el mismo detalle en solo lectura**, aunque el artboard enlace los tres
estados a la misma pantalla: sin chevron, sin `Activar plan`, sin menú, con la línea de fecha de S5 en
lugar de `Borrador · sin publicar`. El contrato no regula qué pasa con las comidas que el paciente ya
marcó cuando cambian los ítems de un plan activo (gap 8); se publicó al board la tarjeta
`planes-editar-items-de-un-plan-activo` y la pantalla **no** ofrece esa edición hasta que el BE responda.

**S17 — Activar.** Botón fijo `Activar plan` con el aviso `Lo va a ver el paciente en su app; el plan
activo anterior pasa a archivado.` Llama `POST /planes/{id}/activar`, reemplaza el plan con la respuesta
(201, con `aprobadoEn`) e invalida la lista. Un 400 muestra el `mensaje` del API: el contrato no explica
cuándo lo da (gap 14) y la pantalla no lo adivina. No hay «desactivar» ni «reactivar»: no existen.

**S18 — Confirmaciones (desviación deliberada del artboard).** El artboard no dibuja confirmación ni
para `Activar plan` ni para eliminar el borrador (`more_vert` solo trae el `aria-label="Eliminar
borrador"`). **Los dos llevan confirmación**, porque activar publica al paciente y archiva el plan
vigente, y eliminar es el único borrado real del módulo y no tiene vuelta atrás. §5 y §12 del contrato
ya las piden. Copy autorada (C4, C5). Eliminar llama `DELETE /planes/{id}`, vuelve a la lista y la
invalida; un error muestra el `mensaje`, y se decide por `codigo`, no por el texto.

**S19 — Editor, copy.** Barra `Editar tiempo` y debajo `Almuerzo · Lunes` (tiempo · día), con `Cerrar sin
guardar`. Aviso: `Guardar reemplaza la lista completa de este tiempo. Lo que no esté acá se elimina; no
se agrega sobre lo anterior.` Resumen: `35 % del día · meta 525 kcal` (`35% del día · meta 525 kcal` con
S4) y `3 de 12 alimentos`. Cada fila: nombre del alimento, detalle `1 taza · 205 kcal` seguido de `por
porción` (C10: `1 taza · 205 kcal por porción`), control de
porciones (`remove` / valor / `add`) y `close` para quitarla. `Agregar alimento` con la ayuda `Usa el
mismo buscador del catálogo, como selector. Porciones de 0.25 a 6.` y botón fijo `Guardar tiempo`.

**S20 — Editor, comportamiento.** Se llega solo desde un borrador y se edita **un tiempo de un día**. La
lista parte de los `items` actuales; al guardar se manda el estado final con `PUT
/planes/{id}/tiempos/{dia}/{tipo}/items` y `{ "items": [{ "alimentoId", "porciones" }] }`, y la respuesta
(el plan completo) reemplaza la fuente de verdad: no se parchea a mano. Tope **12** ítems: con 12,
`Agregar alimento` se deshabilita. `porciones` entre **0.25 y 6**; el control avanza de a 0.25 (el
contrato lo recomienda, no lo exige). Los alimentos se eligen con `AppSearchSelectField` contra `GET
/alimentos` (el selector existe; el buscador del catálogo todavía no). La cifra de kcal de cada fila es
`alimento.kcal`, que el contrato declara **por porción**: la fila lo dice y la app **no la multiplica**
por `porciones`. Los totales del tiempo se leen de `totales`, que el API ya entrega calculados con
`alimentoVersion`. **Lista vacía:** el contrato la permite (`items` tiene tope 12 y ningún mínimo), así
que `Guardar tiempo` **no se bloquea** con una validación inventada; el tiempo se guarda vacío (`items:
[]`), el editor muestra `Sin alimentos` (C11) con `0 de 12 alimentos` y el detalle lo dibuja según S15.
Cerrar sin guardar descarta lo editado.

**S21 — Lo que la UI no promete (§13 del contexto).** No se dibuja ni se promete: «plan generado por IA»
como garantía de resultado; copiar un día a otro o «repetir lunes toda la semana» (son PUT por tiempo);
arrastrar para reordenar tiempos o cambiar el porcentaje de un tiempo tras generar; duplicar un plan,
crear uno vacío, reactivar uno archivado o desactivar el activo; historial o comparación entre planes;
fechas de vigencia (el plan no tiene `desde`/`hasta`: la semana se identifica por `dia`). Tampoco se
promete que editar un alimento del catálogo cambie un plan existente: los totales salen de
`alimentoVersion`, no del alimento vivo, y los ítems anteriores al versionado (`alimentoVersionId:
null`) totalizan con el alimento actual.

**S22 — Estados de datos.** Cada pantalla dibuja carga (spinner), error (el `mensaje` del `ApiFailure` y
un botón de reintento que invalida el provider), vacío y datos. El detalle además cubre `justificacion:
null` y un tiempo sin ítems (`Sin alimentos`, S15 y S20). El estado del plan nunca se infiere del contenido: se lee de `estado`.

**S23 — Tests.** Repositorio con `test/support/fake_http_adapter.dart`; providers con `overrideWith`;
pantallas con `pumpStable`. Cada pantalla prueba carga, error, datos y vacío. Obligatorios por su
riesgo: la conversión de fracciones de S3 (`0.35` → `35%`, `0.004` → `+0.4%`, `pctGrasa` intacto), que el
PUT use la ruta con `dia` y `tipo`, que `Guardar tiempo` mande la lista **completa** (también `items: []`, sin bloquearla), que la fila del
tiempo rotule la cifra como meta, que la kcal del editor diga `por porción` sin multiplicarse, que `ACTIVO` y
`ARCHIVADO` no dibujen acciones de edición, que la tira de días dibuje solo los que `dias` trae, y que
`usarIa: true` con respuesta `REGLAS` muestre el aviso de S11. El contrato que se prueba es el del API.

**S24 — Commits.** Conventional Commits en inglés, sin atribución de IA. Push solo cuando el humano lo
valide en el dispositivo.

**S25 — Entrada desde la ficha.** La lista se alcanza desde la ficha del paciente con la acción
`Ver planes` (C12), en los **dos** estados en que la ficha puede estar:

- con plan (`if (plan != null)`), desde el bloque `Plan y adherencia`;
- sin plan, desde la alerta que ya existe (`_SinPlanAlerta`), porque ese es justo el caso en que hay
  que generar uno y hoy el bloque no se dibuja.

Una sola etiqueta para los dos, no dos: la lista vacía ya trae `Generar plan` en su propio estado de
vacío, así que la ficha no necesita rotular la acción dos veces. Es el único cambio de este módulo
fuera de `lib/features/planes/` y del router.

**S26 — Fidelidad visual, medida contra los artboards (pedido del humano).** La lista y el editor se
dibujan como sus artboards, no como salió la primera implementación. **Tarjeta de la lista
(`PlanesLista.html`)**: borde de 1 px `outlineVariant`, radio 12, relleno 16, separación interna 10; el
nombre a 16/600; la insignia de estado es una píldora **con color** — `secondaryContainer` sobre
`onSecondaryContainer` para `ACTIVO`, `surfaceContainer` sobre `onSurfaceVariant` para `ARCHIVADO` y
`BORRADOR`; la etiqueta de origen es una píldora **con borde** `outlineVariant` y texto
`onSurfaceVariant`; las cuatro métricas van sobre un separador `surfaceContainer` con el rótulo a
10/700 y el valor en mono; la línea de fecha va a 12 en `outline`; la tarjeta archivada se atenúa
(título y valores en `onSurfaceVariant`); el botón fijo `Generar plan` lleva el icono `add`. **Fila del
editor (`EditarTiempoComida.html`)**: una sola línea horizontal con el nombre y `1 taza · 205 kcal por
porción` a la izquierda, el control de porciones en medio y el `close` a la derecha; `-` y `+` son
**botones de 28×28 con borde** `outlineVariant` y radio 8, no iconos sueltos, y el valor va en mono a
13/600 centrado en 28 de ancho; el aviso de reemplazo va en un bloque `surfaceContainerLow` con icono
`info`. El color de la insignia y el botón del editor se dibujan **dentro del módulo**: `AppPill` no
lleva color y no se toca, porque otros consumidores dependen de su forma actual.

**S27 — Detalle: la tira ocupa el ancho y cada tiempo lleva su icono (pedido del humano).** La tira
de días deja de dibujar cuadrados fijos de 40 con scroll: los días que el plan trae **reparten el ancho
disponible** (`Expanded`, alto 40, radio 10), con el elegido en `primary`/`onPrimary` y el resto con
borde `outlineVariant` y texto `onSurfaceVariant`. Cada tiempo de comida lleva, a la izquierda de su
nombre, un **icono dentro de un círculo de 36** con tinte del sistema: `Desayuno` `breakfast_dining`
sobre `secondaryContainer`; `Merienda · mañana` `local_cafe` sobre `surfaceContainer`; `Almuerzo`
`lunch_dining` sobre `primaryContainer`; `Merienda · tarde` `cookie` sobre `surfaceContainer`; `Cena`
`dinner_dining` sobre `tertiaryContainer`. La card sigue **blanca**: el color es un acento, la
información (`pctKcal`, `meta … kcal`, cantidad de alimentos y la lista) manda. La paleta del sistema es
toda verde, así que el contraste sale del ritmo tinte/neutro y del icono, no de colores nuevos: agregar
ámbar o azul exigiría tokens nuevos en el sistema de diseño y no entra acá.

## Tasks

| ID | Specs | Tarea | Superficie | Estado |
|----|-------|-------|-----------|--------|
| T1 | S1, S2, S3, S4, S6, S23 | Capa de datos: **agrega `ApiClient.put<T>`** (hoy no existe; `delete`/`deleteAck` sí) porque reemplazar ítems es `PUT`, `Plan`, `PlanDetalle`, `DiaPlan`, `TiempoComida`, `PlanItem`, `Totales`, `PlanesRepository` (lista, generar, detalle, activar, reemplazar ítems, eliminar), providers y formateadores del módulo | `lib/core/network/api_client.dart`, `lib/features/planes/data/` | hecho |
| T2 | S5, S6, S7, S22, S23 | Pantalla de lista y estado vacío, con su ruta bajo el paciente | `lib/features/planes/ui/`, `lib/core/router/` | hecho |
| T3 | S8, S9, S10, S11, S12, S22, S23 | Pantalla del generador, con el aviso de origen, con su ruta bajo el paciente | `lib/features/planes/ui/`, `lib/core/router/` | hecho |
| T4 | S13, S14, S15, S16, S22, S23 | Detalle semanal: cabecera, tira de días, filas de tiempo, solo lectura, con su ruta anidada bajo el paciente | `lib/features/planes/ui/`, `lib/core/router/` | hecho |
| T5 | S19, S20, S21, S22, S23 | Editor de un tiempo de comida y su ruta; las filas del detalle del borrador pasan a abrirlo | `lib/features/planes/ui/`, `lib/core/router/` | hecho |
| T6 | S24, S25 | Cableado: acción `Ver planes` (C12) en la ficha, en los dos estados (con plan y sin plan), hacia la lista, y actualización de este documento | `lib/features/patients/ui/paciente_ficha_screen.dart`, `lib/core/router/` | hecho |
| T7 | S17, S18 | Acciones del detalle: activar y eliminar con confirmación | `lib/features/planes/ui/` | pending |
| T8 | S25 | **Defecto:** la lista solo se alcanza desde la ficha cuando hay plan activo. Llevar `Ver planes` también al estado sin plan | `lib/features/patients/ui/paciente_ficha_screen.dart` | hecho |
| T9 | S26 | **Fidelidad visual:** la tarjeta de la lista y la fila del editor vuelven a lo que dibujan sus artboards | `lib/features/planes/ui/` | hecho |
| T10 | S27 | **Detalle:** la tira de días ocupa el ancho y cada tiempo lleva su icono con tinte | `lib/features/planes/ui/plan_detalle_screen.dart` | hecho |

Orden fijado por el contrato: el detalle y el editor consumen lo que la capa de datos expone, el
generador abre el detalle que crea y el editor solo se alcanza desde un borrador. En T4 las filas de
tiempo se dibujan sin navegación; T5 las conecta.

## Copy autorada (C#)

Lo que el inventario de los artboards no trae y la pantalla necesita. **Las valida el humano.**

| # | Dónde | Cadena | Por qué existe |
|---|-------|--------|----------------|
| C1 | Sin medición (S8) | `Para generar un plan hace falta al menos una medición.` con la acción `Nueva medición` | el artboard no dibuja este estado; el contrato lo exige y no declara el error |
| C2 | Aviso de origen (S11) | `Pediste IA, pero este plan se generó por reglas.` | el pedido llevó `usarIa: true` y la respuesta volvió `origen: REGLAS` |
| C3 | Título de día (S14) | `Martes`, `Miércoles`, `Jueves`, `Viernes`, `Sábado`, `Domingo` | el artboard solo expande `Lunes`; el contrato entrega `MIERCOLES` y `SABADO` sin tilde |
| C4 | Confirmar activar (S18) | `¿Activar este plan?`, cuerpo `Lo va a ver el paciente en su app; el plan activo anterior pasa a archivado.`, acciones `Activar plan` y `Cancelar` | confirmación que el artboard no dibuja; el cuerpo reusa la frase del artboard |
| C5 | Confirmar eliminar (S18) | `¿Eliminar este borrador?`, acciones `Eliminar borrador` y `Cancelar`; entrada del menú `Eliminar borrador` | la entrada sale del `aria-label` del artboard; el diálogo no está dibujado |
| C6 | Origen distinto de reglas (S5, S13) | `IA` y `Manual` junto a `Por reglas` | el artboard solo dibuja `Por reglas`; el contrato define `IA`, `MANUAL` y `REGLAS` |
| C7 | Plan en borrador en la lista (S5) | `Creado el 20 oct` (sin el sufijo `· solo lectura`) | el artboard dibuja las líneas del activo y del archivado, no la del borrador |
| C8 | Un solo día (S13) | `(1 día)` | el artboard dibuja `(7 días)`; un plan puede tener menos |
| C9 | Fila del tiempo (S15) | `meta` antes de la cifra: `25% · meta 375 kcal · 2 alimentos` | la cifra es `kcalMeta` y el artboard la deja sin rótulo |
| C10 | Fila del editor (S19) | `por porción` tras la kcal: `1 taza · 205 kcal por porción` | `alimento.kcal` es por porción y no se multiplica en pantalla |
| C11 | Tiempo sin ítems (S15, S20) | `Sin alimentos`, y en el editor el resumen `0 de 12 alimentos` | el contrato permite `items: []` y el artboard no dibuja ese estado |
| C13 | Detalle sin días (S13) | `Este plan todavía no tiene días.` | el artboard no dibuja un plan sin días; el contrato permite que `dias` venga vacío |
| C14 | Detalle sin datos (S22) | `No pudimos cargar el plan.` y `Reintentar` | patrón de la agenda para el error que no trae mensaje del API |
| C15 | Salida del detalle (S13) | `Volver a planes` como tooltip | es el `aria-label` del artboard; hasta que exista la lista vuelve a la ficha |
| C16 | Fechas del plan (S13) | meses abreviados `ene`–`dic` | el inventario solo trae `nov` y `oct` |
| C17 | Fila del alimento (S15) | porciones `1 porción` y `N porciones`, armadas con las palabras del inventario | el inventario trae solo esos dos ejemplos |
| C18 | Generador (S10, S11) | `Pediste IA, pero este plan se generó por reglas.` | el contrato documenta el fallback a reglas y producción lo devuelve hoy |
| C19 | Lista sin datos (S22) | `No pudimos cargar los planes.` y `Reintentar` | mismo patrón que C14; el error sin mensaje del API |
| C20 | Salida de la lista (S5) | `Volver a la ficha` como tooltip | es el `aria-label` del artboard de la lista |
| C21 | Tarjeta del borrador (S6) | línea de fecha `Creado el 20 oct` | el artboard solo dibuja esa frase para el archivado; el borrador la usa sin el sufijo `· solo lectura` |
| C22 | Justificación larga (S13) | `Ver más` y `Ver menos` | la IA escribe párrafos donde el artboard esperaba una línea; se corta a 150 palabras |
| C23 | Ficha sin plan (S25) | `Agregá tu primer plan`, la línea que lo explica y la acción `Generar plan` | el artboard no dibuja ese estado; el humano pidió que el banner solo informe |
| C24 | Generador sin red ni API (S12) | `No pudimos generar el plan. Probá de nuevo.` | lo que no es un `ApiFailure` necesita un mensaje propio para no dejar el formulario bloqueado |
| C25 | Nota del generador (S12) | `Con IA puede tardar hasta 3 minutos` | el artboard dice 25 segundos y el recomendador tarda hasta 180 |
| C26 | Fallo del editor (S22) | `No pudimos guardar el tiempo. Probá de nuevo.` | mismo patrón que C24: lo que no es un `ApiFailure` necesita mensaje propio para no dejar el botón colgado |
| C27 | Tiempo ausente (S20) | `Este tiempo de comida ya no está en el plan.` con la acción `Volver al plan` | el plan pudo cambiar entre abrir el detalle y abrir el editor; el artboard no dibuja ese estado |
| C12 | Entrada desde la ficha (S25) | `Ver planes` | acción nueva en `Plan y adherencia`; el artboard solo dibuja la vuelta |

`Merienda · mañana` y `Merienda · tarde` se escriben **con el punto medio** del inventario (` · `),
no con guion ni con coma.

## Entrega

Rama `feat/planes`, base `main`. El total supera con margen el umbral de revisión de un solo PR, así
que se propone **encadenado en tres**. Cada commit compila por separado y trae sus tests y su parte de
este documento; ninguno deja el árbol roto.

| Slice | Entrega | Tareas | Compila y prueba porque |
|-------|---------|--------|-------------------------|
| 1 | `feat(planes): data layer for meal plans` — `put<T>`, entidades, repositorio, providers y formateadores | T1 | no toca pantallas; los tests de repositorio y de conversión de fracciones corren solos |
| 2 | `feat(planes): weekly plan detail` | T4 | la pantalla es de solo lectura y su ruta cuelga del paciente; es el eje porque el generador y la lista la abren |
| 3 | `feat(planes): plan generator` | T3 | abre el detalle del slice 2, así que se valida en el dispositivo sin la lista |
| 4 | `feat(planes): plans list and empty state` | T2 | cierra la navegación lista → detalle |
| 5 | `feat(planes): meal-time editor` | T5 | cierra el flujo de edición del borrador |
| 6 | `feat(planes): activate and delete from the detail` | T7 | según L14; acciones sobre el borrador ya generado |
| 7 | `feat(planes): entry point from patient file` | T6 | según L12; es el único que toca la ficha |

**PR encadenado.** PR 1 = slices 1–2 (leer un plan: se puede revisar sola y no deja nada a medias).
PR 2 = slices 3–4 (generar y recorrer: el generador y la lista usan el detalle del slice 2). PR 3 =
slices 5–7 (editar, actuar y entrar desde la ficha). Si el humano decide que el total cabe en una
revisión, los slices van en un solo PR. Son unidades de revisión, no de entrega.

## Entrega hecha

Los commits de esta rama, en orden, con lo que cada uno deja compilando y verde:

| Commit | Contenido |
|--------|-----------|
| `93fd418` | `feat(core)`: `ApiClient.put<T>`, `receiveTimeout` por llamada y los meses cortos en `fechas.dart` |
| `6a10e8c` | `feat(planes)`: entidades, repositorio, providers y formateadores, con sus tests |
| `58bc1f1` | `feat(planes)`: las tres pantallas, sus rutas bajo el paciente y la entrada desde la ficha, con sus tests |

El resto de este documento describe el plan de entrega original, en slices de revisión. Lo entregado va
en tres commits porque las rutas y la entrada desde la ficha no compilan sin las pantallas: partir el
último habría dejado commits rotos. La revisión se parte igual con las ramas encadenadas de abajo.

## Log

**L1 — Pedido original (verbatim).** «ya tengo diseno de los planes, pdoemos ir por ahi que dices»

**L2 — Origen del diseño.** El diseño llegó como un export de cinco artboards de
`/Users/katze/Downloads/BaleadaFit Ideas-2.html`: lista, sin planes, generar plan, detalle semanal del
borrador y editar un tiempo de comida. Están en `odd/designs/planes/`, sin reformatear, y su
`README.md` es el inventario verbatim de la copy y la autoridad de este documento.

**L3 — Decisión: edición (humano).** Solo el `BORRADOR` es editable. `ACTIVO` y `ARCHIVADO` abren en solo
lectura, aunque el artboard enlace los tres estados al mismo detalle. El contrato no regula qué pasa con
las comidas que el paciente ya marcó cuando cambian los ítems de un plan activo; se publicó al board la
tarjeta `planes-editar-items-de-un-plan-activo`. Cubierto por S16.

**L4 — Decisión: confirmaciones (humano).** Activar un plan y eliminar un borrador llevan confirmación,
en contra del artboard, que no dibuja ninguna. Razón: activar publica al paciente y archiva el plan
vigente; eliminar es irreversible. Cubierto por S18 y C4/C5.

**L5 — Decisión: IA (humano).** El interruptor es real: `POST /pacientes/{id}/planes/generar` acepta
`usarIa` (defecto `true`) e `indicaciones`. La pantalla muestra el `origen` que devuelve el API y, si
pidió IA y llegó `REGLAS`, lo dice. La nota interna del artboard («Hoy el recomendador en producción
devuelve…») no va a la UI. Cubierto por S11.

**L6 — Decisión: días (humano).** El diseño es semanal y el contrato multi-día: con menos de siete días,
la tira dibuja los días que el plan tiene, mapeados por `DiaSemana`, sin chips vacíos inventados. Cubierto
por S14.

**L7 — Decisión: formato numérico (humano).** Un solo formato para el módulo, el que la app ya usa:
`19.5%`, sin espacio antes del signo, punto decimal. El export mezcla `25%` con `25 %`. Cubierto por S4. **Inconsistencia conocida, no
se resuelve acá:** la ficha usa el punto para miles (`1.500`) y también para decimales (`1.5`); se
mantiene tal cual y queda para resolverse de forma global, no dentro de este módulo.

**L8 — Hallazgo del contrato: `usarIa`.** El flag existe y su defecto es `true`. Por eso un `origen:
REGLAS` en producción significa que **el fallback se disparó**, no que el interruptor estuviera apagado:
`GenerarPlan.html` lo dibuja encendido y el contrato lo documenta («si la IA no está disponible cae a
reglas»). El inverso tampoco es una garantía: con el esquema del prompt desalineado del parser, un plan
sale con `origen: IA` sin error ni log.

**L9 — Hallazgos del código.** `ApiClient` no tiene `put<T>` (sí `get`, `post`, `patch`, `delete` y las
variantes `*Ack`; `_send` es genérico por verbo): T1 lo agrega. `AppSearchSelectField<T>` existe y fue
escrito pensando en este módulo (L9 de `agenda.md`). La ruta `/dietas` existe en el shell como
`Diseñador de dietas` pero es una sección del drawer, no la lista de planes de un paciente; la ficha ya
muestra `Con plan` / `Sin plan` y la alerta `SIN_PLAN_ACTIVO` pero no enlaza a ninguna pantalla de
planes. Los formateadores `_miles`, `_uno`, `_entero` y `_firmado` son privados de
`paciente_ficha_screen.dart`: T1 escribe los suyos en el módulo con el mismo comportamiento en lugar de
tocar la ficha (extraerlos exigiría la comprobación diferencial de L8 de `agenda.md`).

**L10 — Cerrada: lista vacía en el editor.** `ReemplazarItemsDto.items` es «Lista completa de alimentos
del tiempo de comida (máximo 12)»: hay tope y **no hay mínimo declarado**, así que `items: []` es válido.
Se cerró con ese hecho del esquema, no por criterio de diseño. `Guardar tiempo` no se bloquea porque el
contrato lo permite y la app no inventa validaciones; el tiempo se guarda vacío y se dibuja con `Sin
alimentos` (C11). Cubierto por S15 y S20.

**L11 — Cerrada: cifras del artboard.** Del esquema indexado: `PlanItemEntity.alimento.kcal` es «Por
porción», el ítem lleva `porciones` (múltiplos de 0.25) y los totales salen de `alimentoVersion`
(«Valores con los que totaliza el ítem»): la contribución real es `kcal × porciones` y **la app no la
calcula**. `TiempoComidaEntity` trae `kcalMeta` («kcal objetivo de este tiempo de comida»), `pctKcal`
(«fracción de las kcal del día», 0..1) y `desviacion` como `(real − meta) / meta`. Se cerró con esos
hechos, no por criterio de diseño: `231 kcal` es por porción y la fila lo dice (C10); `375 kcal` es
`kcalMeta` y la fila lo rotula (C9). Cubierto por S15, S19 y S20.

**L12 — Cerrada: cómo se llega a la lista.** Decisión del humano: la lista se abre desde la ficha con la
acción `Ver planes` (C12). T6 pasa a tener superficie concreta (`paciente_ficha_screen.dart` y el
router).

Corrección sobre la primera redacción: el bloque `Plan y adherencia` hoy se dibuja solo cuando la
ficha trae un plan (`if (plan != null)`), y para un paciente sin plan la ficha muestra
`_SinPlanAlerta`. Como ese es precisamente el caso donde hay que generar un plan, la acción se dibuja
en los **dos** estados, con la misma etiqueta: la lista vacía ya ofrece `Generar plan`, así que la
ficha no inventa un segundo rótulo.

**L13 — Cerrada: las rutas cuelgan del paciente.** `/planes/:id` dejaba el shell sin sección: la barra
decía `BaleadaFit` y el drawer no resaltaba nada, porque `app_sections.dart` no tiene —ni debe tener—
un destino de primer nivel para planes. Un plan pertenece a un paciente y su entrada es la ficha (S25),
así que el detalle pasa a `/pacientes/{id}/planes/{planId}` y el generador a una rama hermana, los dos
bajo la sección `Pacientes`. Un deep link al detalle deja la ficha debajo y volver aterriza ahí.

**L14 — Cerrada: orden detalle → generador → lista.** El generador abre el detalle que acaba de crear y
la lista abre el detalle, así que el detalle va primero y ningún slice deja un botón apuntando a una
ruta que todavía no existe. Consecuencia: T4 entregó solo lectura y S17/S18 (activar y eliminar con
confirmación) se mudan a T7, que se implementa después de la lista.

**L15 — Decisiones del detalle, para validar.** Cada alimento va en su propia fila con la segunda línea
`1 taza · 205 kcal por porción`, en vez de la línea unida con ` · ` del artboard: con nombres largos la
línea unida no deja claro a qué alimento pertenece la cifra. Un ARCHIVADO sin `creadoEn` muestra solo
`solo lectura`, y un ACTIVO sin `aprobadoEn` usa `creadoEn` para la línea `Activo el …`, en vez de
dejar la frase a medias. El nombre del plan sale de la carga y no de la URL: mientras carga, la barra
solo muestra la flecha.

**L16 — Cerrada: T6 se adelantó al final del módulo.** Sin la entrada desde la ficha, planes no se
alcanza desde la app: quedaba solo por deep link. Así que T6 se hizo antes de T5 (editor) y T7
(activar y eliminar), y su prueba es la que cierra el circuito en el dispositivo. La acción se dibuja
en los dos estados, y el botón del detalle ahora vuelve a la lista, que ya tiene ruta.

**L17 — Cerrada: los cuatro defectos del dispositivo.**

1. **Generar con IA fallaba y no se sabía por qué.** El log del teléfono no tiene ninguna excepción de
   Dart: el fallo llegó como error del API, no como caída. Había tres causas de forma detrás: no hay
   timeouts configurados en `ApiClient`, la nota prometía 25 segundos para un trabajo de hasta 180, y la
   pantalla solo atrapaba `ApiFailure`, así que cualquier otro error dejaba el formulario con el spinner
   girando y sin mensaje. Ahora `post` acepta un `receiveTimeout` por llamada (la generación usa cuatro
   minutos), el `catch` final libera el formulario con texto propio, y el bloque de error muestra el
   código y el HTTP cuando existen: sin eso, un fallo es indiagnosticable después.
2. **Volver del detalle llevaba a la ficha.** El detalle estaba registrado como hermano de la lista, no
   como hijo, así que `go` armaba una pila sin la lista. Ahora `:planId` es hija de la ruta de planes y
   volver devuelve a la lista, también con un deep link.
3. **La justificación de la IA era inmensa.** Se corta a 150 palabras con `Ver más` / `Ver menos`; por
   debajo del límite se dibuja como antes, sin control.
4. **El banner de sin plan llevaba la acción.** El humano pidió que solo informe: queda sin botón, y la
   tarjeta de abajo invita con `Agregá tu primer plan` y abre el generador directo, sin pasar por la lista.

**L18 — Cerrada: el nombre por defecto del plan.** El artboard propone `Plan 2026-11-16`, y eso hace
que dos planes del mismo paciente pedidos el mismo día nazcan con el mismo nombre. Pasa a
`Nombre Apellido_2026-11-16_14:35`: paciente, fecha y hora con minutos. El contrato limita el nombre a
120 caracteres, así que cuando no cabe el paciente cede el espacio y la marca de tiempo nunca: es lo
que distingue un plan de otro. Sin ficha cargada todavía, cae a `Plan 2026-11-16_14:35`. El campo sigue
siendo editable, y la pantalla deja de sugerir en cuanto la nutricionista escribe encima.

**L19 — T5 hecho: el editor y el catálogo que le faltaba.** `EditarTiempoScreen` implementa S19 y S20
con la copy del inventario de `EditarTiempoComida.html` y el formato de S4: aviso de reemplazo,
resumen `35% del día · meta 525 kcal`, `3 de 12 alimentos`, filas `1 taza · 205 kcal por porción` con
control de porciones en cuartos entre 0.25 y 6, `Sin alimentos` con `0 de 12 alimentos`, y `Agregar
alimento` con su ayuda. `Guardar tiempo` manda **la lista completa** por `PUT
/planes/{id}/tiempos/{dia}/{tipo}/items`; `items: []` se guarda sin bloquear nada, porque el esquema
declara tope de 12 y ningún mínimo (L10). Con doce alimentos `Agregar alimento` deja de responder en
vez de fallar al guardar. Las filas del detalle abren el editor **solo** en `BORRADOR` (S16).

Hallazgo que obligó a ampliar el módulo: la app **no tenía catálogo de alimentos**, y sin él no había
con qué llenar el selector. Se agregó lo mínimo que el editor necesita — `GET /alimentos` con `q` y
`limit` — en `lib/features/planes/data/alimento_catalogo.dart` y `alimentos_repository.dart`, con su
provider. El módulo de catálogo (#10) es el dueño natural de esa consulta cuando exista; hoy lee
`id`, `nombre`, `porcionDescripcion`, `porcionGramos` y `kcal`, y nada más.

Dos cadenas autoradas nuevas: C26 (el fallo del guardado, mismo patrón que C24) y C27 (un tiempo que
ya no está en el plan, para el caso en que el plan cambie entre abrir el detalle y abrir el editor).

**L20 — Corregido: cómo se entra al editor y cómo se vuelve.** La primera versión empujaba el editor
con `push` como hijo de la ruta del detalle y esperaba el `PlanDetalle` del guardado en el `pop`, para
que el detalle mostrara la respuesta del `PUT` sin releer (S20). El test de ruta probó que no funciona:
al empujar el editor como hijo con `parentNavigatorKey` de la raíz, el detalle se pierde y al volver se
aterriza en la lista — el `pop` deja `/pacientes/{id}/planes` en la configuración. Se cambió al patrón
que el generador ya usa (L13, L14): la fila hace `go` al editor y el editor se va con `go` al detalle,
tanto al guardar como al cerrar sin guardar.

Consecuencia, para que quede dicha y no se lea como descuido: la respuesta del `PUT` ya no es lo que el
detalle dibuja. Después de guardar se invalida `planDetalleProvider` y el detalle **relee** el plan; la
respuesta del `PUT` solo prueba que la escritura ocurrió. Sigue cumpliendo lo que S20 busca —nada se
parchea a mano y la pantalla muestra lo que el API tiene— al precio de un `GET` por guardado. Se
prefirió eso a una navegación que pierde el detalle, que es un defecto visible para quien usa la app.


**L21 — Pedido del humano sobre el dispositivo (verbatim).** «ok, belleza, ya me deja agregar, funciona,
creo que le falra como estilos, a la lista de planes, nose colores o iconos, y tambien la lista de
planes aunque no tengamos planes activos deberia ser accesible, por si tengo en borrador y no activos, y
los botones de  - N + nose les falta estilos, no parecen botones, nose lo mas practico para el usuario
pls»

Se abre con eso: **T8** (la lista se alcanza siempre) y **T9** (fidelidad visual de la tarjeta y del
control de porciones contra `PlanesLista.html` y `EditarTiempoComida.html`). El pedido de estilos no
inventa nada: los dos artboards ya dibujan borde, insignias con color, valores en mono y `-`/`+` como
botones de 28×28; lo que pasó es que la primera implementación no los siguió. S26 fija esos valores.
Lo de la lista es un defecto contra S25: `Ver planes` se dibuja solo con `plan != null`, así que un
paciente con planes en borrador y ninguno activo no tiene por dónde entrar.

**L22 — Desviación deliberada en el control de porciones.** El artboard dibuja `-` y `+` como cuadrados
de 28×28, y así se dibujan: el borde y el icono siguen midiendo 28. Lo que no sigue al artboard es el
**área táctil**, que pasa a 40 porque 28 es menos de lo que un dedo acierta en un teléfono, y el pedido
era «lo más práctico para el usuario». La decisión de dibujo queda igual; cambia sólo lo que se puede
tocar. Hay un test por cada mitad: la caja de 28 y el objetivo de 40.

**L23 — Los tres ajustes del dispositivo (verbatim del humano).** «si son decimales no tienen el mismo
tamano del entero, esa animacion no es bonita, y lo que te comente, si un paciente no tiene un plan
activo, que me deje, ver la lista de planes por si tiene borradores, porque ahorita sale generar, esta
bien, pero no sabemos si tiene un plan borrador o archivado». Y, al preguntarle cuál animación: «oesa
esa animacionde hacerlo grande y peque».

1. **Decimales más chicos que los enteros.** El valor de porciones iba dentro de un `FittedBox` de 28 px,
   así que `1.25` se encogía y `1` no: mismo estilo, tamaño distinto. Pasa a una ranura fija de 34 px
   —lo que mide `0.25` a 13 px de la mono— y el texto deja de encogerse. Todos los valores se dibujan
   al mismo tamaño.
2. **La animación del toque.** El halo que crece y se encoge dentro del cuadradito de 28 px desaparece:
   `NoSplash` en `-`, `+` y la `x`, con un cambio de tono suave mientras el botón está apretado. Sigue
   habiendo respuesta al toque, sin el círculo.
3. **`Ver planes` donde se ve.** El botón que se había puesto dentro de la alerta de `Sin plan activo`
   se mueve a la tarjeta `Agregá tu primer plan`, junto a `Generar plan`: es la tarjeta que el humano
   tiene delante cuando el paciente no tiene plan activo, y ahí decide si mira la lista (puede haber
   borradores o archivados) o genera. La alerta vuelve a solo informar, como pidió L17.

**L24 — El color del detalle, elegido por el humano.** «ahora en el detalle del plan vamos a trabajar, los
dias de la semana estan en cuadros es correcto, pero no llegan hasta el extremo derecho queda un espacio
en mi 14 pro max, lo que signidica que tiene un ancho fijo, segundo tenemos los tiempos, si sale desayuno
merienda etc etc, pero eso podria ser mas colorido, o algo asi, los titulos o las cards, pero que la info
siga siendo la protagonista claro». Entre las tres opciones de color propuestas eligió **la del icono con
tinte y la card blanca**. Los días dejan de tener ancho fijo. S27 fija los valores.
