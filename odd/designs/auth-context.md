# Contexto del flujo de autenticación (para diseñar)

Cómo entra una persona a BaleadaFit: login con correo y contraseña, login con Google, y el registro
de nutricionista que el contrato ya permite y la app **no** tiene.

⚠️ **Estado de verificación:** sale del código de `lib/features/auth/` (leído el 2026-11-19) y del
índice OpenAPI (`baleadafit-api`, 49 endpoints, 90 schemas). No hay capturas de payloads reales de
`/auth/*`.

Complementa `odd/designs/design-system.md` y `odd/tasks/mobile-ui-login.md`.

## 1. Quién es el dueño de las credenciales

**Firebase Authentication**, no la API. La app nunca manda una contraseña a `baleadafit-api`:

```
[correo + contraseña]  ─┐
[Google]               ─┴→ Firebase → ID token (JWT) → cada request: Authorization: Bearer <token>
                                                        ↓
                                            GET /auth/me  → { rol, perfil }
```

Los dos métodos viven en `lib/features/auth/data/auth_gateway.dart`:
`signInWithEmail`, `signInWithGoogle`, `signOut`, `idToken(forceRefresh:)`.

**Con la API hay sólo dos endpoints de `auth`:**

| Endpoint | Para qué |
|---|---|
| `GET /auth/me` | Primera llamada después del login: `rol` (`nutricionista` \| `paciente` \| `sin_perfil`) y `perfil` (objeto sin esquema, `null` si no tiene) |
| `POST /auth/registro-nutricionista` | Crea el perfil de nutricionista para una cuenta de Firebase **sin** perfil: `nombre`, `telefono`, `colegiado` |

No hay endpoint de login, ni de logout, ni de recuperar contraseña, ni de cambiar correo.

## 2. El rol decide toda la navegación

`AuthSession` (`auth_session.dart`) guarda `rol`, `displayName` (sale de `perfil.nombre`) y el
`perfil` crudo. `GET /auth/me` es la bisagra:

- `nutricionista` → la app que conocemos (shell, pacientes, agenda, planes).
- `paciente` → la app del paciente (existe en el contrato, no implementada).
- **`sin_perfil`** → cuenta de Firebase válida sin perfil en la API: es exactamente el estado que
  pide registro. Hoy la app no tiene pantalla para ese estado.

## 3. Errores que la UI tiene que saber dibujar

`auth_failure.dart` ya los distingue; el diseño decide cómo se ven:

| Fallo | Cuándo |
|---|---|
| `InvalidCredentialsFailure` | Firebase rechaza correo/contraseña |
| `NetworkFailure` | Sin red o Firebase no responde |
| `UnauthenticatedFailure` | Hay usuario de Firebase pero `/auth/me` responde 401 |
| `ForbiddenFailure` | 403: rol insuficiente o **correo sin verificar** |
| `SignInCancelledFailure` | El usuario cierra la hoja de Google: no es un error, no debería gritar |
| `UnknownAuthFailure` | Rol que la app no conoce ("Actualizá la app") |

Un detalle de comportamiento que el diseño debe respetar: si `/auth/me` falla después de un login
exitoso, la app **cierra la sesión de Firebase** (`_signIn` → `_signOutQuietly`). No queda una
sesión a medias que se re-autentique sola en el siguiente arranque.

## 4. Lo que existe hoy en pantalla

`login_screen.dart` (rediseño pendiente, ver `mobile-ui-login.md`):

- Encabezado de marca.
- `Correo electrónico` (hint `ejemplo@baleadafit.hn`) y `Contraseña` (hint `••••••••`).
- Enlace `¿Olvidaste tu clave?` que **no recupera nada**: muestra la nota "Pedile a la
  administración que restablezca tu clave."
- Botón primario `Ingresar a mi Consultorio`.
- Separador `o autenticación rápida` y botón `Continuar con Google`.
- Nota `Conexión cifrada con la API`.
- Banners de error y de aviso ya existen (`_ErrorBanner`, `_NoticeBanner`).

**No existe:** pantalla de registro, pantalla de "correo sin verificar", pantalla de `sin_perfil`,
recuperación de contraseña, ni cambio de contraseña. `signOut` existe en el repositorio; su acceso
visual no se documenta acá.

## 5. El registro, con lo que el contrato permite

`POST /auth/registro-nutricionista` toma **tres campos** y usa de Firebase el `uid` y el `correo`
del token:

```json
{ "nombre": "…", "telefono": "…", "colegiado": "…" }
```

- **201** con el perfil creado (`id`, `correo`, `firebaseUid`, `creadoEn`).
- **400** `VALIDACION` con `detalles` por campo.
- **403** si el **correo no está verificado**: con Google siempre lo está; con correo y contraseña
  hay que confirmar el enlace que envía Firebase antes de llamar.
- **409** conflicto: la cuenta ya tiene perfil.
- **401** sin token.

Sobre el alta (leído del board el 2026-11-20, card `registro-nutricionista-sin-aprobacion`):

- `colegiado` es **opcional**: texto libre de hasta 40 caracteres que **no** se valida contra el
  Colegio de Nutricionistas. No es una credencial verificada.
- **El alta es autoservicio y otorga acceso total de inmediato:** tener fila en `nutricionista` ES
  tener acceso a datos de pacientes. Hoy nadie revisa nada.

Consecuencia de diseño: el registro **no es un formulario de alta de cuenta**. La cuenta ya existe
en Firebase; lo que se completa es el perfil profesional. Eso separa el flujo en dos pasos y obliga
a dibujar el estado intermedio "tu correo todavía no está confirmado".

## 6. Qué se puede diseñar (y qué no)

**Se puede, con contrato:**

1. **Login rediseñado** (A1): correo, contraseña, Google, error/aviso, "olvidé mi clave" como nota
   honesta. Sin prometer recuperación.
2. **Registro de nutricionista** (A2): nombre, teléfono, colegiado, con sus errores por campo
   (400), 409 "ya tenés perfil" y el caso 403.
3. **Correo sin verificar** (A3): pantalla con "te mandamos un enlace", reenviar, y qué pasa
   mientras tanto. **Ojo:** reenviar el correo de verificación es una llamada a Firebase, no a la
   API: se puede dibujar, y decidir con el humano si se implementa.
4. **Estado `sin_perfil`** (A4): cuenta válida sin perfil → puerta al registro, sin dejar entrar al
   resto de la app.
5. **Cerrar sesión** (A5): existe en el repositorio; su confirmación no está dibujada en ninguna
   parte.

**No se puede sin inventar:**

- **Recuperar contraseña:** no hay endpoint ni flujo implementado; hoy la app dice "pedile a la
  administración". Diseñarlo como si funcionara sería mentirle al usuario.
- **Registro de paciente:** el contrato no define cómo obtiene acceso un paciente (el rol existe y
  hay endpoints de "mi cuenta (paciente)", pero ningún alta ni invitación). Es un gap del API, no
  un hueco de diseño.
- **Cambiar correo o contraseña desde la app:** no hay endpoint.
- **Borrar la cuenta:** no hay endpoint.

## 7. Gaps del contrato

| # | Gap | Board |
|---|---|---|
| 1 | No hay recuperación de contraseña (Firebase lo soporta, la app no lo expone) | nuevo |
| 2 | No hay forma declarada de que un paciente obtenga acceso | nuevo |
| 3 | `perfil` de `GET /auth/me` es un `object` sin esquema: el cliente lo tipa a mano | nuevo |
| 4 | No hay endpoint para cambiar correo, contraseña ni borrar cuenta | nuevo |
| 5 | El 403 de "correo sin verificar" no trae un código propio que lo distinga de un rol insuficiente | nuevo |

## 8. Decisiones humanas pendientes

1. Si el rediseño incluye **registro** (A2/A3/A4) o sólo el login (A1). Con registro hacen falta las
   tres pantallas del paso intermedio y la llamada a Firebase para reenviar el correo.
2. Si "¿Olvidaste tu clave?" se queda como nota o se convierte en flujo real (depende del gap 1).
3. Tono del mensaje de Google cancelado: hoy es un fallo más; probablemente deba ser silencioso.
4. Si el rediseño dibuja ya las pantallas de **aprobación de cuenta** (A6, ver §10) aunque todavía
   no estén desplegadas, o las deja para cuando salga la nota de cambio.

## 9. Cambios del board (leídos el 2026-11-20)

**Card `baleadafit-api/auth` · `registro-nutricionista-sin-aprobacion`** (actualizada el
2026-11-20): la aprobación de cuentas está **acordada y en implementación**, en la rama
`feat/verificacion-nutricionista`, y **no está desplegada**.

- Un solo `estado` sobre el perfil: `PENDIENTE | APROBADO | RECHAZADO`. Default `APROBADO` en la
  migración (para no cortarle el acceso a las nutricionistas existentes) y `PENDIENTE` explícito en
  el alta nueva.
- Cuando salga, `GET /auth/me` va a traer `estado` dentro del perfil y el rol va a poder ser
  `nutricionista_pendiente`.
- Un perfil `PENDIENTE` o `RECHAZADO` recibe **403 `SIN_PERMISO`** en todo lo que cuelga de la
  nutricionista (pacientes, planes, citas, alimentos, IA); sólo puede seguir editando su perfil.
- El admin es una lista de correos en configuración (`ADMIN_CORREOS`), no un rol del dominio.
- La verificación de correo **no** suma SES: el token de Firebase ya trae `email_verified` y el alta
  responde 403 sin él. Contratar SES duplicaría algo que ya funciona.

Gotchas que ni el código ni el spec dicen:

- No hay ningún endpoint para que una nutricionista edite su **nombre, teléfono ni colegiado**: se
  guardan al registrarse y quedan congelados (`mi-cuenta` no tiene PATCH de perfil).
- El **paciente nunca se autorregistra**: lo crea la nutricionista con `POST /pacientes`.
- En desarrollo `AUTH_DEV_BYPASS` devuelve `emailVerificado: true` siempre: el camino del 403 por
  correo sin verificar no se puede probar con tokens de desarrollo.

## 10. Qué implica para el diseño

1. **No programar contra `estado` ni `/admin` todavía**: el contrato desplegado no los tiene. El
   diseño sí puede dibujarlos, marcados como "pendiente de despliegue".
2. **Faltan dos pantallas** para cuando salga: `cuenta en revisión` (rol
   `nutricionista_pendiente`) y `cuenta rechazada` con su motivo. Sin ellas, un perfil pendiente cae
   en una pantalla vacía con 403 en todo.
3. **El perfil profesional es de sólo lectura**: no diseñar "editar datos" hasta que exista el
   PATCH. Si hace falta, es tarjeta al BE.
4. **Cuidado con lo que promete la pantalla de alta**: hoy el registro otorga acceso inmediato; una
   vez desplegada la aprobación, prometer "acceso al instante" sería falso. La copia tiene que
   sobrevivir a los dos estados.
