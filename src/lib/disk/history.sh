#!/usr/bin/env bash
#
# history.sh: bounded ring buffer and sparkline for disk usage trends.
#
# The series of recent readings lives in a single tmux user-option, never a temp
# file. disk_history_push appends a value and trims to a bounded length, so the
# option can never grow without limit. disk_sparkline maps the series to a row of
# block glyphs. The glyphs are built from their UTF-8 bytes so the source stays
# free of literal block characters and works on bash 3.2.

[[ -n "${_DISK_REVAMPED_HISTORY_LOADED:-}" ]] && return 0
_DISK_REVAMPED_HISTORY_LOADED=1

_DISK_HISTORY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${_DISK_HISTORY_DIR}/../tmux/tmux-ops.sh"

# Default ring length. Overridable with @disk_revamped_history_length.
DISK_HISTORY_MAX="${DISK_HISTORY_MAX:-20}"

# _disk_spark_glyph LEVEL -> one block glyph for a level in 0..4.
_disk_spark_glyph() {
  case "${1}" in
    0) printf '\xe2\x96\x81' ;;
    1) printf '\xe2\x96\x82' ;;
    2) printf '\xe2\x96\x84' ;;
    3) printf '\xe2\x96\x86' ;;
    *) printf '\xe2\x96\x88' ;;
  esac
}

# _disk_spark_level VALUE MAX -> a glyph level 0..4 for VALUE on a 0..MAX scale.
_disk_spark_level() {
  local v="${1%%.*}" max="${2:-100}" lvl
  [[ "${v}" =~ ^-?[0-9]+$ ]] || v=0
  (( v < 0 )) && v=0
  (( max <= 0 )) && max=100
  (( v > max )) && v=max
  lvl=$(( v * 4 / max ))
  (( lvl > 4 )) && lvl=4
  echo "${lvl}"
}

# disk_history_length -> the configured ring length.
disk_history_length() {
  local n
  n=$(get_tmux_option "@disk_revamped_history_length" "${DISK_HISTORY_MAX}")
  [[ "${n}" =~ ^[0-9]+$ ]] && (( n > 0 )) || n="${DISK_HISTORY_MAX}"
  echo "${n}"
}

# disk_history_get -> the stored series, space separated.
disk_history_get() {
  get_tmux_option "@disk_revamped_history" ""
}

# disk_history_push VALUE -> append VALUE and trim to the ring length.
disk_history_push() {
  local value="${1}" series max
  [[ "${value%%.*}" =~ ^[0-9]+$ ]] || return 0
  max=$(disk_history_length)
  series="$(disk_history_get) ${value%%.*}"
  series="$(printf '%s\n' "${series}" | awk -v n="${max}" '{ c = NF; start = (c > n) ? c - n + 1 : 1; out = ""; for (i = start; i <= c; i++) out = out (out == "" ? "" : " ") $i; print out }')"
  set_tmux_option "@disk_revamped_history" "${series}"
}

# disk_sparkline [SERIES] [MAX] -> a row of block glyphs for the series.
# With no SERIES, the stored history is used.
disk_sparkline() {
  local series="${1:-}" max="${2:-100}" out="" token lvl
  [[ -n "${series}" ]] || series="$(disk_history_get)"
  [[ -n "${series}" ]] || { echo ""; return 0; }
  for token in ${series}; do
    lvl="$(_disk_spark_level "${token}" "${max}")"
    out="${out}$(_disk_spark_glyph "${lvl}")"
  done
  echo "${out}"
}

export -f _disk_spark_glyph
export -f _disk_spark_level
export -f disk_history_length
export -f disk_history_get
export -f disk_history_push
export -f disk_sparkline
