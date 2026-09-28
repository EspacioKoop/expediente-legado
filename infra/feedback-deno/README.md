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

- el endpoint público de juego acepta POST únicamente en `/api/report`; las APIs de agentes son privadas y exigen OIDC de GitHub Actions;
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

## Control-plane de la pool de agentes

El mismo KV coordina la exclusión por issue de la pool mediante endpoints privados:

- `POST /api/agent-pool/acquire`: crea un lease atómico si el issue está libre;
- `POST /api/agent-pool/transition`: renueva el TTL y registra la fase;
- `POST /api/agent-pool/release`: libera el lease del run propietario;
- `POST /api/agent-pool/status`: permite al dispatcher excluir leases activos;
- `POST /api/agent-pool/worker-health/status`: devuelve circuit breakers activos por worker;
- `POST /api/agent-pool/worker-health/report`: abre o cierra el circuit breaker de un worker.

Usa una audiencia OIDC separada, `siga98-agent-pool`. El dispatcher `agent-pool.yml` solo puede consultar estado; `agent-worker.yml` puede adquirir, renovar y liberar. Cuando el worker se ejecuta como reusable workflow se valida además la pareja `workflow_ref=agent-pool.yml` + `job_workflow_ref=agent-worker.yml`.

Cada lease dura **30 minutos** y se renueva por fase. Las transiciones y los leases se escriben con `Deno.Kv.atomic().check(...)`, evitando dos adquisiciones simultáneas. Los eventos compactos de transición se conservan 7 días para poder medir el embudo real sin usar un workflow verde como proxy de éxito.

Durante la migración (#1728) los workflows son deliberadamente fail-open si el gateway no está disponible: siguen usando `concurrency`, labels y CLAIM/RELEASE. Un `409 leased` sí bloquea el worker duplicado. El health de workers usa Deno KV como fuente primaria; los marcadores `AGENT_POOL_SLOT_UNHEALTHY/HEALTHY` de #1713 quedan como fallback mientras conviven ambas capas.

Los circuit breakers de workers se almacenan con TTL. El cliente puede solicitar cooldown, pero el servidor lo limita a **5 minutos–6 horas**. Un fallo de cuota reportado por `agent-worker.yml` abre el circuito; un `agent-provider-smoke.yml` verde lo cierra inmediatamente. El smoke usa OIDC y solo recibe `id-token: write`, no permisos de escritura sobre Contents, Issues ni PRs.

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

### Deploy tras cambiar el gateway

`.github/workflows/feedback-deno-deploy.yml` se dispara al integrar en `main`
cambios bajo `infra/feedback-deno/` y también admite `workflow_dispatch`. Primero
ejecuta `deno task check`; después, si existe `secrets.DENO_DEPLOY_TOKEN`, usa el
CLI moderno `deno deploy` para publicar `siga98-feedback-deno` en producción.

El token puede ser un token de organización de Deno Deploy y solo se inyecta en
el paso de despliegue. Si falta, el workflow deja un warning y termina sin
romper el resto del repositorio; el smoke periódico seguirá señalando la deriva.

Tras desplegar, si `SIGA98_FEEDBACK_FALLBACK_URL` está configurada, el workflow
espera hasta un minuto a que `/health` refleje el contrato declarado por
`main.ts` y lo valida con `scripts/check_deno_production.py`. Esto evita que un
merge correcto deje silenciosamente producción en una versión antigua.

## Freshness de producción

`.github/workflows/feedback-deno-production-smoke.yml` compara periódicamente el `/health` desplegado con el contrato declarado por `main.ts`. Extrae la versión y las features `agent_*=true` directamente del source, por lo que no hay que mantener otro número de versión en YAML.

El smoke corre tras cambios del gateway integrados en `main`, cada seis horas y por `workflow_dispatch`. No corre en pull requests: una PR que sube la versión no debe fallar solo porque producción todavía sirve la versión anterior antes del merge. Tras integrar el cambio, el check falla hasta que se haga `deno deploy --prod`, dejando visible la deriva que antes aparecía como 404 silencioso en los agentes.

## Healthcheck

```bash
curl -fsS https://siga98-feedback-deno.<tu-organizacion>.deno.net/health
```

Debe responder con:

```json
{
  "ok": true,
  "service": "siga98-feedback-deno",
  "version": 4,
  "github_configured": true,
  "kv_configured": true,
  "agent_memory": true,
  "agent_pool_control": true,
  "agent_pool_worker_health": true
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
