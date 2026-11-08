# Contexto del módulo "Mis pacientes" (para diseñar)

Todo lo que la nutricionista puede ver y hacer con sus pacientes, con **payloads reales** capturados contra `https://api-pro.baleadafit.com` usando su propia cuenta (`playercamiloh504@gmail.com`). A diferencia del documento del paciente, acá no hay nada deducido: los endpoints responden y los datos están abajo.

Complementa `odd/designs/design-system.md` y `odd/designs/home-context.md`.

## 1. Mapa de endpoints

| Uso | Endpoint | Verificado |
|---|---|---|
| Listar | `GET /pacientes?limit&offset&cursor` | ✅ 2 pacientes |
| Crear | `POST /pacientes` | contrato (23 campos) |
| Expediente | `GET /pacientes/{id}` | ✅ |
| Ficha completa | `GET /pacientes/{id}/ficha` | ✅ 11 bloques |
| Editar | `PATCH /pacientes/{id}` | contrato |
| Dar de baja | `DELETE /pacientes/{id}` | contrato |
| Adherencia | `GET /pacientes/{id}/adherencia?desde&hasta` | ✅ |
| Mediciones | `GET`/`POST /pacientes/{id}/mediciones` | ✅ |
| Borrar medición | `DELETE /mediciones/{id}` | contrato |
| Requerimiento calórico | `GET /pacientes/{id}/requerimiento` | ✅ |
| Planes del paciente | `GET /pacientes/{id}/planes` | ✅ vacío |
| Generar plan | `POST /pacientes/{id}/planes/generar` | contrato |
| Diario de comidas | `GET /pacientes/{id}/registros?desde&hasta` | contrato (nuevo) |
| Marcar comida | `PUT /pacientes/{id}/registros` | contrato (nuevo) |
| Medicamentos | `POST /pacientes/{id}/medicamentos`, `PATCH`/`DELETE /medicamentos/{id}` | contrato |
| Catálogos | `GET /condiciones` (20), `GET /restricciones` (6) | ✅ |

Las listas responden `{ok, data: [], meta: {limit, offset, total, nextCursor, hasMore}}`.

## 2. La lista (`GET /pacientes`)

Cada fila ya trae lo necesario para una tabla sin llamadas extra:

```
id · nombre · apellido · correo · telefono · sexo (M|F) · fechaNacimiento
nivelActividad · meta (BAJAR|MANTENER|SUBIR) · pesoObjetivoKg · fechaObjetivo
estadoFisiologico (NINGUNO|EMBARAZO|LACTANCIA) · motivoConsulta · notas
alergias · cirugias · suplementos · activo (bool)
ultimaMedicion { fecha, pesoKg, tallaCm, pctGrasa, … } · planActivo (objeto|null)
```

Datos reales: `Paciente De Prueba` (M, 31 años, 72.4 kg, 19.5% grasa, meta BAJAR) y `María Isabel Hernández Paz` (78.5 kg, 32.4% grasa). Ambas tenían plan activo `null`; luego se les generó y activó uno (ver §9).

⚠️ `planActivo` en la **lista** viene recortado: `{id, nombre}` y nada más. Para estado, kcal o macro hay que ir a la ficha o a `GET /pacientes/{id}/planes`. La tabla no puede mostrar "ACTIVO · 1500 kcal" desde esta respuesta.

**Columnas defendibles para la tabla**: paciente, edad, peso, % grasa, meta, plan (con plan / sin plan), próxima cita. Todo eso ya viene o está a un `ficha` de distancia.

## 3. La ficha (`GET /pacientes/{id}/ficha`) — la pantalla central

Devuelve 11 bloques ya calculados. **No hay que calcular nada en el cliente**:

| Bloque | Contenido real |
|---|---|
| `paciente` | el registro completo |
| `cabecera` | `edad: 31`, `imc: 23.9`, `clasificacionImc: NORMAL`, `pctGrasa: 19.5`, `masaMagraKg: 58.3`, `masaGrasaKg`, `grasaVisceral`, `composicionFecha` |
| `progreso` | `pesoInicial: 72.4`, `pesoActual: 72.4`, `deltaKg: 0`, `ritmoKgSemana`, `proyeccionKg` |
| `situacion` | `condiciones[]`, `restricciones[]`, `medicacion[]`, `estadoFisiologico`, `alergias`, `cirugias`, `suplementos`, `motivoConsulta` |
| `habitos` | `comidasAlDia`, `aguaLitros`, `horasSueno`, `alcohol`, `tabaco`, `quienCocina`, `presupuesto` |
| `requerimiento` | `medicion`, `edad`, `tmb: 1662`, `factorActividad: 1.2`, `gastoTotal: 1994`, `ajusteMeta: -500`, `kcalObjetivo: 1500`, `proteinaG: 93.8`, `carbohidratoG: 187.5`, `grasaG: 41.7` |
| `adherencia30d` | `desde`, `hasta`, `porcentaje` (null), `cumplidos: 0`, `total: 0` |
| `alertas` | `[{tipo: "SIN_PLAN_ACTIVO", severidad: "alta", detalle: "El paciente no tiene un plan activo."}]` |
| `evolucion` | lista de mediciones |
| `consultas` | `{proximas: [CitaEntity…]}` |
| `planes` | lista (vacía hoy) |

Diseño: la ficha es **una sola llamada** para toda la pantalla. El mock puede ser ambicioso: cabecera con IMC + clasificación, progreso (delta y proyección), alertas, adherencia de 30 días, evolución de peso y próximas consultas.

`progreso` incluye `ritmoKgSemana` y `proyeccionKg`: alcanza para una línea de tendencia, aunque con una sola medición vienen `null`.

## 4. Formularios

### Alta y edición de paciente (`POST` / `PATCH /pacientes`) — 23 campos

| Campo | Tipo | Nota para el diseño |
|---|---|---|
| `nombre`, `apellido` | texto | requeridos |
| `correo` | email | **con este correo el paciente se vincula al iniciar sesión** |
| `telefono` | texto | opcional |
| `sexo` | `M` \| `F` | selector de 2 |
| `fechaNacimiento` | fecha | determina la edad de la ficha |
| `nivelActividad` | `SEDENTARIO` \| `LIGERO` \| `MODERADO` \| `INTENSO` \| `MUY_INTENSO` | factor 1.2 / 1.375 / 1.55 / 1.725 / 1.9 |
| `meta` | `BAJAR` \| `MANTENER` \| `SUBIR` | ajuste −500 / 0 / +300 kcal |
| `pesoObjetivoKg`, `fechaObjetivo` | número, fecha | objetivo pactado |
| `estadoFisiologico` | `NINGUNO` \| `EMBARAZO` \| `LACTANCIA` | **cambia el requerimiento** |
| `condiciones` | array de **códigos** del catálogo | 20 opciones |
| `restricciones` | array de **códigos** del catálogo | 6 opciones |
| `alergias`, `cirugias`, `suplementos`, `motivoConsulta`, `notas`, `presupuesto`, `quienCocina`, `alcohol`, `tabaco` | texto libre | hábitos y contexto social |
| `comidasAlDia`, `aguaLitros`, `horasSueno` | número | hábitos |

Diseño: son **23 campos**, no un formulario plano. Agrupación natural que ya existe en la API: identidad (5) · antropometría y objetivo (4) · clínica (condiciones, restricciones, estado fisiológico, alergias, cirugías, suplementos) · hábitos (7) · notas.

### Nueva medición (`POST /pacientes/{id}/mediciones`) — 21 campos + fuente

Antropometría: `pesoKg`, `tallaCm`, `pctGrasa`, `cinturaCm`, `masaMuscularKg`, `masaGrasaKg`, `grasaVisceral` (1–20), agua intra/extracelular, `anguloFase`.
Pliegues: tricipital, subescapular, suprailiaco, bicipital (mm).
Perímetros: brazo, cadera, muslo (cm). Tensión: sistólica/diastólica.
`fecha` (por defecto hoy), `notas` y **`fuente`: `MANUAL` \| `BASCULA` \| `INBODY` \| `OMRON` \| `OTRO`**.

Diseño: no todos los campos se llenan siempre (en la data real solo hay peso, talla y % grasa; el resto viene `null`). Conviene un formulario por secciones colapsables, con los vacíos visibles pero no obligatorios. `fuente` decide si el dato se presenta como medido o estimado.

### Medicamento — 3 campos

`nombre`, `dosis`, `frecuencia`. Sin campo de fechas: `PATCH`/`DELETE` por id.

## 5. Tablas y listas

| Lista | Columnas posibles |
|---|---|
| Pacientes | nombre, edad, peso, % grasa, meta, plan, próxima cita |
| Mediciones | fecha, peso, talla, **IMC (lo agrega el endpoint)**, % grasa, masa muscular, masa grasa, cintura, grasa visceral, fuente |
| Requerimiento | TMB, factor de actividad, gasto total, ajuste por meta, kcal objetivo, P/C/G en gramos |
| Evolución | fecha + las mismas métricas de medición, para graficar |
| Condiciones | código + nombre + descripción (20 filas) |
| Restricciones | código + nombre (6 filas) |

## 6. Enums y códigos que la UI debe traducir

| Enum | Valores | Etiqueta sugerida |
|---|---|---|
| `sexo` | `M`, `F` | Masculino / Femenino |
| `nivelActividad` | 5 valores | Sedentario … Muy intenso (con su factor) |
| `meta` | `BAJAR`, `MANTENER`, `SUBIR` | Bajar / Mantener / Subir (−500/0/+300) |
| `estadoFisiologico` | `NINGUNO`, `EMBARAZO`, `LACTANCIA` | Ninguno / Embarazo / Lactancia |
| `clasificacionImc` | `NORMAL` (observado) | IMC normal; los otros valores no se vieron |
| `severidad` de alerta | `alta` (observado) | Alta |
| `tipo` de alerta | `SIN_PLAN_ACTIVO` (observado) | Sin plan activo |
| `fuente` de medición | `MANUAL`, `BASCULA`, `INBODY`, `OMRON`, `OTRO` | — |

## 7. Estados que el diseño debe resolver

| Caso | Realidad |
|---|---|
| Sin pacientes | lista vacía, `total: 0` |
| Paciente sin mediciones | `ultimaMedicion: null` → sin IMC ni peso |
| Paciente sin plan | `planActivo: null` + alerta `SIN_PLAN_ACTIVO` de severidad alta |
| Sin adherencia | `porcentaje: null` cuando `total: 0` (no es 0%, es "sin datos") |
| Una sola medición | `ritmoKgSemana` y `proyeccionKg` en `null`: no hay tendencia |
| Paciente inactivo | `activo: false` (la baja es lógica) |
| Ficha sin condiciones ni restricciones | arrays vacíos; no dibujar secciones fantasma |

## 8. Gaps y preguntas abiertas

1. **Tipos de alerta**: solo se observó `SIN_PLAN_ACTIVO`; `severidad` solo aparece como `alta`. El cliente debe tolerar tipos nuevos sin romper.
2. **`clasificacionImc`**: solo se vio `NORMAL`. Falta el catálogo completo (bajo peso, sobrepeso, obesidad…).
3. **Catálogos chicos**: 20 condiciones y 6 restricciones. Un buscador en el formulario es defendible; un acordeón con 20 chips, también.
4. **`DELETE /pacientes/{id}`**: es baja lógica (`activo: false`). La UI debe hablar de "dar de baja", no de borrar.
5. **`POST /planes/generar`** existe, pero el recomendador no está en la app todavía: la ficha muestra planes en solo lectura.
6. **Sin foto ni adjuntos**: no hay campo de imagen; el avatar de iniciales es la única identidad visual.
7. El vínculo paciente↔app depende de que el paciente inicie sesión con el correo cargado (`firebaseUid` pasa de `null` a un valor). Hoy los dos pacientes de prueba **no** han entrado nunca.

## 9. Prueba end-to-end hecha con datos reales

Se ejecutó el camino completo del módulo contra la API real:

1. `POST /pacientes/{id}/planes/generar` → `201`, plan en `BORRADOR` **con los tiempos y alimentos ya armados** (`tiempos[].items[]`), `origen: "REGLAS"` y `justificacion: "Generado por reglas (IA no disponible: IA deshabilitada o BEDROCK_MODEL_ID sin configurar.)"`.
2. `POST /planes/{id}/activar` → `201`, `estado: "ACTIVO"` + `aprobadoEn`.
3. Resultado en `GET /pacientes`: ambos con `planActivo`; en la app el pill pasó de "Sin plan" a "Con plan".
4. En `GET /pacientes/{id}/ficha`: `alertas` pasó de `[{SIN_PLAN_ACTIVO, alta}]` a `[]`, y `planes: [Plan 2026-11-07 · ACTIVO]`.
5. `adherencia30d` sigue en `{porcentaje: null, cumplidos: 0, total: 0}`: el plan no genera registros por sí solo. Desde §10 la nutricionista ya puede marcarlos, así que ese número pasará a moverse.

Conclusión de diseño: **el plan nace completo pero comido**, es decir, tener plan no implica tener adherencia. `porcentaje: null` con plan activo es un estado real y frecuente, no un error.

### El plan generado hoy no es IA

`origen: "REGLAS"` con esa justificación textual. Cualquier pantalla que prometa "plan generado por IA" hoy estaría mintiendo: el recomendador con Bedrock está deshabilitado en este entorno.

## 10. Las comidas: el contrato que faltaba ya existe

Hasta ayer `PUT /me/registros` era el **único** write de registros de comida y es exclusivo del rol `paciente`; con los dos pacientes de prueba en `firebaseUid: null` (nunca entraron), la nutricionista no podía registrar nada por ellos. El API agregó el camino del nutricionista, dos endpoints nuevos bajo el tag `pacientes`:

### `GET /pacientes/{id}/registros` — diario de comidas del paciente

Misma forma de lista que el resto: `{ok, data: [], meta: {limit, offset, total, hasMore, nextCursor}}`, así que es un `getPaged` en el cliente.

| Query | Valor |
|---|---|
| `desde`, `hasta` | `YYYY-MM-DD`; por defecto, los últimos 7 días |
| `limit` | 20 por defecto, máximo 100 |
| `offset` o `cursor` | offset base 0, o el `nextCursor` de la página previa |

Cada fila:

```
id · pacienteId · tiempoComidaId · fecha · cumplido (bool) · comentario
creadoEn · autor (PACIENTE | NUTRICIONISTA)
```

Viene del más reciente al más antiguo. `autor` es **quién escribió la fila por última vez**, no una auditoría: no hay historial de cambios, y si el paciente vuelve a marcar la misma comida el autor pasa a `PACIENTE`.

### `PUT /pacientes/{id}/registros` — marcar una comida

Upsert sobre `(paciente, tiempo de comida, fecha)`, idéntico a `PUT /me/registros`, con `autor: "NUTRICIONISTA"` en la fila resultante.

```
tiempoComidaId (uuid, requerido)  // viene en GET /pacientes/{id}/planes
cumplido     (bool, requerido)
comentario   (string)
fecha        (YYYY-MM-DD, por defecto hoy)
```

Responde `200` con la fila completa; `400` si los datos son inválidos, `404` si el paciente no es del nutricionista.

### Qué cambia en el diseño

- El 403 ya no es un bloqueo de producto: la nutricionista escribe sin suplantar al paciente. `PUT /me/registros` sigue devolviendo 403 a un token de nutricionista, y está bien.
- La ficha puede mostrar el diario de los últimos 7 días con quién marcó cada comida, y el botón de marcar/corregir por tiempo de comida.
- `adherencia30d` deja de ser estructuralmente cero: marcar comidas mueve `cumplidos` y `porcentaje`.
- Lo que sigue faltando: no hay historial ni borrado de un registro; corregir es volver a hacer el `PUT`.
