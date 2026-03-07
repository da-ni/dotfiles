#!/usr/bin/env bash

if ! command -v nvidia-smi >/dev/null 2>&1; then
  echo '{"text":"󰓹 N/A","tooltip":"nvidia-smi not found"}'
  exit 0
fi

util=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null)
temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null)
mem=$(nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits 2>/dev/null)
mem_total=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>/dev/null)
gpu_name=$(nvidia-smi --query-gpu=name --format=csv,noheader,nounits 2>/dev/null)

if [[ -z "$util" || -z "$temp" || -z "$mem" || -z "$mem_total" || -z "$gpu_name" ]]; then
  echo '{"text":"󰓹 N/A","tooltip":"Unable to query GPU"}'
  exit 0
fi

printf '{"text":"󰓹 %s%%","tooltip":"GPU: %s\nUsage: %s%%\nTemperature: %s°C\nMemory: %sMiB / %sMiB"}\n' \
  "$util" "$gpu_name" "$util" "$temp" "$mem" "$mem_total"
