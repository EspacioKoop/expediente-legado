#!/usr/bin/env bash
set -euo pipefail

RAIZ="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "preflight_pr.sh debe ejecutarse dentro de un checkout Git." >&2
  exit 2
}
cd "$RAIZ"

echo "==> Preflight GDScript + tests Python"
bash scripts/check_gdscript.sh

echo "==> Whitespace del working tree"
git diff --check

echo "==> Whitespace del index"
git diff --cached --check

echo "Preflight PR: OK"
