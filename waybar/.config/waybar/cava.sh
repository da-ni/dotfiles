#!/usr/bin/env bash

bars=(▁ ▂ ▃ ▄ ▅ ▆ ▇ █)

PLAYERCTL_AVAILABLE=0
PLAYING_CACHE=0
LAST_CHECK_SECONDS=-1

if command -v playerctl >/dev/null 2>&1; then
  PLAYERCTL_AVAILABLE=1
fi

config_file="/tmp/waybar_cava_config"
cat >"$config_file" <<'EOF'
[general]
bars = 24
framerate = 20
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
  printf '{"text":"%s"}\n' "$text"
}

print_hidden() {
  printf '{"text":"","class":"hidden"}\n'
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

while true; do
  refresh_playback_state

  if (( PLAYING_CACHE == 0 )); then
    if (( MODULE_VISIBLE == 1 )); then
      print_hidden
      MODULE_VISIBLE=0
    fi
    sleep 1
    continue
  fi

  while IFS= read -r line; do
    refresh_playback_state
    if (( PLAYING_CACHE == 0 )); then
      print_hidden
      MODULE_VISIBLE=0
      break
    fi

    MODULE_VISIBLE=1
    print_visible "$(convert_to_bars "$line")"
  done < <(cava -p "$config_file")
done
