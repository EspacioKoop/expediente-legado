#!/usr/bin/env bash
# Deja la máquina lista para ejecutar los gates de calidad en una sola orden.
#
# Los pasos ya existían por separado y ninguno era descubrible: quien clonaba el
# repo ejecutaba la suite, veía fallar pruebas por una GDExtension sin compilar o
# unas ROMs ausentes, y el rastro no decía qué faltaba. Aquí se encadenan, son
# idempotentes y lo que ya está hecho no se repite.
set -euo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$RAIZ"

GDTOOLKIT_VERSION="${GDTOOLKIT_VERSION:-4.3.4}"
BIBLIOTECA="godot/addons/siga98_gb/bin/linux/libsiga98_gb.linux.template_debug.x86_64.so"
AVISOS=0

paso() { printf '\n\033[1m==> %s\033[0m\n' "$1"; }
aviso() { printf '\033[33mAVISO:\033[0m %s\n' "$1"; AVISOS=$((AVISOS + 1)); }

paso "Motor de Godot"
ESPERADA="$(cat .godot-version)"
if ! command -v godot4 >/dev/null 2>&1; then
    aviso "godot4 no está en el PATH. El proyecto declara $ESPERADA en .godot-version."
else
    INSTALADA="$(godot4 --version 2>/dev/null | tail -1)"
    echo "declarada: $ESPERADA · instalada: $INSTALADA"
    # .godot-version fija la build exacta que descarga CI; en local basta con que
    # coincida la línea (mayor.menor), porque los parches no cambian el contrato.
    # Se comparan los dos primeros componentes, no un prefijo: "4.1" no debe
    # darse por buena contra un "4.10".
    linea() { cut -d. -f1,2 <<<"${1%%-stable*}"; }
    if [[ "$(linea "$INSTALADA")" != "$(linea "$ESPERADA")" ]]; then
        aviso "el motor instalado no es de la línea $ESPERADA; CI usará la declarada."
    fi
fi

paso "GDExtension GB/GBC (#124)"
if [[ -x "$BIBLIOTECA" ]]; then
    echo "ya compilada: $BIBLIOTECA"
else
    bash scripts/preparar_emulador_gb.sh linux-debug
fi

paso "ROMs propias"
if compgen -G "godot/roms/*.gbc" >/dev/null; then
    echo "ya presentes: $(ls godot/roms/*.gbc | wc -l) ROM(s)"
else
    bash scripts/preparar_emulador_gb.sh rom
fi

paso "gdtoolkit $GDTOOLKIT_VERSION"
if command -v gdformat >/dev/null 2>&1 &&
    [[ "$(gdformat --version 2>/dev/null)" == "gdformat $GDTOOLKIT_VERSION" ]]; then
    echo "ya disponible en el PATH"
else
    echo "lo instalará check_gdscript.sh en su venv la primera vez que se ejecute"
fi

paso "Listo"
if ((AVISOS > 0)); then
    echo "$AVISOS aviso(s). Revísalos antes de fiarte de un verde local."
fi
cat <<'FIN'
Gate completo (lo mismo que ejecuta CI):

    SIGA98_EXIGIR_EXTENSION=1 bash scripts/check_gdscript.sh
    python3 scripts/verificar_godot.py
FIN
