#!/usr/bin/env bash
set -euo pipefail

STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/hypr-mirror-toggle.state"

J="$(hyprctl monitors all -j)"

INTERNAL="$(jq -r '.[] | select(.name | startswith("eDP")) | .name' <<<"$J" | head -n1)"
if [[ -z "${INTERNAL:-}" ]]; then
  notify-send "Display Toggle" "No internal eDP display found."
  exit 0
fi

# Gather all non-internal monitors (filter out common headless names just in case)
mapfile -t EXTERNALS < <(
  jq -r '
    .[]
    | select(.name | startswith("eDP") | not)
    | select(.name | test("^(HEADLESS|WL)-") | not)
    | .name
  ' <<<"$J"
)

if (( ${#EXTERNALS[@]} == 0 )); then
  notify-send "Display Toggle" "No external monitor connected."
  exit 0
fi

# Helper: get scale, default to 1
get_scale() {
  local name="$1"
  jq -r --arg n "$name" '.[] | select(.name==$n) | (.scale // 1)' <<<"$J"
}

if [[ -f "$STATE_FILE" ]]; then
  # UNMIRROR: just reset ALL externals to normal layout.
  # (This is safe even if Hyprland thinks it isn't mirrored.)
  for ex in "${EXTERNALS[@]}"; do
    scale="$(get_scale "$ex")"
    hyprctl keyword monitor "$ex,preferred,auto,$scale"
  done
  rm -f "$STATE_FILE"
  notify-send "Display Toggle" "Switched to Extended Mode"
else
  # MIRROR: mirror ALL externals to internal
  for ex in "${EXTERNALS[@]}"; do
    scale="$(get_scale "$ex")"
    hyprctl keyword monitor "$ex,preferred,auto,$scale,mirror,$INTERNAL"
  done
  : > "$STATE_FILE"
  notify-send "Display Toggle" "Switched to Mirrored Mode"
fi
