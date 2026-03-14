# Waybar Weather Module (Open-Meteo)

Waybar weather now uses a local script with Open-Meteo instead of `wttrbar`/`wttr.in`.

## Why

- Avoid hangs/timeouts from `wttr.in`.
- Keep module responsive with explicit network timeouts and fallback output.
- Auto-detect location without hardcoding city names.

## Files

- `waybar/.config/waybar/modules/custom-weather.jsonc`
- `waybar/.config/waybar/weather.sh`

## Dependencies

- `curl`
- `jq`

## Behavior

- Auto location: IP geolocation (`ipapi.co`, fallback `ipwho.is`).
- Location cache: `~/.cache/waybar-weather-location.json` (12h TTL).
- Display: compact label (`icon + temperature`) in bar.
- Tooltip: current conditions, today summary, day timeline, and 2-day forecast.
- Click action: sends a desktop notification with current weather summary.

## Optional overrides

Set these env vars if you want fixed coordinates instead of auto-location:

- `WEATHER_LAT`
- `WEATHER_LON`
- `WEATHER_CITY` (optional)
- `WEATHER_COUNTRY` (optional)

## Verify

```bash
~/.config/waybar/weather.sh
omarchy-restart-waybar
```

If the module is blank, run:

```bash
waybar -l debug
```
