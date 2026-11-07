# App shell: drawer, app bar y rutas

Cáscara de navegación del área autenticada: drawer, barra superior, base del main y las rutas de las pantallas (vacías por ahora).
Branch `feat/mobile-login`. Route: inline. Límites del usuario: ≤400 líneas de cambio y ≤2 líneas de comentario por función.

## Specs

**S1 — Componentes reutilizables, en orden.** Primero el drawer, después el app bar, después la base del main. Texto del usuario: "es hora de disenar componentes que vamos a reutiliza, primero el drawer, segundo el app bar, y la base del main".

**S2 — Rutas vacías.** Se crean las rutas de las pantallas del diseño con placeholders; el contenido llega en cada feature. Texto: "y creemos las rutas, vacias de momento".

**S3 — Presupuesto de revisión.** No más de 400 líneas de cambio por entrega. Texto: "recuerda, no mas de 400 lineas".

**S4 — Comentarios mínimos.** Máximo 2 líneas de comentario por función. Texto: "no mas de 2 lineas de comentario por funcion".

**S5 — Fidelidad al diseño.** El drawer y la barra salen de `odd/designs/mobile/02-inicio-clinico.html`: panel de 290 con logo "BaleadaFit Pro" y botón de cerrar, tarjeta de perfil (avatar, nombre, rol), secciones "Navegación Clínica" y "Administración HN", ítem activo en `secondaryContainer`, y "Cerrar sesión" en color de error.

**S6 — Sin botones muertos.** No se dibujan acciones sin comportamiento: se omiten las que el mockup muestra y no tenemos (notificaciones, estado "HN-DISPONIBLE", Auditoría IA, Facturación SAR) y quedan anotadas.

## Tasks

| ID | Spec | Qué | Commit |
|----|------|-----|--------|
| T1 | S1, S5 | `AppDrawer`: header, tarjeta de perfil desde la sesión, secciones, ítem activo, cerrar sesión | pendiente |
| T2 | S1, S5 | `AppTopBar`: hamburguesa, emblema, nombre + sección actual, avatar con iniciales | pendiente |
| T3 | S1 | `AppShell` + `ShellRoute` para que drawer y barra persistan entre pantallas | pendiente |
| T4 | S2, S6 | Rutas nuevas con placeholder y tests de navegación/ítem activo | pendiente |

## Log

**L1 (usuario, verbatim):** "entoces es hora de disenar componentes que vamos a reutiliza, primero el drawer, segundo el app bar, y la base del main y creemos las rutas, vacias de momento, recuerda, no mas de 400 lineas, y no mas de 2 lineas de comentario por funcion vamos con eso pls para ir viendolo ya"

**L2 (evidencia):** los tres mockups mobile usan drawer lateral (11 referencias en `02-inicio-clinico.html`), no bottom navigation. La barra superior del mockup mide 64pt y lleva hamburguesa + monograma + nombre/sección a la izquierda.

**L3 (evidencia):** sesión verificada en el iPhone físico (login por correo y por Google, y restauración al relanzar el proceso).
