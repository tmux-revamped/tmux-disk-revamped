#!/usr/bin/env bash
#
# popup.sh: detail popup and the what-is-eating-space view.
#
# Both popups go through the single _tmux seam, so a test never launches a real
# display-popup. The what-is-eating-space scan runs du in a detached cache worker
# in production; the du call lives behind the _run_du seam, which tests mock. No
# temp files: the scan result is cached in a tmux user-option like every other
# value.

[[ -n "${_DISK_REVAMPED_POPUP_LOADED:-}" ]] && return 0
_DISK_REVAMPED_POPUP_LOADED=1

_DISK_POPUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${_DISK_POPUP_DIR}/../tmux/tmux-ops.sh"
# shellcheck source=/dev/null
source "${_DISK_POPUP_DIR}/../utils/cache.sh"

# Path the dispatcher re-invokes inside a popup. Overridden by the dispatcher.
DISK_SELF="${DISK_SELF:-disk.sh}"

# _tmux ARGS -> the one tmux seam popups use. Mocked in tests.
_tmux() { tmux "$@"; }

# _run_du PATH -> the largest immediate children of PATH, biggest first. The seam
# that owns the heavy filesystem scan, mocked in tests.
_run_du() {
  local path="${1}" n
  n=$(get_tmux_option "@disk_revamped_eat_count" "10")
  du -sh "${path}"/* 2>/dev/null | sort -rh 2>/dev/null | head -n "${n}"
}

# disk_eat_path -> the directory the space scan starts from.
disk_eat_path() {
  local p
  p=$(get_tmux_option "@disk_revamped_eat_path" "")
  [[ -n "${p}" ]] || p=$(get_tmux_option "@disk_revamped_mount" "/")
  echo "${p}"
}

# disk_eat_refresh -> the detached worker: scan and cache the top consumers.
disk_eat_refresh() {
  cache_set eat "$(_run_du "$(disk_eat_path)")"
}

# disk_eat_view -> print the cached scan, or a placeholder before it lands.
disk_eat_view() {
  local v
  v="$(cache_get eat)"
  if [[ -n "${v}" ]]; then
    printf 'Largest items under %s\n\n%s\n' "$(disk_eat_path)" "${v}"
  else
    printf 'Scanning %s ...\n' "$(disk_eat_path)"
  fi
}

# disk_show_eat -> kick off the scan when stale, then open the popup.
disk_show_eat() {
  cache_refresh_if_stale eat "$(get_tmux_option "@disk_revamped_eat_interval" "60")" disk_eat_refresh
  _tmux display-popup -E "${DISK_SELF} eat_view; read -r _"
}

# disk_card -> a plain-text card built from already-cached values.
disk_card() {
  printf 'Disk %s\n' "$(get_tmux_option "@disk_revamped_mount" "/")"
  printf 'Usage %s%%\n' "$(cache_get percent)"
  printf 'Used  %sG\n' "$(cache_get used)"
  printf 'Free  %sG\n' "$(cache_get free)"
  printf 'Total %sG\n' "$(cache_get total)"
  local all
  all="$(cache_get all)"
  [[ -n "${all}" ]] && printf '\nMounts\n%s\n' "${all}"
  return 0
}

# disk_show_popup -> open the detail card popup.
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
