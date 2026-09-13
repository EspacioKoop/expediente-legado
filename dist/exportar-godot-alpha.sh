#!/usr/bin/env bash
# Exporta el port Godot a Linux y Windows para playtesting local.
# No publica, no usa secretos y no toca el empaquetado histórico del backend.
set -euo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_DIR="$RAIZ/godot"
SALIDA="$RAIZ/dist/salida"
MOTOR="${GODOT_BIN:-godot4}"
DECLARADA="$(tr -d '\r\n' < "$RAIZ/.godot-version")"
ACTUAL="$($MOTOR --version | tr -d '\r\n')"
CONFIG_INCIDENCIAS="$GODOT_DIR/datos/incidencias.json"
RESPALDO_INCIDENCIAS="$(mktemp)"
cp "$CONFIG_INCIDENCIAS" "$RESPALDO_INCIDENCIAS"

restaurar_config_incidencias() {
    cp "$RESPALDO_INCIDENCIAS" "$CONFIG_INCIDENCIAS"
    rm -f "$RESPALDO_INCIDENCIAS"
}
trap restaurar_config_incidencias EXIT

# El formulario de feedback se configura al empaquetar, no queda hardcodeado
# en GDScript. La URL es pública dentro de la build y solo se aceptan HTTP(S).
python3 - "$CONFIG_INCIDENCIAS" "${SIGA98_FEEDBACK_URL:-}" <<'PY'
import json
from pathlib import Path
import sys

ruta = Path(sys.argv[1])
url = sys.argv[2].strip()
if url and not url.startswith(("https://", "http://")):
    raise SystemExit("ERROR: SIGA98_FEEDBACK_URL debe usar http:// o https://")
datos = json.loads(ruta.read_text(encoding="utf-8"))
datos["feedback_url"] = url
ruta.write_text(json.dumps(datos, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
PY

python3 - "$DECLARADA" "$ACTUAL" <<'PY'
import re
import sys

declarada, actual = sys.argv[1:]
linea, sep, canal = declarada.partition("-")
if not sep or not linea or not canal:
    raise SystemExit(f"ERROR: .godot-version mal escrito: {declarada!r}")
patron = rf"^{re.escape(linea)}(?:\.\d+)*\.{re.escape(canal)}\b"
if not re.match(patron, actual):
    raise SystemExit(
        f"ERROR: se requiere Godot de la línea {declarada}; encontrado {actual}"
    )
PY

rm -rf "$SALIDA/godot-linux" "$SALIDA/godot-windows"
mkdir -p "$SALIDA/godot-linux" "$SALIDA/godot-windows"

exportar() {
    local preset="$1"
    local destino="$2"
    local registro
    registro="$(mktemp)"
    if ! "$MOTOR" --headless --path "$GODOT_DIR" --export-release "$preset" "$destino" >"$registro" 2>&1; then
        cat "$registro" >&2
        rm -f "$registro"
        cat >&2 <<'EOF'

ERROR: Godot no pudo exportar la alpha.
Comprueba que las Export Templates de la misma versión de Godot están instaladas:
Editor -> Manage Export Templates -> Download and Install.
Después vuelve a ejecutar este script.
EOF
        exit 1
    fi
    cat "$registro"
    rm -f "$registro"
    if [ ! -f "$destino" ]; then
        echo "ERROR: Godot terminó sin crear $destino" >&2
        exit 1
    fi
}

exportar "Linux x86_64" "$SALIDA/godot-linux/SIGA-98.x86_64"
chmod +x "$SALIDA/godot-linux/SIGA-98.x86_64"
exportar "Windows x86_64" "$SALIDA/godot-windows/SIGA-98.exe"

python3 - "$SALIDA" <<'PY'
from pathlib import Path
import shutil
import sys

salida = Path(sys.argv[1])
for plataforma in ("linux", "windows"):
    carpeta = salida / f"godot-{plataforma}"
    base = salida / f"SIGA-98-godot-alpha-{plataforma}"
    zip_path = base.with_suffix(".zip")
    if zip_path.exists():
        zip_path.unlink()
    shutil.make_archive(str(base), "zip", root_dir=carpeta)
PY

(
    cd "$SALIDA"
    sha256sum SIGA-98-godot-alpha-linux.zip SIGA-98-godot-alpha-windows.zip \
        > SIGA-98-godot-alpha-SHA256SUMS.txt
)

echo
echo "Alpha Godot lista en dist/salida/:"
ls -lh \
    "$SALIDA/SIGA-98-godot-alpha-linux.zip" \
    "$SALIDA/SIGA-98-godot-alpha-windows.zip" \
    "$SALIDA/SIGA-98-godot-alpha-SHA256SUMS.txt"
