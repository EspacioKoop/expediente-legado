#!/usr/bin/env bash
# Instala el SDK oficial de Sentry para Godot sin versionar sus binarios.
set -euo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DESTINO="$RAIZ/godot/addons/sentry"
VERSION="${SENTRY_GODOT_VERSION:-2.2.0}"
BUILD="${SENTRY_GODOT_BUILD:-407729a}"
SHA256="${SENTRY_GODOT_SHA256:-539cca58ff4188dafcd1318e03396fa303ea1ae5b2eda6f96a055146af44b156}"
URL="${SENTRY_GODOT_URL:-https://github.com/getsentry/sentry-godot/releases/download/${VERSION}/sentry-godot-${VERSION}%2B${BUILD}.zip}"
MARCADOR="$DESTINO/.siga98-version"

for cmd in curl unzip sha256sum find; do
    command -v "$cmd" >/dev/null 2>&1 || {
        echo "ERROR: falta $cmd para preparar Sentry" >&2
        exit 2
    }
done

if [[ -f "$MARCADOR" ]] && [[ "$(cat "$MARCADOR")" == "$VERSION+$BUILD" ]] && [[ -f "$DESTINO/sentry.gdextension" ]]; then
    echo "Sentry Godot $VERSION+$BUILD ya está preparado."
    exit 0
fi

TEMP="$(mktemp -d)"
trap 'rm -rf "$TEMP"' EXIT
ARCHIVO="$TEMP/sentry.zip"
EXTRAIDO="$TEMP/extract"
mkdir -p "$EXTRAIDO"

echo "Descargando Sentry Godot $VERSION+$BUILD..."
curl --fail --location --retry 3 --output "$ARCHIVO" "$URL"
echo "$SHA256  $ARCHIVO" | sha256sum --check --strict >/dev/null
unzip -q "$ARCHIVO" -d "$EXTRAIDO"

ORIGEN="$(find "$EXTRAIDO" -type d -path '*/addons/sentry' -print -quit)"
if [[ -z "$ORIGEN" ]] || [[ ! -f "$ORIGEN/sentry.gdextension" ]]; then
    echo "ERROR: el release verificado no contiene addons/sentry/sentry.gdextension" >&2
    exit 3
fi

rm -rf "$DESTINO"
mkdir -p "$(dirname "$DESTINO")"
cp -a "$ORIGEN" "$DESTINO"
printf '%s\n' "$VERSION+$BUILD" > "$MARCADOR"

echo "Sentry preparado en godot/addons/sentry ($VERSION+$BUILD)."
