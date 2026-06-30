#!/usr/bin/env bash
#
# disk-revamped.tmux: TPM entry point.
#
# Replaces the #{disk_*} placeholders in status-left and status-right with calls
# to the dispatcher, which reads cached values and never blocks the render.

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DISK_CMD="${PLUGIN_DIR}/src/disk.sh"

placeholders=(
  "\#{disk_percentage}"
  "\#{disk_icon}"
  "\#{disk_fg_color}"
  "\#{disk_bg_color}"
  "\#{disk_used}"
  "\#{disk_total}"
  "\#{disk_read}"
  "\#{disk_write}"
  "\#{disk_all}"
  "\#{disk_free}"
  "\#{disk_inodes}"
  "\#{disk_purgeable}"
  "\#{disk_graph}"
  "\#{disk_fill_rate}"
  "\#{disk_full_eta}"
  "\#{disk_mounts}"
)

commands=(
  "#(${DISK_CMD} percentage)"
  "#(${DISK_CMD} icon)"
  "#(${DISK_CMD} fg_color)"
  "#(${DISK_CMD} bg_color)"
  "#(${DISK_CMD} used)"
  "#(${DISK_CMD} total)"
  "#(${DISK_CMD} read)"
  "#(${DISK_CMD} write)"
  "#(${DISK_CMD} all)"
  "#(${DISK_CMD} free)"
  "#(${DISK_CMD} inodes)"
  "#(${DISK_CMD} purgeable)"
  "#(${DISK_CMD} graph)"
  "#(${DISK_CMD} fill_rate)"
  "#(${DISK_CMD} full_eta)"
  "#(${DISK_CMD} mounts)"
)

interpolate() {
  local value="${1}"
  local i
  for (( i = 0; i < ${#placeholders[@]}; i++ )); do
    value="${value//${placeholders[i]}/${commands[i]}}"
  done
  echo "${value}"
}

update_option() {
  local option="${1}"
  local current
  current=$(tmux show-option -gqv "${option}")
  tmux set-option -gq "${option}" "$(interpolate "${current}")"
}

chmod +x "${DISK_CMD}" 2>/dev/null || true

update_option "status-left"
update_option "status-right"

# Optional popup key bindings. display-popup needs tmux 3.2 or newer. A binding
# is created only when the user sets the corresponding key option.
bind_popup() {
  local key="${1}"
  local cmd="${2}"
  [[ -n "${key}" ]] || return 0
  tmux bind-key "${key}" run-shell "${DISK_CMD} ${cmd}"
}

popup_key=$(tmux show-option -gqv "@disk_revamped_popup_key")
eat_key=$(tmux show-option -gqv "@disk_revamped_eat_key")

bind_popup "${popup_key}" "popup"
bind_popup "${eat_key}" "eat"
