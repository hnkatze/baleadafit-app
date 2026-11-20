# Catálogo de alimentos

El catálogo que la nutricionista busca, consulta y edita. Diseño: `odd/designs/catalogo/`
(6 boards nuevos + 5 anteriores del canvas `BaleadaFit Ideas-4`). Contrato y decisiones de
diseño: `odd/designs/catalogo-context.md`.

## Specs

**S1 — Búsqueda.** Encabezado `Catálogo de alimentos` con el conteo de activos debajo
(`151 alimentos activos`; sale de `meta.total` de una búsqueda sin filtros, no de un endpoint de
conteo). Buscador con placeholder `Buscar por nombre…` y lupa. Debajo, chips de categoría
horizontales, primero `Todas` y después los nueve valores del enum con su etiqueta:
`Plato típico`, `Proteína`, `Cereal y tubérculo`, `Leguminosa`, `Lácteo`, `Fruta`, `Verdura`,
`Grasa`, `Bebida`. El chip elegido filtra por `categoria`.

**S2 — Filtros secundarios.** Bajo los chips, tres controles: tiempo de comida
(`Desayuno`, `Merienda AM`, `Almuerzo`, `Merienda PM`, `Cena`; por defecto ninguno), `Sólo típicos
HN` como interruptor (`soloTipicos`) y `Excluir · N` con las etiquetas elegidas (`excluir`).
Cuando hay filtros puestos, una sección `FILTROS` lista cada uno como chip con `x` para quitarlo y
una acción `Limpiar` que los quita todos.

**S3 — Resultados.** Encima de la lista, el conteo real (`38 resultados`). Cada fila: nombre,
línea secundaria `categoria · porcionDescripcion · porcionGramos g`, línea de macros
`P 31 · C 0 · G 4 g`, la energía con el rótulo `KCAL` y, cuando `esTipicoHn`, la insignia `Típico`.
La fila abre el detalle (S5).

**S4 — Paginación.** Al pie de la lista, `Mostrando 20 de 38` y `Cargar 18 más` mientras
`meta.hasMore`. La acción primaria de la pantalla es `Agregar alimento` con ícono `add`.

**S5 — Sin resultados.** Estado propio, no un error: ícono `search_off`, título
`Ningún alimento con estos filtros`, y el cuerpo que nombra el texto buscado y cuántos filtros
había: `de 151 alimentos coinciden con “quesillo” y los 3 filtros. Quitá uno para ampliar la búsqueda.`
Acción `Limpiar filtros`. Debajo, un bloque de apoyo: `¿No está en el catálogo? Nadie más lo carga:
lo agregás vos.` con acción `Agregar`.

**S6 — Detalle.** Encabezado `Alimento` con flecha de volver y acceso `history` al historial (S8).
El alimento: nombre grande, `categoria` con ícono, `porcionDescripcion · porcionGramos g` y el
rótulo `Por porción`. Bloque de energía: las `kcal` destacadas y los macros con sus rótulos
(`Proteína`, `Carbos`, `Grasa`, `Fibra`) en gramos.
Después, `Micronutrientes`: `Sodio` con la marca `Estimado` y el valor con virgulilla (`~74 mg`),
`Potasio`, `Fósforo`, `Azúcares`, `Grasas saturadas` e `Índice glucémico`; cuando el índice es
nulo, se dibuja `Sin dato` con ícono `remove`, nunca `0`. Nota al pie del bloque:
`El sodio es aproximado: verificar con INCAP. El índice glucémico no aplica a alimentos sin carbohidratos.`
Luego `Contiene` con las etiquetas de `contiene` cruzadas con el vocabulario de `GET /restricciones`,
y cuando no hay ninguna:
`Sin etiquetas de restricción. Aparece aunque se excluya lactosa o gluten.`
Después `Tiempos de comida` con los tiempos **del alimento** (`tiposComida`), como los dibuja el
board: el pollo lleva `Almuerzo` y `Cena`, no los cinco del enum. Y `Fuente: <fuente>`.
Cierre: sección `DAR DE BAJA` con el texto `Sale del catálogo y de las búsquedas. No se borra: su
historial de versiones se conserva.` y el botón `Dar de baja`, más las acciones `Ver historial` y
`Editar`.

**S7 — Dar de baja (confirmación).** Título `¿Dar de baja “<nombre>”?` y tres puntos:
`Es una baja lógica: el alimento no se borra.`, `Deja de aparecer en el catálogo y en las búsquedas
para armar planes.`, `Se conservan sus datos y su historial de versiones.`, más la advertencia
`El catálogo no lista alimentos inactivos, así que después no vas a encontrarlo desde la búsqueda
para reactivarlo.` y el botón destructivo `Dar de baja`. Es un `PATCH /alimentos/{id}` con
`activo: false`. **Desvío deliberado del artboard:** el board lo dibuja como pantalla completa, con
una `close` de color tinta y un botón `Cancelar`; la casa lo implementa como diálogo que se cierra
**sólo** con la cruz roja de la esquina (`cerrar-dialogo`), como el resto de la app.

**S8 — Alta / edición.** Un solo formulario, a pantalla completa, con `x` para cerrar. El board C4
dibuja **sólo** la edición: título `Editar alimento` y acción `Guardar cambios` (los textos del alta
vienen como plantilla en el board anterior, `{{tituloForm}}`/`{{textoBoton}}`). Aviso superior:
`Todos los valores son por porción. Si vaciás un campo, se conserva el valor guardado. Cambiar un
nutriente crea una versión nueva.` Cuatro bloques numerados:
1. `1 · Identidad`: `Nombre`, `Categoría` (los nueve chips), `Típico hondureño` y `Fuente`
   (placeholder `INCAP, USDA, etiqueta del producto…`).
2. `2 · Porción`: `Descripción` y `Gramos`.
3. `3 · Composición por porción`, con subtítulo `ENERGÍA Y MACROS`: `Energía · kcal`,
   `Proteína · g`, `Carbohidrato · g`, `Grasa · g`, `Fibra · g`. Y `MICRONUTRIENTES`:
   `Sodio · mg` con la marca `Estimado` y la ayuda `Se guarda como aproximado. Verificar con INCAP.`,
   `Potasio · mg`, `Fósforo · mg`, `Azúcares · g`, `Grasas sat. · g` e `Índice glucémico`, con
   placeholder `Sin dato` y la ayuda `Dejalo vacío si el alimento no tiene carbohidratos: queda “sin
   dato”, no 0.`
4. `4 · Uso`: `Tiempos de comida` (los cinco con ícono, seleccionables) y `Contiene`, con las
   etiquetas de `GET /restricciones` (el board dice `(de las 6 restricciones)`) y la nota
   `Ninguna marcada: aparece aunque se excluyan restricciones en la búsqueda.`
Acción primaria fija: `Guardar cambios`. **Abierto:** el título y el botón del alta (`Agregar
alimento` aparece sólo en el board anterior). Ninguna afordancia para limpiar un campo ya guardado
(el contrato no define el vaciado): el campo vaciado reenvía el valor anterior.

**S9 — Historial.** Encabezado `<nombre> · N versiones` con flecha de volver. Aviso:
`Cada cambio de nutrientes guarda una versión. Es la prueba de qué valores tenía el alimento cuando
se armó un plan. Valores por porción.` Cada versión: `Versión N`, insignia `VIGENTE` en la que tiene
`vigenteHasta` nulo, `Tabla: <tabla>` y el rango `12 nov 2026 → hoy` (o `→ 12 nov 2026`), más la
rejilla `KCAL`, `PROT`, `CARB`, `GRASA`, `SODIO`, `FIBRA`, `SAT`, `IG` con `sin dato` cuando falta.
Con una sola versión, el estado final explica: `Un alimento recién agregado muestra sólo la Versión
1, vigente, con “→ hoy”. Sin línea de tiempo ni comparación.` No hay diff calculado: la comparación
es visual.

## Tasks

| ID | Qué | Specs | Ruta | Commit |
|---|---|---|---|---|
| T1 | `Alimento` (21 campos) + `AlimentoVersion` + repositorio de los 6 endpoints (buscar, detalle, crear, editar, baja lógica, versiones) | S1-S9 | inline | `feat(catalogo): model the food catalogue and its endpoints` |
| T2 | Pantalla de búsqueda y lista: buscador, chips de categoría, filtros, resultados, paginación y estado sin resultados | S1-S5 | writer | `feat(catalogo): search the catalogue and show its empty state` |
| T3 | Detalle del alimento con macros, micronutrientes, etiquetas, tiempos y la baja con confirmación | S6, S7 | writer | `feat(catalogo): read a food and deactivate it` |
| T4 | Formulario de alta y edición en cuatro bloques, con validación por campo | S8 | writer | `feat(catalogo): add and edit a food` |
| T5 | Historial de versiones | S9 | writer | `feat(catalogo): show the version history of a food` |
| T6 | Ruteo y entrada al módulo desde la navegación | - | inline | `feat(catalogo): reach the catalogue from the shell` |

## Log

**L1 (usuario, 2026-11-19):** "/Users/katze/Downloads/BaleadaFit Ideas-4.html aqui te dejo los design
del catalogo de alimentos, y dejame un contexto del flujo de auth, tenemos login, credenciales y
google y registro nose si tenemos, pero para disenar algo mas bonito, y vamos creando las task del
catalogo pls"

**L2 (evidencia):** el export trae 11 boards: 6 nuevos (`C1 · Catálogo · búsqueda`,
`C2 · Catálogo · sin resultados`, `C3 · Detalle del alimento`, `C4 · Alta / edición`,
`C5 · Historial de versiones`, `C3b · Dar de baja (confirmación)`) y 5 marcados `Anterior · …`.
Los seis nuevos están extraídos en `odd/designs/catalogo/`; los cinco anteriores se conservan como
referencia histórica y **no** se implementan.

**L3 (hecho del contrato):** los micronutrientes vienen en `GET /alimentos/{id}` (21 campos), así que
el detalle es una sola llamada. `/versiones` es sólo historial.

**L4 (decisión de producto):** el conteo del encabezado (`151 alimentos activos`) sale de
`meta.total` de una búsqueda sin filtros, porque el contrato no tiene un endpoint de conteo.

**L5 (desvío del diseño):** S7 no lleva botón `Cancelar` aunque el artboard lo dibuje: la casa usa
la cruz roja como única salida de los diálogos.

**L6 (auth, para el diseño paralelo):** ver `odd/designs/auth-context.md`. Hay login con credenciales
y Google; **no hay registro** en la app aunque `POST /auth/registro-nutricionista` exista, y el rol
`sin_perfil` de `GET /auth/me` es justo el estado que lo pide.

**L7 (correcciones del 2026-11-19 tras el inventario de copy del README del catálogo):**
1. S6 decía "los cinco valores posibles" en `Tiempos de comida`; el board dibuja los tiempos **del
alimento** (`Almuerzo`, `Cena` para el pollo). Corregido.
2. S9 citaba "Una alimento recién agregado"; el board dice "Un alimento". Corregido (era error de
transcripción mío).
3. S7 sugería un diálogo; el board C3b es una pantalla completa con `close` de tinta y botón
`Cancelar`. El desvío a la cruz roja ya no se presenta como si fuera del diseño.
4. S8 afirmaba que el alta usaba `Agregar alimento`: C4 dibuja sólo la edición, y esos textos del
alta existen únicamente como plantilla (`{{tituloForm}}`/`{{textoBoton}}`) en el board anterior.
Queda como decisión abierta.

**L8 (decisiones humanas abiertas, detalladas en `odd/designs/catalogo/README.md`):** origen de la
etiqueta `Sin lactosa` del buscador; chip `Sólo típicos` (C2) vs `Sólo típicos HN` (C1); si el
detalle lista todos los tiempos o sólo los del alimento; cuándo aparece `Estado: una sola versión`
y con qué frase; encabezado del shell (`menu` y avatar `CH`); qué ve quien no es nutricionista;
textos del alta; estados no dibujados (carga, error de red, error por campo, paginación del
historial, éxito); y cómo se dibujan las etiquetas de `Contiene` en el detalle.

**L9 (evidencia T1):** capa de datos con 23 tests. El parent corrigió `AlimentoVersion` tras
consultar el schema: el contrato **no** tiene `alimentoId` (el alimento lo nombra la ruta) y sí tiene
`fuente`, `porcionDescripcion` y `porcionGramos`; quedaron los 19 campos reales.

**L10 (evidencia T3 y T5):** detalle + baja con 19 tests y historial con 11. Decisiones que quedan:
el cruce `contiene → nombre` cae al `codigo` crudo si la restricción no está en el catálogo o está
cargando (no se pierde la etiqueta y no se rompe la pantalla); el diálogo de baja usa
`barrierDismissible: false` para que sólo cierre la cruz; `Ver historial` y `Editar` van apilados
porque en fila desbordan a 390 px; y el bloque `Estado: una sola versión` aparece sólo con
`meta.total == 1`, con el encabezado en singular (`1 versión`).

**L11 (evidencia T2):** búsqueda con 15 tests. Decisiones: paginación por **offset** con límite 20
(el modo cursor no devuelve el `total` real, y S3/S4 lo necesitan para `Mostrando N de M` y
`Cargar K más`); debounce de 300 ms que se reinicia al escribir, con la `x` del buscador y
`Limpiar filtros` aplicando al instante; los dos "Limpiar" no son lo mismo — el de `FILTROS` quita
sólo los chips y `Limpiar filtros` del estado vacío quita también el texto, porque si no la lista
seguiría vacía; una búsqueda nueva conserva la lista anterior bajo una barra de progreso y descarta
la respuesta de una consulta vieja; y el cuerpo de S5 cambia de frase según haya 0, 1 o varios
filtros, contando cada exclusión como uno.
