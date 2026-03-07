#!/usr/bin/env bash

INTERFACE=$(ip route | awk '/^default/ {print $5}' | grep -vE '^(tun|tap|vpn|ppp|wg)' | head -n 1)

if [[ -z "$INTERFACE" ]]; then
  INTERFACE=$(ip route | awk '/^default/ {print $5}' | head -n 1)
fi

if [[ -z "$INTERFACE" ]] || [[ ! -d "/sys/class/net/$INTERFACE" ]]; then
  echo "⇣ 0.00 Mbps ⇡ 0.00 Mbps"
  exit 0
fi

if [[ ! -f "/sys/class/net/$INTERFACE/statistics/rx_bytes" ]] ||
   [[ ! -f "/sys/class/net/$INTERFACE/statistics/tx_bytes" ]]; then
  echo "⇣ 0.00 Mbps ⇡ 0.00 Mbps"
  exit 0
fi

RX_PREV=$(<"/sys/class/net/$INTERFACE/statistics/rx_bytes")
TX_PREV=$(<"/sys/class/net/$INTERFACE/statistics/tx_bytes")
sleep 1
RX_CURR=$(<"/sys/class/net/$INTERFACE/statistics/rx_bytes")
TX_CURR=$(<"/sys/class/net/$INTERFACE/statistics/tx_bytes")

RX_DIFF=$((RX_CURR - RX_PREV))
TX_DIFF=$((TX_CURR - TX_PREV))

RX_MBPS=$(echo "scale=2; $RX_DIFF * 8 / 1000000" | bc)
TX_MBPS=$(echo "scale=2; $TX_DIFF * 8 / 1000000" | bc)

echo "⇣ ${RX_MBPS} Mbps ⇡ ${TX_MBPS} Mbps"
