#!/usr/bin/env bash

PLAYERCTL_BIN="playerctl"
MAX_MEDIA_LEN=42
FIELD_SEP=$'\x1f'

declare -A PLAYER_ICONS=(
  [default]="󰓇"
  [mpv]="🎵"
  [spotify]="󰓇"
  [chromium]=""
  [edge]="󰇩"
  [firefox]="󰈹"
)

declare -A STATUS_ICONS=(
  [playing]="▶"
  [paused]="⏸"
  [stopped]="⏹"
)

format_us() {
  local value="$1"
  if [[ ! "$value" =~ ^[0-9]+$ ]]; then
    printf '00:00'
    return
  fi

  local total_seconds=$((value / 1000000))
  local hours=$((total_seconds / 3600))
  local minutes=$(((total_seconds % 3600) / 60))
  local seconds=$((total_seconds % 60))

  if (( hours > 0 )); then
    printf '%d:%02d:%02d' "$hours" "$minutes" "$seconds"
  else
    printf '%02d:%02d' "$minutes" "$seconds"
  fi
}

truncate_text() {
  local text="$1"
  local max_len="$2"

  if [[ ! "$max_len" =~ ^[0-9]+$ ]] || (( max_len <= 0 )); then
    printf '%s' "$text"
    return
  fi

  if (( ${#text} > max_len )); then
    if (( max_len > 3 )); then
      printf '%s...' "${text:0:max_len-3}"
    else
      printf '%s' "${text:0:max_len}"
    fi
  else
    printf '%s' "$text"
  fi
}

json_payload() {
  TEXT="$1" TOOLTIP="$2" CLASS_NAME="$3" python3 - <<'PY'
import json, os
print(json.dumps({
    "text": os.getenv("TEXT", ""),
    "tooltip": os.getenv("TOOLTIP", ""),
    "class": os.getenv("CLASS_NAME", "")
}, ensure_ascii=False))
PY
}

pick_active_line() {
  local raw="$1"
  local first_paused=""
  local line player status

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    IFS="$FIELD_SEP" read -r player status _ <<<"$line"
    if [[ "$status" == "Playing" ]]; then
      printf '%s\n' "$line"
      return 0
    fi
    if [[ -z "$first_paused" && "$status" == "Paused" ]]; then
      first_paused="$line"
    fi
  done <<<"$raw"

  if [[ -n "$first_paused" ]]; then
    printf '%s\n' "$first_paused"
    return 0
  fi

  return 1
}

last_payload=""

while true; do
  if ! command -v "$PLAYERCTL_BIN" >/dev/null 2>&1; then
    payload=$(json_payload "" "playerctl not installed" "disconnected")
    sleep_for=5
  else
    raw=$($PLAYERCTL_BIN --all-players metadata --format "{{playerName}}${FIELD_SEP}{{status}}${FIELD_SEP}{{artist}}${FIELD_SEP}{{title}}${FIELD_SEP}{{album}}${FIELD_SEP}{{position}}${FIELD_SEP}{{mpris:length}}" 2>/dev/null || true)
    active_line=$(pick_active_line "$raw" || true)

    if [[ -z "$active_line" ]]; then
      payload=$(json_payload "" "" "disconnected")
      sleep_for=3
    else
      IFS="$FIELD_SEP" read -r player status artist title album position_us length_us <<<"$active_line"

      status_lc="${status,,}"
      player_lc="${player,,}"
      player_icon="${PLAYER_ICONS[$player_lc]:-${PLAYER_ICONS[default]}}"
      status_icon="${STATUS_ICONS[$status_lc]:-${STATUS_ICONS[stopped]}}"

      if [[ -n "$artist" && -n "$title" ]]; then
        media_text="$artist - $title"
      elif [[ -n "$title" ]]; then
        media_text="$title"
      elif [[ -n "$artist" ]]; then
        media_text="$artist"
      else
        media_text="$player"
      fi

      pos_fmt=$(format_us "$position_us")
      len_fmt=$(format_us "$length_us")

      meta_line="$artist"
      [[ -n "$artist" && -n "$album" ]] && meta_line+=" - "
      [[ -n "$album" ]] && meta_line+="$album"

      case "$status_lc" in
        playing)
          text="$player_icon $(truncate_text "$media_text" "$MAX_MEDIA_LEN")"
          tooltip="$title"
          [[ -n "$meta_line" ]] && tooltip+=$'\n'"$meta_line"
          tooltip+=$'\n'"$pos_fmt/$len_fmt"
          class_name="playing"
          sleep_for=1
          ;;
        paused)
          text="$status_icon $(truncate_text "$media_text" "$MAX_MEDIA_LEN")"
          tooltip="$title"
          [[ -n "$meta_line" ]] && tooltip+=$'\n'"$meta_line"
          tooltip+=$'\n'"Paused ($pos_fmt/$len_fmt)"
          class_name="paused"
          sleep_for=2
          ;;
        *)
          text="$status_icon"
          tooltip=""
          class_name="stopped"
          sleep_for=3
          ;;
      esac

      payload=$(json_payload "$text" "$tooltip" "$class_name")
    fi
  fi

  if [[ "$payload" != "$last_payload" ]]; then
    printf '%s\n' "$payload"
    last_payload="$payload"
  fi

  sleep "$sleep_for"
done
