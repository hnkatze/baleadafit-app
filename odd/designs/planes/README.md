# Planes · artboards de diseño

Extraídos de `BaleadaFit Ideas-2.html` (board `__bundler`, fuera del repo). Cada archivo `.html` es el contenido del bloque `__bundler/template` de la pantalla, desescapado sin reformatear (el board guarda cada pantalla como un bundle anidado cuyo `template` es el marcado real). Contexto: `odd/designs/planes-context.md`.

Notas sobre los archivos:
- Cada `.html` conserva su `<style data-dc-design-system-vars>` y su `<style>` propio. No dependen de una hoja externa del bundle.
- Referencian recursos que el export no incluye junto al marcado: `<script src="<uuid>">` (runtime del board), fuentes `ds/baleadafit/fonts/*.ttf` (se cae a `system-ui`) y Material Symbols desde Google Fonts (necesita red; sin ella los iconos se ven como texto de ligadura). Los enlaces `*.dc.html` apuntan a pantallas del board que no se exportaron. El marcado se ve abierto en un navegador, sin la parte dinámica.
- Los textos de iconos (`arrow_back`, `add`, …) son ligaduras, no copy; no se cuentan.
- Conteo: cada línea de la lista es una cadena visible (texto, placeholder o valor inicial de un input). Los `aria-label` no son visibles y se citan sólo en la nota estructural.

## Mapa

| Artboard | Archivo | UUID del iframe |
|---|---|---|
| Planes · lista | `PlanesLista.html` | `2791e7ea-a89f-4151-89e0-cad9d0e3f0f0` |
| Planes · sin planes | `PlanesSinPlanes.html` | `a8712476-4a1c-47b9-9bb4-1f1bd352da90` |
| Generar plan | `GenerarPlan.html` | `84227de4-4bfc-416f-9f33-0770c2ad04ab` |
| Detalle semanal · borrador | `DetalleSemanalBorrador.html` | `41a6db00-5d47-4ec9-9081-d6747d9c5368` |
| Editar un tiempo de comida | `EditarTiempoComida.html` | `4b96cf50-221a-442c-923d-c03a25c9dcb3` |

## Inventario de copy (verbatim, en orden visual)

### Planes · lista (`PlanesLista.html`) — 27 cadenas

- "Planes"
- "Paciente De Prueba" [dato de ejemplo]
- "Plan 2026-11-07" [dato de ejemplo]
- "ACTIVO"
- "Por reglas"
- "KCAL"
- "1.500" [dato de ejemplo]
- "PROT"
- "93.8g" [dato de ejemplo]
- "CARB"
- "187.5g" [dato de ejemplo]
- "GRASA"
- "41.7g" [dato de ejemplo]
- "Activo el 7 nov" [dato de ejemplo]
- "Plan 2026-10-20" [dato de ejemplo]
- "ARCHIVADO"
- "Por reglas"
- "KCAL"
- "1.600" [dato de ejemplo]
- "PROT"
- "100g" [dato de ejemplo]
- "CARB"
- "200g" [dato de ejemplo]
- "GRASA"
- "44g" [dato de ejemplo]
- "Creado el 20 oct · solo lectura" [dato de ejemplo]
- "Generar plan"

**Estructura**

- Días: no dibuja días ni tiempos de comida; es la lista de planes del paciente (2 tarjetas).
- Tarjeta de plan: nombre, insignia de estado, etiqueta de origen, 4 métricas en rejilla (KCAL, PROT, CARB, GRASA) y una línea de fecha. Las dos tarjetas son enlaces a `PlanDetalle.dc.html`.
- Acciones: volver a la ficha (flecha, `aria-label="Volver a la ficha"`), abrir un plan (tarjeta), botón fijo inferior "Generar plan".
- Origen: sí, como "Por reglas" en ambas tarjetas (no aparece `IA` ni `REGLAS` literal). Sin estado de progreso. Sin paso de activación.
- El plan activo y el archivado se distinguen por la insignia; el archivado se atenúa y dice "solo lectura".
- Iconos (Material Symbols, no son copy): `arrow_back`, `add`.

### Planes · sin planes (`PlanesSinPlanes.html`) — 5 cadenas

- "Planes"
- "María Isabel Hernández Paz" [dato de ejemplo]
- "Todavía no tiene un plan"
- "Generá el primero con sus metas y restricciones. Va a quedar en borrador hasta que lo revisés y lo activés."
- "Generar plan"

**Estructura**

- Días: ninguno. Estado vacío de la lista: icono `restaurant_menu`, título, texto de ayuda y un botón.
- Acciones: volver a la ficha (flecha, `aria-label="Volver a la ficha"`), "Generar plan" (enlace a `PlanesGenerar.dc.html`).
- Sin origen, sin progreso, sin activación. El texto de ayuda menciona que el plan queda en borrador hasta activarlo.
- Iconos: `arrow_back`, `restaurant_menu`, `add`.

### Generar plan (`GenerarPlan.html`) — 33 cadenas

- "Generar plan"
- "Paciente De Prueba" [dato de ejemplo]
- "Nombre"
- "Plan 2026-11-16" [dato de ejemplo]
- "Kcal objetivo · opcional"
- "Calculado automáticamente"
- "1.000 a 5.000. Si lo dejás vacío, se calcula con Mifflin-St Jeor y la meta del paciente."
- "Distribución de macros"
- "Proteína"
- "25%" [dato de ejemplo]
- "Carbohidrato"
- "50%" [dato de ejemplo]
- "Grasa"
- "25%" [dato de ejemplo]
- "Rangos: proteína 10–50 %, carbohidrato 20–70 %, grasa 10–50 %. Los tres son obligatorios si se cambia uno."
- "Distribución por tiempo de comida"
- "Desayuno"
- "25%" [dato de ejemplo]
- "Merienda · mañana"
- "10%" [dato de ejemplo]
- "Almuerzo"
- "35%" [dato de ejemplo]
- "Merienda · tarde"
- "10%" [dato de ejemplo]
- "Cena"
- "20%" [dato de ejemplo]
- "Indicaciones para el recomendador · opcional"
- "Prefiere desayunos rápidos y cenas sin frituras"
- "Usar IA"
- "Si no está disponible, cae a reglas automáticamente."
- "Hoy el recomendador en producción devuelve resultados por reglas, con o sin este interruptor. No hay forma de prometerle IA al plan todavía."
- "Generar plan"
- "Con IA puede tardar hasta 25 segundos. El plan queda en borrador."

**Estructura**

- Días: ninguno (formulario). Dibuja 5 tiempos de comida con su porcentaje: Desayuno 25%, Merienda · mañana 10%, Almuerzo 35%, Merienda · tarde 10%, Cena 20% (suman 100%).
- Campos: Nombre, Kcal objetivo (opcional), 3 macros (Proteína/Carbohidrato/Grasa, suman 100%), 5 porcentajes por tiempo, textarea de indicaciones (opcional), interruptor "Usar IA" dibujado encendido.
- Acciones: cerrar sin generar (`close`, `aria-label="Cerrar sin generar"`, enlaza a `PlanesLista.dc.html`), botón fijo "Generar plan" (enlaza a `PlanDetalle.dc.html`).
- Progreso de generación: NO hay pantalla ni estado de progreso; sólo la nota "Con IA puede tardar hasta 25 segundos."
- Origen: no hay etiqueta `IA`/`REGLAS`; hay un interruptor "Usar IA" y un aviso informativo (icono `info`) que dice que producción devuelve reglas.
- Activación: ninguna. Dice que el plan queda en borrador.
- Los valores 25% / 50% / 25% y los porcentajes por tiempo están como `value` de inputs (valores iniciales dibujados).
- Iconos: `close`, `info`.

### Detalle semanal · borrador (`DetalleSemanalBorrador.html`) — 39 cadenas

- "Plan 2026-11-07" [dato de ejemplo]
- "Borrador · sin publicar"
- "BORRADOR"
- "Por reglas"
- "KCAL / DÍA"
- "1.500" [dato de ejemplo]
- "PROT"
- "93.8g" [dato de ejemplo]
- "CARB"
- "187.5g" [dato de ejemplo]
- "GRASA"
- "41.7g" [dato de ejemplo]
- "Generado por reglas: no había medición de grasa corporal, se usó el peso y la talla para estimar el gasto." [dato de ejemplo]
- "Totales de la semana"
- "+0.4 %" [dato de ejemplo]
- "10.542 kcal reales de 10.500 kcal meta (7 días)" [dato de ejemplo]
- "DÍA"
- "LUN"
- "MAR"
- "MIE"
- "JUE"
- "VIE"
- "SAB"
- "DOM"
- "Lunes"
- "1.506 kcal · +0.4 %" [dato de ejemplo]
- "Desayuno"
- "25 % · 375 kcal · 2 alimentos" [dato de ejemplo]
- "Merienda · mañana"
- "10 % · 150 kcal · 1 alimento" [dato de ejemplo]
- "Almuerzo"
- "35 % · 525 kcal · 3 alimentos" [dato de ejemplo]
- "Arroz blanco · 1 porción · Pollo a la plancha · 1.5 porciones · Ensalada verde · 1 porción" [dato de ejemplo]
- "Merienda · tarde"
- "10 % · 150 kcal · 1 alimento" [dato de ejemplo]
- "Cena"
- "20 % · 300 kcal · 2 alimentos" [dato de ejemplo]
- "Activar plan"
- "Lo va a ver el paciente en su app; el plan activo anterior pasa a archivado."

**Estructura**

- Días: dibuja 7 chips de día (LUN MAR MIE JUE VIE SAB DOM; LUN resaltado) pero sólo expande UN día: "Lunes". Los otros seis no tienen contenido dibujado. El resumen de la semana dice "(7 días)".
- Tiempo de comida: fila-enlace (a `PlanEditarTiempo.dc.html`) con nombre, línea "porcentaje · kcal · N alimentos" y `chevron_right`. Sólo "Almuerzo" muestra además la línea de alimentos con porciones, separada por " · " en una sola cadena. Los cinco tiempos: Desayuno, Merienda · mañana, Almuerzo, Merienda · tarde, Cena.
- Bloques: encabezado con nombre y subtítulo "Borrador · sin publicar"; tarjeta de estado (BORRADOR + "Por reglas"), metas KCAL / DÍA, PROT, CARB, GRASA y texto de justificación; tarjeta "Totales de la semana" con desviación en %; selector de día; día con su desviación.
- Acciones: volver a planes (flecha, enlaza a `PlanesLista.dc.html`), menú `more_vert` (sólo `aria-label="Eliminar borrador"`; no se dibuja el menú ni confirmación), tocar un tiempo para editarlo, botón fijo "Activar plan" (enlaza a `PlanesLista.dc.html`; sin diálogo de confirmación dibujado).
- Origen: sí, "Por reglas" y la justificación "Generado por reglas: …". Sin progreso de generación. Paso de activación: sí, el botón "Activar plan" con su aviso (el activo anterior pasa a archivado).
- No dibuja copiar/duplicar día o plan.
- Iconos: `arrow_back`, `more_vert`, `chevron_right`, `publish`.

### Editar un tiempo de comida (`EditarTiempoComida.html`) — 17 cadenas

- "Editar tiempo"
- "Almuerzo · Lunes"
- "Guardar reemplaza la lista completa de este tiempo. Lo que no esté acá se elimina; no se agrega sobre lo anterior."
- "35 % del día · meta 525 kcal" [dato de ejemplo]
- "3 de 12 alimentos" [dato de ejemplo]
- "Arroz blanco" [dato de ejemplo]
- "1 taza · 205 kcal" [dato de ejemplo]
- "1" [dato de ejemplo]
- "Pollo a la plancha" [dato de ejemplo]
- "100 g · 231 kcal" [dato de ejemplo]
- "1.5" [dato de ejemplo]
- "Ensalada verde" [dato de ejemplo]
- "1 porción · 89 kcal" [dato de ejemplo]
- "1" [dato de ejemplo]
- "Agregar alimento"
- "Usa el mismo buscador del catálogo, como selector. Porciones de 0.25 a 6."
- "Guardar tiempo"

**Estructura**

- Días: uno solo, "Almuerzo · Lunes" (35 % del día, meta 525 kcal).
- Tiempo de comida: lista de 3 filas de alimento; cada fila lleva nombre, detalle "porción · kcal", control de porciones (`remove` / valor / `add`) y `close` para quitar.
- Acciones: cerrar sin guardar (`close`, `aria-label="Cerrar sin guardar"`, enlaza a `PlanDetalle.dc.html`), quitar alimento, cambiar porciones, "Agregar alimento" (enlaza a `CatalogoBuscador.dc.html`), botón fijo "Guardar tiempo" (enlaza a `PlanDetalle.dc.html`).
- Aviso informativo (icono `info`): guardar reemplaza la lista completa del tiempo.
- Sin etiqueta de origen, sin progreso, sin paso de activación. La pantalla no dice si el plan editado es borrador o activo; se llega desde el detalle de borrador.
- Los totales "3 de 12 alimentos" y "35 % del día · meta 525 kcal" son datos de ejemplo; 12 y 0.25–6 son los topes del contrato.
- Iconos: `close`, `info`, `remove`, `add`.

## Contraste con el contrato

Contrastado contra `odd/designs/planes-context.md` (§11 gaps, §12 qué se puede dibujar, §13 qué no). Lo que sigue distingue lo que el export **dibuja** de lo que sólo **implica**. Los puntos marcados **[DECISIÓN]** necesitan una persona.

### Los cuatro controles pedidos

1. **¿Edita ítems de un plan ACTIVO?** El export no dibuja ninguna pantalla de detalle de un plan activo. `EditarTiempoComida.html` sólo se alcanza desde `DetalleSemanalBorrador.html`, que es un borrador, y no dice en ningún texto si el plan es borrador o activo. Pero `PlanesLista.html` enlaza las tarjetas ACTIVO y ARCHIVADO al mismo destino que usa el flujo de edición (`PlanDetalle.dc.html`), que no se exportó: la lista implica que el detalle (con sus filas editables) se reutiliza para planes activos y archivados. El contrato no regula editar ítems de un plan activo (gap 8: `tiempos[].id`, registros ya marcados en el diario, versión de alimento del ítem reenviado) ni declara qué pasa con el PUT sobre un archivado (la tarjeta archivada dice "solo lectura"). **[DECISIÓN]** Permitir o no el "Editar tiempo" en un plan ACTIVO (y en uno ARCHIVADO) y, si se permite, qué aviso lleva.
2. **¿Asume que el generador produce siete días?** Sí, por implicación. El resumen dice "10.542 kcal reales de 10.500 kcal meta (7 días)" (10.500 = 1.500 × 7), el selector dibuja siete chips (LUN MAR MIE JUE VIE SAB DOM) y la meta semanal de la tarjeta es 7 × diaria. El contrato no declara cuántos días devuelve `generar` y `dias` sólo trae los días con algún tiempo (gap 1; §10: "no dibujar columnas fantasma"). Además el export sólo dibuja el contenido de un día (Lunes); los otros seis chips no tienen contenido ni estado distinto de "no seleccionado". **[DECISIÓN]** Qué muestra el selector cuando `dias` trae menos de siete, y de dónde sale "(7 días)".
3. **¿Muestra copiar o duplicar un día o un plan?** No. Ninguno de los cinco archivos contiene "copiar", "duplicar", "repetir", arrastrar ni reactivar. Nada que contrastar; no hay endpoint (gap 13, §13).
4. **¿Etiqueta el plan como generado por IA?** No como promesa de resultado: la etiqueta de origen que dibuja es "Por reglas" (lista y detalle), coherente con `origen: REGLAS` de producción. No dibuja una etiqueta `IA` ni `MANUAL`. Pero `GenerarPlan.html` muestra el interruptor "Usar IA" **encendido** (por defecto del contrato: `usarIa = true`), con el aviso "Si no está disponible, cae a reglas automáticamente." y la nota "Con IA puede tardar hasta 25 segundos.", y añade un bloque informativo cuyo texto es una nota técnica: "Hoy el recomendador en producción devuelve resultados por reglas, con o sin este interruptor. No hay forma de prometerle IA al plan todavía." **[DECISIÓN]** Si el interruptor "Usar IA" se muestra hoy, y si ese bloque informativo es copy de producto o sólo una anotación de diseño (habla de "producción" y de qué se "puede prometer" al plan). Tampoco están dibujadas las etiquetas `IA` y `MANUAL` para cuando existan.

### Otras diferencias detectadas

- **Estado de generación en curso: no dibujado.** Sólo la nota "Con IA puede tardar hasta 25 segundos."; ni pantalla de carga larga ni cancelación (§10, §3). **[DECISIÓN]** Si hace falta una pantalla de espera antes de implementar.
- **Sin medición (gap 3): no dibujado.** `GenerarPlan.html` no tiene el camino a "nueva medición", ni el botón deshabilitado, ni errores de validación (400 `VALIDACION` con `detalles`, gap 3/4/14).
- **Suma de distribuciones y tiempo en 0 (gap 2).** El formulario dibuja macros (25 / 50 / 25 %) y cinco tiempos (25 / 10 / 35 / 10 / 20 %) que suman 100 %, siempre con cinco tiempos. No dibuja qué pasa si no suman 1 ni un tiempo en 0, que el contrato deja indefinido (¿se omite o queda vacío?). El detalle sí asume cinco tiempos por día.
- **Formato de porcentajes inconsistente en el export:** `GenerarPlan.html` usa "25%" (sin espacio) y `DetalleSemanalBorrador.html`/`EditarTiempoComida.html` usan "25 %" (con espacio). El contrato entrega fracciones 0..1 (`pctKcal`, `desviacion`, `distribucion*`); la conversión ×100 y el signo ("+0.4 %", con punto decimal) son decisiones de la UI. **[DECISIÓN]** Formato único del espacio y del separador decimal (las kcal usan punto de millar: "1.500"; los porcentajes y las porciones usan punto decimal: "+0.4 %", "1.5").
- **Activar sin confirmación dibujada.** `DetalleSemanalBorrador.html` tiene "Activar plan" con una frase que explica el efecto, pero no un diálogo; §5 y §12 piden "con confirmación". Tampoco dibuja el error 400 de activar (gap 14).
- **Eliminar borrador sin menú dibujado.** Sólo `more_vert` con `aria-label="Eliminar borrador"`; no hay menú, texto ni confirmación visibles.
- **Edición de nombre, metas y justificación (PATCH) no está dibujada** en ninguna pantalla, aunque el contrato lo permite (§12). La justificación se muestra como texto de ejemplo ("Generado por reglas: …") y no hay acción de editarla ni de borrarla (gap 7).
- **Editar un tiempo puede dejarlo vacío (gap 9).** Cada alimento tiene un `close` y no se dibuja un mínimo; quitar los tres deja `items: []`, cuyo efecto el contrato no define.
- **Kcal por alimento en la edición.** "100 g · 231 kcal" convive con "1.5" porciones: el export no deja claro si "231 kcal" es por porción o ya multiplicado. Los datos del ítem (`alimento.kcal`, `porciones`, `alimentoVersion`) no resuelven la etiqueta; confirmar con el contrato antes de citar la cifra.
- **Alimentos del tiempo en el detalle.** Sólo "Almuerzo" muestra los alimentos (una cadena unida por " · "); los demás tiempos sólo su resumen. Es diseño de una fila, no contrato.
- **Cosas del contrato que el export no dibuja y §12 permite:** estado vacío de un tiempo, `justificacion: null` (ocultar el bloque), error de red/validación, `MANUAL`, tiempo con totales sin definir (gap 11 nulos en `TotalesEntity`), fecha de activación en el detalle.
- **Lista (gap 12):** la lista dibuja ACTIVO primero y ARCHIVADO después; el contrato no filtra por `estado` ni garantiza que el activo vaya primero, hay que leer `estado` por fila.
- **No dibuja** reordenar/cambiar porcentaje de tiempos tras generar, duplicar/crear vacío/reactivar/desactivar, historial, ni fechas de vigencia (§13): coherente con el contrato.

### Resumen de decisiones humanas

1. Editar ítems de un plan ACTIVO (y ARCHIVADO): permitir o no.
2. Qué dibuja el selector semanal cuando `generar` devuelve menos de 7 días.
3. Interruptor "Usar IA" y bloque informativo "Hoy el recomendador en producción…": mostrar, reformular o quitar.
4. Estado de generación en curso y camino de "sin medición".
5. Confirmación de "Activar plan" y menú/confirmación de "Eliminar borrador".
6. Formato de porcentajes ("25%" vs "25 %") y separador decimal.
