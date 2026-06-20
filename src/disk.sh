#!/usr/bin/env bash
#
# disk.sh: command dispatcher for tmux-disk-revamped.
#
# Usage: disk.sh percentage | icon | fg_color | bg_color | used | total | refresh

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

export CACHE_PREFIX="disk_revamped"
export PLUGIN_LOG_NS="disk-revamped"

# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/utils/platform.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/tmux/tmux-ops.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/utils/cache.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/disk/disk.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/disk/render.sh"

disk_max_age() {
  get_tmux_option "@disk_revamped_interval" "30"
}

disk_mount() {
  get_tmux_option "@disk_revamped_mount" "/"
}

disk_refresh() {
  local pct used total
  read -r pct used total <<< "$(read_disk "$(disk_mount)")"
  cache_set percent "${pct}"
  cache_set used "${used}"
  cache_set total "${total}"
}

disk_tick() {
  cache_refresh_if_stale percent "$(disk_max_age)" disk_refresh
}

main() {
  local cmd="${1:-}"

  if [[ "${cmd}" == "refresh" ]]; then
    disk_refresh
    return 0
  fi

  disk_tick

  case "${cmd}" in
    percentage) disk_render_percentage "$(cache_get percent)" ;;
    icon)       disk_render_icon "$(cache_get percent)" ;;
    fg_color)   disk_render_fg "$(cache_get percent)" ;;
    bg_color)   disk_render_bg "$(cache_get percent)" ;;
    used)       disk_render_size "$(cache_get used)" ;;
    total)      disk_render_size "$(cache_get total)" ;;
    *)          return 0 ;;
  esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
