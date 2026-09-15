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

# En local formateamos antes de probar para que los tests vean exactamente el
# código que se va a subir. En CI no mutamos el checkout: exigimos que ya llegue
# formateado y mostramos el diff si no es así.
if [[ "${CI:-}" == "true" ]]; then
  find_gd | xargs -0 --no-run-if-empty gdformat --check --diff
else
  find_gd | xargs -0 --no-run-if-empty gdformat
fi

find_gd | xargs -0 --no-run-if-empty gdlint

"$PYTHON_BIN" -m unittest discover -s scripts -p 'test_*.py'

# El cierre siempre vuelve a comprobar formato para detectar cambios posteriores
# y mantener una única condición de salida tanto para agentes como para Actions.
find_gd | xargs -0 --no-run-if-empty gdformat --check --diff
