#!/usr/bin/env bash
# Descarga, verifica y ejecuta la última alpha de playtest publicada desde main.
set -euo pipefail

REPO="EspacioKoop/expediente-legado"
CANAL="playtest-latest"
BASE_URL="https://github.com/$REPO/releases/download/$CANAL"

PLATAFORMA=""
FORZAR=0
NO_EJECUTAR=0
DESTINO_EXPLICITO=""

uso() {
    cat <<'EOF'
Uso: bash scripts/playtest.sh [opciones]

Actualiza la alpha de playtest desde GitHub solo cuando cambia el SHA y,
si corresponde a la plataforma anfitriona, la ejecuta.

Opciones:
  --platform linux|windows  Fuerza la plataforma a descargar.
  --force                   Vuelve a descargar aunque el SHA coincida.
  --no-run                  Instala/actualiza sin arrancar el juego.
  --dir RUTA                Usa RUTA como directorio de instalación.
  -h, --help                Muestra esta ayuda.

Variables:
  SIGA98_PLAYTEST_DIR        Directorio de instalación alternativo.
EOF
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --platform)
            [ "$#" -ge 2 ] || { echo "ERROR: falta valor para --platform" >&2; exit 2; }
            PLATAFORMA="$2"
            shift 2
            ;;
        --force)
            FORZAR=1
            shift
            ;;
        --no-run)
            NO_EJECUTAR=1
            shift
            ;;
        --dir)
            [ "$#" -ge 2 ] || { echo "ERROR: falta valor para --dir" >&2; exit 2; }
            DESTINO_EXPLICITO="$2"
            shift 2
            ;;
        -h|--help)
            uso
            exit 0
            ;;
        *)
            echo "ERROR: opción desconocida: $1" >&2
            uso >&2
            exit 2
            ;;
    esac
done

case "$(uname -s)" in
    Linux*) HOST_PLATAFORMA="linux" ;;
    MINGW*|MSYS*|CYGWIN*) HOST_PLATAFORMA="windows" ;;
    *)
        HOST_PLATAFORMA="desconocida"
        ;;
esac

if [ -z "$PLATAFORMA" ]; then
    if [ "$HOST_PLATAFORMA" = "desconocida" ]; then
        echo "ERROR: plataforma no reconocida; usa --platform linux|windows" >&2
        exit 2
    fi
    PLATAFORMA="$HOST_PLATAFORMA"
fi

case "$PLATAFORMA" in
    linux|windows) ;;
    *)
        echo "ERROR: --platform debe ser linux o windows" >&2
        exit 2
        ;;
esac

for comando in curl python3 unzip sha256sum awk; do
    command -v "$comando" >/dev/null 2>&1 || {
        echo "ERROR: falta la dependencia '$comando'" >&2
        exit 1
    }
done

if [ -n "$DESTINO_EXPLICITO" ]; then
    INSTALACION="$DESTINO_EXPLICITO"
elif [ -n "${SIGA98_PLAYTEST_DIR:-}" ]; then
    INSTALACION="$SIGA98_PLAYTEST_DIR/$PLATAFORMA"
else
    : "${HOME:?ERROR: HOME no está definido; usa --dir}"
    INSTALACION="${XDG_DATA_HOME:-$HOME/.local/share}/siga98-playtest/$PLATAFORMA"
fi

ASSET="SIGA-98-playtest-$PLATAFORMA.zip"
CHECKSUMS="SIGA-98-playtest-SHA256SUMS.txt"
METADATOS="SIGA-98-playtest-build.json"

TEMP="$(mktemp -d)"
STAGING=""
limpiar() {
    rm -rf "$TEMP"
    if [ -n "$STAGING" ] && [ -d "$STAGING" ]; then
        rm -rf "$STAGING"
    fi
}
trap limpiar EXIT

echo "Consultando la última alpha de playtest..."
if ! curl --fail --location --retry 3 --silent --show-error     "$BASE_URL/$METADATOS" -o "$TEMP/$METADATOS"; then
    cat >&2 <<EOF
ERROR: todavía no hay un canal '$CANAL' descargable o GitHub no responde.
Revisa el workflow "Alpha playtest" en:
https://github.com/$REPO/actions
EOF
    exit 1
fi

SHA_REMOTO="$(python3 - "$TEMP/$METADATOS" <<'PY'
import json
from pathlib import Path
import sys

datos = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
sha = str(datos.get("sha", "")).strip()
if len(sha) < 7:
    raise SystemExit("metadatos de playtest sin SHA válido")
print(sha)
PY
)"

SHA_LOCAL=""
METADATOS_LOCALES="$INSTALACION/.playtest-build.json"
if [ -f "$METADATOS_LOCALES" ]; then
    SHA_LOCAL="$(python3 - "$METADATOS_LOCALES" <<'PY'
import json
from pathlib import Path
import sys

try:
    datos = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
except (OSError, json.JSONDecodeError):
    print("")
else:
    print(str(datos.get("sha", "")).strip())
PY
)"
fi

if [ "$PLATAFORMA" = "linux" ]; then
    EJECUTABLE="$INSTALACION/SIGA-98.x86_64"
else
    EJECUTABLE="$INSTALACION/SIGA-98.exe"
fi

if [ "$FORZAR" -eq 0 ] && [ "$SHA_LOCAL" = "$SHA_REMOTO" ] && [ -f "$EJECUTABLE" ]; then
    echo "Ya tienes la alpha actual: ${SHA_REMOTO:0:12}"
else
    echo "Descargando alpha ${SHA_REMOTO:0:12} para $PLATAFORMA..."
    curl --fail --location --retry 3 --progress-bar         "$BASE_URL/$ASSET" -o "$TEMP/$ASSET"
    curl --fail --location --retry 3 --silent --show-error         "$BASE_URL/$CHECKSUMS" -o "$TEMP/$CHECKSUMS"

    ESPERADO="$(awk -v archivo="$ASSET" '$2 == archivo {print $1; exit}' "$TEMP/$CHECKSUMS")"
    if [ -z "$ESPERADO" ]; then
        echo "ERROR: $CHECKSUMS no contiene checksum para $ASSET" >&2
        exit 1
    fi
    REAL="$(sha256sum "$TEMP/$ASSET" | awk '{print $1}')"
    if [ "$REAL" != "$ESPERADO" ]; then
        echo "ERROR: checksum SHA-256 inválido para $ASSET" >&2
        echo "esperado: $ESPERADO" >&2
        echo "obtenido: $REAL" >&2
        exit 1
    fi

    mkdir -p "$(dirname "$INSTALACION")"
    STAGING="$INSTALACION.staging.$$"
    RESPALDO="$INSTALACION.previous.$$"
    rm -rf "$STAGING" "$RESPALDO"
    mkdir -p "$STAGING"
    unzip -q "$TEMP/$ASSET" -d "$STAGING"
    cp "$TEMP/$METADATOS" "$STAGING/.playtest-build.json"

    if [ "$PLATAFORMA" = "linux" ]; then
        chmod +x "$STAGING/SIGA-98.x86_64"
    fi

    if [ -e "$INSTALACION" ]; then
        mv "$INSTALACION" "$RESPALDO"
    fi
    if mv "$STAGING" "$INSTALACION"; then
        STAGING=""
        rm -rf "$RESPALDO"
    else
        if [ -e "$RESPALDO" ]; then
            mv "$RESPALDO" "$INSTALACION"
        fi
        echo "ERROR: no se pudo instalar la alpha nueva" >&2
        exit 1
    fi

    echo "Alpha instalada y verificada: ${SHA_REMOTO:0:12}"
fi

if [ "$NO_EJECUTAR" -eq 1 ]; then
    echo "Lista en: $INSTALACION"
    exit 0
fi

if [ "$PLATAFORMA" != "$HOST_PLATAFORMA" ]; then
    echo "Descarga completada para $PLATAFORMA; no se ejecuta desde $HOST_PLATAFORMA."
    echo "Lista en: $INSTALACION"
    exit 0
fi

if [ ! -f "$EJECUTABLE" ]; then
    echo "ERROR: falta el ejecutable esperado: $EJECUTABLE" >&2
    exit 1
fi

echo "Arrancando SIGA-98..."
exec "$EJECUTABLE"
