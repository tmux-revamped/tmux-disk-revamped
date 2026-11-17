#!/usr/bin/env bash

[[ -n "${_DISK_REVAMPED_POPUP_LOADED:-}" ]] && return 0
_DISK_REVAMPED_POPUP_LOADED=1

_DISK_POPUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${_DISK_POPUP_DIR}/../tmux/tmux-ops.sh"
# shellcheck source=/dev/null
source "${_DISK_POPUP_DIR}/../utils/cache.sh"

DISK_SELF="${DISK_SELF:-disk.sh}"

_tmux() { tmux "$@"; }

_disk_hash_free() {
  local rest="${1}" out="" piece hash="#"
  while [[ "${rest}" == *"${hash}"* ]]; do
    printf -v piece '%q' "${rest%%"${hash}"*}"
    out+="${piece}\"\$(printf '%b' '\\0043')\""
    rest="${rest#*"${hash}"}"
  done
  printf -v piece '%q' "${rest}"
  printf '%s%s' "${out}" "${piece}"
}

_disk_popup_cmd() {
  printf '%s %s; read -r _' "$(_disk_hash_free "${DISK_SELF}")" "${1}"
}

_run_du() {
  local path="${1}" n f
  local -a entries=()
  n=$(get_tmux_option "@disk_revamped_eat_count" "10")
  for f in "${path}"/* "${path}"/.[!.]* "${path}"/..?*; do
    [[ -e "${f}" || -L "${f}" ]] && entries+=("${f}")
  done
  ((${#entries[@]} > 0)) || return 0
  du -xsh "${entries[@]}" 2>/dev/null | sort -rh 2>/dev/null | head -n "${n}"
}

disk_eat_path() {
  local p
  p=$(get_tmux_option "@disk_revamped_eat_path" "")
  [[ -n "${p}" ]] || p=$(get_tmux_option "@disk_revamped_mount" "/")
  echo "${p}"
}

disk_eat_refresh() {
  cache_set eat "$(_run_du "$(disk_eat_path)")"
}

disk_eat_view() {
  local v
  v="$(cache_get eat)"
  if [[ -n "${v}" ]]; then
    printf 'Largest items under %s\n\n%s\n' "$(disk_eat_path)" "${v}"
  else
    printf 'Scanning %s ...\n' "$(disk_eat_path)"
  fi
}

disk_show_eat() {
  cache_refresh_if_stale eat "$(get_tmux_option "@disk_revamped_eat_interval" "60")" disk_eat_refresh
  _tmux display-popup -E "$(_disk_popup_cmd eat_view)"
}

_DISK_CARD_FIXED_ROWS=9

disk_card() {
  printf 'Disk %s\n' "$(get_tmux_option "@disk_revamped_mount" "/")"
  printf 'Usage %s%%\n' "$(cache_get percent)"
  printf 'Used  %sG\n' "$(cache_get used)"
  printf 'Free  %sG\n' "$(cache_get free)"
  printf 'Total %sG\n' "$(cache_get total)"
  local all hash="#"
  all="$(cache_get all)"
  all="${all//"${hash}${hash}"/${hash}}"
  [[ -n "${all}" ]] || return 0
  printf '\nMounts\n'
  _disk_card_mounts "${all}" "$(_disk_screen_size)"
}

_disk_screen_size() {
  stty size 2>/dev/null </dev/tty || true
}

_disk_card_mounts() {
  local all="${1}" size="${2}" rows cols room total
  rows="${size%% *}"
  cols="${size##* }"
  if [[ ! "${rows}" =~ ^[0-9]+$ || ! "${cols}" =~ ^[0-9]+$ ]]; then
    printf '%s\n' "${all}"
    return 0
  fi
  total=$(printf '%s\n' "${all}" | wc -l)
  total=$((total))
  room=$((rows - _DISK_CARD_FIXED_ROWS))
  ((room >= 1)) || room=1
  if ((total <= room)); then
    printf '%s\n' "${all}" | cut -c "1-${cols}"
    return 0
  fi
  printf '%s\n' "${all}" | head -n "${room}" | cut -c "1-${cols}"
  printf 'and %s more\n' "$((total - room))"
}

disk_show_popup() {
  _tmux display-popup -E "$(_disk_popup_cmd card)"
}

export -f _tmux
export -f _disk_popup_cmd
export -f _run_du
export -f disk_eat_path
export -f disk_eat_refresh
export -f disk_eat_view
export -f disk_show_eat
export -f disk_card
export -f _disk_screen_size
export -f _disk_card_mounts
export -f disk_show_popup
