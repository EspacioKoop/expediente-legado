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
SAMEBOY_REPO="$(leer_lock sameboy repository)"
SAMEBOY_SHA="$(leer_lock sameboy commit)"
BOOT_ROM_SHA="$("$PYTHON" -c 'import json,sys; print(json.load(open(sys.argv[1], encoding="utf-8"))["sameboy"]["boot_rom"]["sha256"])' "$LOCK")"
SCONS_VERSION="$("$PYTHON" - "$LOCK" <<'PY'
import json
import sys
with open(sys.argv[1], encoding="utf-8") as archivo:
    print(json.load(archivo)["scons"])
PY
)"
DEPS="$NATIVO/.deps"
GODOT_CPP="$DEPS/godot-cpp"
BOOTROMS="$DEPS/bootroms"
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

# Compila la boot ROM CGB libre de SameBoy (Expat) desde el commit fijado. Nunca
# se usa ni se descarga la BIOS de Nintendo. Requiere RGBDS y un compilador C.
compilar_boot_rom() {
    local salida="$BOOTROMS/cgb_boot_fast.bin"
    local obj="$BOOTROMS/obj"
    mkdir -p "$DEPS"
    preparar_repo "$SAMEBOY_REPO" "$SAMEBOY_SHA" "$SAMEBOY" no
    rm -rf "$BOOTROMS"
    mkdir -p "$obj"
    "${CC:-cc}" -std=c99 -Wall -Werror "$SAMEBOY/BootROMs/pb12.c" -o "$obj/pb12"
    rgbgfx -Z -u -c embedded -o "$obj/SameBoyLogo.2bpp" "$SAMEBOY/BootROMs/SameBoyLogo.png"
    "$obj/pb12" < "$obj/SameBoyLogo.2bpp" > "$obj/SameBoyLogo.pb12"
    rgbasm --include "$obj/" --include "$SAMEBOY/BootROMs/" \
        -o "$obj/cgb_boot_fast.o" "$SAMEBOY/BootROMs/cgb_boot_fast.asm"
    rgblink -x -o "$salida" "$obj/cgb_boot_fast.o"
    echo "$BOOT_ROM_SHA  $salida" | sha256sum --check --strict
}

# scons se instala en un entorno virtual propio dentro de .deps/ (ya ignorado).
# Un `pip install` contra el Python del sistema funciona en el runner de CI pero
# falla con `externally-managed-environment` (PEP 668) en cualquier Debian o
# Ubuntu reciente, que es donde se desarrolla: el venv hace la orden idéntica en
# las dos máquinas sin tocar nada fuera del repo.
preparar_scons() {
    local venv="$DEPS/venv"
    SCONS="$venv/bin/scons"
    if [ -x "$SCONS" ] && "$SCONS" --version 2>/dev/null | grep -qF "$SCONS_VERSION"; then
        return
    fi
    "$PYTHON" -m venv "$venv"
    "$venv/bin/python" -m pip install --disable-pip-version-check --quiet \
        "scons==$SCONS_VERSION"
}

compilar_nativo() {
    local plataforma="$1"
    local objetivo="$2"
    mkdir -p "$DEPS"
    preparar_repo "$GODOT_CPP_REPO" "$GODOT_CPP_SHA" "$GODOT_CPP" si
    preparar_repo "$SAMEBOY_REPO" "$SAMEBOY_SHA" "$SAMEBOY" no
    if [ ! -f "$BOOTROMS/cgb_boot_fast.bin" ]; then
        compilar_boot_rom
    fi
    preparar_scons
    (
        cd "$NATIVO"
        "$SCONS" -Q \
            platform="$plataforma" \
            target="$objetivo" \
            arch=x86_64 \
            build_profile=build_profile.json \
            godot_cpp_dir="$GODOT_CPP" \
            sameboy_dir="$SAMEBOY" \
            boot_rom="$BOOTROMS/cgb_boot_fast.bin"
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
    boot-rom)
        compilar_boot_rom
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
        echo "Uso: $0 {linux-debug|linux-all|windows-release|boot-rom|rom|todo-linux}" >&2
        exit 2
        ;;
esac
