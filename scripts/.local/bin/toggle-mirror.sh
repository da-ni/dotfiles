#!/usr/bin/env bash
set -euo pipefail

STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/hypr-mirror-toggle.state.json"
LOG_FILE="${XDG_RUNTIME_DIR:-/tmp}/hypr-mirror-toggle.log"
LOCK_FILE="${XDG_RUNTIME_DIR:-/tmp}/hypr-mirror-toggle.lock"
LOCK_HELD=0

log_debug() {
  local message="$1"
  printf '%s | %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$message" >>"$LOG_FILE"
}

on_error() {
  local rc=$?
  log_debug "error: line=${BASH_LINENO[0]} command=${BASH_COMMAND} rc=$rc"
  exit "$rc"
}

trap on_error ERR

release_lock() {
  if (( LOCK_HELD == 1 )); then
    exec 9>&-
    LOCK_HELD=0
  fi
}

if command -v flock >/dev/null 2>&1; then
  exec 9>"$LOCK_FILE"
  if ! flock -n 9; then
    log_debug "another toggle invocation is already running; skipping"
    exit 0
  fi
  LOCK_HELD=1
fi

log_debug "---- toggle start ----"

J="$(hyprctl monitors all -j)"
log_debug "monitors snapshot: $(jq -c '[.[] | {name, mirrorOf, x, y, width, height, scale, transform, vrr}]' <<<"$J")"

INTERNAL="$(jq -r '.[] | select(.name | startswith("eDP")) | .name' <<<"$J" | head -n1)"
if [[ -z "${INTERNAL:-}" ]]; then
  log_debug "no internal eDP monitor found"
  notify-send "Display Toggle" "No internal eDP display found."
  exit 0
fi

INTERNAL_ID="$(jq -r --arg n "$INTERNAL" '.[] | select(.name==$n) | .id' <<<"$J")"

mapfile -t EXTERNALS < <(
  jq -r '
    .[]
    | select(.name | startswith("eDP") | not)
    | select(.name | test("^(HEADLESS|WL)-") | not)
    | .name
  ' <<<"$J"
)

if (( ${#EXTERNALS[@]} == 0 )); then
  log_debug "no external monitor connected"
  notify-send "Display Toggle" "No external monitor connected."
  exit 0
fi

log_debug "internal=$INTERNAL internal_id=$INTERNAL_ID externals=${EXTERNALS[*]}"

is_currently_mirrored() {
  local ex mirror_of

  for ex in "${EXTERNALS[@]}"; do
    mirror_of="$(jq -r --arg n "$ex" '.[] | select(.name==$n) | (.mirrorOf // "none")' <<<"$J")"
    if [[ "$mirror_of" != "$INTERNAL" && "$mirror_of" != "$INTERNAL_ID" ]]; then
      return 1
    fi
  done

  return 0
}

save_external_layout_state() {
  local tmp_file
  tmp_file="$(mktemp)"

  jq --arg internal "$INTERNAL" --argjson ext "$(printf '%s\n' "${EXTERNALS[@]}" | jq -R . | jq -s .)" '
    {
      version: 2,
      monitors: [
        .[]
        | select(.name == $internal or ((.name as $n | $ext | index($n)) != null))
        | {
            name: .name,
            resolution: "\(.width)x\(.height)@\(.refreshRate)",
            position: "\(.x)x\(.y)",
            scale: (.scale // 1),
            transform: (.transform // 0),
            vrr: (if .vrr then 1 else 0 end)
          }
      ]
    }
  ' <<<"$J" >"$tmp_file"

  mv "$tmp_file" "$STATE_FILE"
  log_debug "saved external layout to $STATE_FILE"
}

build_restore_command() {
  local ex saved
  ex="$1"

  if [[ -f "$STATE_FILE" ]]; then
    if jq -e '.version == 2 and (.monitors | type == "array")' "$STATE_FILE" >/dev/null 2>&1; then
      if ! saved="$(jq -r --arg n "$ex" '
        (.monitors[] | select(.name==$n)) as $m
        | if $m then
            "keyword monitor \($m.name),\($m.resolution),\($m.position),\($m.scale),transform,\($m.transform),vrr,\($m.vrr)"
          else
            empty
          end
      ' "$STATE_FILE")"; then
        saved=""
      fi
    else
      log_debug "state file is not v2; ignoring restore data"
    fi

    if [[ -n "$saved" ]]; then
      printf '%s' "$saved"
      return 0
    fi
  fi

  local fallback_scale
  fallback_scale="$(jq -r --arg n "$ex" '.[] | select(.name==$n) | (.scale // 1)' <<<"$J")"
  printf 'keyword monitor %s,preferred,auto,%s' "$ex" "$fallback_scale"
}

run_batch() {
  local batch=""
  local cmd
  local output

  for cmd in "$@"; do
    if [[ -n "$batch" ]]; then
      batch+="; "
    fi
    batch+="$cmd"
  done

  log_debug "running hyprctl batch: $batch"
  if ! output="$(hyprctl --batch "$batch" 2>&1)"; then
    log_debug "hyprctl batch failed: $output"
    return 1
  fi

  log_debug "hyprctl batch output: $output"
}

if is_currently_mirrored; then
  log_debug "mode detection: mirrored -> switching to extended"
  CMDS=()
  restore_internal="$(build_restore_command "$INTERNAL")"
  if [[ -n "$restore_internal" ]]; then
    CMDS+=("$restore_internal")
  fi
  for ex in "${EXTERNALS[@]}"; do
    CMDS+=("$(build_restore_command "$ex")")
  done

  run_batch "${CMDS[@]}"
  rm -f "$STATE_FILE"
  log_debug "removed state file $STATE_FILE"
  release_lock
  notify-send "Display Toggle" "Switched to Extended Mode"
  log_debug "switch complete: extended"
else
  log_debug "mode detection: extended -> switching to mirrored"
  save_external_layout_state

  CMDS=()
  for ex in "${EXTERNALS[@]}"; do
    scale="$(jq -r --arg n "$ex" '.[] | select(.name==$n) | (.scale // 1)' <<<"$J")"
    CMDS+=("keyword monitor $ex,preferred,auto,$scale,mirror,$INTERNAL")
  done

  run_batch "${CMDS[@]}"
  release_lock
  notify-send "Display Toggle" "Switched to Mirrored Mode"
  log_debug "switch complete: mirrored"
fi
