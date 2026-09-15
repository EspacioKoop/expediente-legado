#!/usr/bin/env bash
set -euo pipefail

GDTOOLKIT_VERSION="${GDTOOLKIT_VERSION:-4.3.4}"
PYTHON_BIN="${PYTHON_BIN:-python3}"

if ! command -v "$PYTHON_BIN" >/dev/null 2>&1; then
  PYTHON_BIN=python
fi

INSTALLED_GDTOOLKIT="$($PYTHON_BIN -c 'import importlib.metadata; print(importlib.metadata.version("gdtoolkit"))' 2>/dev/null || true)"
if [[ "$INSTALLED_GDTOOLKIT" != "$GDTOOLKIT_VERSION" ]]; then
  "$PYTHON_BIN" -m pip install "gdtoolkit==${GDTOOLKIT_VERSION}"
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
