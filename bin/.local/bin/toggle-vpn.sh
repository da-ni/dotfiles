#!/usr/bin/env bash
set -euo pipefail

SERVICE="tuvpn.service"

if systemctl --user is-active --quiet "$SERVICE"; then
  if systemctl --user stop "$SERVICE"; then
    notify-send "VPN" "Disconnected"
  else
    notify-send "VPN" "Failed to disconnect"
    exit 1
  fi
else
  if systemctl --user start "$SERVICE"; then
    notify-send "VPN" "Connected"
  else
    notify-send "VPN" "Failed to connect"
    exit 1
  fi
fi
