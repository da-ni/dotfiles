#!/usr/bin/env bash

bars=(▁ ▂ ▃ ▄ ▅ ▆ ▇ █)

PLAYERCTL_AVAILABLE=0
PLAYING_CACHE=0
LAST_CHECK_SECONDS=-1
LAST_EMITTED_JSON=""
IDLE_POLL_FAST=1
IDLE_POLL_SLOW=5
IDLE_SLOW_AFTER=45
LAST_PLAYING_SECONDS=0
WAYBAR_PARENT_PID=$PPID

# Omarchy currently pins Waybar 0.15.x, where high-frequency custom modules can
# interfere with hover/tooltip behavior. Cache playback state and only emit
# changed JSON payloads to keep the bar responsive without sacrificing visuals.

if command -v playerctl >/dev/null 2>&1; then
  PLAYERCTL_AVAILABLE=1
fi

config_file="/tmp/waybar_cava_config"
fifo_file="/tmp/waybar_cava_${$}.fifo"
cat >"$config_file" <<'EOF'
[general]
bars = 24
framerate = 12
autosens = 1

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 7
EOF

convert_to_bars() {
  IFS=';' read -ra nums <<<"$1"
  out=""
  for n in "${nums[@]}"; do
    (( n >= 0 && n <= 7 )) || n=0
    out+="${bars[$n]}"
  done
  printf '%s\n' "$out"
}

print_visible() {
  local text="$1"
  emit_json "{\"text\":\"$text\"}"
}

print_hidden() {
  emit_json '{"text":"","class":"hidden"}'
}

emit_json() {
  local payload="$1"
  if [[ "$payload" == "$LAST_EMITTED_JSON" ]]; then
    return
  fi
  LAST_EMITTED_JSON="$payload"
  printf '%s\n' "$payload"
}

cleanup() {
  stop_cava
  rm -f -- "$fifo_file"
}

trap cleanup EXIT
trap 'cleanup; exit 0' INT TERM

CAVA_PID=""
FIFO_FD=""

start_cava() {
  stop_cava
  cava -p "$config_file" >"$fifo_file" 2>/dev/null &
  CAVA_PID=$!
  exec {FIFO_FD}<"$fifo_file"
}

stop_cava() {
  if [[ -n "$FIFO_FD" ]]; then
    exec {FIFO_FD}<&-
    FIFO_FD=""
  fi

  [[ -n "$CAVA_PID" ]] || return 0
  if kill -0 "$CAVA_PID" 2>/dev/null; then
    kill "$CAVA_PID" 2>/dev/null || true
    wait "$CAVA_PID" 2>/dev/null || true
  fi
  CAVA_PID=""
}

refresh_playback_state() {
  local status

  if (( SECONDS == LAST_CHECK_SECONDS )); then
    return
  fi

  LAST_CHECK_SECONDS=$SECONDS
  PLAYING_CACHE=0

  if (( PLAYERCTL_AVAILABLE == 0 )); then
    return
  fi

  while IFS= read -r status; do
    if [[ "$status" == "Playing" ]]; then
      PLAYING_CACHE=1
      return
    fi
  done < <(playerctl --all-players status 2>/dev/null)
}

MODULE_VISIBLE=0

mkfifo -m 600 "$fifo_file"

while true; do
  if (( PPID != WAYBAR_PARENT_PID )); then
    exit 0
  fi

  refresh_playback_state

  if (( PLAYING_CACHE == 0 )); then
    idle_for=$((SECONDS - LAST_PLAYING_SECONDS))
    if (( MODULE_VISIBLE == 1 )); then
      print_hidden
      MODULE_VISIBLE=0
    fi
    stop_cava

    if (( idle_for >= IDLE_SLOW_AFTER )); then
      sleep "$IDLE_POLL_SLOW"
    else
      sleep "$IDLE_POLL_FAST"
    fi
    continue
  fi

  LAST_PLAYING_SECONDS=$SECONDS

  if [[ -z "$CAVA_PID" ]] || ! kill -0 "$CAVA_PID" 2>/dev/null; then
    start_cava
  fi

  if [[ -n "$FIFO_FD" ]] && IFS= read -r -t 1 -u "$FIFO_FD" line; then
    MODULE_VISIBLE=1
    print_visible "$(convert_to_bars "$line")"
  elif [[ -n "$CAVA_PID" ]] && ! kill -0 "$CAVA_PID" 2>/dev/null; then
    CAVA_PID=""
    if [[ -n "$FIFO_FD" ]]; then
      exec {FIFO_FD}<&-
      FIFO_FD=""
    fi
  else
    sleep 0.05
  fi
done
