# Design system — Clinical Mint Precision

Estado real de lo que la app usa hoy. Fuente de verdad del código: `lib/core/theme/` y `lib/shared/widgets/`. Origen: los mockups de Stitch en `odd/designs/mobile/` y `odd/designs/stitch-design-system.json`.

## 1. Principios

1. **Clínico, no decorativo.** El color marca acción y estado; no rellena espacios.
2. **Una superficie por grupo.** Varias cajas iguales generan huecos y compiten entre sí (ver §6).
3. **Números estables.** Las cifras clínicas usan familia monoespaciada con `tabularFigures`: un peso que cambia no mueve el layout.
4. **Sin botones muertos.** Si no hay backend, la acción no se dibuja.
5. **Español para el usuario, inglés para el código.**

## 2. Color

Paleta Material 3 derivada del verde clínico. Tokens en `AppColors`.

| Token | Hex | Uso |
|---|---|---|
| `primary` | `#006C49` | Marca, acción principal, iconos activos |
| `onPrimary` | `#FFFFFF` | Texto sobre `primary` |
| `primaryContainer` | `#10B981` | Superficie destacada (tarjeta de próxima cita) |
| `onPrimaryContainer` | `#00422B` | Texto sobre la anterior |
| `primaryFixed` | `#6FFBBE` | Acentos, gráficos |
| `secondary` | `#1B6B51` | Apoyo |
| `secondaryContainer` | `#A6F2D1` | Chips suaves |
| `tertiaryContainer` | `#00B982` | Estados informativos |
| `surface` | `#F9F9FF` | Fondo de pantalla |
| `surfaceContainerLowest` | `#FFFFFF` | Tarjetas sobre fondo |
| `surfaceContainerLow` | `#F0F3FF` | Superficie alterna |
| `surfaceContainer` | `#E7EEFF` | Fondos de bloque |
| `surfaceContainerHighest` | `#D8E3FB` | Franja de métricas, pills |
| `onSurface` | `#111C2D` | Texto principal |
| `onSurfaceVariant` | `#3C4A42` | Texto secundario |
| `outline` | `#6C7A71` | Bordes de control, iconos inactivos |
| `outlineVariant` | `#BBCABF` | Hairlines, divisores, bordes de tarjeta |
| `error` | `#BA1A1A` | Error |
| `errorContainer` / `onErrorContainer` | `#FFDAD6` / `#93000A` | Mensajes de error |

No hay token de éxito ni de advertencia: hoy no se usan estados de ese tipo.

## 3. Tipografía

**Plus Jakarta Sans**, empaquetada en `assets/fonts/` y declarada en `pubspec.yaml` (familia registrada `PlusJakartaSans`). No hay descarga en runtime.
**JetBrains Mono** (`JetBrainsMono`) para cifras tabulares.

| Rol Material | Tamaño / altura / peso | Uso típico |
|---|---|---|
| `displayLarge` | 36 / 1.22 / 800 / -1.08 | Cifras hero |
| `displayMedium` | 32 / 1.25 / 800 | Cifras de tarjeta grande |
| `displaySmall` | 28 / 1.29 / 800 | — |
| `headlineLarge` | 30 / 1.27 / 700 | Título de pantalla |
| `headlineMedium` | 24 / 1.33 / 700 | Cifra de KPI |
| `headlineSmall` | 20 / 1.4 / 600 | Saludo, hora de cita |
| `titleLarge` | 16 / 1.5 / 600 | Título de sección |
| `titleMedium` | 14 / 1.43 / 600 | Título de tarjeta |
| `titleSmall` | 12 / 1.33 / 600 / +0.24 | Nombre en lista |
| `bodyLarge` | 16 / 1.63 / 400 | Texto largo |
| `bodyMedium` | 14 / 1.57 / 400 | Descripción |
| `bodySmall` | 13 / 1.38 / +0.07 | Metadatos, mediciones |
| `labelLarge` | 16 / 1.5 / 600 | Etiqueta de botón |
| `labelMedium` | 12 / 1.33 / 600 / +0.24 | Etiqueta de control |
| `labelSmall` | 11 / 1.27 / 700 / +0.44 | Overline (usado con `letterSpacing: 0.8` en la tarjeta destacada) |

`AppTypography.data(context)` → monoespaciado 13 / 1.38 / 500 con `tabularFigures`.

## 4. Espacio, radios y tamaños

```
space:  xs 4 · sm 8 · md 16 · lg 24 · xl 32 · xxl 48
radius: xs 4 · sm 8 · md 12 · lg 16 · full 999
control: botón 48 · campo 44 · icono sm 18 · md 24
pantalla: gutter 16 · respiro vertical 24
animación: fast 150 ms · medium 250 ms
```

Regla: **`md` es la unidad de separación entre bloques**; entre elementos de un mismo bloque, `sm`.

## 5. Componentes

| Componente | API | Nota de uso |
|---|---|---|
| `AppButton` | `label`, `onPressed`, `icon`, `variant`, `isLoading` | `primary` acción única de pantalla, `tonal` acción rápida, `secondary` acción de apoyo, `text` baja énfasis. Altura 48 |
| `AppTextField` | etiqueta arriba, foco, submit, autofill | Altura 44; error en `error` con mensaje debajo |
| `AppPill` | `label`, `dotColor`, `icon`, `pulse` | Estados breves ("Con plan", "Sin plan"). El punto es un indicador, no decoración |
| `AppDividerLabel` | separador con etiqueta centrada | Bloques de login |
| `AppEmblem` | isotipo vectorial | Barra superior |
| `AppCard` | contenedor base | Superficie + hairline, radio `md` |
| `AppDrawer` | secciones, ítem activo, tarjeta de perfil, cerrar sesión | Vive en el shell |
| `AppTopBar` | hamburguesa, emblema, marca + sección, avatar con iniciales | Vive en el shell |

Patrones locales todavía dentro de las pantallas (candidatos a componente cuando se repitan):

- **Bloque de métricas** (home): jerarquía, no franja. Una tarjeta principal a ancho completo (chip de icono 44 en `primaryContainer`, etiqueta `titleMedium` y cifra `displayLarge` alineada al borde derecho) y dos tarjetas compactas debajo (chip 32 en `surfaceContainerHighest`, cifra `headlineSmall` y etiqueta `bodySmall`). Superficie `surfaceContainerLowest` con hairline `outlineVariant`, radio `md`. Un `0` se pinta en `onSurfaceVariant`: retrocede en vez de gritar.
- **Avatar de iniciales**: círculo 36 con `surfaceContainerHighest` y `labelMedium`; da identidad a una fila de persona.
- **Tarjeta destacada** (home): `primaryContainer`, hora a la izquierda en `headlineSmall`, overline `PRÓXIMA CITA`, nombre `titleMedium`, motivo `bodySmall`.
- **Fila de lista**: superficie + hairline `outlineVariant`, radio `md`, título `titleSmall` + metadato `bodySmall`, pill a la derecha.

## 6. Anti-patrones (observados en la primera versión de la home)

1. **Tres cajas iguales para tres números**: cada tarjeta deja un tercio vacío y las alturas se desalinean cuando una etiqueta ocupa dos líneas. Tampoco es cierto que las tres importen igual. Se resuelve con jerarquía: una tarjeta principal y dos compactas.
0. **Franja plana de métricas** (intento intermedio, descartado): una sola superficie con divisores quita el hueco pero aplana la jerarquía y no deja lugar a iconografía.
2. **Icono + valor + etiqueta apilados**: tres renglones para un dato. El icono suma solo si va en un chip que ancla la lectura y si el valor ocupa el ancho disponible.
3. **Número sin protección de ancho**: `12 → 1.240` rompe la columna. Usar `FittedBox` o monoespaciado.
4. **Estado vacío que repite el KPI**: "Citas hoy 0" + "No tenés citas hoy" dicen lo mismo; el estado vacío debe aportar la siguiente acción.
5. **Verde saturado en superficies grandes**: `primaryContainer` a pantalla completa compite con el contenido; reservarlo para una sola pieza por pantalla.

## 7. Accesibilidad

- Objetivo táctil mínimo 44 pt (campos) y 48 pt (botones).
- Contraste: texto sobre `primaryContainer` usa `onPrimaryContainer`, no `onSurface`.
- Todo icono que comunica estado lleva etiqueta semántica o texto visible.
- No usar solo color para distinguir estados: el pill suma texto ("Con plan" / "Sin plan").

## 8. Gaps conocidos

- No hay escala de iconografía documentada: se usan `MaterialIcons` a 18 y 24.
- No hay sombras ni elevación definidas: todo el sistema es plano con hairlines.
- No hay tokens de estado de cita (`PROGRAMADA`, `COMPLETADA`, `CANCELADA`) mapeados a color; la home no los muestra todavía.
- La tipografía declara 4 pesos (400/600/700/800); usar 500 con la sans no está registrado y caería en el peso más cercano.
