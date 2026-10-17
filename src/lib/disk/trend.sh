#!/usr/bin/env bash

[[ -n "${_DISK_REVAMPED_TREND_LOADED:-}" ]] && return 0
_DISK_REVAMPED_TREND_LOADED=1

disk_fill_rate_compute() {
  [[ "${1}" =~ ^[0-9]+$ && "${2}" =~ ^[0-9]+$ && "${3}" =~ ^[0-9]+$ ]] || { echo ""; return 0; }
  (( ${3} <= 0 )) && { echo ""; return 0; }
  LC_ALL=C awk -v now="${1}" -v prev="${2}" -v secs="${3}" 'BEGIN { printf "%.1f", (now - prev) * 3600.0 / secs / 1048576 }'
}

disk_render_fill_rate() {
  local r="${1}"
  [[ -n "${r}" ]] || { echo ""; return 0; }
  [[ "${r}" =~ ^-?[0-9]+(\.[0-9]+)?$ ]] || { echo ""; return 0; }
  LC_ALL=C awk -v r="${r}" 'BEGIN { if (r == 0) { exit } printf "%s%.1fG/h", (r > 0 ? "+" : ""), r }'
}

disk_eta_compute() {
  local avail="${1}" rate="${2}"
  [[ "${avail}" =~ ^[0-9]+$ ]] || { echo ""; return 0; }
  [[ "${rate}" =~ ^-?[0-9]+(\.[0-9]+)?$ ]] || { echo ""; return 0; }
  LC_ALL=C awk -v a="${avail}" -v r="${rate}" 'BEGIN { if (r <= 0) { exit } printf "%d", a / 1048576 / r }'
}

disk_render_eta() {
  local h="${1}"
  [[ "${h}" =~ ^[0-9]+$ ]] || { echo ""; return 0; }
  if (( h >= 24 )); then
    echo "$(( h / 24 ))d"
  elif (( h >= 1 )); then
    echo "${h}h"
  else
    echo "<1h"
  fi
}

export -f disk_fill_rate_compute
export -f disk_render_fill_rate
export -f disk_eta_compute
export -f disk_render_eta
