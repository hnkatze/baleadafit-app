# Contexto del paciente (para diseñar)

Todo lo que el rol **paciente** puede ver y hacer en la API, con los contratos tal como están documentados hoy y el resultado de haberlos probado. Complementa `odd/designs/home-context.md` (lado nutricionista) y `odd/designs/design-system.md`.

## 1. Estado de verificación (importante antes de dibujar)

Probé los seis endpoints con un token **real** de la cuenta `playercamiloh504@gmail.com` (rol `nutricionista`):

```
GET  /me/hoy        → 403  {codigo: "SIN_PERMISO", mensaje: "No tienes permiso para este recurso."}
GET  /me/plan       → 403
GET  /me/mediciones → 403
GET  /me/registros  → 403
PUT  /me/registros  → 403
GET  /me/citas      → 403
```

Conclusión: **el gating por rol funciona** (el paciente no puede tocar endpoints de nutricionista y viceversa), pero **no pude capturar payloads reales del paciente**. Lo que sigue sale del contrato OpenAPI, no de una respuesta observada. Para cerrar esa brecha hace falta una de estas dos cosas:

1. Credenciales de un paciente con usuario de Firebase, o
2. Activar `prueba.qa@baleadafit.hn` como usuario (hoy su `firebaseUid` es `null`, no puede entrar).

Donde el spec no define el esquema, lo marco explícitamente: **no inventar campos**.

## 2. Los seis endpoints

| Pantalla | Endpoint | Datos |
|---|---|---|
| Hoy | `GET /me/hoy?fecha=YYYY-MM-DD` | comidas del plan con su registro del día, cumplidos y próxima cita |
| Mi plan | `GET /me/plan` | plan activo completo con totales; `null` si no hay |
| Progreso | `GET /me/mediciones` | mediciones con IMC, de la más antigua a la más reciente |
| Diario | `GET /me/registros?desde&hasta` | comidas registradas; por defecto los últimos 7 días |
| Marcar comida | `PUT /me/registros` | el **único** write del paciente |
| Mis citas | `GET /me/citas` | todas las citas, de la más reciente a la más antigua |

Las cuatro listas usan la misma paginación: `limit` (default 20, máx 100), `offset` (base 0) o `cursor` (opaco, es el `nextCursor` previo), y responden `{ok, data: [], meta: {limit, offset, total, hasMore, nextCursor}}`.

## 3. Contratos

### `GET /me/hoy` — pantalla Hoy

```
data:
  fecha: string            // YYYY-MM-DD
  cumplidos: number        // comidas cumplidas del día
  plan: object | null      // null si la nutricionista no activó un plan
  proximaCita: object
  tiempos: []              // comidas del plan con su registro del día
```

⚠️ `plan`, `proximaCita` y `tiempos` figuran como `object`/`[]` **sin esquema** en el OpenAPI. Por `PUT /me/registros` se deduce que cada tiempo trae un **`tiempoComidaId` (uuid)**, y por `PUT /planes/{id}/tiempos/{tipo}/items` que el tipo es uno de:

```
DESAYUNO · MERIENDA_AM · ALMUERZO · MERIENDA_PM · CENA
```

Esos cinco valores son lo único cierto del contenido de `tiempos`.

### `GET /me/plan` — Mi plan activo

```
data:
  id, nombre, nutricionistaId, pacienteId
  estado: BORRADOR | ACTIVO | ARCHIVADO
  origen: MANUAL | REGLAS | IA
  justificacion: string        // resumen del recomendador o notas de la nutricionista
  kcalObjetivo: number
  proteinaG, carbohidratoG, grasaG: number
  desviacion: number           // desvío del día contra kcalObjetivo
  creadoEn, aprobadoEn: date-time
  tiempos: []                  // sin esquema, ver §3.1
  totales: {                   // totales del día
    kcal, proteinaG, carbohidratoG, grasaG, grasasSatG,
    fibraG, azucaresG, sodioMg, potasioMg, fosforoMg, cargaGlucemica
  }
```

Este sí está bien tipado: alcanza para dibujar los macros del día, el anillo de kcal, la desviación y los micronutrientes.

### `GET /me/mediciones` — Progreso

```
data: []            // ⚠️ sin esquema en el spec; el resumen dice "con IMC"
meta: {limit, offset, total, hasMore, nextCursor}
```

Lo que sí se sabe por el lado nutricionista (`GET /pacientes/{id}/mediciones` y `mediciones` en `/pacientes`): `fecha`, `pesoKg`, `tallaCm`, `pctGrasa`, `masaMuscularKg`, `masaGrasaKg`, `grasaVisceral`, `aguaIntracelularL`, `aguaExtracelularL`, `anguloFase`, pliegues (tricipital, subescapular, suprailiaco, bicipital), perímetros (brazo, cadera, muslo), presión sistólica/diastólica, `fuente` (MANUAL/…) y `notas`. El IMC lo agrega este endpoint, no viene en la medición.

### `PUT /me/registros` — el único formulario del paciente

```
tiempoComidaId: uuid (required)   // viene en GET /me/hoy
cumplido: boolean
fecha: string YYYY-MM-DD          // por defecto hoy
comentario: string
```

Respuesta: `{id, pacienteId, tiempoComidaId, cumplido, comentario, fecha, creadoEn}`. Es idempotente por (tiempo, fecha): si ya existe, lo actualiza. `400 VALIDACION` con `detalles: []` por campo.

Diseño: es un **toggle con comentario opcional**, no un formulario largo. Un tap marca/desmarca.

### `GET /me/citas` — Mis citas

Devuelve `CitaEntity` (mismo esquema que la agenda de la nutricionista): `id`, `fechaHora`, `duracionMin`, `motivo`, `estado`, `notas`, campos SOAP (`subjetivo`, `objetivo`, `analisis`, `plan`) y `paciente` anidado.

## 4. Tablas y listas: qué columnas salen de la API

| Lista | Columnas defendibles con la API |
|---|---|
| Comidas de hoy | tipo de tiempo (5 valores), cumplido (bool), comentario |
| Mi plan | kcal objetivo, proteína, carbohidrato, grasa, estado, origen, desviación |
| Totales del plan | 11 números: kcal, P, C, G, saturadas, fibra, azúcares, sodio, potasio, fósforo, carga glucémica |
| Progreso | fecha, peso, talla, % grasa, masa muscular, masa grasa, IMC (calculado por el API) |
| Mis citas | fecha/hora, duración, motivo, estado |

Unidades que la UI debe declarar siempre: `kcal`, `g`, `mg`, `cm`, `kg`, `%`.

## 5. Enums y códigos

| Enum | Valores |
|---|---|
| Estado de plan | `BORRADOR`, `ACTIVO`, `ARCHIVADO` |
| Origen del plan | `MANUAL`, `REGLAS`, `IA` |
| Tiempo de comida | `DESAYUNO`, `MERIENDA_AM`, `ALMUERZO`, `MERIENDA_PM`, `CENA` |
| Códigos de falla | `VALIDACION`, `NO_AUTENTICADO`, `SIN_PERMISO`, `NO_ENCONTRADO`, `CONFLICTO`, `CURSOR_INVALIDO`, `ERROR_HTTP`, `ERROR_INTERNO` |

`SIN_PERMISO` (403) es lo que devuelve un rol equivocado; `NO_AUTENTICADO` (401) falta de token. El paciente **no** puede escribir nada más que su registro de comida: plan, mediciones y citas son de lectura.

## 6. Estados vacíos que el diseño debe resolver

| Caso | Situación real |
|---|---|
| `plan: null` | La nutricionista no activó plan: Hoy no tiene comidas |
| `proximaCita` vacío | Sin cita programada |
| `cumplidos: 0` | Día sin registrar |
| `data: []` en mediciones | Primer uso, sin historial: no hay gráfico |
| `data: []` en citas | Nunca tuvo cita |
| Sin conexión / 401 | Mensaje de la API + reintento |

## 7. Gaps del contrato (a resolver en el repo del API, no en el diseño)

1. `GET /me/hoy` no tipa `plan`, `proximaCita` ni `tiempos`.
2. `GET /me/mediciones` no tipa el ítem (no sabemos si trae `imc` como campo o lo calcula el cliente).
3. `tiempos[]` del plan no tiene esquema: se desconocen los alimentos por comida (nombre, cantidad, unidad, macros) aunque el nutricionista los edita con `items` (máximo 12 por tiempo).
4. No hay endpoint de perfil del paciente (`GET /me/perfil` no existe); los datos personales viven en el expediente del nutricionista.

## 8. Qué necesito de vos para pasar de contrato a pantalla

- Credenciales de un paciente (o activar la cuenta de prueba) para capturar los payloads reales de `/me/hoy`, `/me/mediciones` y `/me/registros`.
- Decisión de qué cuatro pantallas entran primero: **Hoy** es la que justifica la app del paciente; Progreso y Mis citas son lectura pura.
- Si el rediseño del login define un selector de rol o dos apps separadas: el API ya resuelve el rol en `GET /auth/me` (`nutricionista` | `paciente` | `sin_perfil`), así que un login único es suficiente.
