#!/usr/bin/env bash
# Auto-label GitHub issues/PRs by area keywords in title or body.
# Usage: $0 <issue_or_pr_number>
# Expects gh CLI authentication via GH_TOKEN/GITHUB_TOKEN.

set -euo pipefail

if [ "$#" -ne 1 ] || ! [[ "$1" =~ ^[0-9]+$ ]]; then
  echo "Usage: $0 <issue_or_pr_number>" >&2
  exit 1
fi

NUMBER="$1"
ENDPOINT="repos/{owner}/{repo}/issues/${NUMBER}"

# GitHub exposes both issues and pull requests through the Issues API, so the
# same lookup works for either event type.
TITLE="$(gh api "$ENDPOINT" --jq '.title // ""')"
BODY="$(gh api "$ENDPOINT" --jq '.body // ""')"
TEXT="${TITLE}
${BODY}"

LABELS_TO_ADD=()

add_label_if_match() {
  local label="$1"
  local pattern="$2"

  if printf '%s\n' "$TEXT" | grep -Eiq "$pattern"; then
    local existing
    for existing in "${LABELS_TO_ADD[@]:-}"; do
      if [ "$existing" = "$label" ]; then
        return
      fi
    done
    LABELS_TO_ADD+=("$label")
  fi
}

# Match short area names as standalone tokens to avoid false positives such as
# "build" accidentally matching the area "ui".
add_label_if_match "area:arte-assets" '(^|[^[:alnum:]_])arte[- _]?assets?([^[:alnum:]_]|$)'
add_label_if_match "area:siga" '(^|[^[:alnum:]_])siga([^[:alnum:]_]|$)'
add_label_if_match "area:ui" '(^|[^[:alnum:]_])ui([^[:alnum:]_]|$)'
add_label_if_match "area:sueño" '(^|[^[:alnum:]_])(sueño|sueo)([^[:alnum:]_]|$)'

if [ "${#LABELS_TO_ADD[@]}" -eq 0 ]; then
  echo "No area labels matched."
  exit 0
fi

for label in "${LABELS_TO_ADD[@]}"; do
  echo "Adding label: $label"
  # Labels on pull requests are managed through the Issues API as well.
  gh api --method POST "$ENDPOINT/labels" -f "labels[]=$label" >/dev/null
done
