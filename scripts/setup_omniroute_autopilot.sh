#!/usr/bin/env bash
set -Eeuo pipefail

# Conecta OmniRoute local al autopilot mediante Tailscale Serve.
# No usa Funnel ni expone los puertos de OmniRoute a Internet.

REPO="${REPO:-EspacioKoop/expediente-legado}"
OMNIROUTE_MODEL="${OMNIROUTE_MODEL:-autopilot-code}"
OMNIROUTE_PORT="${OMNIROUTE_PORT:-auto}"
GH_CONFIGURE="${GH_CONFIGURE:-1}"

say() { printf '\n==> %s\n' "$*"; }
warn() { printf 'AVISO: %s\n' "$*" >&2; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "Falta '$1'. Instálalo y vuelve a ejecutar."; }

need curl
need jq
need tailscale

say "Comprobando Tailscale"
if ! tailscale status --json >/tmp/siga98-tailscale-status.json 2>/dev/null; then
  warn "Tailscale está instalado pero no conectado."
  echo "Ejecuta: sudo tailscale up"
  exit 2
fi

TS_DNS="$(jq -r '.Self.DNSName // empty' /tmp/siga98-tailscale-status.json | sed 's/\.$//')"
TS_IPV4="$(tailscale ip -4 2>/dev/null | head -n1 || true)"
[[ -n "$TS_DNS" ]] || die "No pude obtener el MagicDNS del equipo."
[[ -n "$TS_IPV4" ]] || die "No pude obtener la IPv4 Tailscale del equipo."

probe_port() {
  local p="$1" code
  for path in /api/health /healthz /v1/models; do
    code="$(curl -sS --max-time 2 -o /dev/null -w '%{http_code}' "http://127.0.0.1:${p}${path}" 2>/dev/null || true)"
    case "$code" in 200|401|403) printf '%s' "$p"; return 0 ;; esac
  done
  return 1
}

say "Buscando OmniRoute local"
if [[ "$OMNIROUTE_PORT" == auto ]]; then
  for p in 20131 20128 20130; do
    if found="$(probe_port "$p")"; then OMNIROUTE_PORT="$found"; break; fi
  done
fi
[[ "$OMNIROUTE_PORT" =~ ^[0-9]+$ ]] || die "No encontré OmniRoute. Usa OMNIROUTE_PORT=<puerto>."
LOCAL_ORIGIN="http://127.0.0.1:${OMNIROUTE_PORT}"
echo "OmniRoute detectado: $LOCAL_ORIGIN"

if [[ -z "${OMNIROUTE_API_KEY:-}" ]]; then
  printf 'Pega la API key de ENDPOINT de OmniRoute (entrada oculta): ' >&2
  IFS= read -rs OMNIROUTE_API_KEY
  printf '\n' >&2
fi
[[ -n "${OMNIROUTE_API_KEY:-}" ]] || die "La API key está vacía."

MODELS_TMP="$(mktemp)"
trap 'rm -f "$MODELS_TMP" /tmp/siga98-tailscale-status.json /tmp/siga98-omniroute-private-models.json' EXIT

say "Validando API key"
HTTP="$(curl -sS --max-time 12 -o "$MODELS_TMP" -w '%{http_code}' -H "Authorization: Bearer ${OMNIROUTE_API_KEY}" "${LOCAL_ORIGIN}/v1/models" || true)"
[[ "$HTTP" == 200 ]] || die "GET /v1/models devolvió HTTP $HTTP. Usa una API key de endpoint, no la contraseña del dashboard."
echo "Catálogo accesible: $(jq '(.data // []) | length' "$MODELS_TMP" 2>/dev/null || echo 0) modelos/aliases."

if ! jq -e --arg m "$OMNIROUTE_MODEL" '(.data // []) | any(.id == $m)' "$MODELS_TMP" >/dev/null 2>&1; then
  warn "No veo '$OMNIROUTE_MODEL' en /v1/models. Crea ese combo o usa OMNIROUTE_MODEL=<id-visible>."
fi

say "Configurando Tailscale Serve privado"
sudo tailscale serve --bg "http://127.0.0.1:${OMNIROUTE_PORT}"
TAILNET_BASE="https://${TS_DNS}/v1"

PRIVATE_HTTP="$(curl -sS --max-time 12 -o /tmp/siga98-omniroute-private-models.json -w '%{http_code}' -H "Authorization: Bearer ${OMNIROUTE_API_KEY}" "${TAILNET_BASE}/models" || true)"
[[ "$PRIVATE_HTTP" == 200 ]] || die "Tailscale Serve respondió HTTP $PRIVATE_HTTP. Revisa: tailscale serve status"

POLICY_FILE="${HOME}/.omniroute/github-autopilot-tailnet-policy.hujson"
mkdir -p "$(dirname "$POLICY_FILE")"
cat >"$POLICY_FILE" <<EOF
// Fusiona estas secciones con la policy existente.
{
  "tagOwners": {
    "tag:github-autopilot": []
  },
  "grants": [
    {
      "src": ["tag:github-autopilot"],
      "dst": ["${TS_IPV4}"],
      "ip": ["tcp:443"]
    }
  ]
}
EOF
chmod 600 "$POLICY_FILE"

if [[ "$GH_CONFIGURE" == 1 ]] && command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  say "Configurando GitHub"
  gh variable set OMNIROUTE_BASE_URL --repo "$REPO" --body "$TAILNET_BASE"
  gh variable set OMNIROUTE_MODEL --repo "$REPO" --body "$OMNIROUTE_MODEL"
  printf '%s' "$OMNIROUTE_API_KEY" | gh secret set OMNIROUTE_API_KEY --repo "$REPO"
  if [[ -n "${TS_OAUTH_CLIENT_ID:-}" && -n "${TS_AUDIENCE:-}" ]]; then
    printf '%s' "$TS_OAUTH_CLIENT_ID" | gh secret set TS_OAUTH_CLIENT_ID --repo "$REPO"
    printf '%s' "$TS_AUDIENCE" | gh secret set TS_AUDIENCE --repo "$REPO"
  else
    warn "Faltan TS_OAUTH_CLIENT_ID/TS_AUDIENCE. Crea la Federated Identity de Tailscale y vuelve a ejecutar con ambas variables exportadas."
  fi
fi

cat <<EOF

Endpoint privado: $TAILNET_BASE
Modelo/combo:     $OMNIROUTE_MODEL
Policy Tailscale: $POLICY_FILE

Siguiente paso:
- fusiona el snippet con Access controls;
- crea una Federated Identity de GitHub limitada a $REPO y tag:github-autopilot;
- vuelve a ejecutar con TS_OAUTH_CLIENT_ID y TS_AUDIENCE.

No uses Tailscale Funnel y no abras los puertos de OmniRoute en el router.
EOF
