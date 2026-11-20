#!/bin/sh

[ -n "${DISK_REVAMPED_DISK_LOADED:-}" ] && return 0
DISK_REVAMPED_DISK_LOADED=1

# shellcheck source=SCRIPTDIR/state.sh
. "${REVAMPED_LIB:?}/state.sh"
# shellcheck source=SCRIPTDIR/platform.sh
. "${REVAMPED_LIB}/platform.sh"
# shellcheck source=SCRIPTDIR/command.sh
. "${REVAMPED_LIB}/command.sh"
# shellcheck source=SCRIPTDIR/cache.sh
. "${REVAMPED_LIB}/cache.sh"
# shellcheck source=SCRIPTDIR/publish.sh
. "${REVAMPED_LIB}/publish.sh"
# shellcheck source=SCRIPTDIR/ticker.sh
. "${REVAMPED_LIB}/ticker.sh"
# shellcheck source=SCRIPTDIR/notify.sh
. "${REVAMPED_LIB}/notify.sh"

disk_revamped_format() {
  printf '%s\n' "${DISK_REVAMPED_SETTINGS}" | awk -F '\t' -v live="${DISK_REVAMPED_LIVE}" '{ printf "%s#{@disk_revamped_%s}", (NR > 1 ? "\t" : ""), $1 } END { count = split(live, name, " "); for (i = 1; i <= count; i++) { printf "\t#{@disk_revamped_%s}", name[i] } }'
}

disk_revamped_resolve() {
  env | DISK_REVAMPED_ROWS="${DISK_REVAMPED_SETTINGS}" DISK_REVAMPED_VALUES="$1" awk -v live="${DISK_REVAMPED_LIVE}" '
    BEGIN {
      count = split(ENVIRON["DISK_REVAMPED_ROWS"], rows, "\n")
      split(ENVIRON["DISK_REVAMPED_VALUES"], given, "\t")
      for (i = 1; i <= count; i++) {
        at = index(rows[i], "\t")
        if (at == 0) { at = length(rows[i]) + 1 }
        name[i] = substr(rows[i], 1, at - 1)
        value[i] = (given[i] != "") ? given[i] : substr(rows[i], at + 1)
        want["DISK_REVAMPED_" toupper(name[i])] = i
      }
    }
    {
      at = index($0, "=")
      key = substr($0, 1, at - 1)
      if (key in want) {
        value[want[key]] = substr($0, at + 1)
      }
    }
    END {
      for (i = 1; i <= count; i++) { print name[i] "\t" value[i] }
      extra = split(live, state, " ")
      for (i = 1; i <= extra; i++) { print state[i] "\t" given[count + i] }
    }
  '
}

disk_revamped_setting_rows() {
  disk_revamped_setting_rows_format=$(disk_revamped_format)
  disk_revamped_setting_rows_live=$(tmux display-message -p "${disk_revamped_setting_rows_format}" 2>/dev/null) || disk_revamped_setting_rows_live=""
  disk_revamped_resolve "${disk_revamped_setting_rows_live}"
}

disk_revamped_load() {
  disk_revamped_load_values=$(disk_revamped_setting_rows)
  while IFS='	' read -r disk_revamped_load_name disk_revamped_load_value; do
    IFS= read -r "DISK_REVAMPED_S_${disk_revamped_load_name}" <<EOF
${disk_revamped_load_value}
EOF
  done <<EOF
${disk_revamped_load_values}
EOF
}

disk_revamped_parse_version() {
  printf '%s\n' "$1" | sed -En 's/^tmux[ -]([a-z]+-)?([0-9]+\.[0-9]+).*/\2/p'
}

disk_revamped_version_ge() {
  case "$1:$2" in
  *[!0-9.:]* | :* | *:) return 1 ;;
  *) ;;
  esac
  disk_revamped_version_ge_have="${1%%.*}"
  disk_revamped_version_ge_want="${2%%.*}"
  [ "${disk_revamped_version_ge_have}" -gt "${disk_revamped_version_ge_want}" ] && return 0
  [ "${disk_revamped_version_ge_have}" -eq "${disk_revamped_version_ge_want}" ] || return 1
  disk_revamped_version_ge_have="${1#*.}"
  disk_revamped_version_ge_want="${2#*.}"
  [ "${disk_revamped_version_ge_have%%.*}" -ge "${disk_revamped_version_ge_want%%.*}" ]
}

disk_revamped_emit() {
  for disk_revamped_emit_arg in "$@"; do
    case "${disk_revamped_emit_arg}" in
    *\;) disk_revamped_emit_arg="${disk_revamped_emit_arg%;}\\;" ;;
    *) ;;
    esac
    DISK_REVAMPED_PLAN="${DISK_REVAMPED_PLAN}${disk_revamped_emit_arg:-${DISK_REVAMPED_EMPTY}}
"
  done
  DISK_REVAMPED_PLAN="${DISK_REVAMPED_PLAN}
"
}

disk_revamped_literal() {
  printf '%s\n' "$1" | sed -e "s/'/'\\\\''/g" -e "s/#/'\"\$(printf '%b' '\\\\0043')\"'/g" -e "1s/^/'/" -e "\$s/\$/'/"
}

disk_revamped_send() {
  set --
  disk_revamped_send_sep=""
  while IFS= read -r disk_revamped_send_line; do
    if [ -z "${disk_revamped_send_line}" ]; then
      [ "$#" -eq 0 ] || disk_revamped_send_sep=";"
      continue
    fi
    [ -z "${disk_revamped_send_sep}" ] || set -- "$@" "${disk_revamped_send_sep}"
    disk_revamped_send_sep=""
    [ "${disk_revamped_send_line}" != "${DISK_REVAMPED_EMPTY}" ] || disk_revamped_send_line=""
    set -- "$@" "${disk_revamped_send_line}"
  done <<PLAN
${DISK_REVAMPED_PLAN}
PLAN
  [ "$#" -gt 0 ] || return 0
  tmux "$@" 2>/dev/null
}

disk_revamped_send_each() {
  disk_revamped_send_each_status=0
  set --
  while IFS= read -r disk_revamped_send_each_line; do
    if [ -n "${disk_revamped_send_each_line}" ]; then
      [ "${disk_revamped_send_each_line}" != "${DISK_REVAMPED_EMPTY}" ] || disk_revamped_send_each_line=""
      set -- "$@" "${disk_revamped_send_each_line}"
      continue
    fi
    [ "$#" -gt 0 ] || continue
    tmux "$@" || disk_revamped_send_each_status=1
    set --
  done <<PLAN
${DISK_REVAMPED_PLAN}
PLAN
  return "${disk_revamped_send_each_status}"
}

disk_revamped_deliver() {
  ! disk_revamped_send || return 0
  disk_revamped_send_each
}

disk_revamped_lines() {
  printf '%s' "${DISK_REVAMPED_PLAN}" | awk -v empty="${DISK_REVAMPED_EMPTY}" '$0 == empty { $0 = "\"\"" } $0 == "" && line != "" { print line; line = ""; next } $0 == "" { next } { line = (line == "" ? $0 : line " " $0) } END { if (line != "") { print line } }'
}

disk_revamped_json() {
  printf '%s' "${DISK_REVAMPED_PLAN}" | awk -v empty="${DISK_REVAMPED_EMPTY}" '
    function quote(s,    out, i, c) {
      out = ""
      for (i = 1; i <= length(s); i++) {
        c = substr(s, i, 1)
        if (c == "\\") { out = out "\\\\" } else if (c == "\"") { out = out "\\\"" } else { out = out c }
      }
      return "\"" out "\""
    }
    /^$/ { if (args != "") { rows = rows (rows == "" ? "" : ",") "[" args "]" } args = ""; next }
    $0 == empty { $0 = "" }
    { args = args (args == "" ? "" : ",") quote($0) }
    END {
      if (args != "") { rows = rows (rows == "" ? "" : ",") "[" args "]" }
      print "{\"bindings\":[" rows "]}"
    }
  '
}

disk_revamped_bindings() {
  printf '%s' "${DISK_REVAMPED_PLAN}" | awk 'previous == "" && $0 == "bind-key" { count++ } { previous = $0 } END { print count + 0 }'
}

disk_revamped_setting_name() {
  disk_revamped_setting_name_raw=$(printf '%s\n' "${1#--}" | tr '-' '_')
  case " ${DISK_REVAMPED_NAMES} " in
  *" ${disk_revamped_setting_name_raw} "*) printf '%s\n' "${disk_revamped_setting_name_raw}" ;;
  *) printf '\n' ;;
  esac
}

disk_revamped_bind() {
  case "$1" in
  "" | off) return 0 ;;
  *) ;;
  esac
  disk_revamped_bind_key="$1" disk_revamped_bind_note="$2"
  shift 2
  set -- "${disk_revamped_bind_key}" "$@"
  [ "${DISK_REVAMPED_NOTES}" != 1 ] || set -- -N "${disk_revamped_bind_note}" "$@"
  disk_revamped_emit bind-key "$@"
}

disk_revamped_job_quote() {
  printf '%s\n' "$1" | sed -e "s/'/'\\\\''/g" -e 's/#/##/g' -e 's/%/%%/g' -e "1s/^/'/" -e "\$s/\$/'/"
}

disk_revamped_carried() {
  disk_revamped_carried_set=$(env | sed -n 's/^DISK_REVAMPED_\([A-Z_]*\)=\(.*\)$/\1 \2/p')
  [ -n "${disk_revamped_carried_set}" ] || return 0
  printf '%s\n' "${disk_revamped_carried_set}" | DISK_REVAMPED_WANTED="${DISK_REVAMPED_CARRIED}" awk '
    BEGIN { count = split(ENVIRON["DISK_REVAMPED_WANTED"], name, " "); for (i = 1; i <= count; i++) { wanted[toupper(name[i])] = i } }
    {
      key = $1
      if (!(key in wanted)) { next }
      given[wanted[key]] = 1
      value[wanted[key]] = substr($0, length(key) + 2)
    }
    END {
      for (i = 1; i <= count; i++) {
        if (!given[i]) { continue }
        flag = name[i]
        gsub(/_/, "-", flag)
        print flag "\t" value[i]
      }
    }
  '
}

disk_revamped_tools() {
  disk_revamped_tools_path="${REVAMPED_LIB%/lib}/bin/disk-revamped"
  DISK_REVAMPED_TOOL=$(disk_revamped_literal "${disk_revamped_tools_path}")
  DISK_REVAMPED_JOB=$(disk_revamped_job_quote "${disk_revamped_tools_path}")
  disk_revamped_tools_rows=$(disk_revamped_carried)
  while IFS='	' read -r disk_revamped_tools_flag disk_revamped_tools_value; do
    [ -n "${disk_revamped_tools_flag}" ] || continue
    DISK_REVAMPED_TOOL="${DISK_REVAMPED_TOOL} --${disk_revamped_tools_flag} $(disk_revamped_literal "${disk_revamped_tools_value}")"
    DISK_REVAMPED_JOB="${DISK_REVAMPED_JOB} --${disk_revamped_tools_flag} $(disk_revamped_job_quote "${disk_revamped_tools_value}")"
  done <<EOF
${disk_revamped_tools_rows}
EOF
}

disk_revamped_held() {
  tmux list-keys -T prefix 2>/dev/null | awk '
    {
      at = 2
      if ($at == "-r") { at++ }
      if ($at == "-T") { at += 2 }
      key = $at
      if (key ~ /^\\./) { key = substr(key, 2) }
      rest = ""
      for (i = at + 1; i <= NF; i++) { rest = rest " " $i }
      if (index(rest, "disk-revamped") == 0) { printf "%s ", key }
    }
  '
}

disk_revamped_doubled() {
  disk_revamped_doubled_rest="$1" disk_revamped_doubled_hash='#' DISK_REVAMPED_DOUBLED=""
  while [ "${disk_revamped_doubled_rest}" != "${disk_revamped_doubled_rest#*"${disk_revamped_doubled_hash}"}" ]; do
    DISK_REVAMPED_DOUBLED="${DISK_REVAMPED_DOUBLED}${disk_revamped_doubled_rest%%"${disk_revamped_doubled_hash}"*}${disk_revamped_doubled_hash}${disk_revamped_doubled_hash}"
    disk_revamped_doubled_rest="${disk_revamped_doubled_rest#*"${disk_revamped_doubled_hash}"}"
  done
  DISK_REVAMPED_DOUBLED="${DISK_REVAMPED_DOUBLED}${disk_revamped_doubled_rest}"
}

disk_revamped_now() {
  DISK_REVAMPED_NOW=$(date +%s 2>/dev/null) || DISK_REVAMPED_NOW=0
}

disk_revamped_version() {
  disk_revamped_version_raw=$(tmux -V 2>/dev/null) || disk_revamped_version_raw=""
  DISK_REVAMPED_TMUX=$(disk_revamped_parse_version "${disk_revamped_version_raw}")
}

disk_revamped_number() {
  DISK_REVAMPED_NUMBER="$1"
  revamped_cache_is_number "$1" || DISK_REVAMPED_NUMBER="$2"
}

disk_revamped_store() {
  disk_revamped_emit set-option -gq "@disk_revamped_$1" "$2"
  IFS= read -r "DISK_REVAMPED_S_$1" <<EOF
$2
EOF
}

disk_revamped_wanted() {
  for disk_revamped_wanted_name in "$@"; do
    case " ${DISK_REVAMPED_WANT} " in
    *" ${disk_revamped_wanted_name} "*) return 0 ;;
    *) ;;
    esac
  done
  return 1
}

disk_revamped_due() {
  disk_revamped_due_ts="$1"
  shift
  disk_revamped_wanted "$@" || return 1
  revamped_cache_is_number "${disk_revamped_due_ts}" || return 0
  [ "$((DISK_REVAMPED_NOW - disk_revamped_due_ts))" -gt "${DISK_REVAMPED_DETAIL}" ]
}

disk_revamped_kept() {
  case " ${DISK_REVAMPED_DUE} " in
  *" $1 "*) return 0 ;;
  *) return 1 ;;
  esac
}

disk_revamped_limit() {
  disk_revamped_number "${DISK_REVAMPED_S_interval}" "${DISK_REVAMPED_DEFAULT_INTERVAL}"
  DISK_REVAMPED_LIMIT="${DISK_REVAMPED_NUMBER}"
}

disk_revamped_stale() {
  revamped_cache_is_number "${DISK_REVAMPED_S_percent_ts}" || return 0
  [ "$((DISK_REVAMPED_NOW - DISK_REVAMPED_S_percent_ts))" -gt "${DISK_REVAMPED_LIMIT}" ]
}

disk_revamped_locked() {
  [ "${DISK_REVAMPED_S_percent_lock}" = 1 ] || return 1
  revamped_cache_is_number "${DISK_REVAMPED_S_percent_lock_ts}" || return 1
  [ "$((DISK_REVAMPED_NOW - DISK_REVAMPED_S_percent_lock_ts))" -lt "${REVAMPED_CACHE_MAX_RUN_DEFAULT}" ]
}

disk_revamped_level() {
  if [ "$1" -ge "$3" ]; then
    DISK_REVAMPED_TIER=high
  elif [ "$1" -ge "$2" ]; then
    DISK_REVAMPED_TIER=medium
  else
    DISK_REVAMPED_TIER=low
  fi
}

disk_revamped_tier() {
  disk_revamped_number "${DISK_REVAMPED_S_medium_thresh}" "${DISK_REVAMPED_DEFAULT_MEDIUM}"
  disk_revamped_tier_medium="${DISK_REVAMPED_NUMBER}"
  disk_revamped_number "${DISK_REVAMPED_S_high_thresh}" "${DISK_REVAMPED_DEFAULT_HIGH}"
  disk_revamped_level "$1" "${disk_revamped_tier_medium}" "${DISK_REVAMPED_NUMBER}"
}

disk_revamped_style() {
  case "$1:${DISK_REVAMPED_TIER}" in
  icon:high) DISK_REVAMPED_OUT="${DISK_REVAMPED_S_high_icon}" ;;
  icon:medium) DISK_REVAMPED_OUT="${DISK_REVAMPED_S_medium_icon}" ;;
  icon:low) DISK_REVAMPED_OUT="${DISK_REVAMPED_S_low_icon}" ;;
  fg_color:high) DISK_REVAMPED_OUT="${DISK_REVAMPED_S_high_fg_color}" ;;
  fg_color:medium) DISK_REVAMPED_OUT="${DISK_REVAMPED_S_medium_fg_color}" ;;
  fg_color:low) DISK_REVAMPED_OUT="${DISK_REVAMPED_S_low_fg_color}" ;;
  bg_color:high) DISK_REVAMPED_OUT="${DISK_REVAMPED_S_high_bg_color}" ;;
  bg_color:medium) DISK_REVAMPED_OUT="${DISK_REVAMPED_S_medium_bg_color}" ;;
  *) DISK_REVAMPED_OUT="${DISK_REVAMPED_S_low_bg_color}" ;;
  esac
}

disk_revamped_pad() {
  if ! revamped_cache_is_number "${DISK_REVAMPED_WIDTH}"; then
    DISK_REVAMPED_WIDTH=0
    [ "${DISK_REVAMPED_S_fixed_width}" != on ] || DISK_REVAMPED_WIDTH="${DISK_REVAMPED_NATURAL}"
  fi
  [ "${DISK_REVAMPED_WIDTH}" -gt 0 ] || return 0
  revamped_publish_count "${DISK_REVAMPED_OUT}"
  [ "${revamped_publish_count_out}" -lt "${DISK_REVAMPED_WIDTH}" ] || return 0
  disk_revamped_pad_gap=$(printf "%$((DISK_REVAMPED_WIDTH - revamped_publish_count_out))s" '')
  DISK_REVAMPED_OUT="${disk_revamped_pad_gap}${DISK_REVAMPED_OUT}"
}

disk_revamped_label() {
  [ -z "${DISK_REVAMPED_LABEL}" ] || return 0
  [ "${DISK_REVAMPED_S_icons}" = nerd ] || return 0
  DISK_REVAMPED_LABEL=$(printf '%b' "${DISK_REVAMPED_GLYPH}")
}

disk_revamped_output() {
  disk_revamped_value "$1"
  [ -n "${DISK_REVAMPED_OUT}" ] || return 0
  case " ${DISK_REVAMPED_LABELLED} " in
  *" $1 "*) disk_revamped_own "$1" ;;
  *) return 0 ;;
  esac
  disk_revamped_pad
  disk_revamped_label
  [ -z "${DISK_REVAMPED_LABEL}" ] || DISK_REVAMPED_OUT="${DISK_REVAMPED_LABEL} ${DISK_REVAMPED_OUT}"
}

disk_revamped_show() {
  disk_revamped_output "$1"
  [ -z "${DISK_REVAMPED_OUT}" ] || printf '%s\n' "${DISK_REVAMPED_OUT}"
}

disk_revamped_plan_keys() {
  case "${DISK_REVAMPED_S_popup_key}: ${DISK_REVAMPED_KEYS} " in
  "${DISK_REVAMPED_DEFAULT_POPUP_KEY}:"*" ${DISK_REVAMPED_DEFAULT_POPUP_KEY} "*) DISK_REVAMPED_SKIPPED="${DISK_REVAMPED_SKIPPED}${DISK_REVAMPED_SKIPPED:+ }${DISK_REVAMPED_DEFAULT_POPUP_KEY}" ;;
  *) disk_revamped_bind "${DISK_REVAMPED_S_popup_key}" "Disk details" run-shell "${DISK_REVAMPED_TOOL} popup" ;;
  esac
  disk_revamped_bind "${DISK_REVAMPED_S_eat_key}" "Largest items" run-shell "${DISK_REVAMPED_TOOL} eat"
}

disk_revamped_replaced() {
  printf '%s\n' "$1" | DISK_REVAMPED_PUT="${DISK_REVAMPED_JOB}" awk -v mode="${DISK_REVAMPED_S_render}" -v kinds="${DISK_REVAMPED_METRICS}" '
    BEGIN {
      command = ENVIRON["DISK_REVAMPED_PUT"]
      count = split(kinds, kind, " ")
    }
    {
      line = $0
      for (i = 1; i <= count; i++) {
        holder = "#{disk_" kind[i] "}"
        target = (mode == "options") ? "#{E:@disk_revamped_out_" kind[i] "}" : "#(" command " status " kind[i] ")"
        done = ""
        while ((at = index(line, holder)) > 0) {
          done = done substr(line, 1, at - 1) target
          line = substr(line, at + length(holder))
        }
        line = done line
      }
      print line
    }
  '
}

disk_revamped_used() {
  printf '%s\n' "$1" | awk -v kinds="${DISK_REVAMPED_METRICS}" '
    BEGIN { count = split(kinds, kind, " ") }
    { text = text $0 " " }
    END {
      out = ""
      for (i = 1; i <= count; i++) {
        if (index(text, "#{disk_" kind[i] "}") > 0 || index(text, "@disk_revamped_out_" kind[i] "}") > 0 || index(text, " status " kind[i] ")") > 0) { out = out (out == "" ? "" : " ") kind[i] }
      }
      print out
    }
  '
}

disk_revamped_plan_status() {
  disk_revamped_plan_status_all=""
  for disk_revamped_plan_status_option in status-left status-right; do
    disk_revamped_plan_status_now=$(tmux show-option -gqv "${disk_revamped_plan_status_option}" 2>/dev/null) || disk_revamped_plan_status_now=""
    disk_revamped_plan_status_all="${disk_revamped_plan_status_all} ${disk_revamped_plan_status_now}"
    case "${disk_revamped_plan_status_now}" in
    *"#{disk_"*"}"*) disk_revamped_plan_status_new=$(disk_revamped_replaced "${disk_revamped_plan_status_now}") ;;
    *) continue ;;
    esac
    [ "${disk_revamped_plan_status_new}" != "${disk_revamped_plan_status_now}" ] || continue
    disk_revamped_emit set-option -gq "${disk_revamped_plan_status_option}" "${disk_revamped_plan_status_new}"
  done
  disk_revamped_plan_status_used=$(disk_revamped_used "${disk_revamped_plan_status_all}")
  [ "${disk_revamped_plan_status_used}" = "${DISK_REVAMPED_S_published}" ] || disk_revamped_emit set-option -gq @disk_revamped_published "${disk_revamped_plan_status_used}"
  DISK_REVAMPED_S_published="${disk_revamped_plan_status_used}"
}

disk_revamped_plan() {
  disk_revamped_load
  disk_revamped_version
  DISK_REVAMPED_NOTES=0
  ! disk_revamped_version_ge "${DISK_REVAMPED_TMUX}" "${DISK_REVAMPED_NOTES_SINCE}" || DISK_REVAMPED_NOTES=1
  disk_revamped_tools
  DISK_REVAMPED_KEYS=$(disk_revamped_held)
  DISK_REVAMPED_PLAN="" DISK_REVAMPED_SKIPPED=""
  disk_revamped_plan_keys
  disk_revamped_plan_status
}

disk_revamped_apply() {
  disk_revamped_plan
  disk_revamped_apply_status=0
  disk_revamped_deliver || disk_revamped_apply_status=1
  if [ "${DISK_REVAMPED_S_render}" = options ]; then
    revamped_ticker_start "${REVAMPED_LIB%/lib}/bin/disk-revamped"
  else
    tmux set-option -gqu @disk_revamped_ticker_pid 2>/dev/null || :
  fi
  return "${disk_revamped_apply_status}"
}

disk_revamped_df_tool() {
  DISK_REVAMPED_DF='df'
  ! revamped_is_macos || DISK_REVAMPED_DF="${DISK_REVAMPED_BSD_DF}"
}

disk_revamped_raw_add() {
  DISK_REVAMPED_RAW="${DISK_REVAMPED_RAW}
${DISK_REVAMPED_MARK}$1
$2"
}

disk_revamped_raw_read() {
  disk_revamped_raw_read_name="$1"
  shift
  disk_revamped_raw_read_text=$("$@" 2>/dev/null) || :
  disk_revamped_raw_add "${disk_revamped_raw_read_name}" "${disk_revamped_raw_read_text}"
}

disk_revamped_raw_blocks() {
  disk_revamped_raw_blocks_names=""
  for disk_revamped_raw_blocks_path in "${DISK_REVAMPED_SYS}"/block/*; do
    [ -e "${disk_revamped_raw_blocks_path}" ] || continue
    disk_revamped_raw_blocks_names="${disk_revamped_raw_blocks_names}${disk_revamped_raw_blocks_path##*/}
"
  done
  disk_revamped_raw_add blocks "${disk_revamped_raw_blocks_names}"
}

disk_revamped_raw_io() {
  disk_revamped_raw_blocks
  disk_revamped_raw_read diskstats cat /proc/diskstats
}

disk_revamped_raw_mounts() {
  disk_revamped_raw_mounts_names=""
  revamped_publish_replace , ' ' "${DISK_REVAMPED_S_mounts}"
  set --
  for disk_revamped_raw_mounts_name in ${revamped_publish_replace_out}; do
    [ -e "${disk_revamped_raw_mounts_name}" ] || continue
    set -- "$@" "${disk_revamped_raw_mounts_name}"
    disk_revamped_raw_mounts_names="${disk_revamped_raw_mounts_names}${disk_revamped_raw_mounts_name}
"
  done
  [ "$#" -gt 0 ] || return 0
  disk_revamped_raw_add mountnames "${disk_revamped_raw_mounts_names}"
  disk_revamped_raw_read mountdf "${DISK_REVAMPED_DF}" -Pk "$@"
}

disk_revamped_gather() {
  disk_revamped_df_tool
  disk_revamped_raw_read usage "${DISK_REVAMPED_DF}" -Pk "${DISK_REVAMPED_S_mount}"
  if disk_revamped_wanted inodes; then
    DISK_REVAMPED_DUE="${DISK_REVAMPED_DUE} inodes"
    disk_revamped_raw_read inodes "${DISK_REVAMPED_DF}" -i "${DISK_REVAMPED_S_mount}"
  fi
  if revamped_is_macos && disk_revamped_wanted purgeable; then
    DISK_REVAMPED_DUE="${DISK_REVAMPED_DUE} purgeable"
    disk_revamped_raw_read purgeable diskutil info "${DISK_REVAMPED_S_mount}"
  fi
  if revamped_is_linux && disk_revamped_wanted read write; then
    DISK_REVAMPED_DUE="${DISK_REVAMPED_DUE} io"
    disk_revamped_raw_io
  fi
  if disk_revamped_due "${DISK_REVAMPED_S_all_ts}" all; then
    DISK_REVAMPED_DUE="${DISK_REVAMPED_DUE} all"
    disk_revamped_raw_read all "${DISK_REVAMPED_DF}" -h
  fi
  if [ -n "${DISK_REVAMPED_S_mounts}" ] && disk_revamped_wanted mounts; then
    DISK_REVAMPED_DUE="${DISK_REVAMPED_DUE} mounts"
    disk_revamped_raw_mounts
  fi
  if disk_revamped_wanted fill_rate full_eta; then
    DISK_REVAMPED_DUE="${DISK_REVAMPED_DUE} fill"
  fi
}

disk_revamped_figures() {
  LC_ALL=C awk -v history="${DISK_REVAMPED_S_history}" -v keep="$1" -v mark="${DISK_REVAMPED_MARK}" -v sep="${DISK_REVAMPED_SEP}" -v mac="$2" -v fill="$3" -v now="${DISK_REVAMPED_NOW}" -v prev_used="${DISK_REVAMPED_S_used_raw}" -v prev_fill="${DISK_REVAMPED_S_fill_ts}" -v prev_rate="${DISK_REVAMPED_S_fill_rate}" -v prev_eta="${DISK_REVAMPED_S_full_eta}" -v prev_rd="${DISK_REVAMPED_S_rd_raw}" -v prev_wr="${DISK_REVAMPED_S_wr_raw}" -v prev_io="${DISK_REVAMPED_S_io_ts}" -v prev_read="${DISK_REVAMPED_S_read}" -v prev_write="${DISK_REVAMPED_S_write}" '
    function digits(text) { gsub(/[^0-9]/, "", text); return (text == "") ? 0 : text + 0 }
    function gigs(kb) { return int((kb + 1048575) / 1048576) }
    function speed(current, before, secs,    kb) {
      kb = current - before
      if (kb < 0) { kb = 0 }
      kb = int(kb / secs)
      return (kb >= 1024) ? sprintf("%.1fMB/s", kb / 1024) : sprintf("%dKB/s", kb)
    }
    function last_percent(text,    last) {
      while (match(text, /[0-9]+%/)) { last = substr(text, RSTART, RLENGTH - 1); text = substr(text, RSTART + RLENGTH) }
      return last
    }
    function joined(list, item) { return list (list == "" ? "" : sep) item }
    index($0, mark) == 1 { section = substr($0, length(mark) + 1); next }
    section == "usage" && !have_usage {
      for (i = 5; i <= NF; i++) {
        if ($i ~ /^[0-9]+%$/) {
          percent = substr($i, 1, length($i) - 1)
          total_kb = digits($(i - 3))
          used_kb = digits($(i - 2))
          avail_kb = digits($(i - 1))
          have_usage = 1
          break
        }
      }
    }
    section == "inodes" && !have_inodes && /[0-9]+%/ { inodes = last_percent($0); have_inodes = 1 }
    section == "purgeable" && !have_purge && tolower($0) ~ /purgeable/ {
      have_purge = 1
      if (match($0, /[0-9]+(\.[0-9]+)?[ \t]*(GB|MB|G|M)/)) {
        text = substr($0, RSTART, RLENGTH)
        size = text
        sub(/[ \t]*[GM]B?$/, "", size)
        purgeable = (text ~ /M[B]?$/) ? int(size / 1024) : int(size)
      }
    }
    section == "blocks" && $1 != "" && $1 !~ /^(loop|ram|dm-|zram)/ { whole[$1] = 1 }
    section == "diskstats" { has_io = 1 }
    section == "diskstats" && ($3 in whole) { reads += $6; writes += $10 }
    section == "all" && ++all_rows > 1 {
      if (mac) {
        if ($1 ~ /^\/dev\// && $9 !~ /^\/Volumes\//) { everything = joined(everything, $9 " " $5) }
      } else if ($1 ~ /^\/dev\// && $6 !~ /^\/boot/ && $6 !~ /^\/snap/) { everything = joined(everything, $6 " " $5) }
    }
    section == "mountnames" && $0 != "" { names[++name_count] = $0 }
    section == "mountdf" {
      for (i = 5; i <= NF; i++) {
        if ($i ~ /^[0-9]+%$/) {
          if (++mount_rows <= name_count) { listed = joined(listed, names[mount_rows] " " $i) }
          break
        }
      }
    }
    END {
      if (have_usage) {
        used = gigs(used_kb)
        total = gigs(total_kb)
        free = gigs(avail_kb)
        count = split(history, past, " ")
        past[++count] = percent + 0
        history = ""
        for (i = (count > keep ? count - keep + 1 : 1); i <= count; i++) { history = history (history == "" ? "" : " ") past[i] }
      } else {
        percent = ""
      }
      if (fill && have_usage) {
        used_raw = used_kb
        fill_ts = now
        if (prev_used ~ /^[0-9]+$/ && prev_fill ~ /^[0-9]+$/ && now - prev_fill > 0) {
          fill_rate = sprintf("%.1f", (used_kb - prev_used) * 3600.0 / (now - prev_fill) / 1048576)
          if (fill_rate + 0 > 0) { full_eta = int(avail_kb / 1048576 / fill_rate) }
        } else if (prev_used ~ /^[0-9]+$/ && prev_fill ~ /^[0-9]+$/) {
          used_raw = prev_used
          fill_ts = prev_fill
          fill_rate = prev_rate
          full_eta = prev_eta
        }
      }
      if (has_io) {
        rd_raw = int(reads / 2)
        wr_raw = int(writes / 2)
        io_ts = now
        if (prev_io ~ /^[0-9]+$/ && prev_rd ~ /^[0-9]+$/ && prev_wr ~ /^[0-9]+$/) {
          secs = now - prev_io
          if (secs > 0) {
            read = speed(rd_raw, prev_rd, secs)
            write = speed(wr_raw, prev_wr, secs)
          } else {
            rd_raw = prev_rd
            wr_raw = prev_wr
            io_ts = prev_io
            read = prev_read
            write = prev_write
          }
        }
      }
      printf "percent\t%s\nused\t%s\ntotal\t%s\nfree\t%s\nread\t%s\nwrite\t%s\ninodes\t%s\npurgeable\t%s\n", percent, used, total, free, read, write, inodes, purgeable
      printf "mounts_list\t%s\nall\t%s\nfill_rate\t%s\nfull_eta\t%s\nhistory\t%s\n", listed, everything, fill_rate, full_eta, history
      printf "rd_raw\t%s\nwr_raw\t%s\nio_ts\t%s\nused_raw\t%s\nfill_ts\t%s\n", rd_raw, wr_raw, io_ts, used_raw, fill_ts
    }
  '
}

disk_revamped_measure() {
  DISK_REVAMPED_F_percent="" DISK_REVAMPED_F_used="" DISK_REVAMPED_F_total="" DISK_REVAMPED_F_free="" DISK_REVAMPED_F_read="" DISK_REVAMPED_F_write=""
  DISK_REVAMPED_F_inodes="" DISK_REVAMPED_F_purgeable="" DISK_REVAMPED_F_mounts_list="" DISK_REVAMPED_F_all="" DISK_REVAMPED_F_fill_rate=""
  DISK_REVAMPED_F_full_eta="" DISK_REVAMPED_F_history="" DISK_REVAMPED_F_rd_raw="" DISK_REVAMPED_F_wr_raw="" DISK_REVAMPED_F_io_ts=""
  DISK_REVAMPED_F_used_raw="" DISK_REVAMPED_F_fill_ts=""
  disk_revamped_number "${DISK_REVAMPED_S_history_length}" "${DISK_REVAMPED_DEFAULT_HISTORY}"
  [ "${DISK_REVAMPED_NUMBER}" -gt 0 ] || DISK_REVAMPED_NUMBER="${DISK_REVAMPED_DEFAULT_HISTORY}"
  disk_revamped_measure_mac=0
  ! revamped_is_macos || disk_revamped_measure_mac=1
  disk_revamped_measure_fill=0
  ! disk_revamped_kept fill || disk_revamped_measure_fill=1
  disk_revamped_measure_rows=$(printf '%s\n' "${DISK_REVAMPED_RAW}" | disk_revamped_figures "${DISK_REVAMPED_NUMBER}" "${disk_revamped_measure_mac}" "${disk_revamped_measure_fill}") || disk_revamped_measure_rows=""
  while IFS='	' read -r disk_revamped_measure_name disk_revamped_measure_value; do
    [ -n "${disk_revamped_measure_name}" ] || continue
    IFS= read -r "DISK_REVAMPED_F_${disk_revamped_measure_name}" <<EOF
${disk_revamped_measure_value}
EOF
  done <<EOF
${disk_revamped_measure_rows}
EOF
}

disk_revamped_keep() {
  disk_revamped_store percent "${DISK_REVAMPED_F_percent}"
  disk_revamped_store used "${DISK_REVAMPED_F_used}"
  disk_revamped_store total "${DISK_REVAMPED_F_total}"
  disk_revamped_store free "${DISK_REVAMPED_F_free}"
  disk_revamped_store history "${DISK_REVAMPED_F_history}"
  disk_revamped_store percent_ts "${DISK_REVAMPED_NOW}"
  if disk_revamped_kept inodes; then
    disk_revamped_store inodes "${DISK_REVAMPED_F_inodes}"
  fi
  if disk_revamped_kept purgeable; then
    disk_revamped_store purgeable "${DISK_REVAMPED_F_purgeable}"
  fi
  if disk_revamped_kept io; then
    disk_revamped_store read "${DISK_REVAMPED_F_read}"
    disk_revamped_store write "${DISK_REVAMPED_F_write}"
    disk_revamped_store rd_raw "${DISK_REVAMPED_F_rd_raw}"
    disk_revamped_store wr_raw "${DISK_REVAMPED_F_wr_raw}"
    disk_revamped_store io_ts "${DISK_REVAMPED_F_io_ts}"
  fi
  if disk_revamped_kept all; then
    disk_revamped_store all "${DISK_REVAMPED_F_all}"
    disk_revamped_store all_ts "${DISK_REVAMPED_NOW}"
  fi
  if disk_revamped_kept mounts; then
    disk_revamped_store mounts_list "${DISK_REVAMPED_F_mounts_list}"
  fi
  if disk_revamped_kept fill; then
    disk_revamped_store fill_rate "${DISK_REVAMPED_F_fill_rate}"
    disk_revamped_store full_eta "${DISK_REVAMPED_F_full_eta}"
    disk_revamped_store used_raw "${DISK_REVAMPED_F_used_raw}"
    disk_revamped_store fill_ts "${DISK_REVAMPED_F_fill_ts}"
  fi
}

disk_revamped_alert() {
  [ "${DISK_REVAMPED_S_notify}" = 1 ] || return 0
  revamped_cache_is_number "${DISK_REVAMPED_F_percent}" || return 0
  revamped_cache_is_number "${DISK_REVAMPED_S_high_thresh}" || return 0
  if [ "${DISK_REVAMPED_F_percent}" -ge "${DISK_REVAMPED_S_high_thresh}" ]; then
    [ "${DISK_REVAMPED_S_notified}" != 1 ] || return 0
    revamped_notify_send "Disk almost full" "Usage at ${DISK_REVAMPED_F_percent}% on ${DISK_REVAMPED_S_mount}"
    disk_revamped_store notified 1
    return 0
  fi
  [ "${DISK_REVAMPED_S_notified}" != 1 ] || disk_revamped_store notified 0
}

disk_revamped_sample() {
  disk_revamped_number "${DISK_REVAMPED_S_detail_interval}" "${DISK_REVAMPED_DEFAULT_DETAIL}"
  DISK_REVAMPED_DETAIL="${DISK_REVAMPED_NUMBER}"
  DISK_REVAMPED_RAW="" DISK_REVAMPED_DUE=""
  disk_revamped_gather
  disk_revamped_measure
  disk_revamped_keep
  disk_revamped_alert
}

disk_revamped_refresh() {
  DISK_REVAMPED_PLAN=""
  disk_revamped_now
  disk_revamped_sample
  DISK_REVAMPED_STORED=1
  disk_revamped_send || DISK_REVAMPED_STORED=0
}

disk_revamped_value_shaped() {
  DISK_REVAMPED_OUT=""
  [ -n "$2" ] || return 0
  # shellcheck disable=SC2059
  DISK_REVAMPED_OUT=$(printf "$1" "$2")
}

disk_revamped_value_tiered() {
  DISK_REVAMPED_OUT=""
  [ -n "$2" ] || return 0
  disk_revamped_number "$2" 0
  disk_revamped_tier "${DISK_REVAMPED_NUMBER}"
  disk_revamped_style "$1"
}

disk_revamped_value_size() {
  DISK_REVAMPED_OUT=""
  [ -n "$1" ] || return 0
  if revamped_cache_is_number "$1" && [ "$1" -ge 1024 ]; then
    DISK_REVAMPED_OUT=$(LC_ALL=C awk -v gigabytes="$1" 'BEGIN { printf "%.1fT", gigabytes / 1024 }')
    return 0
  fi
  disk_revamped_value_shaped "${DISK_REVAMPED_S_size_format}" "$1"
}

disk_revamped_value_fill() {
  DISK_REVAMPED_OUT=$(LC_ALL=C awk -v rate="$1" 'BEGIN { if (rate !~ /^-?[0-9]+(\.[0-9]+)?$/ || rate + 0 == 0) { exit } printf "%s%.1fG/h", (rate > 0 ? "+" : ""), rate }')
}

disk_revamped_value_eta() {
  DISK_REVAMPED_OUT=""
  revamped_cache_is_number "$1" || return 0
  if [ "$1" -ge 24 ]; then
    DISK_REVAMPED_OUT="$(($1 / 24))d"
  elif [ "$1" -ge 1 ]; then
    DISK_REVAMPED_OUT="$1h"
  else
    DISK_REVAMPED_OUT="<1h"
  fi
}

disk_revamped_value_list() {
  DISK_REVAMPED_OUT=""
  [ -n "$1" ] || return 0
  disk_revamped_doubled "$1"
  revamped_publish_replace "${DISK_REVAMPED_SEP}" "${DISK_REVAMPED_S_separator}" "${DISK_REVAMPED_DOUBLED}"
  DISK_REVAMPED_OUT="${revamped_publish_replace_out}"
}

disk_revamped_value_graph() {
  DISK_REVAMPED_OUT=""
  disk_revamped_value_graph_rest="${DISK_REVAMPED_S_history}" disk_revamped_value_graph_bytes=""
  while [ -n "${disk_revamped_value_graph_rest}" ]; do
    disk_revamped_value_graph_item="${disk_revamped_value_graph_rest%% *}"
    disk_revamped_value_graph_rest="${disk_revamped_value_graph_rest#"${disk_revamped_value_graph_item}"}"
    disk_revamped_value_graph_rest="${disk_revamped_value_graph_rest# }"
    disk_revamped_number "${disk_revamped_value_graph_item%%.*}" 0
    [ "${DISK_REVAMPED_NUMBER}" -le 100 ] || DISK_REVAMPED_NUMBER=100
    set -- 201 202 204 206 210
    shift $((DISK_REVAMPED_NUMBER * 4 / 100))
    disk_revamped_value_graph_bytes="${disk_revamped_value_graph_bytes}\\0342\\0226\\0$1"
  done
  [ -n "${disk_revamped_value_graph_bytes}" ] || return 0
  DISK_REVAMPED_OUT=$(printf '%b' "${disk_revamped_value_graph_bytes}")
}

disk_revamped_value() {
  case "$1" in
  percentage) disk_revamped_value_shaped "${DISK_REVAMPED_S_percentage_format}" "${DISK_REVAMPED_S_percent}" ;;
  icon | fg_color | bg_color) disk_revamped_value_tiered "$1" "${DISK_REVAMPED_S_percent}" ;;
  used) disk_revamped_value_size "${DISK_REVAMPED_S_used}" ;;
  total) disk_revamped_value_size "${DISK_REVAMPED_S_total}" ;;
  free) disk_revamped_value_size "${DISK_REVAMPED_S_free}" ;;
  purgeable) disk_revamped_value_size "${DISK_REVAMPED_S_purgeable}" ;;
  read) DISK_REVAMPED_OUT="${DISK_REVAMPED_S_read}" ;;
  write) DISK_REVAMPED_OUT="${DISK_REVAMPED_S_write}" ;;
  inodes) disk_revamped_value_shaped "${DISK_REVAMPED_S_inodes_format}" "${DISK_REVAMPED_S_inodes}" ;;
  graph) disk_revamped_value_graph ;;
  fill_rate) disk_revamped_value_fill "${DISK_REVAMPED_S_fill_rate}" ;;
  full_eta) disk_revamped_value_eta "${DISK_REVAMPED_S_full_eta}" ;;
  mounts) disk_revamped_value_list "${DISK_REVAMPED_S_mounts_list}" ;;
  all) disk_revamped_value_list "${DISK_REVAMPED_S_all}" ;;
  *) DISK_REVAMPED_OUT="" ;;
  esac
}

disk_revamped_own() {
  DISK_REVAMPED_NATURAL=0
  case "$1" in
  percentage) DISK_REVAMPED_LABEL="${DISK_REVAMPED_S_percentage_label}" DISK_REVAMPED_WIDTH="${DISK_REVAMPED_S_percentage_width}" DISK_REVAMPED_GLYPH='\0363\0260\0213\0212' DISK_REVAMPED_NATURAL=4 ;;
  used) DISK_REVAMPED_LABEL="${DISK_REVAMPED_S_used_label}" DISK_REVAMPED_WIDTH="${DISK_REVAMPED_S_used_width}" DISK_REVAMPED_GLYPH='\0363\0260\0206\0274' ;;
  total) DISK_REVAMPED_LABEL="${DISK_REVAMPED_S_total_label}" DISK_REVAMPED_WIDTH="${DISK_REVAMPED_S_total_width}" DISK_REVAMPED_GLYPH='\0363\0260\0206\0274' ;;
  free) DISK_REVAMPED_LABEL="${DISK_REVAMPED_S_free_label}" DISK_REVAMPED_WIDTH="${DISK_REVAMPED_S_free_width}" DISK_REVAMPED_GLYPH='\0363\0260\0235\0260' ;;
  read) DISK_REVAMPED_LABEL="${DISK_REVAMPED_S_read_label}" DISK_REVAMPED_WIDTH="${DISK_REVAMPED_S_read_width}" DISK_REVAMPED_GLYPH='\0363\0260\0207\0232' DISK_REVAMPED_NATURAL=9 ;;
  write) DISK_REVAMPED_LABEL="${DISK_REVAMPED_S_write_label}" DISK_REVAMPED_WIDTH="${DISK_REVAMPED_S_write_width}" DISK_REVAMPED_GLYPH='\0363\0260\0225\0222' DISK_REVAMPED_NATURAL=9 ;;
  inodes) DISK_REVAMPED_LABEL="${DISK_REVAMPED_S_inodes_label}" DISK_REVAMPED_WIDTH="${DISK_REVAMPED_S_inodes_width}" DISK_REVAMPED_GLYPH='\0363\0260\0231\0205' DISK_REVAMPED_NATURAL=4 ;;
  purgeable) DISK_REVAMPED_LABEL="${DISK_REVAMPED_S_purgeable_label}" DISK_REVAMPED_WIDTH="${DISK_REVAMPED_S_purgeable_width}" DISK_REVAMPED_GLYPH='\0363\0260\0203\0242' ;;
  graph) DISK_REVAMPED_LABEL="${DISK_REVAMPED_S_graph_label}" DISK_REVAMPED_WIDTH="${DISK_REVAMPED_S_graph_width}" DISK_REVAMPED_GLYPH='\0363\0260\0236\0261' ;;
  fill_rate) DISK_REVAMPED_LABEL="${DISK_REVAMPED_S_fill_rate_label}" DISK_REVAMPED_WIDTH="${DISK_REVAMPED_S_fill_rate_width}" DISK_REVAMPED_GLYPH='\0363\0260\0224\0265' ;;
  full_eta) DISK_REVAMPED_LABEL="${DISK_REVAMPED_S_full_eta_label}" DISK_REVAMPED_WIDTH="${DISK_REVAMPED_S_full_eta_width}" DISK_REVAMPED_GLYPH='\0363\0260\0224\0237' ;;
  mounts) DISK_REVAMPED_LABEL="${DISK_REVAMPED_S_mounts_label}" DISK_REVAMPED_WIDTH="${DISK_REVAMPED_S_mounts_width}" DISK_REVAMPED_GLYPH='\0363\0260\0211\0223' ;;
  *) DISK_REVAMPED_LABEL="${DISK_REVAMPED_S_all_label}" DISK_REVAMPED_WIDTH="${DISK_REVAMPED_S_all_width}" DISK_REVAMPED_GLYPH='\0363\0260\0211\0223' ;;
  esac
}

disk_revamped_status() {
  disk_revamped_load
  disk_revamped_now
  disk_revamped_limit
  DISK_REVAMPED_WANT="${DISK_REVAMPED_S_published} $1"
  if disk_revamped_stale && ! disk_revamped_locked; then
    revamped_cache_refresh_if_stale percent "${DISK_REVAMPED_LIMIT}" disk_revamped_refresh || :
  fi
  disk_revamped_show "$1"
}

disk_revamped_publish() {
  DISK_REVAMPED_WANT="${DISK_REVAMPED_S_published}"
  disk_revamped_refresh
  [ "${DISK_REVAMPED_STORED}" = 1 ] || return 0
  disk_revamped_publish_rest="${DISK_REVAMPED_S_published}"
  while [ -n "${disk_revamped_publish_rest}" ]; do
    disk_revamped_publish_metric="${disk_revamped_publish_rest%% *}"
    disk_revamped_publish_rest="${disk_revamped_publish_rest#"${disk_revamped_publish_metric}"}"
    disk_revamped_publish_rest="${disk_revamped_publish_rest# }"
    [ -n "${disk_revamped_publish_metric}" ] || continue
    disk_revamped_output "${disk_revamped_publish_metric}"
    revamped_publish_add "@disk_revamped_out_${disk_revamped_publish_metric}" "${DISK_REVAMPED_OUT}"
  done
  revamped_publish_commit || :
}

disk_revamped_tick() {
  disk_revamped_load
  disk_revamped_publish
}

disk_revamped_daemon() {
  revamped_ticker_run disk_revamped disk_revamped_tick "$$" "${DISK_REVAMPED_DEFAULT_INTERVAL}"
}

disk_revamped_eat_target() {
  DISK_REVAMPED_TARGET="${DISK_REVAMPED_S_eat_path:-${DISK_REVAMPED_S_mount}}"
}

disk_revamped_eat_rows() {
  LC_ALL=C awk -v keep="$1" -v sep="${DISK_REVAMPED_SEP}" '
    function human(kb,    value, unit) {
      value = kb
      unit = "K"
      if (kb >= 1048576) { value = kb / 1048576; unit = "G" } else if (kb >= 1024) { value = kb / 1024; unit = "M" }
      return sprintf((value >= 10 || unit == "K") ? "%.0f%s" : "%.1f%s", value, unit)
    }
    count < keep && /^[0-9]+\t/ {
      at = index($0, "\t")
      name = substr($0, at + 1)
      sub(/^.*\//, "", name)
      row = human(substr($0, 1, at - 1) + 0) " " name
      out = out (out == "" ? "" : sep) row
      count++
    }
    END { print out }
  '
}

disk_revamped_eat_read() {
  DISK_REVAMPED_SCAN=""
  set --
  for disk_revamped_eat_read_item in "${DISK_REVAMPED_TARGET}"/* "${DISK_REVAMPED_TARGET}"/.[!.]* "${DISK_REVAMPED_TARGET}"/..?*; do
    [ -e "${disk_revamped_eat_read_item}" ] || [ -L "${disk_revamped_eat_read_item}" ] || continue
    set -- "$@" "${disk_revamped_eat_read_item}"
  done
  [ "$#" -gt 0 ] || return 0
  disk_revamped_number "${DISK_REVAMPED_S_eat_count}" "${DISK_REVAMPED_DEFAULT_EAT_COUNT}"
  [ "${DISK_REVAMPED_NUMBER}" -gt 0 ] || DISK_REVAMPED_NUMBER="${DISK_REVAMPED_DEFAULT_EAT_COUNT}"
  DISK_REVAMPED_SCAN=$(du -xsk -- "$@" 2>/dev/null | sort -rn | disk_revamped_eat_rows "${DISK_REVAMPED_NUMBER}") || DISK_REVAMPED_SCAN=""
}

disk_revamped_eat_fresh() {
  [ -n "${DISK_REVAMPED_S_eat}" ] || return 1
  revamped_cache_is_number "${DISK_REVAMPED_S_eat_ts}" || return 1
  disk_revamped_number "${DISK_REVAMPED_S_eat_interval}" "${DISK_REVAMPED_DEFAULT_EAT_INTERVAL}"
  [ "$((DISK_REVAMPED_NOW - DISK_REVAMPED_S_eat_ts))" -le "${DISK_REVAMPED_NUMBER}" ]
}

disk_revamped_eat_scan() {
  disk_revamped_load
  disk_revamped_now
  disk_revamped_eat_target
  if disk_revamped_eat_fresh; then
    DISK_REVAMPED_SCAN="${DISK_REVAMPED_S_eat}"
    return 0
  fi
  printf 'Scanning %s ...\n' "${DISK_REVAMPED_TARGET}" >&2
  disk_revamped_eat_read
  DISK_REVAMPED_PLAN=""
  disk_revamped_store eat "${DISK_REVAMPED_SCAN}"
  disk_revamped_store eat_ts "${DISK_REVAMPED_NOW}"
  disk_revamped_send || :
}

disk_revamped_popup_check() {
  DISK_REVAMPED_POPUP_OK=0
  ! disk_revamped_version_ge "${DISK_REVAMPED_TMUX}" "${DISK_REVAMPED_POPUP_SINCE}" || DISK_REVAMPED_POPUP_OK=1
}

disk_revamped_popup_open() {
  disk_revamped_load
  disk_revamped_version
  disk_revamped_popup_check
  if [ "${DISK_REVAMPED_POPUP_OK}" != 1 ]; then
    tmux display-message "disk-revamped: tmux 3.2+ is required for the disk popups" 2>/dev/null || :
    return 0
  fi
  disk_revamped_tools
  tmux display-popup -E -w 80% -h 80% "${DISK_REVAMPED_TOOL} $1; read -r disk_revamped_wait" 2>/dev/null || :
}

disk_revamped_popup() {
  disk_revamped_popup_open card
}

disk_revamped_eat() {
  disk_revamped_popup_open scan
}
