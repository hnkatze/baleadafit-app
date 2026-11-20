# Contexto del módulo Catálogo de alimentos (para diseñar)

El catálogo que la nutricionista consulta y edita, según el contrato OpenAPI indexado
(`baleadafit-api`, **49 endpoints, 90 schemas**, índice del 2026-11-16 consultado el
2026-11-19) y los conteos reales de producción.

⚠️ **Estado de verificación:** sale del contrato indexado, **no de payloads capturados**: los
endpoints del catálogo no se probaron todavía con un token real. Donde el spec no define algo lo
digo explícitamente; no inventar campos.

Complementa `odd/designs/design-system.md` y `pacientes-context.md`. El lenguaje visual base ya
existe: `odd/designs/mobile/06-catalogo-alimentos.html` es el artboard original de Stitch. Estos
boards nuevos lo extienden, no lo reinventan.

## 1. Mapa de endpoints

Siete endpoints bajo el tag `catálogo`:

| Uso | Endpoint | Notas |
|---|---|---|
| Buscar | `GET /alimentos` | Paginada, cinco filtros |
| Agregar | `POST /alimentos` | Sólo nutricionistas. Valores **por porción** |
| Detalle | `GET /alimentos/{id}` | Trae la composición **completa**, micros incluidos |
| Editar | `PATCH /alimentos/{id}` | `activo: false` lo saca del catálogo sin borrarlo |
| Historial | `GET /alimentos/{id}/versiones` | Qué valores tuvo y desde/hasta cuándo |
| Restricciones | `GET /restricciones` | Catálogo de etiquetas que un paciente no puede comer |
| Condiciones | `GET /condiciones` | Catálogo clínico (para la ficha, no para el catálogo) |

Conteos reales de producción al 2026-11-01: **151 alimentos, 153 versiones, 6 restricciones,
20 condiciones**. Hay datos de sobra para buscar y paginar, pero el catálogo **no crece solo**:
nadie más escribe acá.

## 2. El alimento (`AlimentoEntity`, 21 campos)

Lo que devuelven la lista, el detalle, el `POST` y el `PATCH`:

```
id · nombre · categoria · porcionDescripcion · porcionGramos
kcal · proteinaG · carbohidratoG · grasaG · fibraG              // por porción
sodioMg · potasioMg · fosforoMg · azucaresG · grasasSatG · indiceGlucemico
esTipicoHn (bool) · tiposComida [] · contiene [] (etiquetas) · fuente · activo
```

`categoria` es un enum de nueve: `PLATO_TIPICO`, `PROTEINA`, `CEREAL_TUBERCULO`, `LEGUMINOSA`,
`LACTEO`, `FRUTA`, `VERDURA`, `GRASA`, `BEBIDA`.

`tiposComida` es un enum de cinco: `DESAYUNO`, `MERIENDA_AM`, `ALMUERZO`, `MERIENDA_PM`, `CENA`.

`contiene` son etiquetas que coinciden con los códigos de restricción: es lo que permite decir
"este alimento tiene lactosa" sin adivinar. Se cruzan con `GET /restricciones`.

`fuente` es texto libre (INCAP, USDA, etiqueta del producto…).

## 3. Lo que cambió contra el índice anterior

La versión previa de este documento decía que los micronutrientes sólo existían en la *versión*,
lo que obligaba a una segunda llamada. **Ya no es así:** `GET /alimentos/{id}` devuelve los 21
campos, micros incluidos.

| Campo | Detalle del alimento | Versión (`AlimentoVersionEntity`, 19 campos) |
|---|---|---|
| kcal, proteína, carbohidrato, grasa, fibra | ✅ | ✅ |
| sodio, potasio, fósforo, azúcares, grasas saturadas, índice glucémico | ✅ | ✅ |
| `tabla`, `version`, `vigenteDesde`, `vigenteHasta` | ❌ | ✅ |

Consecuencia de diseño: **la ficha de un alimento se dibuja con una sola llamada**. `/versiones`
es sólo para el historial, no para completar nutrientes.

Dos detalles que sí sobreviven:

- `sodioMg` viene documentado como **estimado** ("verificar con INCAP"): si se dibuja, marcarlo
  como aproximado y no con la misma autoridad que `kcal`.
- `indiceGlucemico` es nulo en alimentos sin carbohidratos: el diseño necesita un estado "sin
  dato", no un `0`.

## 4. Buscar (`GET /alimentos`)

| Query | Valores |
|---|---|
| `q` | texto libre |
| `categoria` | uno de los nueve valores |
| `tipoComida` | uno de los cinco |
| `soloTipicos` | booleano: sólo platos y alimentos típicos hondureños |
| `excluir` | etiquetas separadas por coma: `excluir=lactosa,gluten` quita los alimentos que las contienen |
| `limit` / `offset` / `cursor` | paginación estándar (20 por defecto, máximo 100) |

Lo que **no** hay: filtro por rango de kcal o de macros, ni parámetro de orden. El orden lo
decide el servidor. `meta` trae `total` y `hasMore`, así que el estado "sin resultados" puede
distinguir "no hay nada con estos filtros" de "todavía no cargó".

`excluir` es la bisagra con el módulo de pacientes: sirve para armar el plan de alguien con
restricciones sin ir quitando alimentos a mano.

## 5. Editar y versionar

- `POST /alimentos` y `PATCH /alimentos/{id}` aceptan **todos** los nutrientes, micros incluidos.
- `PATCH` es parcial por naturaleza, pero **no está definido cómo limpiar un campo**: omitirlo
  conserva el valor. La UI no debe ofrecer "borrar el sodio".
- `PATCH` con `activo: false` lo saca del catálogo **sin borrarlo**. Ninguna copia debe decir
  "borrar".
- `GET /alimentos/{id}/versiones` da el historial: `tabla`, `version` (consecutivo),
  `vigenteDesde`, `vigenteHasta` (`null` en la vigente), de la más nueva a la más vieja, paginada.
- Un `PATCH` que cambia nutrientes crea una versión nueva: el historial es la prueba de qué se
  comía antes, y por eso merece su propia pantalla.

## 6. Estados de datos que hay que dibujar

| Estado | Cómo se ve |
|---|---|
| Catálogo con datos | 151 alimentos: es el caso normal |
| Búsqueda sin resultados | El caso frecuente al combinar categoría + texto + excluir |
| Filtros aplicados | Varios a la vez; hay que poder ver cuáles y quitarlos |
| Alimento sin índice glucémico | `null`, no cero |
| Sodio estimado | Valor presente con la marca de aproximado |
| Alimento inactivo | Existe con `activo: false`; no aparece en el catálogo |
| Historial de una sola versión | Un alimento recién creado tiene una versión, `vigenteHasta: null` |
| Carga lenta | 151 filas de a 20: hay que decidir scroll infinito vs. paginado explícito |

## 7. Gaps del contrato

**Resuelto:** el alimento no devolvía los micronutrientes que sí aceptaba al escribir. Hoy el
detalle los trae (tarjeta `alimento-no-devuelve-micronutrientes` en `baleadafit-api/catalogo`).

| # | Gap | Board |
|---|---|---|
| 1 | No hay filtro por nutriente (kcal máximo, proteína mínima), justo lo que se quiere al armar un plan | nuevo |
| 2 | No hay parámetro de orden (por nombre, por kcal) | nuevo |
| 3 | No hay endpoint de **duplicar** un alimento, el atajo natural cuando se parece a otro | nuevo |
| 4 | No hay una llamada "alimentos compatibles con este paciente": se compone con `excluir` + los códigos de `GET /restricciones` | nuevo |
| 5 | `sodioMg` es estimado y el contrato no dice con qué criterio | nuevo |

## 8. Artboards a diseñar

Cinco boards, en este orden. Mismo lenguaje que `mobile/06-catalogo-alimentos.html` y el resto
del set móvil (390 px de ancho, barra inferior fija para la acción primaria).

**C1 · Catálogo · búsqueda.** Barra de búsqueda arriba, chips de categoría horizontales, y una
fila de filtros secundarios: tiempo de comida, "sólo típicos hondureños", exclusiones. Filas con
nombre, porción (`porcionDescripcion` + `porcionGramos`), kcal destacada y los macros en una
línea secundaria. Rol de nutricionista: acción primaria `Agregar alimento`.

**C2 · Catálogo · sin resultados.** Qué filtros estaban puestos, cuántos resultados dieron cero
(`meta.total`), y una salida clara: `Limpiar filtros`. No es un error, es una búsqueda vacía.

**C3 · Detalle de un alimento.** Una sola pantalla con la composición completa: cabecera con
nombre, porción y categoría; kcal grande; macros; y una sección de micronutrientes donde el
**sodio se lee como estimado** y el índice glucémico ausente se dice, no se dibuja como 0. Abajo:
etiquetas de `contiene` (cruzadas con `GET /restricciones`, en su vocabulario), tiempos de comida
y `fuente`. Acciones: `Editar`, `Ver historial`, `Dar de baja` (baja lógica, con confirmación).

**C4 · Alta / edición de alimento.** Los 21 campos agrupados en cuatro bloques, no en una lista
plana: (1) identidad — nombre, categoría, típico HN, fuente; (2) porción — descripción y gramos;
(3) composición — macros y micros por porción, con la marca de estimado en sodio; (4) uso —
tiempos de comida y etiquetas de `contiene`. El formulario de alta y el de edición son el mismo
board: en edición, los campos vaciados **no** se pueden limpiar (omitir conserva), así que no hay
afordancia de "quitar".

**C5 · Historial de versiones.** Lista de versiones con `version`, `tabla`, `vigenteDesde` →
`vigenteHasta` (`null` = "hoy" en la vigente), y el resumen de nutrientes de cada una. Es una
pantalla de lectura: la compara el ojo, no hay diff calculado por el servidor.

## 9. Lo que NO se puede dibujar todavía

- Ordenar por calorías o proteína: no hay parámetro de orden.
- Filtrar por "menos de X kcal": no existe el filtro.
- "Alimentos compatibles con este paciente" en una sola vista: hay que cruzar restricciones y
  llamar dos endpoints.
- Duplicar un alimento de un toque: no existe en el API (habría que precargar el formulario).
- Comparar dos alimentos lado a lado más allá de macros: requiere dos llamadas al detalle.
- Limpiar un nutriente ya cargado desde el formulario: el contrato no define el vaciado.

## 10. Controles y su fuente de datos

Cada control de la UI tiene que llenarse desde el contrato, no desde el copy del artboard. Lo que
sigue fija de dónde sale cada uno; si un control no figura acá, no se dibuja.

| Control | Fuente | Notas |
|---|---|---|
| Chips de categoría | enum `CategoriaAlimento` (9 valores) | Los **textos** son copy de la app; el **valor** es el enum |
| Tiempo de comida | enum `TipoComida` (5 valores) | Igual: etiqueta propia, valor del enum |
| `Sólo típicos HN` | query `soloTipicos` (boolean) | No hay endpoint: es un parámetro de la búsqueda |
| `Excluir · N` y `Contiene` del detalle | `GET /restricciones` → `RestriccionEntity{id, codigo, nombre, descripcion}` | Se dibuja `nombre`; se manda `codigo` en `excluir` y se compara con `alimento.contiene`. **Nunca hardcodear las 6 etiquetas** |
| Conteo del encabezado (`151 activos`) | `meta.total` de una búsqueda sin filtros con `limit=1` | No hay endpoint de conteo: es el workaround documentado |
| Conteo de resultados (`38 resultados`) | `meta.total` de la búsqueda ya filtrada | Sólo en modo offset |
| `Cargar N más` | `meta.hasMore` y `meta.nextCursor` o `limit`/`offset` | El modo cursor es el de mobile |
| Filas de la lista | `nombre`, `categoria`, `porcionDescripcion`, `porcionGramos`, `kcal`, macros, `esTipicoHn` | Todo viene en `AlimentoEntity`: la fila no necesita el detalle |
| Detalle | `GET /alimentos/{id}` (21 campos) | Una sola llamada, micros incluidos |
| Historial | `GET /alimentos/{id}/versiones` | `version`, `tabla`, `vigenteDesde`, `vigenteHasta` (nulo = vigente) |
| Formulario | `CategoriaAlimento`, `TipoComida`, `GET /restricciones` + los 21 campos | El alta y la edición comparten los mismos catálogos |
| Avatar e iniciales del shell | `perfil.nombre` de `GET /auth/me` | `perfil` es un `object` **sin esquema** (gap de auth): el cliente lo tipa a mano |

## 11. Pedido al BE

Cuatro tarjetas publicadas en el board (`baleadafit-api/catalogo`), porque ningún filtro del cliente
las resuelve:

| Tarjeta | Qué falta | Qué desbloquea en el diseño |
|---|---|---|
| `alimentos-sin-filtro-de-activo` | query `activo` en `GET /alimentos` | Listar y reactivar alimentos dados de baja: hoy la baja es irreversible desde la app |
| `alimentos-sin-parametro-de-orden` | `orderBy` (al menos nombre y kcal) | Cualquier control de ordenamiento, hoy imposible sin romper la paginación |
| `alimentos-sin-filtro-por-nutrientes` | rangos numéricos (kcal máx., proteína mín.) | Buscar "lo que entra en X kcal", el filtro que se usa al armar un plan |
| `alimentos-sin-conteo-de-activos` | conteo de activos o `total` global | El `151 alimentos activos` del encabezado, sin una llamada extra |

Mientras esas tarjetas sigan abiertas, la UI **no** dibuja ordenamiento, ni filtros por nutriente, ni
afordancia de reactivación, y el conteo del encabezado se lee del workaround documentado.
