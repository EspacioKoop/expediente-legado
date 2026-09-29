#!/usr/bin/env bash
# Escanea commits en busca de tokens, claves y contraseñas con gitleaks.
#
#   bash scripts/escanear_secretos.sh              # commits de la rama: origin/main..HEAD
#   bash scripts/escanear_secretos.sh A..B         # un rango concreto (lo usa CI)
#   bash scripts/escanear_secretos.sh --todo       # historial de todas las refs locales
#   bash scripts/escanear_secretos.sh --autoprueba # demuestra que el gate detecta y no filtra
#
# La salida siempre va redactada: el log de un PR público no puede convertirse
# en el sitio donde se publica el secreto que se pretendía frenar. Los falsos
# positivos se silencian con `.gitleaksignore` (huella del hallazgo) o con una
# allowlist en `.gitleaks.toml`, nunca rebajando el gate.
set -euo pipefail

GITLEAKS_VERSION="8.30.1"

# Versión y hashes fijados a mano: el fichero de checksums viaja en la misma
# release que el binario, así que comprobarlo contra él no protege de una
# release manipulada. Al subir de versión hay que copiar aquí los nuevos.
declare -A GITLEAKS_SHA256=(
  [linux_x64]="551f6fc83ea457d62a0d98237cbad105af8d557003051f41f3e7ca7b3f2470eb"
  [linux_arm64]="e4a487ee7ccd7d3a7f7ec08657610aa3606637dab924210b3aee62570fb4b080"
  [darwin_x64]="dfe101a4db2255fc85120ac7f3d25e4342c3c20cf749f2c20a18081af1952709"
  [darwin_arm64]="b40ab0ae55c505963e365f271a8d3846efbc170aa17f2607f13df610a9aeb6a5"
)

plataforma() {
  local so arq
  case "$(uname -s)" in
    Linux) so=linux ;;
    Darwin) so=darwin ;;
    *) return 1 ;;
  esac
  case "$(uname -m)" in
    x86_64 | amd64) arq=x64 ;;
    aarch64 | arm64) arq=arm64 ;;
    *) return 1 ;;
  esac
  echo "${so}_${arq}"
}

sha256_de() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | cut -d' ' -f1
  else
    shasum -a 256 "$1" | cut -d' ' -f1
  fi
}

# Deja en GITLEAKS la ruta de un binario de la versión canónica. Respeta uno ya
# instalado en el PATH si coincide; si no, lo descarga una vez a la caché.
resolver_gitleaks() {
  if command -v gitleaks >/dev/null 2>&1 &&
    [[ "$(gitleaks version 2>/dev/null)" == "$GITLEAKS_VERSION" ]]; then
    GITLEAKS="$(command -v gitleaks)"
    return
  fi

  local cache="${GITLEAKS_CACHE:-$HOME/.cache/expediente-legado/gitleaks-$GITLEAKS_VERSION}"
  GITLEAKS="$cache/gitleaks"
  [[ -x "$GITLEAKS" ]] && return

  local plat
  if ! plat="$(plataforma)" || [[ -z "${GITLEAKS_SHA256[$plat]:-}" ]]; then
    echo "Plataforma sin binario fijado ($(uname -s) $(uname -m))." >&2
    echo "Instala gitleaks $GITLEAKS_VERSION en el PATH y repite." >&2
    exit 2
  fi

  local tmp paquete
  tmp="$(mktemp -d)"
  paquete="$tmp/gitleaks.tar.gz"
  curl --fail --silent --show-error --location --retry 3 \
    --proto '=https' --proto-redir '=https' --tlsv1.2 \
    -o "$paquete" \
    "https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_${plat}.tar.gz"
  if [[ "$(sha256_de "$paquete")" != "${GITLEAKS_SHA256[$plat]}" ]]; then
    echo "El SHA-256 de gitleaks $GITLEAKS_VERSION ($plat) no coincide con el fijado." >&2
    rm -rf "$tmp"
    exit 2
  fi
  tar -xzf "$paquete" -C "$tmp" gitleaks
  mkdir -p "$cache"
  mv "$tmp/gitleaks" "$GITLEAKS"
  rm -rf "$tmp"
}

# escanear <repo> [log-opts]: sin log-opts gitleaks recorre `git log --all`.
escanear() {
  local repo="$1" log_opts="${2:-}"
  local args=(git --no-banner --redact --verbose --exit-code 1)
  [[ -n "$log_opts" ]] && args+=(--log-opts="$log_opts")
  "$GITLEAKS" "${args[@]}" "$repo"
}

repo_temporal() {
  local dir="$1"
  git -C "$dir" init -q
  git -C "$dir" config user.name autoprueba
  git -C "$dir" config user.email autoprueba@invalid
  git -C "$dir" config commit.gpgsign false
  # Un hook global de pre-commit que bloquee credenciales impediría plantar el
  # token de la autoprueba; aquí solo interesa lo que detecta gitleaks.
  git -C "$dir" config core.hooksPath /dev/null
  echo "# limpio" >"$dir/LEEME.md"
  git -C "$dir" add LEEME.md
  git -C "$dir" commit -q -m limpio
}

# Prueba el contrato real del gate con el binario que usará CI: un repo limpio
# pasa, un token plantado se detecta y la salida no lo reproduce en claro. El
# token se genera en cada ejecución para que este script no lo contenga.
autoprueba() {
  local salida token
  # Global y no `local`: el trap de salida se ejecuta cuando la función ya ha
  # terminado y sus variables locales no existen.
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT

  mkdir "$tmp/limpio" "$tmp/sucio"
  repo_temporal "$tmp/limpio"
  if ! salida="$(escanear "$tmp/limpio" 2>&1)"; then
    echo "$salida" >&2
    echo "AUTOPRUEBA FALLIDA: un repo limpio no debería dar hallazgos." >&2
    return 1
  fi

  repo_temporal "$tmp/sucio"
  token="ghp_$(LC_ALL=C tr -dc 'A-Za-z0-9' < <(head -c 4096 /dev/urandom) | cut -c1-36)"
  echo "GITHUB_TOKEN=$token" >"$tmp/sucio/.env"
  git -C "$tmp/sucio" add .env
  git -C "$tmp/sucio" commit -q -m "token plantado"
  if salida="$(escanear "$tmp/sucio" HEAD~1..HEAD 2>&1)"; then
    echo "$salida" >&2
    echo "AUTOPRUEBA FALLIDA: el token plantado no se detectó." >&2
    return 1
  fi
  if ! grep -q "leaks found: 1" <<<"$salida"; then
    echo "$salida" >&2
    echo "AUTOPRUEBA FALLIDA: gitleaks falló sin informar del hallazgo." >&2
    return 1
  fi
  if grep -qF "$token" <<<"$salida"; then
    echo "AUTOPRUEBA FALLIDA: la salida contiene el token sin redactar." >&2
    return 1
  fi
  echo "Autoprueba de secretos: OK (limpio pasa, token plantado detectado y redactado)."
}

resolver_gitleaks

case "${1:-}" in
  --autoprueba)
    autoprueba
    ;;
  --todo)
    escanear "$(git rev-parse --show-toplevel)"
    ;;
  "")
    raiz="$(git rev-parse --show-toplevel)"
    if git -C "$raiz" rev-parse --verify -q origin/main >/dev/null; then
      escanear "$raiz" "origin/main..HEAD"
    else
      escanear "$raiz"
    fi
    ;;
  -*)
    echo "Opción desconocida: $1" >&2
    exit 2
    ;;
  *)
    escanear "$(git rev-parse --show-toplevel)" "$1"
    ;;
esac
