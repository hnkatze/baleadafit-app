# Medicamentos

Módulo de medicación del paciente para el rol nutricionista: lista, alta, edición y baja lógica.
Fuente de verdad del diseño: `odd/designs/medicamentos/` (3 artboards extraídos del canvas
`BaleadaFit Ideas`) y `odd/designs/medicamentos-context.md` (contrato).

## Specs

**S1 — Lista.** Pantalla propia, título `Medicación`, con el nombre del paciente debajo y flecha
de volver. Cada fila: ícono de pastilla, nombre del medicamento y, en una línea secundaria, la
composición `dosis · frecuencia`; si falta una, se muestra sólo la que hay; si faltan las dos, no
se dibuja línea secundaria (ni `·`, ni `null`, ni guiones). Cada fila lleva chevron y abre el
editor de ese medicamento.

**S2 — Aviso de la lista.** Encima de las filas, una nota informativa con este texto exacto:
`Medicación vigente. Una baja la saca de esta lista y del expediente; el historial clínico se conserva.`
(Reescrito el 2026-11-20: el texto anterior decía que una baja no vuelve a aparecer, y el contrato
ya permite leer los inactivos con `?incluirInactivos=true`.)

**S3 — Acción primaria de la lista.** Barra fija al pie, en todos los estados, con el botón
`Registrar medicamento` y el ícono `add`.

**S4 — Estado vacío.** Cuando el paciente no tiene medicación: ícono de pastilla, título
`Sin medicación registrada` y el cuerpo exacto
`Registrá los medicamentos que el paciente toma, con dosis y frecuencia si las conocés.`
No se dibuja la lista ni el aviso de S2; el botón de S3 sigue presente.

**S5 — Origen de los datos.** La medicación se lee de `situacion.medicacion` de
`GET /pacientes/{id}/ficha`, que la app ya carga: no hay `GET` propio de medicamentos y no se
agrega ninguna llamada nueva para listar.

**S6 — Después de escribir.** Crear, editar o dar de baja invalida la ficha del paciente, para
que la lista y el expediente vuelvan a leer el mismo dato. No se guarda estado local paralelo.

**S7 — Editor.** Alta y edición comparten un board: título `Editar medicamento` en edición (alta:
`Registrar medicamento`), nombre del paciente debajo, y cierre con `x` en la esquina (no botón de
cancelar). Campos: `Nombre` (obligatorio, 2–120), `Dosis · opcional` (placeholder `500 mg`, ayuda
`ej. 500 mg`, máx. 80), `Frecuencia · opcional` (placeholder `Cada 12 horas con comida`, ayuda
`ej. Cada 12 horas con comida`, máx. 120).

**S8 — Nota del editor.** Debajo de los campos opcionales, texto exacto:
`Vaciado, el campo conserva lo que ya estaba: para borrar la dosis o la frecuencia usá la x del campo.`
(Reescrito el 2026-11-20: el contrato ya define el vaciado con `null`, así que la nota vieja —"no
todavía no hay forma definida de borrarlas"— era falsa.)

**S9 — Dar de baja.** Sólo en edición: sección destructiva `DAR DE BAJA` con el texto exacto
`Se conserva en el historial clínico, pero sale de la lista.` y el botón `Dar de baja`. Pide
confirmación en un diálogo que se cierra **sólo** con la cruz roja (regla de la casa). Llama
`DELETE /medicamentos/{id}`, que responde 200 con el medicamento en `activo: false`. La baja **sí**
es recuperable por el API (`PATCH {"activo": true}` después de leer con `?incluirInactivos=true`),
pero esta app todavía no dibuja esa reactivación: es T7, pendiente de diseño.

**S16 — Limpiar un campo (nuevo, 2026-11-20).** En edición, `Dosis` y `Frecuencia` llevan una acción
`x` dentro del campo (sufijo) que **borra** el valor guardado mandando `dosis: null` o
`frecuencia: null` en el `PATCH`. Sólo aparece cuando el campo tiene valor. Un campo vaciado a mano
no borra: reenvía el valor guardado (S8). Mandar `""` ya no es válido: el API responde 400.

**S17 — Duplicado (nuevo, 2026-11-20).** El alta responde `duplicadoDe: {id, nombre}` cuando ya
existe un medicamento vigente con el mismo nombre normalizado. El alta **se guarda igual**: el
formulario muestra el aviso exacto `Ya hay un medicamento vigente con ese nombre: <nombre>. Se guardó
igual.` y no bloquea nada.

**S10 — Guardar.** Acción primaria `Guardar cambios`. Alta: `POST /pacientes/{id}/medicamentos`
con `nombre` siempre y `dosis`/`frecuencia` sólo si tienen texto. Edición: `PATCH /medicamentos/{id}`
con los mismos campos y **omitiendo** los que quedaron vacíos (omitir conserva, hecho del contrato).

**S11 — Validación.** Un 400 `VALIDACION` trae `detalles` por campo: el mensaje va en el campo que
corresponde cuando el contrato lo identifica, y si no, en el bloque de fallo. 404 se muestra como
"no existe o no pertenece al usuario". Ningún fallo deja el formulario deshabilitado.

**S12 — Sin dato.** `dosis` y `frecuencia` nulos nunca se dibujan como `null`, cadena vacía ni
`—`: se omite el dato.

**S13 — Rutas.** Las pantallas cuelgan del paciente, como hijos del expediente:
`/pacientes/{id}/medicacion` (la lista, dentro del shell, con flecha de volver a la ficha) y
`/pacientes/{id}/medicacion/nueva` y `/pacientes/{id}/medicacion/{medicamentoId}` (el formulario, a
pantalla completa con `x` y fuera del shell, como el alta de paciente y la nueva medición).

**S14 — Bloque en la ficha.** La ficha dibuja una tarjeta `Medicación` después de la tarjeta de
Objetivo y antes de `Mediciones`: es contexto clínico vigente, no historial. Con medicación: hasta
tres filas (nombre + `composicion`) y al pie `Ver todo · N`, con N = total. Sin medicación:
`Sin medicación registrada` y, al pie, un **botón sólido** `Registrar medicamento` con ícono `add`
—no texto de color: es la acción principal de la tarjeta—. Se alimenta de
`ficha.situacion.medicamentos` —la ficha ya la trae, no hay llamada extra— y tocar la tarjeta abre
la pantalla de S13.

**S15 — Atajo del menú.** La entrada `Medicamentos` del menú de desborde deja de ser inerte: abre la
misma pantalla que S14, sin diálogo intermedio. Es navegación, no una acción.

## Tasks

| ID | Qué | Specs | Ruta | Commit |
|---|---|---|---|---|
| T1 | Modelo `Medicamento` y lectura desde `situacion.medicacion` de la ficha | S5, S12 | inline | `feat(medicamentos): model the medication the ficha already brings` |
| T2 | Repositorio de los tres endpoints (la lista sale de la ficha ya cargada; la invalidación la hacen las pantallas) | S5, S6, S10 | inline | `feat(medicamentos): register, edit and deactivate through the API` |
| T3 | Pantalla de lista con sus dos estados y la acción primaria | S1-S4, S12 | writer | `feat(medicamentos): list the medication with its empty state` |
| T4 | Editor de alta y edición, con validación por campo | S7, S8, S10-S12 | writer | `feat(medicamentos): add and edit a medication` |
| T5 | Bloque `Medicación` en la ficha, atajo del menú, ruteo y baja con confirmación | S9, S13-S15 | inline | `feat(medicamentos): reach the medication from the ficha and deactivate it` |
| T6 | Contra el contrato del 2026-11-17: copy de S2 y S8, limpiar con `null` (S16), aviso de duplicado (S17) y `actualizadoEn` en el modelo | S2, S8, S16, S17 | writer | `fix(medicamentos): follow the new contract for clearing and duplicates` |
| T7 | Reactivar un medicamento dado de baja, leyendo `GET /pacientes/{id}?incluirInactivos=true` | S9 | - | pendiente de diseño: ningún board lo dibuja |

## Log

**L1 (usuario, 2026-11-19):** "dale con eso, y dejame el doc para el catalogo de alimentos pls, para hacer el desing"

**L2 (usuario, antes):** "en stich no, en los desing ? /Users/katze/Downloads/BaleadaFit Ideas-3.html  miremos el de medicamentos, es simple"

**L3 (evidencia, 2026-11-19):** el canvas export es un bundler anidado; los tres boards
(`Medicación · lista`, `Medicación · sin registros`, `Medicación · editar`) se extrajeron y sus
textos están citados literalmente en las specs.

**L4 (evidencia, 2026-11-19):** índice `baleadafit-api` (49 endpoints, 90 schemas):
`MedicamentoEntity` = `activo, creadoEn, dosis, frecuencia, id, nombre, pacienteId`; no hay `GET`
de medicamentos; `DELETE` responde 200 con el medicamento; `activo: true` no está definido para
reactivar; vaciar `dosis`/`frecuencia` no está definido.

**L5 (decisión):** la lista se alimenta de la ficha ya cargada en vez de una llamada nueva, porque
no existe `GET /medicamentos` y el contrato advierte que el filtrado de `situacion.medicacion` no
está declarado. El aviso de S2 confiesa esa limitación al usuario en vez de prometer historial.

**L6 (usuario, 2026-11-19) — decisión de entrada:** "los medicamentos son en pacientes verdad,
pero en donde ira eso ?" → entre tres opciones eligió **bloque `Medicación` en la ficha más el
atajo del menú de desborde**, las dos a la misma pantalla. De ahí salen S14 y S15; el ítem del menú
deja de estar inerte.

**L7 (evidencia T1):** `Medicamento` + `SituacionFicha.medicamentos`; 4 tests
(`test/features/patients/data/medicacion_ficha_test.dart`), analyze limpio. El getter `composicion`
resuelve `500 mg · Cada 12 horas`, `50 mg` y `null` para el caso sin dosis ni frecuencia, así la
fila nunca dibuja `·` suelto.

**L8 (evidencia T2):** `registrarMedicamento` / `actualizarMedicamento` / `darDeBajaMedicamento`; 3
tests (`test/features/patients/data/medicamentos_repository_test.dart`) y los 31 de `data/` pasan.
Un campo en blanco no viaja: mandar `""` está indefinido en el contrato.

**L9 (evidencia T3 y T4, verificadas por el parent):** `medicacion_screen.dart` (11 tests) y
`medicamento_form_screen.dart` (14 tests) → 25 verdes. Decisiones de los writers que quedan
incorporadas: la nota de S8 se dibuja **sólo en edición** (en alta no hay valor guardado que
conservar); el placeholder es `500 mg` / `Cada 12 horas con comida` y la ayuda `ej. …` (el artboard
los muestra juntos en una línea); la acción primaria de S3 va en barra fija en los dos estados, no
duplicada dentro del estado vacío.

**L10 (nota del contrato, no resuelta):** si el usuario vacía un campo ya cargado, el formulario
reenvía el valor guardado y no promete haberlo borrado, que es lo que el contrato permite. Queda
como decisión humana si algún día se bloquea el campo en su lugar.

**L11 (evidencia T5, verificada por el parent):** `flutter analyze` sin issues y suite completa en
verde (+473, 1 omitido). La tarjeta `Medicación` quedó justo antes de `Mediciones` y después de
`Próximas consultas`: `Objetivo` es un bloque interno de `_Requerimiento` y sólo existe con
mediciones, así que esa es la lectura literal de S14. La baja invalida la ficha en el repositorio y
la lista la observa con `skipLoadingOnReload`, sin un segundo invalidate que duplique la petición.
Este corte **no observó RED** (tests e implementación escritos juntos); se compensó leyendo las
aserciones: el test de S15 navega por el menú, exige `MedicacionScreen` en la ruta del paciente y
la vuelta a la ficha, así que sin el cableado falla.

**L12 (riesgo abierto, no reproducido en dispositivo):** a 390 px con la fuente de test (Ahem) el
botón `Registrar medicamento` desborda 47 px en la barra fija; el mismo botón a 800 px no desborda.
Se sospecha artefacto de la fuente Ahem, no del layout: verificar en el iPhone antes de dar el
módulo por cerrado.

**L13 (contrato nuevo, 2026-11-20):** el board publicó `medicamentos-contrato-lectura-y-limpieza-2026-11`
(17-nov) y el módulo se construyó sobre el índice del 16-nov, así que dos notas quedaron falsas.
Lo que cambió: `GET /pacientes/{id}?incluirInactivos=true` trae los dados de baja; `PATCH
/medicamentos/{id}` acepta `null` para limpiar y **400** si llega `""`; el alta devuelve
`duplicadoDe: {id, nombre}` y sigue guardando; hay `actualizadoEn` además de `creadoEn`; la ficha
sigue trayendo sólo lo vigente. De ahí salen S16 y S17, y se reescribieron S2, S8 y S9. La
reactivación (T7) queda esperando diseño: ningún artboard la dibuja.
