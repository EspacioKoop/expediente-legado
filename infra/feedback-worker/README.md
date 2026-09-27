# Gateway de feedback F9

Este directorio contiene el gateway serverless primario del Parte de
incidencias de SIGA-98. Cloudflare Workers es el proveedor recomendado; Deno
Deploy actúa como segundo gateway y Vercel queda como tercer respaldo mientras
siga disponible.

El juego **no** habla directamente con la API de GitHub y **no** contiene PAT,
tokens ni credenciales SMTP. Solo conoce URLs HTTPS públicas.

## Arquitectura

```text
F9
 ├─ gateway primario: Cloudflare Worker
 ├─ gateway secundario: Deno Deploy
 ├─ gateway terciario: Vercel
 └─ último recurso: issue de GitHub pre-rellenado + copia local
```

## Contrato HTTP

El endpoint de creación es:

```text
POST /api/report
Content-Type: application/json
```

El payload usa `schema: 1`, `source: siga98-f9`, una categoría permitida,
título y cuerpo. El gateway limita tamaño y formato antes de llamar a GitHub.

Los healthchecks están en `GET /` y `GET /health`.

## Seguridad

Crea un **fine-grained personal access token** de GitHub dedicado a este
servicio:

- acceso únicamente a `EspacioKoop/expediente-legado`;
- permiso de repositorio **Issues: Read and write**;
- ningún permiso de Contents, Actions, Administration o código;
- caducidad corta y rotación periódica.

No reutilices un token personal amplio ni el token de otro servicio.

El Worker protege la creación de issues antes de contactar con GitHub:

- 6 reportes/minuto por origen de red;
- 30 reportes/minuto globales por ubicación Cloudflare;
- el origen de red se convierte a SHA-256 truncado antes de llegar al
  rate-limiter;
- esa información no se incorpora al issue ni se persiste en el repositorio;
- los payloads de más de 24 KiB se rechazan.

El rate limiting es una defensa de abuso, no una autenticación: un cliente
público no puede guardar de forma segura un secreto compartido.

## Despliegue inicial en Cloudflare

Requiere Node.js/npm y una cuenta de Cloudflare Workers.

```bash
cd infra/feedback-worker
npx wrangler@latest login
npx wrangler@latest secret put GITHUB_TOKEN
npx wrangler@latest deploy
```

Wrangler solicita el token de GitHub de forma interactiva. **No lo pongas en la
línea de comandos, en un archivo versionado, en una captura ni en un mensaje.**

El despliegue devolverá una URL parecida a:

```text
https://siga98-feedback.<tu-subdominio>.workers.dev
```

Comprueba el servicio:

```bash
curl -fsS https://siga98-feedback.<tu-subdominio>.workers.dev/health
```

Debe responder con `ok: true` y `github_configured: true`.

El endpoint para el juego es:

```text
https://siga98-feedback.<tu-subdominio>.workers.dev/api/report
```

## Conectar las alphas

En GitHub:

```text
Settings → Secrets and variables → Actions → Variables
SIGA98_FEEDBACK_URL=https://siga98-feedback.<tu-subdominio>.workers.dev/api/report
```

Esta URL **no es un secreto**. El exportador la empaqueta como endpoint
primario. Si también está definida
`SIGA98_FEEDBACK_FALLBACK_URL`, la inserta como segundo gateway (Deno) y
añade después el endpoint Vercel existente. Si los tres fallan, F9 conserva el
reporte localmente y abre un issue pre-rellenado.

La configuración y despliegue de Deno están documentados en
`infra/feedback-deno/README.md`.

## Desarrollo local

Los secretos locales van en `infra/feedback-worker/.dev.vars`; Git los
ignora:

```dotenv
GITHUB_TOKEN=github_pat_...
```

Después:

```bash
cd infra/feedback-worker
npx wrangler@latest dev
```

El cliente solo admite HTTP contra `localhost` o `127.0.0.1`. Cualquier
gateway remoto debe usar HTTPS.

## Variables del Worker

No secretas:

- `GITHUB_REPOSITORY`: configurada en `wrangler.jsonc`.
- `GITHUB_LABELS`: opcional; solo etiquetas que ya existan.

Secrets:

- `GITHUB_TOKEN`: obligatorio.
- `RESEND_API_KEY`, `REPORT_EMAIL_TO`, `REPORT_EMAIL_FROM`: opcionales si
  se quiere conservar también el aviso por correo.

Los secrets deben configurarse con Wrangler o el panel de Cloudflare; nunca en
`wrangler.jsonc`.

## Rotación del token

Para sustituir el token sin tocar código:

```bash
cd infra/feedback-worker
npx wrangler@latest secret put GITHUB_TOKEN
```

Comprueba el healthcheck y revoca después el token anterior en GitHub.
