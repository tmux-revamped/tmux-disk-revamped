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
source "${PLUGIN_DIR}/src/lib/utils/publish.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/utils/ticker.sh"
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

disk_render_metric() {
  local cmd="${1}"
  case "${cmd}" in
    start)   ticker_start "${PLUGIN_DIR}/src/disk.sh"; return 0 ;;
    daemon)  disk_daemon; return 0 ;;
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

disk_is_labelled() {
  case "${1}" in
    percentage | used | total | free | read | write | inodes | purgeable | graph | fill_rate | full_eta | mounts | all) return 0 ;;
    *) return 1 ;;
  esac
}

disk_nerd_label() {
  case "${1}" in
    percentage) printf '\xf3\xb0\x8b\x8a' ;;
    used) printf '\xf3\xb0\x86\xbc' ;;
    total) printf '\xf3\xb0\x86\xbc' ;;
    free) printf '\xf3\xb0\x9d\xb0' ;;
    read) printf '\xf3\xb0\x87\x9a' ;;
    write) printf '\xf3\xb0\x95\x92' ;;
    inodes) printf '\xf3\xb0\x99\x85' ;;
    purgeable) printf '\xf3\xb0\x83\xa2' ;;
    graph) printf '\xf3\xb0\x9e\xb1' ;;
    fill_rate) printf '\xf3\xb0\x94\xb5' ;;
    full_eta) printf '\xf3\xb0\x94\x9f' ;;
    mounts) printf '\xf3\xb0\x89\x93' ;;
    all) printf '\xf3\xb0\x89\x93' ;;
    *) printf '' ;;
  esac
}

disk_option_exists() {
  [[ -n "$(tmux show-option -gq "${1}" 2>/dev/null)" ]]
}

disk_label() {
  local option="@disk_revamped_${1}_label"
  if disk_option_exists "${option}"; then
    tmux show-option -gqv "${option}" 2>/dev/null
  elif [[ "$(get_tmux_option "@disk_revamped_icons" "ascii")" == "nerd" ]]; then
    disk_nerd_label "${1}"
  fi
}

disk_natural_width() {
  case "${1}" in
    percentage) printf '4' ;;
    read) printf '9' ;;
    write) printf '9' ;;
    inodes) printf '4' ;;
    *) printf '0' ;;
  esac
}

disk_padded() {
  publish_pad "${2}" "$(publish_width disk_revamped "${1}" "$(disk_natural_width "${1}")")"
}

disk_labelled() {
  local metric="${1}" value="${2}" label
  [[ -n "${value}" ]] || return 0
  value="$(disk_padded "${metric}" "${value}")"
  label="$(disk_label "${metric}")"
  if [[ -n "${label}" ]]; then
    printf '%s %s\n' "${label}" "${value}"
  else
    printf '%s\n' "${value}"
  fi
}

disk_output() {
  local metric="${1}" out
  out="$(disk_render_metric "${metric}")"
  if disk_is_labelled "${metric}"; then
    disk_labelled "${metric}" "${out}"
  elif [[ -n "${out}" ]]; then
    printf '%s\n' "${out}"
  fi
}

disk_publish() {
  local metric
  disk_refresh
  for metric in $(get_tmux_option "@disk_revamped_published" ""); do
    publish_add "@disk_revamped_out_${metric}" "$(disk_output "${metric}")"
  done
  publish_commit
}

_disk_reexec() { exec "${PLUGIN_DIR}/src/disk.sh" daemon; }

disk_daemon() {
  if ticker_run disk_revamped disk_publish "$$"; then
    _disk_reexec
  fi
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
  disk_output "${cmd}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
