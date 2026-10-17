#!/usr/bin/env bash

[[ -n "${_DISK_REVAMPED_DISK_LOADED:-}" ]] && return 0
_DISK_REVAMPED_DISK_LOADED=1

_DISK_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${_DISK_LIB_DIR}/../utils/platform.sh"

disk_parse_df() {
  local line total used pct avail
  line=$(printf '%s\n' "${1}" | grep -E '[0-9]+%' | head -1)
  [[ -n "${line}" ]] || { echo ""; return 0; }
  total=$(awk '{ print $2 }' <<< "${line}" | tr -dc '0-9')
  used=$(awk '{ print $3 }' <<< "${line}" | tr -dc '0-9')
  pct=$(grep -oE '[0-9]+%' <<< "${line}" | head -1 | tr -d '%')
  avail=$(awk '{ print $4 }' <<< "${line}" | tr -dc '0-9')
  echo "${pct:-0} ${used:-0} ${total:-0} ${avail:-0}"
}

disk_whole_devices() {
  local name
  while IFS= read -r name; do
    case "${name}" in
      "" | loop* | ram* | dm-* | zram*) continue ;;
    esac
    printf '%s\n' "${name}"
  done <<< "${1}"
}

diskstats_io() {
  local devices
  devices="$(printf '%s\n' "${2:-}" | tr '\n' ' ')"
  printf '%s\n' "${1}" | LC_ALL=C awk -v devs="${devices}" '
    BEGIN { n = split(devs, d, " "); for (i = 1; i <= n; i++) keep[d[i]] = 1 }
    ($3 in keep) { r += $6; w += $10 }
    END { print int(r / 2), int(w / 2) }'
}

disk_rate_compute() {
  [[ "${1}" =~ ^[0-9]+$ && "${2}" =~ ^[0-9]+$ && "${3}" =~ ^[0-9]+$ ]] || { echo 0; return 0; }
  (( ${3} <= 0 )) && { echo 0; return 0; }
  local d=$(( ${1} - ${2} ))
  (( d < 0 )) && d=0
  echo $(( d / ${3} ))
}

disk_format_rate() {
  [[ "${1}" =~ ^[0-9]+$ ]] || { echo "0KB/s"; return 0; }
  LC_ALL=C awk -v k="${1}" 'BEGIN {
    if (k >= 1024) printf "%.1fMB/s", k / 1024;
    else printf "%dKB/s", k;
  }'
}

disks_from_df_macos() {
  printf '%s\n' "${1}" | awk 'NR>1 && $1 ~ /^\/dev\// && $9 !~ /^\/Volumes\// { print $9, $5 }'
}

disks_from_df_linux() {
  printf '%s\n' "${1}" | awk 'NR>1 && $1 ~ /^\/dev\// && $6 !~ /^\/boot/ && $6 !~ /^\/snap/ { print $6, $5 }'
}

_read_df_macos() { /bin/df -g "${1}" 2>/dev/null; }
_read_df_linux() { df -BG "${1}" 2>/dev/null; }
_read_diskstats() { cat /proc/diskstats 2>/dev/null; }
_read_sys_block() {
  local f
  for f in /sys/block/*; do
    [[ -e "${f}" ]] && printf '%s\n' "${f##*/}"
  done
  return 0
}
_read_df_h() { df -h 2>/dev/null; }
_read_df_h_macos() { /bin/df -h 2>/dev/null; }
_read_df_kb_macos() { /bin/df -Pk "${1}" 2>/dev/null; }
_read_df_kb_linux() { df -Pk "${1}" 2>/dev/null; }

read_all_disks() {
  if is_macos; then
    disks_from_df_macos "$(_read_df_h_macos)"
  elif is_linux; then
    disks_from_df_linux "$(_read_df_h)"
  fi
}

read_disk_io() {
  if is_linux; then
    diskstats_io "$(_read_diskstats)" "$(disk_whole_devices "$(_read_sys_block)")"
  fi
}

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

read_disk_kb() {
  local mount="${1:-/}"
  if is_macos; then
    disk_parse_df "$(_read_df_kb_macos "${mount}")"
  elif is_linux; then
    disk_parse_df "$(_read_df_kb_linux "${mount}")"
  else
    echo ""
  fi
}

export -f disk_parse_df
export -f disk_whole_devices
export -f diskstats_io
export -f disk_rate_compute
export -f disk_format_rate
export -f disks_from_df_macos
export -f disks_from_df_linux
export -f _read_df_macos
export -f _read_df_linux
export -f _read_diskstats
export -f _read_sys_block
export -f _read_df_h
export -f _read_df_h_macos
export -f _read_df_kb_macos
export -f _read_df_kb_linux
export -f read_disk_kb
export -f read_disk
export -f read_disk_io
export -f read_all_disks

disk_parse_inodes() {
  local line pct
  line=$(printf '%s\n' "${1}" | grep -E '[0-9]+%' | head -1)
  [[ -n "${line}" ]] || { echo ""; return 0; }
  pct=$(grep -oE '[0-9]+%' <<< "${line}" | tail -1 | tr -d '%')
  echo "${pct:-0}"
}

disk_parse_purgeable() {
  local line num unit
  line=$(printf '%s\n' "${1}" | grep -iE 'purgeable' | head -1)
  [[ -n "${line}" ]] || { echo ""; return 0; }
  num=$(grep -oE '[0-9]+(\.[0-9]+)?[[:space:]]*(GB|MB|G|M)' <<< "${line}" | head -1)
  [[ -n "${num}" ]] || { echo ""; return 0; }
  unit=$(grep -oE '(GB|MB|G|M)' <<< "${num}" | head -1)
  num=$(grep -oE '[0-9]+(\.[0-9]+)?' <<< "${num}" | head -1)
  case "${unit}" in
    MB|M) awk -v n="${num}" 'BEGIN { printf "%d", n / 1024 }' ;;
    *)    awk -v n="${num}" 'BEGIN { printf "%d", n }' ;;
  esac
}

_read_df_inodes_macos() { df -i "${1}" 2>/dev/null; }
_read_df_inodes_linux() { df -i "${1}" 2>/dev/null; }
_read_diskutil() { diskutil info "${1}" 2>/dev/null; }

read_inodes() {
  local mount="${1:-/}"
  if is_macos; then
    disk_parse_inodes "$(_read_df_inodes_macos "${mount}")"
  elif is_linux; then
    disk_parse_inodes "$(_read_df_inodes_linux "${mount}")"
  else
    echo ""
  fi
}

read_purgeable() {
  local mount="${1:-/}"
  if is_macos; then
    disk_parse_purgeable "$(_read_diskutil "${mount}")"
  else
    echo ""
  fi
}

export -f disk_parse_inodes
export -f disk_parse_purgeable
export -f _read_df_inodes_macos
export -f _read_df_inodes_linux
export -f _read_diskutil
export -f read_inodes
export -f read_purgeable
