# Sala de mando

Una web con token para ver el estado de los agentes y dar órdenes desde cualquier sitio, incluido el móvil (#1778).

- **Sala:** issues en cola del pool agrupados por label (`needs-human` primero), PRs abiertas con su estado de CI, reservas vivas de #1713 en las últimas 72 h y `/health` del gateway de producción.
- **Órdenes:** crea un issue. Si eliges «Delegar al pool», le pone `agent:auto` en la misma llamada. Con objetivo y rutas añade un bloque `AGENT_PLAN_BEGIN/END`, sin valla de código, para que el worker se salte el planificador.

La app solo lee GitHub y el gateway; no tiene KV propio. Vive en la org `siga-98` de Deno Deploy, separada del gateway `siga98-feedback-deno` (org `expediente-legado`), así que un fallo aquí no toca la memoria de agentes ni los leases del pool.

## Configuración (variables de Deno Deploy)

| Variable | Qué es |
| --- | --- |
| `MANDO_TOKEN` | Token de acceso, de al menos 32 caracteres. Rotarlo cierra todas las sesiones. |
| `GITHUB_TOKEN` | Token fine-grained limitado a este repo: Issues de lectura y escritura; Pull requests y Metadata de lectura. |
| `GITHUB_REPOSITORY` | Opcional. Por defecto `EspacioKoop/expediente-legado`. |
| `MANDO_GATEWAY_URL` | Opcional. Por defecto el gateway de producción. |

Si falta cualquiera de los dos tokens, todo salvo `/health` responde 503.

## Seguridad

- La sesión es una cookie `caducidad.firma` (HMAC-SHA256 con `MANDO_TOKEN`), válida 30 días, con `HttpOnly`, `Secure` y `SameSite=Strict`.
- Los POST exigen el mismo `Origin` o `Sec-Fetch-Site: same-origin`.
- La CSP es `default-src 'none'` y no hay JavaScript.

## Desarrollo

```bash
deno task check
deno task test
MANDO_TOKEN=... GITHUB_TOKEN=... deno task start
```

`mando-deno.yml` ejecuta formato, tipos y pruebas en cada PR, y al fusionar en `main` despliega con `secrets.DENO_DEPLOY_TOKEN_SIGA98`.
