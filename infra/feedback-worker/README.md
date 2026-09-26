# Gateway de feedback F9

Este directorio contiene un gateway serverless de referencia para el Parte de
incidencias de SIGA-98 (#1460).

El juego **no** habla directamente con la API de GitHub y **no** contiene PAT,
tokens ni credenciales SMTP. Solo conoce una URL HTTPS pública. El gateway
recibe el payload filtrado, crea el issue usando un secreto de servidor y puede
enviar un correo adicional.

## Contrato HTTP

`POST /` con `Content-Type: application/json`:

```json
{
  "schema": 1,
  "source": "siga98-f9",
  "category": "bug",
  "title": "Texto breve",
  "body": "PARTE DE INCIDENCIAS · SIGA-98\n...",
  "diagnostic": {
    "build": "<sha>",
    "plataforma": "windows"
  }
}
```

El gateway ignora campos que no necesita para crear el issue. Valida origen,
categoría, título y tamaño antes de llamar a GitHub.

Respuesta de éxito:

```json
{
  "ok": true,
  "issue_number": 1234,
  "issue_url": "https://github.com/EspacioKoop/expediente-legado/issues/1234",
  "email_sent": false
}
```

## Variables/secrets del servidor

Obligatorias:

- `GITHUB_TOKEN`: token de servidor con permiso mínimo para crear issues en el
  repositorio objetivo.

Opcionales:

- `GITHUB_REPOSITORY`: por defecto `EspacioKoop/expediente-legado`.
- `GITHUB_LABELS`: etiquetas separadas por comas, solo si ya existen.
- `RESEND_API_KEY`: activa el aviso por correo.
- `REPORT_EMAIL_TO`: destinatario del aviso.
- `REPORT_EMAIL_FROM`: remitente verificado por Resend.

El correo usa la API HTTPS de Resend desde el servidor. Ninguna de estas
variables debe copiarse a `godot/datos/incidencias.json`, GitHub Actions
artifacts ni al ejecutable.

## Despliegue

`worker.js` usa únicamente Web APIs estándar y el formato `export default
{ fetch() }` de Cloudflare Workers. Puede desplegarse con Wrangler o adaptarse
sin dependencias a otra función serverless.

Una vez desplegado, crear en GitHub:

```text
Settings → Secrets and variables → Actions → Variables
SIGA98_FEEDBACK_URL=https://<gateway>
```

`.github/workflows/alpha-playtest.yml` pasa esa **URL pública** al exportador.
`dist/exportar-godot-alpha.sh` la inyecta temporalmente en
`godot/datos/incidencias.json` durante el empaquetado.

## Protección frente a abuso

El endpoint es público por necesidad: un secreto incluido en el juego se puede
extraer. Configura rate limiting en el proveedor serverless (por IP y ventana
temporal) y mantén los límites de tamaño/categoría de `worker.js`. El token de
GitHub debe tener el alcance mínimo posible y vivir solo como secreto del
servidor.

## Fallback

Si `SIGA98_FEEDBACK_URL` no está configurada o el POST falla, el juego guarda
una copia local y abre un GitHub Issue pre-rellenado. No usa el portapapeles.
