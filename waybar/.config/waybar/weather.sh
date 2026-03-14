#!/usr/bin/env bash

set -u

LOCATION_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/waybar-weather-location.json"
LOCATION_TTL=43200

fallback_json() {
  printf '{"text":"--","tooltip":"Weather service unavailable","class":"warning"}\n'
}

have_cmd() {
  command -v "$1" >/dev/null 2>&1
}

fetch_url() {
  curl -fsSL --connect-timeout 3 --max-time 8 "$1"
}

map_weather_code() {
  case "$1" in
    0) printf 'Clear sky|☀' ;;
    1) printf 'Mainly clear|🌤' ;;
    2) printf 'Partly cloudy|⛅' ;;
    3) printf 'Overcast|☁' ;;
    45|48) printf 'Fog|🌫' ;;
    51|53|55|56|57) printf 'Drizzle|🌦' ;;
    61|63|65|66|67|80|81|82) printf 'Rain|🌧' ;;
    71|73|75|77|85|86) printf 'Snow|❄' ;;
    95|96|99) printf 'Thunderstorm|⛈' ;;
    *) printf 'Unknown|🌡' ;;
  esac
}

load_cached_location() {
  [[ -f "$LOCATION_CACHE" ]] || return 1
  local now
  now=$(date +%s)
  local mtime
  mtime=$(stat -c %Y "$LOCATION_CACHE" 2>/dev/null || printf '0')
  (( now - mtime < LOCATION_TTL )) || return 1
  jq -er '.lat and .lon' "$LOCATION_CACHE" >/dev/null 2>&1 || return 1
  jq -r '.' "$LOCATION_CACHE"
}

save_cached_location() {
  mkdir -p "$(dirname "$LOCATION_CACHE")"
  printf '%s\n' "$1" >"$LOCATION_CACHE"
}

resolve_location() {
  if [[ -n "${WEATHER_LAT:-}" && -n "${WEATHER_LON:-}" ]]; then
    jq -n \
      --argjson lat "$WEATHER_LAT" \
      --argjson lon "$WEATHER_LON" \
      --arg city "${WEATHER_CITY:-Custom location}" \
      --arg country "${WEATHER_COUNTRY:-}" \
      '{lat:$lat,lon:$lon,city:$city,country:$country}'
    return 0
  fi

  if load_cached_location; then
    return 0
  fi

  local raw loc
  raw=$(fetch_url "https://ipapi.co/json/" 2>/dev/null || true)
  if [[ -n "$raw" ]]; then
    loc=$(jq -cer '{lat:(.latitude|tonumber),lon:(.longitude|tonumber),city:(.city // "Unknown"),country:(.country_name // "")}' <<<"$raw" 2>/dev/null || true)
    if [[ -n "$loc" ]]; then
      save_cached_location "$loc"
      printf '%s\n' "$loc"
      return 0
    fi
  fi

  raw=$(fetch_url "https://ipwho.is/" 2>/dev/null || true)
  if [[ -n "$raw" ]]; then
    loc=$(jq -cer 'select(.success == true) | {lat:(.latitude|tonumber),lon:(.longitude|tonumber),city:(.city // "Unknown"),country:(.country // "")}' <<<"$raw" 2>/dev/null || true)
    if [[ -n "$loc" ]]; then
      save_cached_location "$loc"
      printf '%s\n' "$loc"
      return 0
    fi
  fi

  return 1
}

main() {
  have_cmd curl || { fallback_json; return 0; }
  have_cmd jq || { fallback_json; return 0; }

  local location lat lon city country
  location=$(resolve_location 2>/dev/null || true)
  [[ -n "$location" ]] || { fallback_json; return 0; }

  lat=$(jq -r '.lat' <<<"$location")
  lon=$(jq -r '.lon' <<<"$location")
  city=$(jq -r '.city' <<<"$location")
  country=$(jq -r '.country // ""' <<<"$location")

  local weather_url weather
  weather_url="https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&current=temperature_2m,apparent_temperature,weather_code,wind_speed_10m,relative_humidity_2m,precipitation&hourly=temperature_2m,weather_code,precipitation_probability&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,sunrise,sunset,wind_speed_10m_max&forecast_days=4&timezone=auto"
  weather=$(fetch_url "$weather_url" 2>/dev/null || true)
  [[ -n "$weather" ]] || { fallback_json; return 0; }

  local temp feels wind humidity precip code condition icon place text tooltip notify_body
  temp=$(jq -r '.current.temperature_2m // empty' <<<"$weather")
  feels=$(jq -r '.current.apparent_temperature // empty' <<<"$weather")
  wind=$(jq -r '.current.wind_speed_10m // empty' <<<"$weather")
  humidity=$(jq -r '.current.relative_humidity_2m // empty' <<<"$weather")
  precip=$(jq -r '.current.precipitation // empty' <<<"$weather")
  code=$(jq -r '.current.weather_code // empty' <<<"$weather")

  [[ -n "$temp" && -n "$feels" && -n "$wind" && -n "$humidity" && -n "$precip" && -n "$code" ]] || { fallback_json; return 0; }

  IFS='|' read -r condition icon <<<"$(map_weather_code "$code")"
  place="$city"
  [[ -n "$country" ]] && place+=" (${country})"

  local today_label today_max today_min today_pop today_sunrise today_sunset today_windmax
  today_label=$(jq -r '.daily.time[0] | strptime("%Y-%m-%d") | strftime("%a")' <<<"$weather")
  today_max=$(jq -r '.daily.temperature_2m_max[0] // empty' <<<"$weather")
  today_min=$(jq -r '.daily.temperature_2m_min[0] // empty' <<<"$weather")
  today_pop=$(jq -r '.daily.precipitation_probability_max[0] // empty' <<<"$weather")
  today_sunrise=$(jq -r '.daily.sunrise[0][11:16] // empty' <<<"$weather")
  today_sunset=$(jq -r '.daily.sunset[0][11:16] // empty' <<<"$weather")
  today_windmax=$(jq -r '.daily.wind_speed_10m_max[0] // empty' <<<"$weather")
  [[ -n "$today_label" && -n "$today_max" && -n "$today_min" && -n "$today_pop" && -n "$today_sunrise" && -n "$today_sunset" && -n "$today_windmax" ]] || { fallback_json; return 0; }

  local day_timeline h_time h_temp h_code h_pop h_icon timeline_row temp_cell
  day_timeline=""
  while IFS='|' read -r h_time h_temp h_code h_pop; do
    [[ -n "$h_time" ]] || continue
    IFS='|' read -r _ h_icon <<<"$(map_weather_code "$h_code")"
    temp_cell="$(printf '%2.0f' "$h_temp")°"
    printf -v timeline_row '%-5s  %4s  %-4s  %3s%%' "$h_time" "$temp_cell" "$h_icon" "$h_pop"
    day_timeline+="$timeline_row"
    day_timeline+=$'\n'
  done < <(jq -r '.daily.time[0] as $today | [range(0; (.hourly.time|length)) as $i | {full:.hourly.time[$i], time:(.hourly.time[$i][11:16]), t:.hourly.temperature_2m[$i], c:.hourly.weather_code[$i], p:(.hourly.precipitation_probability[$i] // 0)} | select(.full | startswith($today)) | select((.time == "08:00") or (.time == "12:00") or (.time == "16:00") or (.time == "20:00"))] | .[] | "\(.time)|\(.t)|\(.c)|\(.p)"' <<<"$weather")

  [[ -n "$day_timeline" ]] || day_timeline="No day timeline data"
  day_timeline=${day_timeline%$'\n'}

  local next_days d_day d_date d_max d_min d_code d_pop d_cond d_icon timeline_header
  next_days=""
  while IFS='|' read -r d_day d_date d_max d_min d_code d_pop; do
    [[ -n "$d_day" ]] || continue
    IFS='|' read -r d_cond d_icon <<<"$(map_weather_code "$d_code")"
    next_days+="• ${d_day} ${d_date}  ${d_icon} $(printf '%.0f' "$d_max")°/$(printf '%.0f' "$d_min")°  ${d_cond}  (${d_pop}% rain)"
    next_days+=$'\n'
  done < <(jq -r '[range(1; (.daily.time|length)) as $i | {day:(.daily.time[$i] | strptime("%Y-%m-%d") | strftime("%a")), d:(.daily.time[$i][5:10]), max:.daily.temperature_2m_max[$i], min:.daily.temperature_2m_min[$i], c:.daily.weather_code[$i], p:(.daily.precipitation_probability_max[$i] // 0)}] | .[:2] | .[] | "\(.day)|\(.d)|\(.max)|\(.min)|\(.c)|\(.p)"' <<<"$weather")

  next_days=${next_days%$'\n'}
  printf -v timeline_header '%-5s  %4s  %-4s  %4s' 'Time' 'Temp' 'Cond' 'Rain'

  text="${icon} $(printf '%.0f' "$temp")°"
  tooltip="${place}
━━━━━━━━━━━━━━
Now  ${icon} ${condition}
Temp $(printf '%.0f' "$temp")°C (feels $(printf '%.0f' "$feels")°C)
Humidity $(printf '%.0f' "$humidity")%   Wind $(printf '%.0f' "$wind") km/h

Today (${today_label})
↑ $(printf '%.0f' "$today_max")°  ↓ $(printf '%.0f' "$today_min")°   Rain ${today_pop}%   Gusts $(printf '%.0f' "$today_windmax") km/h
Sunrise ${today_sunrise}   Sunset ${today_sunset}

Day timeline
${timeline_header}
${timeline_header//?/-}
${day_timeline}

2-day forecast
${next_days}"
  notify_body="${place}
${condition}, $(printf '%.0f' "$temp")°C (feels $(printf '%.0f' "$feels")°C)
Humidity $(printf '%.0f' "$humidity")% • Wind $(printf '%.0f' "$wind") km/h • Rain now $(printf '%.1f' "$precip") mm

Today: ↑$(printf '%.0f' "$today_max")° ↓$(printf '%.0f' "$today_min")° • Rain ${today_pop}% • Gusts $(printf '%.0f' "$today_windmax") km/h

2-day forecast
${next_days}"

  if [[ "${1:-}" == "--notify" ]]; then
    if have_cmd notify-send; then
      notify-send "Weather" "$notify_body"
    fi
    return 0
  fi

  jq -cn --arg text "$text" --arg tooltip "$tooltip" '{text:$text,tooltip:$tooltip}'
}

main "$@"
