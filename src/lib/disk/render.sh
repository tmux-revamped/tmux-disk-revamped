#!/usr/bin/env bash
#
# render.sh: map cached disk values to icons, colors, and formatted text.

[[ -n "${_DISK_REVAMPED_RENDER_LOADED:-}" ]] && return 0
_DISK_REVAMPED_RENDER_LOADED=1

_DISK_RENDER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${_DISK_RENDER_DIR}/../tmux/tmux-ops.sh"

_disk_level() {
  local v="${1%%.*}" med="${2}" high="${3}"
  [[ "${v}" =~ ^-?[0-9]+$ ]] || v=0
  if (( v >= high )); then
    echo "high"
  elif (( v >= med )); then
    echo "medium"
  else
    echo "low"
  fi
}

_disk_value_level() {
  _disk_level "${1:-0}" "$(get_tmux_option "@disk_revamped_medium_thresh" "70")" \
    "$(get_tmux_option "@disk_revamped_high_thresh" "90")"
}

disk_render_percentage() {
  [[ -z "${1}" ]] && { echo ""; return 0; }
  local fmt
  fmt=$(get_tmux_option "@disk_revamped_percentage_format" "%s%%")
  # shellcheck disable=SC2059
  printf "${fmt}" "${1}"
}

disk_render_icon() {
  [[ -z "${1}" ]] && { echo ""; return 0; }
  case "$(_disk_value_level "${1}")" in
    high)   get_tmux_option "@disk_revamped_high_icon" "▰▰▰" ;;
    medium) get_tmux_option "@disk_revamped_medium_icon" "▰▰▱" ;;
    *)      get_tmux_option "@disk_revamped_low_icon" "▰▱▱" ;;
  esac
}

disk_render_fg() {
  [[ -z "${1}" ]] && { echo ""; return 0; }
  get_tmux_option "@disk_revamped_$(_disk_value_level "${1}")_fg_color" ""
}

disk_render_bg() {
  [[ -z "${1}" ]] && { echo ""; return 0; }
  get_tmux_option "@disk_revamped_$(_disk_value_level "${1}")_bg_color" ""
}

disk_render_size() {
  [[ -z "${1}" ]] && { echo ""; return 0; }
  local fmt
  fmt=$(get_tmux_option "@disk_revamped_size_format" "%sG")
  # shellcheck disable=SC2059
  printf "${fmt}" "${1}"
}

disk_render_all() {
  [[ -z "${1}" ]] && { echo ""; return 0; }
  local sep out="" line
  sep=$(get_tmux_option "@disk_revamped_separator" ", ")
  while IFS= read -r line; do
    [[ -z "${line}" ]] && continue
    [[ -n "${out}" ]] && out="${out}${sep}"
    out="${out}${line}"
  done <<< "${1}"
  echo "${out}"
}

export -f _disk_level
export -f _disk_value_level
export -f disk_render_percentage
export -f disk_render_icon
export -f disk_render_fg
export -f disk_render_bg
export -f disk_render_size
export -f disk_render_all
