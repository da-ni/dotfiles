#!/usr/bin/env bash

bars=(▁ ▂ ▃ ▄ ▅ ▆ ▇ █)

config_file="/tmp/waybar_cava_config"
cat >"$config_file" <<'EOF'
[general]
bars = 24
framerate = 60
autosens = 1

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 7
EOF

trap "kill 0" EXIT

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

is_playing() {
  local status

  if ! command -v playerctl >/dev/null 2>&1; then
    return 1
  fi

  while IFS= read -r status; do
    if [[ "$status" == "Playing" ]]; then
      return 0
    fi
  done < <(playerctl --all-players status 2>/dev/null)

  return 1
}

cava -p "$config_file" |
while IFS= read -r line; do
  if is_playing; then
    print_visible "$(convert_to_bars "$line")"
  else
    print_hidden
  fi
done
