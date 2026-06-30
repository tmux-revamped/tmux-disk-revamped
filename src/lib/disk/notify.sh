#!/usr/bin/env bash
#
# notify.sh: full-disk threshold desktop notification.
#
# Off by default. When @disk_revamped_notify is 1, crossing the high threshold
# fires one desktop notification through the _disk_notify seam, which tests mock.
# A one-shot guard kept in a tmux option suppresses repeats until usage drops
# back below the threshold, so the user is not paged on every refresh.

[[ -n "${_DISK_REVAMPED_NOTIFY_LOADED:-}" ]] && return 0
_DISK_REVAMPED_NOTIFY_LOADED=1

_DISK_NOTIFY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${_DISK_NOTIFY_DIR}/../tmux/tmux-ops.sh"
# shellcheck source=/dev/null
source "${_DISK_NOTIFY_DIR}/../utils/platform.sh"
# shellcheck source=/dev/null
source "${_DISK_NOTIFY_DIR}/../utils/has-command.sh"

# _disk_notify TITLE MESSAGE -> deliver a desktop notification. The single seam
# every test mocks so no real notifier is ever invoked.
_disk_notify() {
  local title="${1}" message="${2}"
  if is_macos && has_command osascript; then
    osascript -e "display notification \"${message}\" with title \"${title}\"" >/dev/null 2>&1
  elif has_command notify-send; then
    notify-send "${title}" "${message}" >/dev/null 2>&1
  fi
  return 0
}

# _disk_notify_decide PCT THRESH NOTIFIED -> fire | reset | none.
# fire when PCT crosses the threshold and no notice is outstanding; reset when it
# drops back below; none otherwise.
_disk_notify_decide() {
  local pct="${1%%.*}" thresh="${2}" notified="${3}"
  [[ "${pct}" =~ ^[0-9]+$ ]] || { echo "none"; return 0; }
  [[ "${thresh}" =~ ^[0-9]+$ ]] || { echo "none"; return 0; }
  if (( pct >= thresh )); then
    [[ "${notified}" == "1" ]] && { echo "none"; return 0; }
    echo "fire"
    return 0
  fi
  [[ "${notified}" == "1" ]] && { echo "reset"; return 0; }
  echo "none"
}

# disk_notify_check PCT THRESH -> evaluate the crossing and act on it.
disk_notify_check() {
  local pct="${1}" thresh="${2}" notified action
  [[ "$(get_tmux_option "@disk_revamped_notify" "0")" == "1" ]] || return 0
  notified=$(get_tmux_option "@disk_revamped_notified" "0")
  action=$(_disk_notify_decide "${pct}" "${thresh}" "${notified}")
  case "${action}" in
    fire)
      _disk_notify "Disk almost full" "Usage at ${pct}% on $(get_tmux_option "@disk_revamped_mount" "/")"
      set_tmux_option "@disk_revamped_notified" "1"
      ;;
    reset)
      set_tmux_option "@disk_revamped_notified" "0"
      ;;
    *) : ;;
  esac
  return 0
}

export -f _disk_notify
export -f _disk_notify_decide
export -f disk_notify_check
