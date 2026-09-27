# CI brain y memoria SQLite/Turso

Este servicio resume la salud de GitHub Actions sin guardar logs completos,
capturas ni artefactos. La fuente de verdad del código y del trabajo sigue
siendo GitHub; esta base es memoria técnica auxiliar.

## Qué guarda

- run ID, workflow, SHA/rama, evento, resultado y duración;
- job ID, nombre, resultado y duración;
- recuerdos técnicos de hasta 2.000 caracteres con metadata JSON acotada;
- agregados de jobs que han fallado al menos dos veces en los últimos 30 días.

El snapshot local se poda a 120 días por defecto. Con ese esquema, incluso
miles de ejecuciones ocupan muy poco frente a logs o artefactos.

## Uso local

No necesita dependencias externas:

```bash
export GH_TOKEN=...
export GITHUB_REPOSITORY=EspacioKoop/expediente-legado
python3 scripts/ci_brain.py collect
python3 scripts/ci_brain.py summary
```

Memoria manual:

```bash
python3 scripts/ci_brain.py remember \
  --kind workaround \
  --key gdformat-call-layout \
  --summary "Los tests textuales deben tolerar el reflow de gdformat."

python3 scripts/ci_brain.py recall --query gdformat
```

## Nube opcional con Turso

Turso es compatible con SQLite/libSQL. El cliente de este repo usa directamente
Hrana sobre HTTPS, así que no instala un SDK adicional.

Crea una base, recupera su URL y emite un token con la CLI de Turso. Después
configura en GitHub:

- variable de Actions `TURSO_DATABASE_URL` (normalmente `libsql://...`);
- secret de Actions `TURSO_AUTH_TOKEN`.

El workflow **CI brain** se ejecuta cada hora. Si ambos valores están presentes,
replica el snapshot a Turso mediante `/v2/pipeline`. Si ninguno existe, no
falla: deja SQLite + resumen como artifact durante 14 días. Una configuración a
medias sí falla para evitar creer que existe memoria remota cuando no la hay.

## Relación con #1551

#1551 implementa la memoria **caliente** de agentes en Deno KV, con TTL y OIDC.
Este corte aporta la memoria **fría/histórica**:

```text
GitHub / CI
    │
    ├── Deno KV (#1551)   → contexto temporal de agentes
    │
    └── SQLite / Turso    → historial CI + recuerdos técnicos compactos
```

No se modifica el autopilot mientras #1551 tenga esos archivos reservados. Una
vez integrado #1551, `remember`/`recall` pueden convertirse en una fuente
fría adicional sin cambiar #182 ni las Normas Platino.

## Seguridad y límites

- no se guardan secretos;
- no se guardan logs completos;
- el token Turso vive solo como Actions secret;
- la URL se valida como `libsql://` o HTTPS;
- el protocolo remoto comprueba errores Hrana aunque el HTTP sea 2xx;
- ningún recuerdo concede permisos ni sustituye CLAIM/PR_READY/RELEASE.
