# Catálogo de alimentos · artboards de diseño

Extraídos de `BaleadaFit Ideas-4.html` (board `__bundler`, en `~/Downloads`, fuera del repo). Cada archivo `.html` es el contenido del bloque `__bundler/template` de la pantalla, desescapado sin reformatear. Contexto de contrato: `odd/designs/catalogo-context.md`. Specs de producto: `odd/tasks/catalogo.md` (S1-S9, la lectura vinculante de estos boards).

Notas sobre los archivos:
- Son 11: los seis boards nuevos (sección «Boards nuevos») y los cinco `Anterior*.html` (sección «Referencia histórica»).
- Cada `.html` conserva su `<style data-dc-design-system-vars>` y su `<style>` propio. No dependen de una hoja externa del bundle.
- Cada archivo está envuelto en comillas dobles literales (`"<!DOCTYPE …</html>"`): es un artefacto del desescapado, no copy; no se cuentan.
- Referencian recursos que el export no incluye junto al marcado: `<script src="<uuid>">` (runtime del board), fuentes `ds/baleadafit/fonts/*.ttf` (se cae a `system-ui`) y Material Symbols desde Google Fonts (necesita red; sin ella los iconos se ven como texto de ligadura). Los enlaces `*.dc.html` apuntan a pantallas del board; los nombres no coinciden con los archivos exportados (`AlimentosBuscar.dc.html` = `CatalogoBusqueda.html`, `AlimentoVersiones.dc.html` = `AlimentoHistorial.html`, `CatalogoBuscador/Ficha/Alta/Versiones.dc.html` = los anteriores).
- Ancho 390 px en todos. Alto de vista previa: baja 844, detalle 1240, formulario 2000, historial 1000.
- Los `<span class="ms">` son ligaduras de Material Symbols, no copy: no se cuentan y se citan como ícono.
- Conteo: cada línea de la lista es una cadena visible (texto, `placeholder` o `value` de un input). Los `aria-label`, los `<title>` y la etiqueta oculta `Buscar alimento` (`<label>` de 1 px, sólo lector de pantalla) no son visibles: se citan sólo en la nota estructural y no cuentan.
- Los datos de ejemplo del board van marcados `[dato de ejemplo]`; las anotaciones de diseño que no son copy de producto, `[anotación]`.

## Mapa

| Artboard (título en el board) | Archivo | Spec |
|---|---|---|
| C1 · Catálogo · búsqueda | `CatalogoBusqueda.html` | S1-S4 |
| C2 · Catálogo · sin resultados | `CatalogoSinResultados.html` | S5 |
| C3 · Detalle del alimento | `AlimentoDetalle.html` | S6 |
| C4 · Alta / edición | `AlimentoForm.html` | S8 |
| C5 · Historial de versiones | `AlimentoHistorial.html` | S9 |
| C3b · Dar de baja (confirmación) | `AlimentoBaja.html` | S7 |
| Anterior · buscador | `Anteriorbuscador.html` | no se implementa |
| Anterior · sin resultados | `Anteriorsinresultados.html` | no se implementa |
| Anterior · ficha del alimento | `Anteriorfichadelalimento.html` | no se implementa |
| Anterior · alta / edición | `Anterioraltaedicin.html` | no se implementa |
| Anterior · historial de versiones | `Anteriorhistorialdeversiones.html` | no se implementa |

El export no trae los UUID de iframe de estos boards; no se anotan.

## Boards nuevos · inventario de copy (verbatim, en orden visual)

### C1 · Catálogo · búsqueda (`CatalogoBusqueda.html`) — 54 cadenas

- "Catálogo de alimentos"
- "151 alimentos activos"
- "CH"
- "Buscar por nombre…" [placeholder]
- "Todas"
- "Plato típico"
- "Proteína"
- "Cereal y tubérculo"
- "Leguminosa"
- "Lácteo"
- "Fruta"
- "Verdura"
- "Grasa"
- "Bebida"
- "Almuerzo"
- "Sólo típicos HN"
- "Excluir · 1"
- "FILTROS"
- "Almuerzo"
- "Sin lactosa"
- "Limpiar"
- "38 resultados"
- "por porción"
- "Pollo a la plancha" [dato de ejemplo]
- "Proteína · 1 pieza mediana · 100 g" [dato de ejemplo]
- "P 31 · C 0 · G 4 g" [dato de ejemplo]
- "165" [dato de ejemplo]
- "KCAL"
- "Frijoles rojos cocidos" [dato de ejemplo]
- "Típico"
- "Leguminosa · 1 taza · 170 g" [dato de ejemplo]
- "P 15 · C 40 · G 1 g" [dato de ejemplo]
- "225" [dato de ejemplo]
- "KCAL"
- "Arroz blanco cocido" [dato de ejemplo]
- "Cereal y tubérculo · 1 taza · 160 g" [dato de ejemplo]
- "P 4 · C 45 · G 0 g" [dato de ejemplo]
- "205" [dato de ejemplo]
- "KCAL"
- "Tortilla de maíz" [dato de ejemplo]
- "Típico"
- "Cereal y tubérculo · 1 unidad · 30 g" [dato de ejemplo]
- "P 2 · C 13 · G 1 g" [dato de ejemplo]
- "65" [dato de ejemplo]
- "KCAL"
- "Plátano frito (tajadas)" [dato de ejemplo]
- "Típico"
- "Cereal y tubérculo · 1 taza · 120 g" [dato de ejemplo]
- "P 1 · C 35 · G 9 g" [dato de ejemplo]
- "215" [dato de ejemplo]
- "KCAL"
- "Mostrando 20 de 38"
- "Cargar 18 más"
- "Agregar alimento"

**Estructura**

- Encabezado: `menu` (`aria-label="Abrir menú"`), título, conteo, avatar "CH". Buscador con lupa (`search`) y etiqueta oculta "Buscar alimento". Chips de categoría en fila horizontal (grupo con `aria-label="Categoría"`), "Todas" primero y los nueve valores del enum.
- Filtros secundarios: tres controles en una fila — tiempo de comida (`schedule`, `expand_more`; dibuja "Almuerzo"), "Sólo típicos HN" (`flag`) y "Excluir · 1" (`block`, `expand_more`).
- Sección "FILTROS" con dos chips con `x` (`aria-label="Quitar filtro Almuerzo"` y `"Quitar filtro Sin lactosa"`) y la acción "Limpiar".
- Lista: encabezado "38 resultados" + "por porción"; cinco filas (enlaces a `AlimentoDetalle.dc.html`) con nombre, `categoria · porción · gramos`, línea `P · C · G`, la energía y el rótulo "KCAL"; la insignia "Típico" (`flag`) aparece en tres de las cinco.
- Pie: "Mostrando 20 de 38" y "Cargar 18 más"; acción primaria fija "Agregar alimento" (`add`, enlaza a `AlimentoForm.dc.html`).
- Iconos: `menu`, `search`, `schedule`, `expand_more`, `flag`, `block`, `close`, `add`.

### C2 · Catálogo · sin resultados (`CatalogoSinResultados.html`) — 14 cadenas

- "Catálogo de alimentos"
- "151 alimentos activos"
- "CH"
- "quesillo" [value, dato de ejemplo]
- "FILTROS"
- "Lácteo"
- "Sólo típicos"
- "Sin lactosa"
- "Ningún alimento con estos filtros"
- "0"
- "de 151 alimentos coinciden con “quesillo” y los 3 filtros. Quitá uno para ampliar la búsqueda."
- "Limpiar filtros"
- "¿No está en el catálogo? Nadie más lo carga: lo agregás vos."
- "Agregar"

**Estructura**

- Mismo encabezado que C1 (`aria-label="Abrir menú"`). El buscador trae el valor "quesillo" y un `close` para borrarlo (`aria-label="Borrar texto de búsqueda"`).
- "FILTROS" con tres chips con `x` (`aria-label` "Quitar filtro Lácteo", "Quitar filtro Sólo típicos", "Quitar filtro Sin lactosa"); el de categoría lleva el ícono `category`, el de típicos `flag`, el de exclusión `block`. No dibuja "Limpiar" junto a los chips (sí el botón "Limpiar filtros" debajo).
- Estado vacío: ícono `search_off`, título, un "0" grande, cuerpo con el texto y el número de filtros, botón "Limpiar filtros" (`filter_alt_off`).
- Bloque de apoyo: ícono `playlist_add`, texto y acción "Agregar" (enlaza a `AlimentoForm.dc.html`). Sin barra fija inferior ni conteo de resultados.
- Iconos: `menu`, `search`, `close`, `category`, `flag`, `block`, `search_off`, `filter_alt_off`, `playlist_add`.

### C3 · Detalle del alimento (`AlimentoDetalle.html`) — 41 cadenas

- "Alimento"
- "Pollo a la plancha" [dato de ejemplo]
- "Proteína" [dato de ejemplo]
- "1 pieza mediana · 100 g" [dato de ejemplo]
- "Por porción"
- "165" [dato de ejemplo]
- "kcal"
- "Proteína"
- "31 g" [dato de ejemplo]
- "Carbos"
- "0 g" [dato de ejemplo]
- "Grasa"
- "4 g" [dato de ejemplo]
- "Fibra"
- "0 g" [dato de ejemplo]
- "Micronutrientes"
- "Sodio"
- "Estimado"
- "~74 mg" [dato de ejemplo]
- "Potasio"
- "256 mg" [dato de ejemplo]
- "Fósforo"
- "228 mg" [dato de ejemplo]
- "Azúcares"
- "0 g" [dato de ejemplo]
- "Grasas saturadas"
- "1 g" [dato de ejemplo]
- "Índice glucémico"
- "Sin dato"
- "El sodio es aproximado: verificar con INCAP. El índice glucémico no aplica a alimentos sin carbohidratos."
- "Contiene"
- "Sin etiquetas de restricción. Aparece aunque se excluya lactosa o gluten."
- "Tiempos de comida"
- "Almuerzo" [dato de ejemplo]
- "Cena" [dato de ejemplo]
- "Fuente: USDA" [dato de ejemplo]
- "DAR DE BAJA"
- "Sale del catálogo y de las búsquedas. No se borra: su historial de versiones se conserva."
- "Dar de baja"
- "Ver historial"
- "Editar"

**Estructura**

- Encabezado: flecha (`arrow_back`, `aria-label="Volver al catálogo"`, enlaza a `AlimentosBuscar.dc.html`), título "Alimento" y acceso `history` (`aria-label="Ver historial de versiones"`, enlaza a `AlimentoVersiones.dc.html`).
- Bloque de identidad: ícono de la categoría (`egg_alt`), nombre, categoría (`category`) y porción (`scale`), rótulo "Por porción".
- Energía: región con `aria-label="Energía y macronutrientes"`; kcal grande (`local_fire_department`) y cuatro macros.
- Micronutrientes: seis filas. Sodio lleva la marca "Estimado" (`info`) y la virgulilla; "Índice glucémico" dibuja "Sin dato" con `remove`; nota con `info`.
- "Contiene": dibuja sólo el caso vacío (`warning` con el texto "Sin etiquetas de restricción…"); no dibuja etiquetas. "Tiempos de comida": dos chips (`lunch_dining` Almuerzo, `dinner_dining` Cena). "Fuente" con `menu_book`. No dibuja la insignia "Típico".
- Cierre: bloque "DAR DE BAJA" con texto y botón "Dar de baja" (`visibility_off`, enlaza a `AlimentoBaja.dc.html`); barra fija con "Ver historial" (`history`) y "Editar" (`edit`, enlaza a `AlimentoForm.dc.html`).
- Iconos: `arrow_back`, `history`, `egg_alt`, `category`, `scale`, `local_fire_department`, `science`, `info`, `remove`, `warning`, `verified`, `schedule`, `lunch_dining`, `dinner_dining`, `menu_book`, `visibility_off`, `edit`.

### C4 · Alta / edición (`AlimentoForm.html`) — 66 cadenas

- "Editar alimento"
- "Mismo formulario para el alta" [anotación]
- "Todos los valores son por porción. Si vaciás un campo, se conserva el valor guardado. Cambiar un nutriente crea una versión nueva." ("por porción" va en negrita dentro de la misma frase)
- "1 · Identidad"
- "Nombre"
- "Pollo a la plancha" [value, dato de ejemplo]
- "Categoría"
- "Plato típico"
- "Proteína"
- "Cereal y tubérculo"
- "Leguminosa"
- "Lácteo"
- "Fruta"
- "Verdura"
- "Grasa"
- "Bebida"
- "Típico hondureño"
- "Fuente"
- "INCAP, USDA, etiqueta del producto…" [placeholder]
- "USDA" [value, dato de ejemplo]
- "2 · Porción"
- "Descripción"
- "1 pieza mediana" [value, dato de ejemplo]
- "Gramos"
- "100" [value, dato de ejemplo]
- "3 · Composición por porción"
- "ENERGÍA Y MACROS"
- "Energía · kcal"
- "165" [value, dato de ejemplo]
- "Proteína · g"
- "31" [value, dato de ejemplo]
- "Carbohidrato · g"
- "0" [value, dato de ejemplo]
- "Grasa · g"
- "4" [value, dato de ejemplo]
- "Fibra · g"
- "0" [value, dato de ejemplo]
- "MICRONUTRIENTES"
- "Sodio · mg"
- "Estimado"
- "74" [value, dato de ejemplo]
- "Se guarda como aproximado. Verificar con INCAP."
- "Potasio · mg"
- "256" [value, dato de ejemplo]
- "Fósforo · mg"
- "228" [value, dato de ejemplo]
- "Azúcares · g"
- "0" [value, dato de ejemplo]
- "Grasas sat. · g"
- "1" [value, dato de ejemplo]
- "Índice glucémico"
- "Sin dato" [placeholder]
- "Dejalo vacío si el alimento no tiene carbohidratos: queda “sin dato”, no 0."
- "4 · Uso"
- "Tiempos de comida"
- "Desayuno"
- "Merienda AM"
- "Almuerzo"
- "Merienda PM"
- "Cena"
- "Contiene (de las 6 restricciones)"
- "Lactosa"
- "Gluten"
- "[4 más de GET /restricciones]" [anotación]
- "Ninguna marcada: aparece aunque se excluyan restricciones en la búsqueda."
- "Guardar cambios"

**Estructura**

- Hoja completa: cierre `close` (`aria-label="Cerrar sin guardar"`, enlaza a `AlimentoDetalle.dc.html`), título y la anotación "Mismo formulario para el alta". Aviso informativo (`info`) bajo el título.
- Cuatro bloques numerados con ícono (`badge`, `scale`, `nutrition`, `restaurant`): identidad, porción, composición (subtítulos "ENERGÍA Y MACROS" y "MICRONUTRIENTES") y uso.
- Categoría: nueve chips; no se distingue por el copy cuál está elegida. "Típico hondureño": control con `flag`. Tiempos de comida: cinco chips con ícono (`free_breakfast`, `bakery_dining`, `restaurant`, …) y `check` en los seleccionados. "Contiene": dos chips de ejemplo (Lactosa, Gluten) y un chip punteado `[4 más de GET /restricciones]`.
- Sodio con la marca "Estimado" (`info`); el campo de índice glucémico trae placeholder "Sin dato" y una ayuda con `warning`. No dibuja ninguna afordancia para limpiar un campo ni errores por campo.
- Acción primaria fija "Guardar cambios" (`save`). No dibuja el título ni el botón del alta.
- Iconos: `close`, `info`, `badge`, `flag`, `scale`, `nutrition`, `restaurant`, `free_breakfast`, `bakery_dining`, `check`, `warning`, `save`.

### C5 · Historial de versiones (`AlimentoHistorial.html`) — 44 cadenas

- "Historial de versiones"
- "Pollo a la plancha · 2 versiones" [dato de ejemplo]
- "Cada cambio de nutrientes guarda una versión. Es la prueba de qué valores tenía el alimento cuando se armó un plan. Valores por porción."
- "Versión 2"
- "VIGENTE"
- "Tabla: USDA" [dato de ejemplo]
- "12 nov 2026 → hoy" [dato de ejemplo]
- "KCAL"
- "165" [dato de ejemplo]
- "PROT"
- "31 g" [dato de ejemplo]
- "CARB"
- "0 g" [dato de ejemplo]
- "GRASA"
- "4 g" [dato de ejemplo]
- "SODIO"
- "~74 mg" [dato de ejemplo]
- "FIBRA"
- "0 g" [dato de ejemplo]
- "SAT"
- "1 g" [dato de ejemplo]
- "IG"
- "sin dato"
- "Versión 1"
- "Tabla: INCAP" [dato de ejemplo]
- "1 mar 2025 → 12 nov 2026" [dato de ejemplo]
- "KCAL"
- "172" [dato de ejemplo]
- "PROT"
- "30 g" [dato de ejemplo]
- "CARB"
- "0 g" [dato de ejemplo]
- "GRASA"
- "5 g" [dato de ejemplo]
- "SODIO"
- "~80 mg" [dato de ejemplo]
- "FIBRA"
- "0 g" [dato de ejemplo]
- "SAT"
- "1 g" [dato de ejemplo]
- "IG"
- "sin dato"
- "Estado: una sola versión"
- "Un alimento recién agregado muestra sólo la Versión 1, vigente, con “→ hoy”. Sin línea de tiempo ni comparación."

**Estructura**

- Encabezado: flecha (`arrow_back`, `aria-label="Volver al alimento"`, enlaza a `AlimentoDetalle.dc.html`), título y "<nombre> · 2 versiones".
- Aviso informativo (`info`). Dos tarjetas de versión, la más nueva primero; la vigente lleva la insignia "VIGENTE" (`check`), "Tabla: …" (`table_chart`) y el rango (`date_range`). Rejilla de 8 métricas por versión.
- Tercer bloque, "Estado: una sola versión" (`fiber_new`): es una nota de diseño que ilustra el caso de una sola versión, no una tarjeta más. Sin diff, sin paginación, sin barra inferior.
- Iconos: `arrow_back`, `info`, `check`, `table_chart`, `date_range`, `history`, `fiber_new`.

### C3b · Dar de baja (confirmación) (`AlimentoBaja.html`) — 8 cadenas

- "Dar de baja"
- "¿Dar de baja “Pollo a la plancha”?" [dato de ejemplo en el nombre]
- "Es una baja lógica: el alimento no se borra."
- "Deja de aparecer en el catálogo y en las búsquedas para armar planes."
- "Se conservan sus datos y su historial de versiones."
- "El catálogo no lista alimentos inactivos, así que después no vas a encontrarlo desde la búsqueda para reactivarlo."
- "Dar de baja"
- "Cancelar"

**Estructura**

- Se dibuja como **pantalla completa** de 390 × 844, no como modal: encabezado con `close` (`aria-label="Cancelar y volver"`, enlaza a `AlimentoDetalle.dc.html`, color de tinta, no rojo) y el título "Dar de baja".
- Icono grande `visibility_off` sobre fondo de error, título con el nombre y la frase de baja lógica. Lista de tres filas con ícono: `search_off`, `history`, `help`.
- Dos acciones al pie: "Dar de baja" (botón destructivo con `visibility_off`; enlaza a `AlimentosBuscar.dc.html`) y "Cancelar" (botón con borde; enlaza a `AlimentoDetalle.dc.html`).

## Referencia histórica · `Anterior*.html` (NO se implementa)

Los cinco boards `Anterior · …` quedan sólo para entender qué cambió contra los nuevos. Ningún spec los cubre y ninguna tarea los implementa (`odd/tasks/catalogo.md`, L2). Inventario igual de verbatim; mismas reglas de conteo.

### Anterior · buscador (`Anteriorbuscador.html`) — 47 cadenas

- "BaleadaFit Pro"
- "Catálogo"
- "CH"
- "Buscar alimento..." [placeholder]
- "Todas"
- "Plato típico"
- "Proteína"
- "Cereal/Tubérculo"
- "Leguminosa"
- "Lácteo"
- "Fruta"
- "Verdura"
- "Grasa"
- "Bebida"
- "Todos los tiempos"
- "Desayuno"
- "Merienda AM"
- "Almuerzo"
- "Merienda PM"
- "Cena"
- "Sólo típicos"
- "Excluir restricciones"
- "151 alimentos"
- "Baleada sencilla" [dato de ejemplo]
- "Típico"
- "Plato típico · 1 unidad (180 g)" [dato de ejemplo]
- "310 kcal" [dato de ejemplo]
- "9P · 45C · 10G" [dato de ejemplo]
- "Pollo a la plancha" [dato de ejemplo]
- "Proteína · 100 g" [dato de ejemplo]
- "165 kcal" [dato de ejemplo]
- "31P · 0C · 4G" [dato de ejemplo]
- "Arroz blanco cocido" [dato de ejemplo]
- "Cereal/Tubérculo · 1 taza (160 g)" [dato de ejemplo]
- "205 kcal" [dato de ejemplo]
- "4P · 45C · 0G" [dato de ejemplo]
- "Frijoles rojos cocidos" [dato de ejemplo]
- "Típico"
- "Leguminosa · 1 taza (170 g)" [dato de ejemplo]
- "225 kcal" [dato de ejemplo]
- "15P · 40C · 1G" [dato de ejemplo]
- "Plátano frito (tajadas)" [dato de ejemplo]
- "Típico"
- "Cereal/Tubérculo · 1 taza (120 g)" [dato de ejemplo]
- "215 kcal" [dato de ejemplo]
- "1P · 35C · 9G" [dato de ejemplo]
- "Ver más (146 restantes)"

**Estructura**

- Marca "BaleadaFit Pro" con `monitor_heart`, `menu` (`aria-label="Abrir menú"`) y avatar; buscador con `aria-label="Buscar alimento"`; botón `add` (`aria-label="Agregar alimento"`, enlaza a `CatalogoAlta.dc.html`). Chips de categoría, los cinco tiempos más "Todos los tiempos" en una segunda fila de chips, y los controles "Sólo típicos" y "Excluir restricciones". Sin sección de filtros activos, sin "Limpiar".
- Cinco filas (enlazan a `CatalogoFicha.dc.html`) con kcal con unidad en la misma cadena y macros en formato `9P · 45C · 10G`. Pie "Ver más (146 restantes)". Iconos: `menu`, `monitor_heart`, `add`, `search`, `flag`.

### Anterior · sin resultados (`Anteriorsinresultados.html`) — 12 cadenas

- "BaleadaFit Pro"
- "Catálogo"
- "CH"
- "quinoa" [value, dato de ejemplo]
- "Todas"
- "Verdura"
- "Grasa"
- "Bebida"
- "Excluye: gluten" [dato de ejemplo]
- "Sin resultados para estos filtros"
- "Probá con otro texto o quitá algún filtro para ampliar la búsqueda."
- "Quitar filtros"

**Estructura**

- Mismo encabezado que el buscador anterior; buscador con "quinoa", tres chips de categoría visibles y una insignia de exclusión (`block`). Estado vacío con `search_off`, título, texto y "Quitar filtros". Sin conteo, sin "Agregar", sin `aria-label` de borrar texto. Iconos: `menu`, `monitor_heart`, `search`, `block`, `search_off`.

### Anterior · ficha del alimento (`Anteriorfichadelalimento.html`) — 36 cadenas

- "Baleada sencilla"
- "Plato típico"
- "Típico HN"
- "1 unidad (180 g) · Desayuno, Merienda AM"
- "Por porción"
- "310 kcal"
- "Proteína"
- "9 g"
- "Carbohidrato"
- "45 g"
- "Grasa"
- "10 g"
- "Fibra"
- "3 g"
- "Micronutrientes"
- "(versión vigente)"
- "Sodio *"
- "~480 mg"
- "Potasio"
- "210 mg"
- "Fósforo"
- "140 mg"
- "Azúcares"
- "2 g"
- "Grasas saturadas"
- "4 g"
- "Índice glucémico"
- "55"
- "* Estimado, verificar con INCAP."
- "Tabla INCAP 2021 rev.3 · vigente desde 1 mar 2025"
- "Historial ›"
- "Contiene"
- "Gluten"
- "Lactosa"
- "Fuente: INCAP"
- "Desactivar del catálogo"

**Estructura**

- Flecha (`aria-label="Volver al catálogo"`), título del alimento y `edit` (`aria-label="Editar alimento"`, enlaza a `CatalogoAlta.dc.html`). Sin título "Alimento". Tiempos de comida como texto en la línea de la porción. Sodio marcado con asterisco, no con insignia. Índice glucémico con valor (55); no dibuja el caso "Sin dato". "Contiene" dibuja dos etiquetas (`flag`). Enlace "Historial ›" (a `CatalogoVersiones.dc.html`). Acción destructiva "Desactivar del catálogo" (`visibility_off`) sin texto explicativo ni confirmación. Iconos: `arrow_back`, `edit`, `flag`, `warning`, `visibility_off`.

### Anterior · alta / edición (`Anterioraltaedicin.html`) — 61 cadenas

- "{{tituloForm}}" [plantilla, se resuelve en el script: `Editar alimento` / `Agregar alimento`]
- "Datos generales"
- "Nombre"
- "Baleada sencilla" [value, dato de ejemplo]
- "Categoría"
- "Plato típico"
- "Proteína"
- "Cereal/Tubérculo"
- "Leguminosa"
- "Lácteo"
- "Fruta"
- "Verdura"
- "Grasa"
- "Bebida"
- "Porción"
- "1 unidad" [value, dato de ejemplo]
- "Gramos"
- "180" [value, dato de ejemplo]
- "Es un plato o alimento típico hondureño"
- "Tiempos de comida"
- "Desayuno"
- "Merienda AM"
- "Almuerzo"
- "Merienda PM"
- "Cena"
- "Contiene (restricciones)"
- "Gluten"
- "Lactosa"
- "Maní"
- "Mariscos"
- "Huevo"
- "Soya"
- "Fuente"
- "INCAP" [value, dato de ejemplo]
- "Macros (por porción)"
- "Kcal"
- "310" [value, dato de ejemplo]
- "Proteína (g)"
- "9" [value, dato de ejemplo]
- "Carbohidrato (g)"
- "45" [value, dato de ejemplo]
- "Grasa (g)"
- "10" [value, dato de ejemplo]
- "Fibra (g)"
- "3" [value, dato de ejemplo]
- "Micronutrientes (versión actual)"
- "Guardar esto crea una nueva versión; la anterior queda en el historial."
- "Sodio (mg)"
- "· estimado"
- "480" [value, dato de ejemplo]
- "Potasio (mg)"
- "210" [value, dato de ejemplo]
- "Fósforo (mg)"
- "140" [value, dato de ejemplo]
- "Azúcares (g)"
- "2" [value, dato de ejemplo]
- "Grasas saturadas (g)"
- "4" [value, dato de ejemplo]
- "Índice glucémico"
- "55" [value, dato de ejemplo]
- "{{textoBoton}}" [plantilla, se resuelve en el script: `Guardar cambios` / `Agregar alimento`]

**Estructura**

- Flecha de volver (`arrow_back`, `aria-label="Volver al catálogo"`, enlaza a `CatalogoBuscador.dc.html`), no un `x`. Una sola columna sin bloques numerados: "Datos generales", "Macros (por porción)", "Micronutrientes (versión actual)". Dibuja las seis restricciones (Gluten, Lactosa, Maní, Mariscos, Huevo, Soya) y un script con la propiedad `editando` (por defecto `false`) que decide título y botón; de ahí sale el único copy de alta del export (`Agregar alimento` para título y botón). Sin aviso superior de "valores por porción" ni de "se conserva el valor guardado"; índice glucémico sin placeholder "Sin dato".

### Anterior · historial de versiones (`Anteriorhistorialdeversiones.html`) — 9 cadenas

- "Historial de versiones"
- "Baleada sencilla · tabla de composición" [dato de ejemplo]
- "2"
- "Tabla INCAP 2021 rev.3" [dato de ejemplo]
- "vigente desde 1 mar 2025" [dato de ejemplo]
- "Vigente"
- "1"
- "Tabla INCAP 2019" [dato de ejemplo]
- "12 jun 2023 – 28 feb 2025" [dato de ejemplo]

**Estructura**

- Flecha (`aria-label="Volver a la ficha"`, enlaza a `CatalogoFicha.dc.html`), título y subtítulo. Dos tarjetas: la vigente con `check_circle` e insignia "Vigente". No dibuja nutrientes por versión, sin aviso, sin rango con "→ hoy" (usa "vigente desde …").

### Qué cambió, anterior → nuevo (sólo lectura)

- Marca y navegación: "BaleadaFit Pro" + "Catálogo" → "Catálogo de alimentos" con conteo "151 alimentos activos"; "Abrir menú" y avatar siguen.
- Categorías: "Cereal/Tubérculo" → "Cereal y tubérculo".
- Filtros: los tiempos pasan de fila de chips a un control único; aparecen "FILTROS" con chips con `x` y "Limpiar" (antes sólo una insignia "Excluye: gluten" y "Quitar filtros").
- Resultados: "151 alimentos" / "Ver más (146 restantes)" → "38 resultados" / "Mostrando 20 de 38" / "Cargar 18 más"; kcal pasan de "310 kcal" a número con rótulo "KCAL".
- Sin resultados: se añade el conteo "0", el texto con el número de filtros y el bloque "Agregar".
- Detalle: "Desactivar del catálogo" → "Dar de baja" con texto y pantalla de confirmación propia; se añaden "Sin dato" para IG, la marca "Estimado" y el estado vacío de "Contiene"; el historial pasa a ícono + botón.
- Formulario: de una columna a cuatro bloques numerados, con aviso superior y ayudas de sodio e IG.
- Historial: de dos tarjetas con tabla a tarjetas con ocho nutrientes por versión, "→ hoy" y aviso.

## Contraste con el contrato

Contrastado contra `odd/designs/catalogo-context.md` (§2-§8) y `odd/tasks/catalogo.md` (S1-S9, lectura vinculante). Lo que sigue distingue lo que el export **dibuja** de lo que el contrato **permite**. Los puntos marcados **[DECISIÓN]** necesitan una persona.

### Desvíos ya decididos

- **`Cancelar` en la baja (S7, L5).** `AlimentoBaja.html` dibuja un botón "Cancelar" y una `close` de encabezado en color de tinta. La casa cierra los diálogos **sólo** con la cruz roja de la esquina (`cerrar-dialogo`): el botón "Cancelar" no se implementa. El board también la dibuja como pantalla completa, mientras que S7 la llama diálogo.
- **Conteo `151 alimentos activos` (S1, L4).** Aparece en C1 y C2 y el contrato no tiene endpoint de conteo: sale de `meta.total` de una búsqueda sin filtros. El mismo valor alimenta "de 151 alimentos coinciden…" en C2.
- **Paginación explícita (S4).** El contrato deja abierto «scroll infinito vs. paginado explícito» (§6); C1 dibuja "Cargar 18 más" y S4 lo adopta mientras `meta.hasMore`.
- **Alta = mismo formulario (S8).** El board dice "Mismo formulario para el alta"; S8 fija el título `Agregar alimento` para el alta. Ese texto no está en C4: sólo lo trae la propiedad `editando` del `Anterioraltaedicin.html`.
- **Vaciado de campos (S8, §5).** C4 no dibuja ninguna afordancia de «quitar» y lo dice; S8 lo fija: el campo vaciado reenvía el valor anterior.
- **Baja lógica (§5, S7).** Ninguna copia dice «borrar»: C3 y C3b dicen "No se borra". Coincide con `PATCH activo: false`.

### Lo que el export dibuja y el contrato no permite o no define

- **Detalle sin etiquetas.** C3 dibuja sólo el caso vacío de "Contiene" (que S6 sí prevé). El caso con etiquetas, cruzadas con el vocabulario de `GET /restricciones`, no está dibujado.
- **`Contiene (de las 6 restricciones)` y `[4 más de GET /restricciones]`** (C4). Es una anotación de diseño que cuenta de las seis restricciones (6 es el conteo de producción al 2026-11-01); dibuja sólo Lactosa y Gluten. No es copy.
- **"Estado: una sola versión"** (C5): es una nota de diseño que ilustra el estado de un alimento con una sola versión; S9 lo recoge como texto final. **[DECISIÓN]** Si va como estado real de la pantalla (cuándo se muestra) o sólo se calcula con `N == 1`. Además el texto dice "Un alimento recién agregado", mientras S9 lo cita con un error tipográfico, `Una alimento recién agregado`: **[DECISIÓN]** Cuál de los dos se usa verbatim.
- **Etiquetas de `excluir`.** "Sin lactosa" (chip) vs. `excluir=lactosa` del contrato: el export dibuja el texto en prosa con «Sin». **[DECISIÓN]** De dónde sale la etiqueta ("Sin " + vocabulario de `GET /restricciones` o una tabla propia).
- **Rótulo inconsistente.** El control de C1 dice "Sólo típicos HN" y el chip de C2 "Sólo típicos"; en S2 sólo existe `Sólo típicos HN`. **[DECISIÓN]** Cuál va en el chip de filtros activos.
- **"Tiempos de comida" en C3.** S6 pide «los cinco valores posibles»; C3 dibuja sólo Almuerzo y Cena (los del alimento). **[DECISIÓN]** Mostrar sólo los del alimento o los cinco con los no aplicables atenuados.
- **"Carbos" (C3) vs. "Carbohidrato" (C4, S6 usa `Carbos`).** Ya resuelto por S6; sólo se deja constancia.
- **"kcal" (minúscula, C3) vs. "KCAL" (C1, S3).** Rótulo distinto por pantalla; ambos coinciden con los specs (S6 no fija mayúsculas).
- **Menú `menu` y avatar "CH"** (C1, C2): navegación del shell que el contrato no regula y S1 no menciona. Corresponde a T6, no a este módulo. **[DECISIÓN]** Qué se hace con ese encabezado.
- **Borrar texto de búsqueda** (`close` en C2, `aria-label="Borrar texto de búsqueda"`): comportamiento de UI, no está en S1-S5.

### Lo que el contrato permite y el export no dibuja

- **Rol de nutricionista** (§8): la acción "Agregar alimento" aparece siempre; no hay variante sin permiso para quien no es nutricionista.
- **Estados de datos (§6):** carga (primera y "Cargar más"), error de red, alimento inactivo, sodio ausente. C1 no dibuja un estado de carga; el catálogo de 151 filas se pagina de a 20.
- **Errores de validación por campo** (400 con `detalles`): T4 pide «validación por campo»; C4 no dibuja ninguno.
- **Paginación del historial** (`GET /alimentos/{id}/versiones` es paginado): C5 dibuja dos tarjetas y ningún "cargar más".
- **Insignia "Típico" en el detalle:** `esTipicoHn` está en el contrato y en la lista (C1), no en C3.
- **Selección de categoría del formulario:** el contrato tiene `categoria` como enum de nueve; C4 los dibuja pero el copy no dice cuál está elegida.
- **Filtro de categoría activo en C1:** el copy no indica el chip elegido (no hay un chip en la sección "FILTROS" para la categoría en C1, y sí en C2 con "Lácteo").
- **Éxito de guardar y de dar de baja:** ningún board dibuja la respuesta (mensaje, vuelta al listado).
- **Alimento ya inactivo:** el contrato lo permite con `activo: false`; no se dibuja cómo reactivarlo y la baja misma lo advierte («no vas a encontrarlo… para reactivarlo»).
- **Lo que el contrato dice que no se puede dibujar (§9)** — ordenar, filtrar por kcal, compatibles con un paciente, duplicar, comparar —: ninguno de los once archivos lo dibuja. Coherente con el contrato.

### Resumen de decisiones humanas

1. Etiqueta de los chips de exclusión ("Sin lactosa"): de dónde sale (vocabulario de `GET /restricciones` o tabla propia).
2. "Sólo típicos HN" vs. "Sólo típicos": cuál va en el chip de filtros activos.
3. "Tiempos de comida" en el detalle: sólo los del alimento o los cinco del enum (S6).
4. "Estado: una sola versión" del historial: cuándo se muestra y qué frase va verbatim ("Un alimento…" del board o "Una alimento…" de S9).
5. Encabezado de C1/C2 (`menu`, avatar "CH"): qué entra en este módulo y qué es del shell (T6).
6. Rol: qué ve quien no es nutricionista (acción "Agregar alimento" y "Editar"/"Dar de baja").
7. Texto del botón principal del alta (el board sólo dibuja "Guardar cambios"; `Agregar alimento` viene del anterior) y título del alta.
8. Estados no dibujados: carga, error de red, error por campo, paginación del historial, confirmación de éxito.
9. Cuando haya etiquetas de `contiene`: cómo se dibujan en el detalle (el board sólo dibuja el caso vacío).

Ya decididos y por eso fuera de la lista: ausencia de "Cancelar" en la baja (L5), conteo de `meta.total` sin endpoint propio (L4), "Cargar más" explícito (S4), vaciado de campos que conserva (S8).
