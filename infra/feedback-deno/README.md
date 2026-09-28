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

## Memoria temporal de agentes

El mismo Deno KV ofrece dos endpoints privados para Qwen/Gemini:

- `POST /api/agent-memory/search`
- `POST /api/agent-memory/remember`

No usan `GITHUB_TOKEN` como credencial del cliente. Los workflows solicitan a GitHub Actions un token **OIDC** efímero con audiencia `siga98-agent-memory`. El gateway valida la firma RS256 contra el JWKS oficial de GitHub y el claim `repository`. Para ejecuciones directas admite `agent-autopilot.yml`, `agent-ci-repair.yml` y `agent-worker.yml`; cuando el worker es reutilizable exige además que `workflow_ref` sea `agent-pool.yml` y que `job_workflow_ref` identifique `agent-worker.yml`, evitando autorizar al dispatcher por sí solo.

La memoria es deliberadamente pequeña: TTL de 30 días, hasta 1200 caracteres por resumen, 8 tags, 12 rutas, búsqueda sobre los 50 registros recientes y devolución máxima de 8 resultados. Los resúmenes con patrones de credenciales se rechazan.

El repositorio, los issues, #181/#182, CI y las Normas Platino siguen siendo la fuente de verdad. La wiki es memoria consolidada en solo lectura; Deno KV es únicamente memoria operativa transitoria.

No hace falta crear otro secret en GitHub ni en Deno. La única dependencia adicional del runtime es acceso saliente a `token.actions.githubusercontent.com` para validar los tokens OIDC.

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
deno deploy --prod
```

La organización (`expediente-legado`) y la aplicación (`siga98-feedback-deno`)
están versionadas en el bloque `deploy` de `deno.json`: sin `org`, la CLI
aborta con `missing field 'org'`. Despliega siempre desde este directorio; un
`--config` que apunte fuera de él hace que la subida falle con «source upload
did not arrive intact». Sin `--prod` crea solo un preview, útil para probar
antes de promocionar. La CLI puede reescribir `deno.json` al desplegar; pasa
`deno fmt deno.json` antes de comitear o CI fallará en «Formato».

La CLI autentica mediante el flujo de Deno Deploy y guarda su token de
autenticación en el keyring del sistema.

### Redeploy tras cambiar el gateway

`feedback-deno.yml` solo comprueba formato y tipos: **no despliega**. Tras
integrar en `main` cualquier cambio de `main.ts` o `agent_memory.ts`, vuelve a
desplegar con `--prod` y compara el `/health` de producción con el de
`main.ts`. Si no coinciden, producción sigue sirviendo una versión antigua; así
se produjo el 404 de `/api/agent-memory/search` de #1606, con producción aún en
`version: 1` y el repo ya en `version: 2`.

## Healthcheck

```bash
curl -fsS https://siga98-feedback-deno.<tu-organizacion>.deno.net/health
```

Debe responder con:

```json
{
  "ok": true,
  "service": "siga98-feedback-deno",
  "version": 2,
  "github_configured": true,
  "kv_configured": true,
  "agent_memory": true
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
