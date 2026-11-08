# Contexto del módulo Agenda (para diseñar)

Todo lo que el rol **nutricionista** puede ver y hacer con sus citas, según el contrato
OpenAPI indexado (`baleadafit-api`, 45 endpoints, 84 schemas, reindexado el 2026-11-07).

⚠️ **Estado de verificación:** este documento sale del contrato, **no de payloads capturados**.
Los endpoints de citas no se probaron todavía con un token real en esta sesión. Donde el spec
no define el esquema lo digo explícitamente: no inventar campos.

Complementa `odd/designs/design-system.md`, `home-context.md` y `pacientes-context.md`.

## 1. Mapa de endpoints

| Uso | Endpoint | Notas |
|---|---|---|
| Agenda | `GET /citas` | Paginada. Filtros: `desde`, `hasta`, `pacienteId`, `estado` |
| Programar | `POST /citas` | Responde **409 si se traslapa** con otra cita programada |
| Reprogramar / completar / cancelar | `PATCH /citas/{id}` | Mismo endpoint para las tres cosas, se distinguen por el body |

Tres endpoints en total. No hay endpoint de disponibilidad, de horarios de consultorio ni de
"próximo hueco libre": la única señal de choque es el 409 al crear.

## 2. La cita (`CitaEntity`)

Es a la vez el evento de agenda y la **nota clínica** de la consulta: lleva los cuatro campos
SOAP.

```
id · pacienteId · nutricionistaId
fechaHora (ISO 8601 con zona) · duracionMin · estado
motivo · notas
paciente { id, nombre, apellido, telefono }   // anidado, ya viene en la lista
subjetivo · objetivo · analisis · plan        // SOAP: S, O, A, P
proximaCitaSugerida (solo fecha) · creadoEn
```

`estado` es un enum de **tres** valores: `PROGRAMADA`, `COMPLETADA`, `CANCELADA`.
No existe "en curso", "confirmada por el paciente" ni "no asistió".

## 3. Programar (`POST /citas`)

```json
{
  "pacienteId": "uuid",
  "fechaHora": "2026-11-07T15:00:00.000Z",   // ISO con zona, obligatorio
  "duracionMin": 45,                          // por defecto 45
  "motivo": "Revisión de mediciones",
  "notas": ""
}
```

- **409 al traslapar.** No devuelve los huecos disponibles, sólo el rechazo. La UI tiene que
  ofrecer un camino de recuperación: cambiar la hora e intentar de nuevo.
- Responde 201 con la cita completa, ya con `paciente` anidado y `estado: PROGRAMADA`.

## 4. Reprogramar, completar y cancelar (`PATCH /citas/{id}`)

Mismo endpoint, body parcial:

| Intención | Body mínimo |
|---|---|
| Reprogramar | `fechaHora` (y opcionalmente `duracionMin`, `motivo`, `notas`) |
| Completar | `estado: "COMPLETADA"` + los campos SOAP que se hayan cargado |
| Cancelar | `estado: "CANCELADA"` |

Acepta además `subjetivo`, `objetivo`, `analisis`, `plan`, `proximaCitaSugerida`,
`pacienteId`. No hay endpoint aparte para la nota SOAP: se guarda con el mismo PATCH.

`proximaCitaSugerida` es **sólo fecha** (`YYYY-MM-DD`), no un instante.

## 5. La lista (`GET /citas`)

Paginación estándar: `limit` (20 por defecto, máximo 100), `offset` o `cursor`; responde
`{ok, data: [], meta: {limit, offset, total, hasMore, nextCursor}}`.

Filtros: `desde`, `hasta` (sin formato declarado en el spec), `pacienteId`, `estado`
(**uno solo a la vez**; no hay "programadas y completadas a la vez").

No hay parámetro de orden: la descripción dice "ordenadas por fecha", así que el orden lo
impone el servidor y el cliente no lo elige. No hay filtro "hoy" ni "esta semana": se piden
`desde`/`hasta` y el rango lo calcula el cliente.

## 6. Fechas: el detalle que rompe pantallas

- `fechaHora` es un instante ISO **con zona**: se formatea en la zona del dispositivo.
- `proximaCitaSugerida` y las fechas de calendario se guardan a **medianoche UTC**. Formatearlas
  en `America/Tegucigalpa` (GMT-6) muestra **el día anterior**. Es el mismo defecto ya
  documentado para la ficha y el dashboard.
- La hora que se muestra al usuario debe salir de `fechaHora.toLocal()`, nunca de restarle horas.

## 7. Estados de datos que hay que dibujar

Los conocemos por contrato y por el estado real de la base:

| Estado | Cómo se ve |
|---|---|
| **Agenda vacía** | Es el estado **real hoy**: la base de producción tiene **0 citas** al 2026-11-01. Es la pantalla que primero se va a ver |
| Día sin citas | El home ya resuelve esto con "Sin citas hoy" / "Sin pendientes" |
| Cita programada | Estado normal, con `duracionMin` para dimensionarla |
| Cita completada | Tiene SOAP cargado; el diseño tiene que dejar lugar a la nota |
| Cita cancelada | Sigue en la lista si el rango la incluye; no se borra |
| Traslape rechazado | 409 al crear: mensaje y oportunidad de corregir la hora |

## 8. Gaps del contrato (a resolver en el repo del API, no en el diseño)

1. No hay endpoint de **disponibilidad** ni de horario de consultorio: la agenda no puede
   saber qué horas son válidas sin inventarlas o intentar y esperar 409.
2. `estado` no distingue **no asistió** (incomparecencia) de cancelada. Clínicamente son cosas
   distintas y la agenda las querría separadas.
3. `desde`/`hasta` no declaran formato en el spec (los demás endpoints usan `YYYY-MM-DD`).
4. No hay confirmación del paciente ni canal de recordatorio: no existen campos ni endpoints
   de notificación.
5. La lista no acepta orden ni más de un `estado`.

## 9. Qué se puede dibujar sin inventar

- Una agenda por día con las citas dimensionadas por `duracionMin`, con hora local, paciente y
  motivo: todo eso viene en la respuesta.
- Un formulario de programación con paciente (`GET /pacientes` ya existe), fecha y hora,
  duración, motivo y notas.
- El detalle de una cita con la nota SOAP en cuatro bloques y `proximaCitaSugerida` como
  sugerencia de la siguiente.
- Acciones de reprogramar, completar y cancelar sobre la misma cita.
- El estado vacío de la agenda, que hoy es el caso real.

## 10. Lo que NO se puede dibujar todavía

- Calendario con huecos libres, "arrastrá a otro horario" o sugerencia de horarios: no hay
  endpoint de disponibilidad.
- Recordatorios, WhatsApp, confirmación del paciente: no existen.
- Un estado "no asistió": habría que pedirlo al API.
- Totales de agenda por semana o métricas de ocupación: ningún endpoint agrega eso (`GET
  /dashboard` sólo trae las citas de hoy).
