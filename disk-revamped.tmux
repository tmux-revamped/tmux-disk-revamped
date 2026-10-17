#!/usr/bin/env bash

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DISK_CMD="${PLUGIN_DIR}/src/disk.sh"
HASH="#"
DISK_CMD_QUOTED="$(printf '%q' "${DISK_CMD}")"
DISK_CMD_QUOTED="${DISK_CMD_QUOTED//"${HASH}"/${HASH}${HASH}}"

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
  "#(${DISK_CMD_QUOTED} percentage)"
  "#(${DISK_CMD_QUOTED} icon)"
  "#(${DISK_CMD_QUOTED} fg_color)"
  "#(${DISK_CMD_QUOTED} bg_color)"
  "#(${DISK_CMD_QUOTED} used)"
  "#(${DISK_CMD_QUOTED} total)"
  "#(${DISK_CMD_QUOTED} read)"
  "#(${DISK_CMD_QUOTED} write)"
  "#(${DISK_CMD_QUOTED} all)"
  "#(${DISK_CMD_QUOTED} free)"
  "#(${DISK_CMD_QUOTED} inodes)"
  "#(${DISK_CMD_QUOTED} purgeable)"
  "#(${DISK_CMD_QUOTED} graph)"
  "#(${DISK_CMD_QUOTED} fill_rate)"
  "#(${DISK_CMD_QUOTED} full_eta)"
  "#(${DISK_CMD_QUOTED} mounts)"
)

render_mode="$(tmux show-option -gqv "@disk_revamped_render")"

target_for() {
  local command="${1}" metric
  metric="${command##* }"
  metric="${metric%)}"
  if [[ "${render_mode}" == "options" ]]; then
    printf '#{E:@disk_revamped_out_%s}' "${metric}"
  else
    printf '%s' "${command}"
  fi
}

interpolate() {
  local value="${1}" i placeholder replacement out rest
  for (( i = 0; i < ${#placeholders[@]}; i++ )); do
    placeholder="${placeholders[i]#\\}"
    replacement="$(target_for "${commands[i]}")"
    out=""
    rest="${value}"
    while [[ "${rest}" == *"${placeholder}"* ]]; do
      out="${out}${rest%%"${placeholder}"*}${replacement}"
      rest="${rest#*"${placeholder}"}"
    done
    value="${out}${rest}"
  done
  echo "${value}"
}

used_metrics() {
  local text="${1}" used="" i metric
  for (( i = 0; i < ${#placeholders[@]}; i++ )); do
    metric="${commands[i]##* }"
    metric="${metric%)}"
    if [[ "${text}" == *${placeholders[i]}* || "${text}" == *"@disk_revamped_out_${metric}}"* ]]; then
      used="${used:+${used} }${metric}"
    fi
  done
  echo "${used}"
}

update_option() {
  local option="${1}"
  local current
  current=$(tmux show-option -gqv "${option}")
  tmux set-option -gq "${option}" "$(interpolate "${current}")"
}

chmod +x "${DISK_CMD}" 2>/dev/null || true

status_text="$(tmux show-option -gqv status-left) $(tmux show-option -gqv status-right)"
tmux set-option -gq "@disk_revamped_published" "$(used_metrics "${status_text}")"

update_option "status-left"
update_option "status-right"

if [[ "${render_mode}" == "options" ]]; then
  "${DISK_CMD}" start 2>/dev/null || true
fi

bind_popup() {
  local key="${1}"
  local cmd="${2}"
  [[ -n "${key}" ]] || return 0
  [[ "${key}" == "off" ]] && return 0
  tmux bind-key "${key}" run-shell "${DISK_CMD_QUOTED} ${cmd}"
}

popup_key=$(tmux show-option -gqv "@disk_revamped_popup_key")
[[ -z "${popup_key}" ]] && popup_key="M-d"
eat_key=$(tmux show-option -gqv "@disk_revamped_eat_key")

bind_popup "${popup_key}" "popup"
bind_popup "${eat_key}" "eat"
