#!/usr/bin/env bash
#
# disk.sh: command dispatcher for tmux-disk-revamped.
#
# Usage: disk.sh percentage | icon | fg_color | bg_color | used | total | refresh

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

export CACHE_PREFIX="disk_revamped"
export PLUGIN_LOG_NS="disk-revamped"

export DISK_SELF="${PLUGIN_DIR}/src/disk.sh"

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
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/disk/history.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/disk/trend.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/disk/notify.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/disk/popup.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/disk/doctor.sh"

disk_max_age() {
  get_tmux_option "@disk_revamped_interval" "30"
}

disk_mount() {
  get_tmux_option "@disk_revamped_mount" "/"
}

disk_refresh() {
  local pct used total avail
  read -r pct used total avail <<< "$(read_disk "$(disk_mount)")"
  cache_set percent "${pct}"
  cache_set used "${used}"
  cache_set total "${total}"
  cache_set free "${avail}"
  cache_set all "$(read_all_disks)"
  disk_refresh_io
  disk_refresh_fill "${used}" "${avail}"
  disk_refresh_inodes
  disk_refresh_mounts
  disk_refresh_purgeable
  disk_history_push "${pct}"
  disk_notify_check "${pct}" "$(disk_high_thresh)"
}

# disk_refresh_io -> compute read and write rates from the cumulative counters,
# keeping the previous counters in tmux options so no temp file is needed.
disk_refresh_io() {
  local io rd wr now prev_rd prev_wr prev_ts dt
  io="$(read_disk_io)"
  [[ -n "${io}" ]] || return 0
  read -r rd wr <<< "${io}"
  now=$(date +%s)
  prev_rd=$(cache_get rd_raw)
  prev_wr=$(cache_get wr_raw)
  prev_ts=$(cache_get io_ts)
  if [[ "${prev_ts}" =~ ^[0-9]+$ ]]; then
    dt=$(( now - prev_ts ))
    cache_set read "$(disk_format_rate "$(disk_rate_compute "${rd}" "${prev_rd}" "${dt}")")"
    cache_set write "$(disk_format_rate "$(disk_rate_compute "${wr}" "${prev_wr}" "${dt}")")"
  fi
  cache_set rd_raw "${rd}"
  cache_set wr_raw "${wr}"
  cache_set io_ts "${now}"
}

disk_high_thresh() {
  get_tmux_option "@disk_revamped_high_thresh" "90"
}

# disk_refresh_fill USED AVAIL -> compute the fill rate and time-until-full from
# the change in used space, keeping the previous reading in tmux options.
disk_refresh_fill() {
  local used="${1}" avail="${2}" now prev_used prev_ts dt rate
  [[ "${used}" =~ ^[0-9]+$ ]] || return 0
  now=$(date +%s)
  prev_used=$(cache_get used_raw)
  prev_ts=$(cache_get fill_ts)
  if [[ "${prev_ts}" =~ ^[0-9]+$ && "${prev_used}" =~ ^[0-9]+$ ]]; then
    dt=$(( now - prev_ts ))
    rate=$(disk_fill_rate_compute "${used}" "${prev_used}" "${dt}")
    cache_set fill_rate "${rate}"
    if [[ "${avail}" =~ ^[0-9]+$ ]]; then
      cache_set full_eta "$(disk_eta_compute "${avail}" "${rate}")"
    fi
  fi
  cache_set used_raw "${used}"
  cache_set fill_ts "${now}"
}

# disk_refresh_inodes -> cache the inode usage percentage for the mount.
disk_refresh_inodes() {
  cache_set inodes "$(read_inodes "$(disk_mount)")"
}

# disk_refresh_purgeable -> cache APFS purgeable space, empty off macOS.
disk_refresh_purgeable() {
  cache_set purgeable "$(read_purgeable "$(disk_mount)")"
}

# disk_refresh_mounts -> cache "<mount> <pct>%" for every pinned mount.
disk_refresh_mounts() {
  local list m pct out=""
  list=$(get_tmux_option "@disk_revamped_mounts" "")
  [[ -n "${list}" ]] || return 0
  list="${list//,/ }"
  for m in ${list}; do
    read -r pct _ <<< "$(read_disk "${m}")"
    [[ -n "${pct}" ]] || continue
    out="${out}${out:+$'\n'}${m} ${pct}%"
  done
  cache_set mounts "${out}"
}

disk_tick() {
  cache_refresh_if_stale percent "$(disk_max_age)" disk_refresh
}

main() {
  local cmd="${1:-}"

  case "${cmd}" in
    refresh)   disk_refresh; return 0 ;;
    card)      disk_card; return 0 ;;
    eat_view)  disk_eat_view; return 0 ;;
    doctor)    disk_doctor; return 0 ;;
    popup)     disk_show_popup; return 0 ;;
    eat)       disk_show_eat; return 0 ;;
  esac

  disk_tick

  case "${cmd}" in
    percentage) disk_render_percentage "$(cache_get percent)" ;;
    icon)       disk_render_icon "$(cache_get percent)" ;;
    fg_color)   disk_render_fg "$(cache_get percent)" ;;
    bg_color)   disk_render_bg "$(cache_get percent)" ;;
    used)       disk_render_size "$(cache_get used)" ;;
    total)      disk_render_size "$(cache_get total)" ;;
    free)       disk_render_size "$(cache_get free)" ;;
    read)       cache_get read ;;
    write)      cache_get write ;;
    inodes)     disk_render_inodes "$(cache_get inodes)" ;;
    purgeable)  disk_render_size "$(cache_get purgeable)" ;;
    graph)      disk_sparkline ;;
    fill_rate)  disk_render_fill_rate "$(cache_get fill_rate)" ;;
    full_eta)   disk_render_eta "$(cache_get full_eta)" ;;
    mounts)     disk_render_all "$(cache_get mounts)" ;;
    all)        disk_render_all "$(cache_get all)" ;;
    *)          return 0 ;;
  esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
