#!/usr/bin/env bash
set -euo pipefail

GDTOOLKIT_VERSION="${GDTOOLKIT_VERSION:-4.3.4}"

if ! command -v gdformat >/dev/null 2>&1 || ! command -v gdlint >/dev/null 2>&1; then
  python -m pip install "gdtoolkit==${GDTOOLKIT_VERSION}"
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

python -m unittest discover -s scripts -p 'test_*.py'

# El cierre siempre vuelve a comprobar formato para detectar cambios posteriores
# y mantener una única condición de salida tanto para agentes como para Actions.
find_gd | xargs -0 --no-run-if-empty gdformat --check --diff
