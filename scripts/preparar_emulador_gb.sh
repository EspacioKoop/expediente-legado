#!/usr/bin/env bash
# Prepara la GDExtension GB/GBC y/o la ROM propia de #124 de forma reproducible.
set -euo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NATIVO="$RAIZ/godot/native/siga98_gb"
LOCK="$NATIVO/deps.lock.json"
MODO="${1:-linux-debug}"

if command -v python3 >/dev/null 2>&1; then
    PYTHON=python3
else
    PYTHON=python
fi

leer_lock() {
    "$PYTHON" - "$LOCK" "$1" "$2" <<'PY'
import json
import sys

ruta, grupo, campo = sys.argv[1:]
with open(ruta, encoding="utf-8") as archivo:
    datos = json.load(archivo)
print(datos[grupo][campo] if grupo else datos[campo])
PY
}

GODOT_CPP_REPO="$(leer_lock godot_cpp repository)"
GODOT_CPP_SHA="$(leer_lock godot_cpp commit)"
PEANUT_REPO="$(leer_lock peanut_gb repository)"
PEANUT_SHA="$(leer_lock peanut_gb commit)"
SAMEBOY_REPO="$(leer_lock sameboy repository)"
SAMEBOY_SHA="$(leer_lock sameboy commit)"
SCONS_VERSION="$("$PYTHON" - "$LOCK" <<'PY'
import json
import sys
with open(sys.argv[1], encoding="utf-8") as archivo:
    print(json.load(archivo)["scons"])
PY
)"
DEPS="$NATIVO/.deps"
GODOT_CPP="$DEPS/godot-cpp"
PEANUT="$DEPS/peanut-gb"
SAMEBOY="$DEPS/sameboy"

preparar_repo() {
    local repo="$1"
    local sha="$2"
    local destino="$3"
    local submodulos="$4"
    if [ -d "$destino/.git" ] && [ "$(git -C "$destino" rev-parse HEAD 2>/dev/null || true)" = "$sha" ]; then
        return
    fi
    rm -rf "$destino"
    mkdir -p "$destino"
    git -C "$destino" init -q
    git -C "$destino" remote add origin "$repo"
    git -C "$destino" fetch --depth 1 origin "$sha"
    git -C "$destino" checkout --detach -q FETCH_HEAD
    test "$(git -C "$destino" rev-parse HEAD)" = "$sha"
    if [ "$submodulos" = "si" ]; then
        git -C "$destino" submodule update --init --recursive --depth 1
    fi
}

compilar_nativo() {
    local plataforma="$1"
    local objetivo="$2"
    mkdir -p "$DEPS"
    preparar_repo "$GODOT_CPP_REPO" "$GODOT_CPP_SHA" "$GODOT_CPP" si
    preparar_repo "$PEANUT_REPO" "$PEANUT_SHA" "$PEANUT" no
    preparar_repo "$SAMEBOY_REPO" "$SAMEBOY_SHA" "$SAMEBOY" no
    "$PYTHON" -m pip install --disable-pip-version-check --quiet "scons==$SCONS_VERSION"
    (
        cd "$NATIVO"
        scons -Q \
            platform="$plataforma" \
            target="$objetivo" \
            arch=x86_64 \
            build_profile=build_profile.json \
            godot_cpp_dir="$GODOT_CPP" \
            peanut_gb_dir="$PEANUT" \
            sameboy_dir="$SAMEBOY"
    )
}

# Compila TODAS las ROMs jugables del índice godot/datos/roms_propias.json y
# las deja en godot/roms/<id>.gbc. Una ROM en proyecto no tiene fuente y se omite.
compilar_rom() {
    mkdir -p "$RAIZ/godot/roms"
    local id
    while read -r id; do
        make -C "$RAIZ/gbc/minijuegos/$id" clean all
        cp "$RAIZ/gbc/minijuegos/$id/build/$id.gbc" "$RAIZ/godot/roms/$id.gbc"
    done < <("$PYTHON" - "$RAIZ/godot/datos/roms_propias.json" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as archivo:
    for rom in json.load(archivo)["roms"]:
        if rom["estado"] == "jugable":
            print(rom["id"])
PY
)
}

case "$MODO" in
    linux-debug)
        compilar_nativo linux template_debug
        ;;
    linux-all)
        compilar_nativo linux template_debug
        compilar_nativo linux template_release
        ;;
    windows-release)
        compilar_nativo windows template_release
        ;;
    rom)
        compilar_rom
        ;;
    todo-linux)
        compilar_nativo linux template_debug
        compilar_nativo linux template_release
        compilar_rom
        ;;
    *)
        echo "Uso: $0 {linux-debug|linux-all|windows-release|rom|todo-linux}" >&2
        exit 2
        ;;
esac
