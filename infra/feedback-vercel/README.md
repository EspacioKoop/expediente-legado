# Gateway de feedback en Vercel

Proyecto mínimo para desplegar el endpoint de F9 de SIGA-98.

## Endpoint

`POST /api/report`

La función:

1. valida el payload enviado por el juego;
2. crea un issue en GitHub usando un token almacenado solo en Vercel;
3. opcionalmente envía un correo con Resend;
4. devuelve la URL del issue al juego.

## Variables de entorno

Obligatoria:

- `GITHUB_TOKEN`: token con permiso mínimo para crear issues.

Opcionales:

- `GITHUB_REPOSITORY`: por defecto `EspacioKoop/expediente-legado`.
- `GITHUB_LABELS`: etiquetas existentes separadas por comas.
- `RESEND_API_KEY`
- `REPORT_EMAIL_TO`
- `REPORT_EMAIL_FROM`

## Configurar la alpha

Tras desplegar, usa como repository variable de GitHub:

```text
SIGA98_FEEDBACK_URL=https://<tu-proyecto>.vercel.app/api/report
```

La URL es pública; los secretos no lo son y nunca entran en el ejecutable.
