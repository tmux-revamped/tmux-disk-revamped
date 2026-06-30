#!/usr/bin/env bash
#
# doctor.sh: a capability report explaining what this host can and cannot show.

[[ -n "${_DISK_REVAMPED_DOCTOR_LOADED:-}" ]] && return 0
_DISK_REVAMPED_DOCTOR_LOADED=1

_DISK_DOCTOR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${_DISK_DOCTOR_DIR}/../utils/platform.sh"
# shellcheck source=/dev/null
source "${_DISK_DOCTOR_DIR}/../utils/has-command.sh"
# shellcheck source=/dev/null
source "${_DISK_DOCTOR_DIR}/../tmux/tmux-ops.sh"

# _doctor_tool NAME -> "  NAME: found" or "  NAME: not found".
_doctor_tool() {
  if has_command "${1}"; then
    printf '  %s: found\n' "${1}"
  else
    printf '  %s: not found\n' "${1}"
  fi
}

# disk_doctor -> a human readable report of detected sources and gaps.
disk_doctor() {
  printf 'tmux-disk-revamped doctor\n'
  printf 'platform: %s\n' "$(platform_os)"

  if is_macos; then
    printf 'usage source: df -g\n'
    printf 'io rates: unavailable (macOS has no per-disk read/write counters)\n'
    printf 'purgeable: APFS via diskutil\n'
  elif is_linux; then
    printf 'usage source: df -BG\n'
    printf 'io rates: /proc/diskstats\n'
    printf 'purgeable: unavailable (macOS only)\n'
  else
    printf 'usage source: none (unsupported platform)\n'
    printf 'io rates: unavailable\n'
    printf 'purgeable: unavailable\n'
  fi

  printf 'tools\n'
  _doctor_tool df
  _doctor_tool du
  _doctor_tool diskutil
  _doctor_tool notify-send
  _doctor_tool osascript

  printf 'notifications: %s\n' "$([[ "$(get_tmux_option "@disk_revamped_notify" "0")" == "1" ]] && echo "on" || echo "off")"
  return 0
}

export -f _doctor_tool
export -f disk_doctor
