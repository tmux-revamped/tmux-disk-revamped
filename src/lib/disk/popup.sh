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
  _tmux display-popup -E "${DISK_SELF} eat_view; read -r _"
}

disk_card() {
  printf 'Disk %s\n' "$(get_tmux_option "@disk_revamped_mount" "/")"
  printf 'Usage %s%%\n' "$(cache_get percent)"
  printf 'Used  %sG\n' "$(cache_get used)"
  printf 'Free  %sG\n' "$(cache_get free)"
  printf 'Total %sG\n' "$(cache_get total)"
  local all hash="#"
  all="$(cache_get all)"
  all="${all//"${hash}${hash}"/${hash}}"
  [[ -n "${all}" ]] && printf '\nMounts\n%s\n' "${all}"
  return 0
}

disk_show_popup() {
  _tmux display-popup -E "${DISK_SELF} card; read -r _"
}

export -f _tmux
export -f _run_du
export -f disk_eat_path
export -f disk_eat_refresh
export -f disk_eat_view
export -f disk_show_eat
export -f disk_card
export -f disk_show_popup
