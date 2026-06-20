#!/usr/bin/env bash
#
# disk.sh: disk usage acquisition via df.
#
# disk_parse_df is pure. The df calls live behind seams tests can stub. df flags
# differ by platform, so each platform has its own seam.

[[ -n "${_DISK_REVAMPED_DISK_LOADED:-}" ]] && return 0
_DISK_REVAMPED_DISK_LOADED=1

_DISK_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${_DISK_LIB_DIR}/../utils/platform.sh"

# disk_parse_df TEXT -> "<pct> <used_gb> <total_gb>" from df output.
# Reads the data line that carries the capacity percentage, so a wrapped header
# does not matter. Used and total are reduced to plain integers in gigabytes.
disk_parse_df() {
  local line total used pct
  line=$(printf '%s\n' "${1}" | grep -E '[0-9]+%' | head -1)
  [[ -n "${line}" ]] || { echo ""; return 0; }
  total=$(awk '{ print $2 }' <<< "${line}" | tr -dc '0-9')
  used=$(awk '{ print $3 }' <<< "${line}" | tr -dc '0-9')
  pct=$(grep -oE '[0-9]+%' <<< "${line}" | head -1 | tr -d '%')
  echo "${pct:-0} ${used:-0} ${total:-0}"
}

# Host-probe seams.
_read_df_macos() { df -g "${1}" 2>/dev/null; }
_read_df_linux() { df -BG "${1}" 2>/dev/null; }

# read_disk MOUNT -> "<pct> <used_gb> <total_gb>", empty on an unknown platform.
read_disk() {
  local mount="${1:-/}"
  if is_macos; then
    disk_parse_df "$(_read_df_macos "${mount}")"
  elif is_linux; then
    disk_parse_df "$(_read_df_linux "${mount}")"
  else
    echo ""
  fi
}

export -f disk_parse_df
export -f _read_df_macos
export -f _read_df_linux
export -f read_disk
