# Sentry en las alphas de SIGA-98

La integración es **opt-in**. Si Actions no tiene el secret `SENTRY_DSN`, la
alpha se construye exactamente como antes y no descarga ni carga Sentry.

## Qué se instala

`scripts/preparar_sentry.sh` descarga el release oficial fijado de
`getsentry/sentry-godot`, verifica su SHA-256 y copia únicamente
`addons/sentry` al proyecto. Los binarios no se versionan.

El primer corte fija Sentry Godot 2.2.0 (build 407729a). El proyecto usa Godot
4.7, dentro de la línea soportada por el SDK 2.x.

## Activarlo en GitHub Actions

1. Crea un proyecto **Godot** en Sentry.
2. Copia el DSN del proyecto.
3. En GitHub abre **Settings → Secrets and variables → Actions**.
4. Crea el repository secret `SENTRY_DSN`.

No hace falta añadir un token de administración de Sentry. El DSN solo se
inyecta en el checkout efímero de `export-alpha` antes de importar/exportar.

Cada build queda identificado con:

- `release=siga98@<GITHUB_SHA>`;
- `environment=alpha`;
- `dist=<GITHUB_RUN_ID>.<GITHUB_RUN_ATTEMPT>`.

El tracing de rendimiento queda desactivado (`0.0`) en este corte: buscamos
primero errores y crashes sin aumentar tráfico ni coste de forma accidental.

## Desarrollo local

Para instalar el SDK sin comprometer binarios:

```bash
bash scripts/preparar_sentry.sh
```

Para una prueba local explícita puedes trabajar sobre una copia temporal de
`project.godot`:

```bash
python3 scripts/configurar_sentry.py \
  --project /tmp/project.godot \
  --dsn "$SENTRY_DSN" \
  --release "siga98@local" \
  --environment local
```

No pegues el DSN en archivos versionados. `godot/addons/sentry/` está
ignorado porque se regenera desde el release verificado.

## Relación con F9

Sentry cubre telemetría automática (errores, excepciones y crashes). El
reportador F9 sigue siendo la vía para contexto humano, problemas visuales,
diseño, UX y fallos que no generan una excepción. Ninguno sustituye al otro.

## Límites del primer corte

- No crea automáticamente issues de GitHub desde Sentry.
- No sube símbolos de depuración a Sentry.
- No habilita performance tracing.
- No afirma que un crash real haya sido recibido hasta configurar el DSN y
  comprobar una alpha exportada.
