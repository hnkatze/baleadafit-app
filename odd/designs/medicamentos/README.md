# Medicamentos · artboards de diseño

Extraídos de `BaleadaFit Ideas-3.html` (board `__bundler`, en `~/Downloads`, fuera del repo). Cada
archivo `.html` es el contenido del bloque `__bundler/template` de la pantalla, desescapado sin
reformatear. Contexto de contrato: `odd/designs/medicamentos-context.md`. Specs de producto:
`odd/tasks/medicamentos.md`.

Notas sobre los archivos:
- Cada `.html` conserva su `<style data-dc-design-system-vars>` y su `<style>` propio. No dependen
  de una hoja externa del bundle.
- Referencian recursos que el export no incluye junto al marcado: fuentes `ds/baleadafit/fonts/*.ttf`
  (se cae a `system-ui`) y Material Symbols desde Google Fonts (necesita red; sin ella los iconos
  se ven como texto de ligadura). El enlace `MedicamentoForm.dc.html` de la lista apunta a una
  pantalla del board que se exportó aparte (`MedicacionEditar.html`).
- Los textos de iconos (`arrow_back`, `medication`, …) son ligaduras, no copy; no se cuentan.
- El ancho es 390 px; la lista mide 920 y el estado vacío 980 de alto.

## Mapa

| Artboard | Archivo | UUID del iframe |
|---|---|---|
| Medicación · lista | `MedicacionLista.html` | `6bf9cb98-2706-4c21-8fba-a09ee99cbdd9` |
| Medicación · sin registros | `MedicacionSinRegistros.html` | `1edb6fea-d288-4055-ac39-76eb3e676783` |
| Editar medicamento | `MedicacionEditar.html` | `644765d9-e510-4846-955b-a8ef5f33d504` |

## Inventario de copy (verbatim, en orden visual)

### Medicación · lista (`MedicacionLista.html`) — 9 cadenas

- "Medicación"
- "Paciente De Prueba" [dato de ejemplo]
- "Medicación vigente. Una vez que salís de esta pantalla, una baja no vuelve a aparecer: no hay forma de recuperarla."
- "Metformina" [dato de ejemplo]
- "500 mg · Cada 12 horas con comida" [dato de ejemplo]
- "Losartán" [dato de ejemplo]
- "50 mg" [dato de ejemplo]
- "Ácido fólico" [dato de ejemplo]
- "Registrar medicamento"

**Estructura**

- Encabezado: flecha de volver (`aria-label` de volver a la ficha) + título "Medicación" + nombre
  del paciente debajo.
- Aviso informativo (icono `info`) antes de la lista: dice que una baja no se recupera al salir.
- Tres filas: icono `medication`, nombre, línea secundaria `dosis · frecuencia`, y `chevron_right`
  que abre el editor. La tercera fila **no dibuja línea secundaria** (ni `·`, ni guiones): es el
  caso "sin dosis ni frecuencia".
- Acción primaria fija al pie, a todo el ancho: "Registrar medicamento" con icono `add`.
- Sin menú, sin baja desde la lista, sin paginación ni buscador: la lista es corta por contrato.

### Medicación · sin registros (`MedicacionSinRegistros.html`) — 5 cadenas

- "Medicación"
- "María Isabel Hernández Paz" [dato de ejemplo]
- "Sin medicación registrada"
- "Registrá los medicamentos que el paciente toma, con dosis y frecuencia si las conocés."
- "Registrar medicamento"

**Estructura**

- Estado vacío centrado: icono `medication` grande, título, cuerpo y un botón. Sin el aviso
  informativo de la lista.
- Iconos: `arrow_back`, `medication`, `add`.

### Editar medicamento (`MedicacionEditar.html`) — 13 cadenas

- "Editar medicamento"
- "Paciente De Prueba" [dato de ejemplo]
- "Nombre"
- "Metformina" [valor inicial]
- "Dosis · opcional"
- "500 mg" [placeholder]
- "ej. 500 mg"
- "Frecuencia · opcional"
- "Cada 12 horas con comida" [placeholder]
- "ej. Cada 12 horas con comida"
- "Si dejás la dosis o la frecuencia en blanco, se conserva el valor guardado: todavía no hay forma definida de borrarlas del todo."
- "DAR DE BAJA"
- "Se conserva en el historial clínico, pero sale de la lista. No vas a poder recuperarla desde esta pantalla después de salir."
- "Dar de baja"
- "Guardar cambios"

**Estructura**

- Hoja completa: cierre con `x` en la esquina (icono `close`), título "Editar medicamento" y nombre
  del paciente.
- Tres campos de texto: Nombre (obligatorio, con valor), Dosis y Frecuencia (opcionales, con
  placeholder + ayuda `ej. …`). El board **no dibuja** ninguna afordancia para limpiar dosis o
  frecuencia.
- Nota informativa (icono `info`) bajo los campos: los vacíos conservan lo guardado.
- Bloque destructivo al pie: rótulo "DAR DE BAJA", texto explicativo y botón con icono
  `medication_liquid`. No dibuja diálogo de confirmación.
- Acción primaria fija: "Guardar cambios".
- No hay pantalla de alta dibujada: el board de edición es también el de alta (mismo formulario,
  sin bloque de baja).

## Contraste con el contrato

Contrastado contra `odd/designs/medicamentos-context.md`. Lo que sigue distingue lo que el export
**dibuja** de lo que sólo **implica**.

- **La lista no tiene fuente propia.** El board dibuja una lista "vigente", pero el contrato no
  tiene `GET` de medicamentos: sale de `situacion.medicacion` de la ficha, cuyo filtrado por
  `activo` y orden **no están declarados** (gap 3). El aviso informativo del board ya confiesa la
  peor consecuencia (la baja no se recupera), así que el diseño no promete historial. **[DECISIÓN]**
  Si se quiere listar sólo activos, hay que verificarlo con un payload real antes de filtrar en la
  app.
- **Baja irreversible.** El board dibuja "Dar de baja" en el editor y avisa que no se recupera:
  coherente con `DELETE` lógico y con que `activo: true` no esté definido para reactivar (gap 5).
- **Campos que no se limpian.** El board dice exactamente lo que el contrato permite: omitir
  conserva (gap 2). No dibuja "quitar dosis". **[DECISIÓN]** Qué se hace hoy si el usuario borra el
  texto de un campo ya cargado: reenviar el valor anterior (lo que implica el contrato) y decirlo,
  o bloquear el campo.
- **Alta vs. edición.** El board de edición incluye el bloque de baja y el título "Editar". Para el
  alta hace falta el mismo formulario sin ese bloque y con acción "Registrar medicamento", que el
  export no dibuja: es una decisión de UI, no de contrato.
- **Validación.** El board no dibuja errores. El contrato devuelve 400 `VALIDACION` con `detalles`
  por campo: hace falta un estado de error por campo que el diseño no define.
- **Duplicados.** Registrar dos veces el mismo nombre no da error (no hay 409): el board no puede
  prometer "ya existe".
- **Sin fecha de baja.** El contrato no registra cuándo se dio de baja: el diseño no dibuja "desde
  el 12 de octubre".

### Resumen de decisiones humanas

1. Si la lista filtra por `activo` en la app o muestra lo que traiga la ficha.
2. Qué pasa si el usuario vacía un campo ya cargado (reenviar el valor actual y avisarlo, o
   bloquear el campo).
3. Título y acción del board de alta (el export sólo dibuja el de edición).
4. Forma del error de validación por campo, que el export no dibuja.
