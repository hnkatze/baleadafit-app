# Contexto del módulo Medicamentos (para diseñar)

Todo lo que el rol **nutricionista** puede hacer con la medicación de un paciente, según el contrato OpenAPI indexado (`baleadafit-api`, 49 endpoints, 90 schemas, indexado el 2026-11-16).

⚠️ **Estado de verificación:** este documento sale del contrato, **no de payloads capturados**. Los tres endpoints no se probaron todavía con un token real. Donde el spec no define algo lo digo explícitamente: no inventar campos.

Complementa `odd/designs/design-system.md` y `pacientes-context.md` (el medicamento es un bloque de la ficha del paciente; allí está el contexto clínico).

## 1. Mapa de endpoints

| Uso | Endpoint | Notas |
|---|---|---|
| Registrar | `POST /pacientes/{id}/medicamentos` | `nombre` obligatorio; `dosis` y `frecuencia` opcionales. Responde 201 |
| Editar o dar de baja | `PATCH /medicamentos/{id}` | Corrige datos o manda `activo: false`. Responde 200 |
| Dar de baja | `DELETE /medicamentos/{id}` | **Baja lógica** (`activo = false`), nunca borra. Responde 200 **con el medicamento**, no 204 |

Tres endpoints. **No hay un `GET` de medicamentos propio.** La medicación llega embebida en otras respuestas (§4): no se puede pedir "los medicamentos del paciente" sin traer el expediente o la ficha.

## 2. El medicamento (`MedicamentoEntity`)

```
id · pacienteId
nombre
dosis (string | null)        // ej. "500 mg"
frecuencia (string | null)   // ej. "Cada 12 horas con comida"
activo (bool)                // false = dado de baja; el historial se conserva
creadoEn (date-time)
```

Son **tres datos clínicos**, todos texto libre: no hay catálogo de fármacos, no hay unidad ni vía de administración, no hay fecha de inicio ni de fin, no hay indicación ni prescriptor. `dosis` y `frecuencia` son **cadenas**, no números: no se pueden sumar, ordenar por dosis ni validar contra rangos.

## 3. Las operaciones

### Registrar (`POST /pacientes/{id}/medicamentos`)

```json
{
  "nombre": "Metformina",                       // obligatorio, 2–120
  "dosis": "500 mg",                            // opcional, máx. 80
  "frecuencia": "Cada 12 horas con comida"      // opcional, máx. 120
}
```

- 201 con el medicamento completo (`activo: true`, `creadoEn` lleno).
- Errores: **400** `VALIDACION` con `detalles` por campo (nombre de 1 carácter, texto demasiado largo); **404** si el paciente no existe o no es de esta nutricionista; 401; 403.
- El contrato no define unicidad: registrar dos veces "Metformina" **no se rechaza** (no hay 409 declarado). La UI no puede prometer "ya existe".

### Editar (`PATCH /medicamentos/{id}`)

Body parcial con los mismos tres campos más `activo`:

```json
{ "nombre": "…", "dosis": "…", "frecuencia": "…", "activo": false }
```

- Responde 200 con el medicamento actualizado. Errores: 400, 404, 401, 403.
- `activo: false` "lo saca del expediente activo sin borrar el historial". `activo: true` no está explicado en este endpoint; el contrato del paciente (`PATCH /pacientes/{id}`) dice que su `activo` usa "el mismo criterio que la medicación" y que `true` reactiva. Es evidencia **indirecta**, no una regla escrita para medicamentos (gap 5).
- ⚠️ **Texto vacío.** `dosis` y `frecuencia` son `string | null` al **leer**, pero el body sólo admite `string`: no hay `null` declarado. **Hecho (tarjeta `no-esta-definido-como-limpiar-un-campo-de-texto`):** omitir un campo de texto al editar conserva el valor; no está definido cómo borrarlo. Para este PATCH: omitir `dosis` o `frecuencia` conserva el valor guardado; enviar `""` no está definido. No asumir que un campo vaciado en el formulario **borra** la dosis: la UI no debe mostrar una acción que prometa "quitar dosis" hasta que el BE defina cómo.
- No hay `PUT`: no hay forma de reemplazar el medicamento entero; todo se corrige campo por campo.
- Un PATCH con body `{}` no está definido (no dice si da 400 o no hace nada).

### Dar de baja (`DELETE /medicamentos/{id}`)

- **Baja lógica**: `activo` pasa a `false`; "nunca se borra, para conservar el historial clínico".
- Responde **200 con el medicamento** (`activo: false`), distinto de `DELETE /planes/{id}`, que responde 204 sin cuerpo. El cliente puede reemplazar la fila local con esa respuesta.
- Errores: 404, 401, 403. **No declara 400**: un medicamento ya dado de baja no tiene un error propio documentado; no dice si repetir el DELETE es idempotente.
- Habla de "dar de baja", no de "eliminar": igual que el paciente (`pacientes-context.md` §8).

## 4. Dónde se lee la medicación

Los endpoints de esta sección **no son de este módulo**, pero la UI depende de ellos:

| Respuesta | Campo | Qué trae |
|---|---|---|
| `GET /pacientes/{id}` | `medicamentos[]` | "Medicación vigente (`activo`), la más reciente primero" |
| `GET /pacientes/{id}/ficha` | `situacion.medicacion[]` | Lista de `MedicamentoEntity`. El contrato no dice si filtra por `activo` ni el orden |

Consecuencia: en el expediente **las bajas desaparecen de la vista**, y ningún endpoint devuelve los medicamentos inactivos, así que la UI no puede ofrecer "reactivar" después de recargar. Sólo se puede deshacer una baja en la misma sesión, mientras se conserve en memoria la respuesta del PATCH/DELETE.

Tras crear, editar o dar de baja hay que **refrescar el expediente o la ficha**: no hay evento ni lista propia que se actualice sola.

## 5. La lista

No hay lista de medicamentos propia ni paginación, filtros u orden: viven como arreglo dentro del expediente y de la ficha (§4). Ningún parámetro del módulo (`limit`, `offset`, `cursor`) aplica a estos tres endpoints.

## 6. Fechas

- El único dato temporal del medicamento es `creadoEn`, un instante ISO con zona: se formatea en la zona del dispositivo (`toLocal()`).
- **No hay** fecha de inicio, fin ni de baja: la baja no registra cuándo. No dibujar "desde marzo" ni "suspendido el 12 de octubre".
- Las fechas de calendario (por ejemplo `fechaNacimiento`, mediciones) vienen a medianoche UTC; mostrarlas en `America/Tegucigalpa` da el día anterior. No aplica a este módulo, pero sí a la ficha donde vive.

## 7. Estados de datos que hay que dibujar

| Estado | Cómo se ve |
|---|---|
| **Sin medicación** | Arreglo vacío en el expediente/ficha. No dibujar una sección fantasma; ofrecer "Registrar medicamento" |
| Medicamento activo | `activo: true`, con `dosis` y `frecuencia` posiblemente `null` |
| Sin dosis o sin frecuencia | `null`: mostrar el nombre solo, sin guiones ni "undefined" |
| Dado de baja | `activo: false`; fuera del expediente activo; sólo visible en la respuesta del DELETE/PATCH |
| Validación fallida | 400 con `detalles` por campo (nombre de menos de 2 caracteres, textos largos) |
| Paciente o medicamento ajeno | 404 ("no existe o no pertenece al usuario"): el contrato no distingue entre inexistente y ajeno |
| Medicamento repetido | Permitido: dos filas iguales no dan error |
| Editando con texto vacío | Comportamiento no definido: ver §3 |

## 8. Gaps del contrato (a resolver en el repo del API, no en el diseño)

**Estado en el board:** contrastado con el índice de 20 tarjetas de `baleadafit-api` (se conocen las claves y los títulos, no el cuerpo de cada tarjeta). Marcas: `ya pedido: <clave>` = hay tarjeta que lo pide al BE; `resuelto: <clave>` = había tarjeta y el contrato ya lo resuelve; `nuevo` = no hay tarjeta, hay que pedirlo. **Ninguna tarjeta es de este módulo: medicamentos no está pedido al BE todavía.** La única coincidencia es transversal (borrar campos de texto), y se marca como `ya pedido`; todo lo demás es `nuevo` y hay que abrir tarjeta.

| # | Gap | Board |
|---|---|---|
| 1 | No hay `GET` de medicamentos ni forma de traer los inactivos: las bajas son irrecuperables desde la UI | nuevo |
| 2 | `dosis`/`frecuencia` son `string \| null` al leer y sólo `string` al escribir: omitir conserva el valor (hecho de la tarjeta), pero no hay forma declarada de limpiarlos | ya pedido: no-esta-definido-como-limpiar-un-campo-de-texto |
| 3 | `GET /pacientes/{id}/ficha` no dice si `situacion.medicacion` trae sólo activos ni en qué orden (el detalle del paciente sí lo dice) | nuevo |
| 4 | Sin fecha de inicio, fin ni de baja; sin prescriptor, indicación, vía ni unidad estructurada | nuevo |
| 5 | `activo: true` en `PATCH /medicamentos/{id}` no está explicado (sólo por analogía con el paciente) | nuevo |
| 6 | Sin unicidad ni aviso de duplicados | nuevo |
| 7 | `DELETE` repetido o `PATCH {}` sin comportamiento definido | nuevo |
| 8 | Sin catálogo de fármacos ni interacciones: el nombre es libre | nuevo |
| 9 | El paciente no tiene endpoint para ver su medicación; `GET /auth/me` devuelve `perfil` como objeto sin esquema | nuevo |

## 9. Qué se puede dibujar sin inventar

- Una sección "Medicación" en la ficha con una fila por medicamento: nombre, dosis y frecuencia (cuando existen).
- Formulario de alta con nombre (obligatorio, 2–120), dosis (máx. 80) y frecuencia (máx. 120), con contadores y errores por campo.
- Edición de los tres campos con confirmación de que la corrección reemplaza el valor.
- Acción "Dar de baja" con confirmación, que explica que se conserva el historial.
- Estado vacío "Sin medicación registrada" con la acción de registrar.
- Refrescar la lista tras cada operación a partir de la respuesta del endpoint.

## 10. Lo que NO se puede dibujar todavía

- Medicación pasada ("medicamentos dados de baja") o reactivar uno: ningún endpoint devuelve los inactivos.
- Cronología ("tomó metformina de marzo a junio"): no hay fechas de inicio ni de fin.
- Alertas de interacción con alimentos o con otros fármacos, o autocompletado de nombres: no hay catálogo.
- Recordatorios de toma al paciente, o que el paciente vea o edite su medicación.
- Borrar un medicamento de forma definitiva: el contrato es baja lógica y lo dice explícitamente.
- Una acción "quitar dosis": mientras `""` no esté definido, no se puede prometer que limpia el valor.
