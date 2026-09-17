#!/usr/bin/env bash
set -euo pipefail

GDTOOLKIT_VERSION="${GDTOOLKIT_VERSION:-4.3.4}"
PYTHON_BIN="${PYTHON_BIN:-python3}"

if ! command -v "$PYTHON_BIN" >/dev/null 2>&1; then
  PYTHON_BIN=python
fi

# gdtoolkit se instala en un entorno virtual propio. Un `pip install` contra el
# Python del sistema funciona en el runner de CI pero falla con
# `externally-managed-environment` (PEP 668) en cualquier Debian o Ubuntu
# reciente, que es donde se desarrolla. Si ya hay un gdformat/gdlint de la
# versión canónica en el PATH se respeta y no se instala nada.
VENV="${GDTOOLKIT_VENV:-$HOME/.cache/expediente-legado/gdtoolkit-$GDTOOLKIT_VERSION}"

version_en_path() {
  command -v gdformat >/dev/null 2>&1 &&
    [[ "$(gdformat --version 2>/dev/null)" == "gdformat $GDTOOLKIT_VERSION" ]]
}

# Un venv coloca sus ejecutables en bin/ en POSIX y en Scripts/ en Windows. Se
# detecta en vez de asumirlo: este script también se ejecuta a mano en Windows.
venv_bin() {
  if [[ -d "$VENV/Scripts" ]]; then echo "$VENV/Scripts"; else echo "$VENV/bin"; fi
}

if ! version_en_path; then
  if [[ ! -x "$(venv_bin)/gdformat" ]]; then
    "$PYTHON_BIN" -m venv "$VENV"
    "$(venv_bin)/python" -m pip install --disable-pip-version-check --quiet \
      "gdtoolkit==${GDTOOLKIT_VERSION}"
  fi
  PATH="$(venv_bin):$PATH"
  export PATH
fi

find_gd() {
  find godot -type f -name '*.gd' \
    -not -path 'godot/native/siga98_gb/.deps/*' -print0
}

huella_gd() {
  "$PYTHON_BIN" - <<'PY'
from hashlib import sha256
from pathlib import Path

huella = sha256()
for ruta in sorted(Path("godot").rglob("*.gd")):
    normalizada = ruta.as_posix()
    if normalizada.startswith("godot/native/siga98_gb/.deps/"):
        continue
    huella.update(normalizada.encode("utf-8"))
    huella.update(b"\0")
    huella.update(ruta.read_bytes())
    huella.update(b"\0")
print(huella.hexdigest())
PY
}

# En local formateamos antes de probar para que los tests vean exactamente el
# código que se va a subir. Si gdformat toca algo, el preflight falla a propósito:
# así el agente debe revisar el diff y repetirlo antes de commit/push. En CI no
# mutamos el checkout: exigimos que el GDScript ya llegue formateado.
if [[ "${CI:-}" == "true" ]]; then
  find_gd | xargs -0 --no-run-if-empty gdformat --check --diff
else
  huella_antes="$(huella_gd)"
  find_gd | xargs -0 --no-run-if-empty gdformat
  huella_despues="$(huella_gd)"
  if [[ "$huella_antes" != "$huella_despues" ]]; then
    echo >&2
    echo "gdformat modificó uno o más archivos .gd." >&2
    echo "Revisa y conserva el diff de formato; después ejecuta este preflight otra vez." >&2
    exit 3
  fi
fi

find_gd | xargs -0 --no-run-if-empty gdlint

"$PYTHON_BIN" -m unittest discover -s scripts -p 'test_*.py'

# El cierre siempre vuelve a comprobar formato para detectar cambios posteriores
# y mantener una única condición de salida tanto para agentes como para Actions.
find_gd | xargs -0 --no-run-if-empty gdformat --check --diff
