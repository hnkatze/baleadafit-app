# Contexto del módulo Catálogo de alimentos (para diseñar)

El catálogo que la nutricionista consulta y edita, según el contrato OpenAPI indexado
(`baleadafit-api`, 45 endpoints, 84 schemas, reindexado el 2026-11-07) y los conteos reales
de producción.

⚠️ **Estado de verificación:** sale del contrato y de los conteos de la base, **no de payloads
capturados** en esta sesión. Donde el spec no define el esquema lo digo explícitamente.

Complementa `odd/designs/design-system.md` y `pacientes-context.md`.

## 1. Mapa de endpoints

| Uso | Endpoint | Notas |
|---|---|---|
| Buscar | `GET /alimentos` | Paginada, con cinco filtros |
| Agregar | `POST /alimentos` | Sólo nutricionistas. Valores **por porción** |
| Detalle | `GET /alimentos/{id}` | Devuelve sólo macros (ver §3) |
| Editar | `PATCH /alimentos/{id}` | `activo: false` lo saca del catálogo sin borrarlo |
| Historial | `GET /alimentos/{id}/versiones` | Qué valores tuvo y desde/hasta cuándo |

Conteos reales de producción al 2026-11-01: **151 alimentos, 153 versiones, 6 restricciones,
20 condiciones**. O sea: hay datos de sobra para buscar y paginar, pero el catálogo **no crece
solo** — nadie más escribe acá.

## 2. El alimento (`AlimentoEntity`)

Lo que devuelven la lista, el detalle y el POST:

```
id · nombre · categoria · porcionDescripcion · porcionGramos
kcal · proteinaG · carbohidratoG · grasaG · fibraG        // por porción
esTipicoHn (bool) · tiposComida [] · contiene [] (etiquetas) · fuente · activo
```

`categoria` es un enum de nueve: `PLATO_TIPICO`, `PROTEINA`, `CEREAL_TUBERCULO`, `LEGUMINOSA`,
`LACTEO`, `FRUTA`, `VERDURA`, `GRASA`, `BEBIDA`.

`tiposComida` es un enum de cinco: `DESAYUNO`, `MERIENDA_AM`, `ALMUERZO`, `MERIENDA_PM`, `CENA`.

`contiene` son etiquetas que coinciden con los códigos de restricción: es lo que permite decir
"este alimento tiene lactosa" sin adivinar.

`fuente` es texto libre (INCAP, USDA, etiqueta del producto…).

## 3. El detalle que hay que saber antes de dibujar

**Los micronutrientes no vienen en el alimento.** `GET /alimentos/{id}` devuelve sólo macro
(kcal, proteína, carbohidrato, grasa, fibra). Sodio, potasio, fósforo, azúcares, grasas
saturadas e índice glucémico **sólo existen en la versión**, que se lee aparte con
`GET /alimentos/{id}/versiones`.

| Campo | Alimento | Versión |
|---|---|---|
| kcal, proteína, carbohidrato, grasa, fibra | ✅ | ✅ |
| sodio, potasio, fósforo, azúcares, grasas saturadas, índice glucémico | ❌ | ✅ |
| `tabla`, `version`, `vigenteDesde`, `vigenteHasta` | ❌ | ✅ |

Consecuencia de diseño: una ficha de alimento que muestre sodio o potasio necesita **una
segunda llamada**, o hay que limitar la vista del catálogo a macros y dejar el detalle
nutricional completo para una pantalla propia.

`tabla` es un **string con el nombre de la revisión** de la composición, no un objeto: los
nutrientes son hermanos de `version`, no hijos de `tabla`.

## 4. Buscar (`GET /alimentos`)

| Query | Valores |
|---|---|
| `q` | texto libre |
| `categoria` | uno de los nueve valores |
| `tipoComida` | uno de los cinco |
| `soloTipicos` | booleano: sólo platos y alimentos típicos hondureños |
| `excluir` | etiquetas separadas por coma: `excluir=lactosa,gluten` quita los alimentos que las contienen |
| `limit` / `offset` / `cursor` | paginación estándar (20 por defecto, máximo 100) |

Lo que **no** hay: filtro por rango de kcal o de macros, filtro por `esTipicoHn` combinable,
ni parámetro de orden. El orden lo decide el servidor.

`excluir` es la bisagra con el módulo de pacientes: sirve para armar el plan de alguien con
restricciones sin ir quitando alimentos a mano.

## 5. Editar y versionar

- `POST /alimentos` y `PATCH /alimentos/{id}` aceptan **todos** los nutrientes, incluidos los
  micronutrientes que la lectura no devuelve.
- `PATCH` con `activo: false` lo saca del catálogo **sin borrarlo**. Ninguna copia debe decir
  "borrar".
- `GET /alimentos/{id}/versiones` da el historial: `tabla`, `version` (consecutivo),
  `vigenteDesde`, `vigenteHasta` (`null` en la vigente). El `id` de la versión **es también el
  cursor** de esa lista paginada.
- `sodioMg` viene documentado como **estimado** ("verificar con INCAP"): si se muestra, conviene
  marcarlo como aproximado en vez de presentarlo con la misma autoridad que `kcal`.

## 6. Estados de datos que hay que dibujar

| Estado | Cómo se ve |
|---|---|
| Catálogo con datos | 151 alimentos: es el caso normal |
| Búsqueda sin resultados | El caso frecuente al filtrar por categoría + texto + excluir |
| Alimento sin micronutrientes | `GET /alimentos/{id}` nunca los trae: hay que decidir si se piden aparte |
| Alimento inactivo | Existe en la base con `activo: false`; no aparece en el catálogo |
| Sin historial | Un alimento recién creado tiene una sola versión, con `vigenteHasta: null` |
| Carga lenta | 151 filas con paginación de 20: hay que decidir entre scroll infinito y paginado |

## 7. Gaps del contrato

El gap 1 y el 3 ya están pedidos al BE en el board: card `alimento-no-devuelve-micronutrientes`
en `baleadafit-api/catalogo`.

1. El alimento no devuelve los micronutrientes que sí acepta al escribir: asimetría real entre
   `POST`/`PATCH` y `GET`.
2. No hay filtro por nutriente (kcal máximo, proteína mínima), que es justo lo que una
   nutricionista querría al armar un plan.
3. No hay parámetro de orden (por nombre, por kcal).
4. No hay endpoint de **duplicar** un alimento, que es el atajo natural cuando se parece a otro.
5. No hay búsqueda de alimentos por restricción de un paciente en una sola llamada: se compone
   con `excluir` y los códigos de `GET /restricciones`.

## 8. Qué se puede dibujar sin inventar

- Buscador con las tres capas reales: texto, categoría y tiempo de comida, más el interruptor
  de "sólo típicos hondureños" y el de excluir restricciones.
- Filas con nombre, porción, kcal y los macros, que es todo lo que trae la lista.
- Una ficha de alimento con la composición completa cuando se pide también la versión vigente.
- El formulario de alta y edición con los 18 campos del contrato, incluidos los micronutrientes.
- El historial de versiones con "vigente desde / hasta".
- El estado de búsqueda sin resultados.

## 9. Lo que NO se puede dibujar todavía

- Ordenar por calorías o proteína: no hay parámetro de orden.
- "Alimentos compatibles con este paciente" en una sola vista: hay que cruzarlo con las
  restricciones y llamar dos endpoints.
- Duplicar un alimento de un toque: no existe en el API (habría que precargar el formulario).
- Comparar dos alimentos lado a lado con micronutrientes sin dos llamadas extra a `/versiones`.
