#!/usr/bin/env bash

MONITORS_JSON=$(hyprctl monitors all -j)

INTERNAL=$(echo "$MONITORS_JSON" | jq -r '.[] | select(.name | startswith("eDP")) | .name' | head -n1)
EXTERNAL=$(echo "$MONITORS_JSON" | jq -r '.[] | select(.name | startswith("eDP") | not) | .name' | head -n1)

if [ -z "$INTERNAL" ]; then
    notify-send "Display Toggle" "No internal eDP display found."
    exit 0
fi
if [ -z "$EXTERNAL" ]; then
    notify-send "Display Toggle" "No external monitor connected."
    exit 0
fi

SCALE=$(echo "$MONITORS_JSON" | jq -r ".[] | select(.name == \"$EXTERNAL\") | .scale")
INTERNAL_ID=$(echo "$MONITORS_JSON" | jq -r ".[] | select(.name == \"$INTERNAL\") | .id")

MIRROR_TARGET_ID=$(echo "$MONITORS_JSON" | jq -r ".[] | select(.name == \"$EXTERNAL\") | .mirrorOf")

if [ "$MIRROR_TARGET_ID" == "$INTERNAL_ID" ]; then
    hyprctl keyword monitor "$EXTERNAL,preferred,auto,$SCALE"
    notify-send "Display Toggle" "Switched to Extended Mode"
else
    hyprctl keyword monitor "$EXTERNAL,preferred,auto,$SCALE,mirror,$INTERNAL"
    notify-send "Display Toggle" "Switched to Mirrored Mode"
fi
