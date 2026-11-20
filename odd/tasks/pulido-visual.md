# Pulido visual y navegación (BO)

Feature: los pequeños acentos que dan vida a la app, en la lista de pacientes y en el inicio, la entrada
a la ficha del paciente desde el inicio, y animaciones de navegación. Nace de una observación del humano
sobre el detalle de planes (L1) y de lo que ya dibujan los artboards de `odd/designs/mis-pacientes/` y
`odd/designs/mobile/`. **La copy no cambia**: no hay cadenas nuevas.

## Specs

**S1 — La ficha del paciente se alcanza desde el inicio.** En `HomeScreen`, toda fila que nombre un
paciente abre su ficha:

- cada tarjeta de `Tus pacientes` (ya recibe un `PacienteResumen` con `id`, hoy sin usar);
- la tarjeta de la próxima cita y las de `Después`, por el `paciente.id` de la cita.

La pantalla no navega sola: recibe `onAbrirPaciente(String pacienteId)` del router, que hace
`context.push(AppRoutes.paciente(id))` — el mismo patrón con callbacks que ya usan la lista de pacientes
y la de planes. Una fila tocable se ve tocable: chevron `chevron_right` en `onSurfaceVariant` al final.

**S2 — Acento de estado del plan, en las dos listas.** La píldora del plan deja de aparecer sólo cuando
hay plan activo. En `Tus pacientes` y en el directorio se dibuja **siempre**, con color:

- con plan (`tienePlanActivo`): fondo `secondaryContainer`, texto `onSecondaryContainer` y punto de 8 px
  en `primary`;
- sin plan: fondo `surfaceContainer`, texto `onSurfaceVariant`, sin punto.

Es una píldora **privada del módulo de pacientes**: `AppPill` no lleva fondo y otros consumidores
dependen de su forma actual, así que no se toca.

**S3 — El directorio no pierde nada de lo que ya tiene.** Nombre, `perfil` (`N años · Bajar|Mantener|
Subir`), medidas en mono, avatar de iniciales, buscador, chips de filtro con conteo, estado vacío y el
tap que abre la ficha quedan como están. S2 sólo agrega la píldora de estado.

**S4 — Animaciones de navegación (decisión del humano).** Las páginas **dentro** del shell (inicio,
pacientes, ficha, planes, agenda, dietas, catálogo, configuración) entran con un desvanecido corto y un
desplazamiento mínimo: `FadeTransition` de 220 ms con `Curves.easeOutCubic` y un `slide` de 12 px desde
8. Los formularios a pantalla completa (`nuevo paciente`, `editar paciente`, `generar plan`, `editar
tiempo`, `medición`, `nueva cita`) entran con desvanecido y subida de 24 px en 260 ms, porque se
comportan como una hoja que cubre la app. **Sin excepciones inventadas**: cuando el sistema pide menos
movimiento (`MediaQuery.disableAnimations`), la página se construye sin transición. No se anima nada
dentro de las pantallas: esto es sólo navegación.

**S5 — Nada de lo que funciona se rompe.** Los tests existentes del router, del inicio y del directorio
siguen verdes. Cada unidad de esta feature compila y prueba sola.

## Tasks

| ID | Specs | Tarea | Superficie | Estado |
|----|-------|-------|-----------|--------|
| V1 | S1, S5 | Inicio: filas tocables hacia la ficha y chevron de afordancia | `lib/features/home/ui/`, `lib/core/router/` | hecho |
| V2 | S2, S3, S5 | Píldora de estado del plan en las dos listas, con color | `lib/features/patients/ui/`, `lib/features/home/ui/` | hecho |
| V3 | S4, S5 | Transiciones de navegación del shell y de los formularios | `lib/core/router/` | hecho |

V1 y V2 tocan el inicio; se entregan en commits separados y V2 va después de V1 en el mismo archivo.
V3 es independiente.

## Log

**L1 — Pedido original (verbatim).** «me gusta, miremos que esas cosas pequenas, son las que les da vida
a esto, podemos hacer algo similar en la lista de pacientes, y en la del inicio, y que sea accesible
desde el inicio a la ficha del paciente tambien pls, animaciones de navegacion tambien pls»

**L2 — Lo que ya existe (medido, no supuesto).** El inicio ya tiene los acentos más ricos de la app: la
tarjeta de la próxima cita con una línea de ECG dibujada con `CustomPaint`, la `_DayTimeline` con los
bloques de cita y el marcador de "ahora", y las dos métricas con su círculo de icono. Lo que le falta es
que las tarjetas de `Tus pacientes` sean tocables — hoy no tienen `onTap` — y que la píldora del plan
tenga color. El directorio ya dibuja avatar de iniciales, medidas en mono y los chips de filtro con
conteo; su artboard (`odd/designs/mis-pacientes/MpDirectorio.html`) pide además la píldora de estado con
fondo y punto, que es lo que hoy falta.

**L3 — No hay ninguna transición de navegación.** El router declara todo con `builder:` y seis
formularios con `MaterialPage`, sin `CustomTransitionPage` ni `transitionsBuilder`. La única animación
de `lib/` es el pulso de `AppPill`, que hoy nadie usa con `pulse: true`.

**L4 — Entregado y verificado.** Las tres unidades están hechas y el árbol quedó con `flutter analyze`
limpio y **410 tests verdes, 1 omitido**.

- **V1.** `HomeScreen` recibe `onAbrirPaciente` y el router lo cablea a `push(AppRoutes.paciente(id))`.
  Son tocables las filas de `Tus pacientes`, la tarjeta de la próxima cita y las de `Después`, todas con
  chevron. En la tarjeta grande el chevron va superpuesto para no robarle ancho al timeline ni al ECG.
- **V2.** La píldora del plan se dibuja siempre, con tinte: `secondaryContainer` con punto `primary`
  cuando hay plan, `surfaceContainer` sin punto cuando no. Se hizo con un widget compartido nuevo,
  `lib/shared/widgets/app_tinted_pill.dart`, porque la necesitan las dos listas: `AppPill` no lleva fondo
  y no se toca, que otros consumidores dependen de su forma.
- **V3.** `lib/core/router/app_transitions.dart` concentra las dos transiciones: desvanecido de 220 ms y
  12 px de subida para las páginas del shell, 260 ms y 24 px para los formularios, con `NoTransitionPage`
  cuando el sistema pide menos movimiento. `login` y `showcase` quedan sin tocar: están fuera del shell y
  el login es el arranque.

Queda una cosa sin prueba visual: la posición del chevron de la próxima cita se decidió por geometría y
no hay test que impida que un nombre largo lo pise. Se ve en el dispositivo.
