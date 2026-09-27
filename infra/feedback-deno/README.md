# Fallback F9 en Deno Deploy

Gateway secundario para el Parte de incidencias de SIGA-98.

La cadena prevista es:

```text
Cloudflare -> Deno Deploy -> Vercel -> issue pre-rellenado + copia local
```

Deno no comparte credenciales con el juego. El cliente solo recibe una URL HTTPS
pública. `GITHUB_TOKEN` vive como secret del servicio.

## Seguridad

El servicio:

- acepta POST únicamente en `/api/report`;
- exige `schema: 1` y `source: siga98-f9`;
- limita el cuerpo a 24 KiB comprobando también los bytes realmente recibidos;
- limita a 6 reportes/minuto por origen y 30/minuto global mediante Deno KV;
- transforma la dirección de red con HMAC-SHA-256 antes de usarla como clave;
- no guarda la dirección de red en GitHub;
- falla cerrado con HTTP 503 si Deno KV no está disponible;
- no devuelve detalles internos de errores upstream.

El HMAC reutiliza `GITHUB_TOKEN` como clave únicamente para derivar la clave
efímera del rate limiter. El token nunca se devuelve, registra ni persiste en KV.

## Despliegue

Usa el Deno Deploy actual en `https://console.deno.com`, no Deploy Classic.

Se necesita:

1. una organización Deno Deploy;
2. una aplicación, por ejemplo `siga98-feedback-deno`;
3. una base Deno KV asignada a la aplicación;
4. `GITHUB_TOKEN` como **Secret**;
5. `GITHUB_REPOSITORY=EspacioKoop/expediente-legado` como variable normal.

El PAT debe ser fine-grained y limitarse al repositorio
`EspacioKoop/expediente-legado`, con **Issues: Read and write** y sin permisos
de Contents, Actions o Administration.

Desde este directorio, con Deno reciente:

```bash
deno deploy create
deno deploy database provision siga98-feedback-kv --kind denokv
deno deploy database assign siga98-feedback-kv --app siga98-feedback-deno
```

Después configura `GITHUB_TOKEN` como secret desde el panel de Deno Deploy
(Settings -> Environment Variables), evitando pasarlo por historial de shell.

Configura también:

```text
GITHUB_REPOSITORY=EspacioKoop/expediente-legado
```

y despliega:

```bash
deno deploy --app siga98-feedback-deno --prod
```

La CLI autentica mediante el flujo de Deno Deploy y guarda su token de
autenticación en el keyring del sistema.

## Healthcheck

```bash
curl -fsS https://siga98-feedback-deno.<tu-organizacion>.deno.net/health
```

Debe responder con:

```json
{
  "ok": true,
  "service": "siga98-feedback-deno",
  "version": 1,
  "github_configured": true,
  "kv_configured": true
}
```

No añadas la URL a las builds hasta que ambos indicadores sean `true`.

## Conectar las alphas

En GitHub Actions añade una variable pública:

```text
SIGA98_FEEDBACK_FALLBACK_URL=https://siga98-feedback-deno.<tu-organizacion>.deno.net/api/report
```

El exportador conservará `SIGA98_FEEDBACK_URL` como primario y añadirá este
endpoint antes del fallback Vercel.
