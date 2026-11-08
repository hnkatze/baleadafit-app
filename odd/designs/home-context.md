# Contexto del home (para rediseñar)

Documento de contexto, no de diseño: qué datos existen de verdad, qué puede mostrar la pantalla y dónde el mock tiene margen de decisión. La implementación actual está en `lib/features/home/ui/home_screen.dart`; los tokens en `odd/designs/design-system.md`.

## 1. Para qué existe la pantalla

La nutricionista abre la app entre consultas, con una mano y poco tiempo. La pregunta que trae es **"¿qué tengo hoy?"**. Todo lo que no responda eso, compite.

Consecuencia de diseño: la pantalla se lee de arriba hacia abajo en menos de diez segundos y lo accionable está en la primera mitad.

## 2. Qué datos existen (verificado con la cuenta real `playercamiloh504@gmail.com`)

### `GET /dashboard` — 1 llamada

```json
{
  "pacientesActivos": 2,
  "planesEnBorrador": 0,
  "citasHoy": [
    {
      "id": "fc79642c-…",
      "fechaHora": "2026-11-07T15:00:00.000Z",
      "duracionMin": 45,
      "motivo": "Revisión de mediciones",
      "estado": "PROGRAMADA",
      "paciente": { "id": "3543a8c6-…", "nombre": "Paciente", "apellido": "De Prueba", "telefono": null }
    }
  ]
}
```

Trae además `notas`, `subjetivo`, `objetivo`, `analisis`, `plan`, `proximaCitaSugerida` (campos SOAP), todos `null` hasta que se complete la consulta.

### `GET /pacientes?limit=4` — 2ª llamada

Cada paciente trae: `nombre`, `apellido`, `correo`, `sexo`, `fechaNacimiento`, `nivelActividad`, `meta` (BAJAR/…), `pesoObjetivoKg`, `estadoFisiologico`, `activo`, **`ultimaMedicion`** (`fecha`, `pesoKg`, `tallaCm`, `pctGrasa`, y ~15 campos más que hoy vienen `null`) y **`planActivo`**.

Con eso se puede mostrar, sin llamadas extra: peso actual, % de grasa, talla, objetivos, y si tiene plan o no.

### Lo que la API devuelve en lista trae `meta`

`{limit, offset, total, hasNext, nextCursor}` — sirve para "ver todos".

## 3. Qué NO existe (no se debe dibujar)

| Elemento del mockup Stitch | Estado real |
|---|---|
| Adherencia global 94.2% | No hay endpoint global; existe `GET /pacientes/{id}/adherencia` por paciente |
| "Seguimiento prioritario" | No hay endpoint de prioridades ni scoring |
| InBody 270 sincronizado | No hay integración BLE ni endpoint |
| WhatsApp Bot / confirmaciones | No hay endpoint |
| "HN-DISPONIBLE" | No hay estado de disponibilidad |
| Auditoría IA, Facturación SAR | No existen |
| Notificaciones | No hay endpoint |

Si el rediseño las necesita, se convierten en issues del repo del API; en la app serían botones muertos.

## 4. Anatomía actual

```
┌ barra: hamburguesa · emblema · BaleadaFit Pro / Inicio · avatar ┐
│ (gestionada por AppShell, no por la pantalla)                    │
├──────────────────────────────────────────────────────────────────┤
│ Hola, Lic. Camilo Henriquez        ← saludo de la sesión          │
│ Así va tu consulta hoy.            ← subtítulo                    │
│                                                                   │
│ ┌ 2 ────┬ 0 ─────┬ 2 ┐             ← franja de 3 métricas          │
│ │ Pacientes activos · Planes en borrador · Citas hoy │            │
│                                                                   │
│ ┌ 09:00 ─ PRÓXIMA CITA ─ Paciente De Prueba ─ Revisión de mediciones ┐
│ └──────────────────────────────────────────────────────────────┘  │
│                                                                   │
│ Resto del día                                                     │
│ ┌ 12:30 · María Isabel Hernández Paz · Primera consulta ┐         │
│                                                                   │
│ Tus pacientes                                                     │
│ ┌ Paciente De Prueba · 72.4 kg · 19.5% grasa ── [Sin plan] ┐      │
│ ┌ María Isabel Hernández Paz · 78.5 kg · 32.4% grasa ─ [Sin plan] │
└──────────────────────────────────────────────────────────────────┘
```

## 5. Estados que el mock debe resolver

| Estado | Qué se ve hoy |
|---|---|
| Cargando | spinner centrado |
| Error del resumen | "No pudimos cargar tu resumen." + mensaje de la API + botón Reintentar |
| Error de pacientes | línea discreta; el resumen sigue visible |
| Sin citas hoy | frase guía: "No tenés citas hoy. Buen momento para revisar los planes en borrador." |
| Sin pacientes | la sección no se dibuja |
| Día terminado (citas todas pasadas) | lista "Citas de hoy" sin tarjeta destacada |

## 6. Restricciones técnicas que condicionan el diseño

- **Dos llamadas, no N.** No hay endpoint que agregue pacientes + citas + adherencia. Si el mock pide un bloque nuevo, se resuelve con una llamada acotada (`query`/`limit`) o pidiendo endpoint nuevo.
- **Sin eliminar/reordenar sin backend**: hoy la app no puede marcar cita como completada ni cancelar desde la home (`PATCH /citas/{id}` existe y está libre).
- **Zona horaria**: el servidor decide "hoy" en UTC. Una cita creada a las 20:00 locales del 6 (= 02:00Z del 7) cuenta como *del día siguiente*. El mock no lo resuelve; conviene mostrarlo como "próximas" en vez de "hoy" si el equipo confirma el corte.
- **Sin paginación visual**: se piden 4 pacientes. Un "ver todos" necesita pantalla de pacientes.
- **Ancho de referencia**: 393 pt (iPhone 14 Pro Max), gutter 16, respiro vertical 24.
- **Cuántos números caben**: la franja tolera 3 métricas a 393 pt con etiquetas de hasta 2 líneas. Cuatro ya pide otro patrón.

## 7. Dónde el mock tiene margen de decisión

1. **Jerarquía**: hoy próxima cita y métricas compiten; ¿la próxima cita debería ser lo primero?
2. **Densidad**: ¿los pacientes van como filas, tarjetas con minigráfico de peso, o lista colapsada?
3. **Acciones rápidas**: existen rutas reales (`/pacientes`, `/dietas`, `/catalogo`, `/agenda`) — un acceso directo no sería botón muerto.
4. **Color**: la tarjeta destacada usa `#10B981` (verde saturado) y el mock decide si ese peso visual se mantiene.
5. **Estado vacío**: ¿frase guía, ilustración o acción sugerida?
6. **Datos por paciente**: peso, % grasa, talla, objetivo y plan existen; la pregunta es cuántos mostrar sin ruido.

## 8. Preguntas abiertas

- ¿La home debe mostrar "hoy" o "próximas citas" (hoy + mañana)?
- ¿"Planes en borrador" es accionable? Hoy no hay pantalla de planes.
- ¿El saludo lleva el nombre completo con honorífico (`Lic. Camilo Henriquez`) o solo el nombre?
- ¿Números de las métricas en JetBrains Mono (tabular) o en la sans?
