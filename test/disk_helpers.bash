#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/helpers.bash
source "${BATS_TEST_DIRNAME:-.}/helpers.bash"

GNU_USAGE='Filesystem     1024-blocks      Used Available Capacity Mounted on
/dev/sda1        104857600  57671680  47185920      55% /'

BSD_USAGE='Filesystem   1024-blocks      Used Available Capacity  Mounted on
/dev/disk3s1s1 104857600  57671680  47185920    55%    /'

GNU_ALL='Filesystem      Size  Used Avail Use% Mounted on
tmpfs           1.6G  2.0M  1.6G   1% /run
/dev/sda1       100G   55G   45G  55% /
/dev/sda2       500M  100M  400M  20% /boot
/dev/sdb1       1.0T  300G  700G  30% /data
/dev/loop0      100M  100M     0 100% /snap/core'

BSD_ALL='Filesystem        Size    Used   Avail Capacity iused ifree %iused  Mounted on
/dev/disk3s1s1   926Gi    12Gi    15Gi    45%    426k  157M    0%   /
devfs            200Ki   200Ki     0Bi   100%     692     0  100%   /dev
/dev/disk3s5     926Gi   890Gi    15Gi    99%    2.1M  157M    1%   /System/Volumes/Data
/dev/disk4s1     500Gi   100Gi   400Gi    20%     1k   4M    0%   /Volumes/Backup'

setup() {
  harness_setup
  for name in $(compgen -v DISK_REVAMPED_); do
    unset "${name}"
  done
  FAKE="${BATS_TEST_TMPDIR}/fake"
  SYS="${BATS_TEST_TMPDIR}/sys"
  export HOME="${BATS_TEST_TMPDIR}/home" FAKE SYS REVAMPED_TEST_SYS="${SYS}"
  mkdir -p "${HOME}" "${FAKE}" "${SYS}/block" "${BATS_TEST_TMPDIR}/stubs"
  UNTRACED='{ set +x; } 2>/dev/null'
  printf '3.6\n' >"${FAKE}/version"
  : >"${FAKE}/vars"
  : >"${FAKE}/log"
  : >"${FAKE}/asked"
  now 1000000
  fake_tmux
  fake_date
  fake_df df
  fake_df bsd-df
  linux
  harness_hide diskutil notify-send osascript
}

quiet() {
  printf '#!/bin/sh\n%s\n%s\n' "${UNTRACED}" "$2" >"${BATS_TEST_TMPDIR}/stubs/$1"
  chmod +x "${BATS_TEST_TMPDIR}/stubs/$1"
}

var() {
  local kept
  kept=$(grep -v "^$1	" "${FAKE}/vars" || :)
  printf '%s\n%s\t%s\n' "${kept}" "$1" "$2" | grep -v '^$' >"${FAKE}/vars.tmp"
  mv -f "${FAKE}/vars.tmp" "${FAKE}/vars"
}

value() {
  awk -F '\t' -v want="$1" '$1 == want { print $2 }' "${FAKE}/vars"
}

option() {
  var "@disk_revamped_$1" "$2"
}

held() {
  value "@disk_revamped_$1"
}

now() {
  printf '%s\n' "$1" >"${FAKE}/now"
}

later() {
  local current
  current=$(cat "${FAKE}/now")
  now $((current + ${1:-100}))
}

fake_date() {
  quiet date 'cat "'"${FAKE}"'/now"'
}

fake_df() {
  quiet "$1" 'printf "'"$1"' %s\n" "$*" >>"'"${FAKE}"'/asked"
file="'"${FAKE}"'/df.$(printf "%s" "$*" | tr -c "A-Za-z0-9_.-" "_")"
[ -f "${file}" ] || exit 1
exec "'"${BATS_TEST_TMPDIR}"'/farm/cat" "${file}"'
}

df_says() {
  printf '%s\n' "$2" >"${FAKE}/df.$(printf '%s' "$1" | tr -c 'A-Za-z0-9_.-' '_')"
}

macos() {
  export REVAMPED_TEST_UNAME_S=Darwin REVAMPED_TEST_DF="${BATS_TEST_TMPDIR}/stubs/bsd-df"
}

linux() {
  export REVAMPED_TEST_UNAME_S=Linux
  unset REVAMPED_TEST_DF
}

says() {
  printf '%s\n' "$2" >"${FAKE}/$1.out"
  quiet "$1" 'printf "%s %s\n" "'"$1"'" "$*" >>"'"${FAKE}"'/asked"; cat "'"${FAKE}/$1"'.out"'
}

diskstats() {
  printf '%s\n' "$1" >"${FAKE}/proc.diskstats"
  quiet cat 'case "$1" in
/proc/diskstats) printf "cat %s\n" "$1" >>"'"${FAKE}"'/asked"; exec "'"${BATS_TEST_TMPDIR}"'/farm/cat" "'"${FAKE}"'/proc.diskstats" ;;
*) exec "'"${BATS_TEST_TMPDIR}"'/farm/cat" "$@" ;;
esac'
}

block_device() {
  mkdir -p "${SYS}/block/$1"
}

df_usage() {
  df_says "-Pk /" "$(printf 'Filesystem     1024-blocks      Used Available Capacity Mounted on\n/dev/sda1        %s  %s  %s      %s%% /' "$1" "$2" "$3" "$4")"
}

sampled() {
  option percent "${1:-42}"
  option percent_ts "${2:-1000000}"
}

asked() {
  cat "${FAKE}/asked"
}

fake_tmux() {
  cat >"${BATS_TEST_TMPDIR}/stubs/tmux" <<EOF
#!/bin/sh
${UNTRACED}
printf '%s\n' "\$*" >>"${FAKE}/log"
expanded() {
  printf '%s\n' "\$1" | awk -v vars="${FAKE}/vars" '
    BEGIN { while ((getline row < vars) > 0) { at = index(row, "\t"); value[substr(row, 1, at - 1)] = substr(row, at + 1) } }
    {
      line = \$0
      out = ""
      while ((at = index(line, "#{")) > 0) {
        stop = index(substr(line, at), "}")
        name = substr(line, at + 2, stop - 3)
        out = out substr(line, 1, at - 1) value[name]
        line = substr(line, at + stop)
      }
      print out line
    }
  '
}
looked() {
  awk -F '\t' -v want="\$1" '\$1 == want { print \$2 }' "${FAKE}/vars"
}
put() {
  kept=\$(grep -v "^\$1	" "${FAKE}/vars" || :)
  printf '%s\n%s\t%s\n' "\${kept}" "\$1" "\$2" | grep -v '^\$' >"${FAKE}/vars.tmp"
  mv -f "${FAKE}/vars.tmp" "${FAKE}/vars"
}
written() {
  while [ "\$#" -gt 0 ]; do
    if [ "\$1" = set-option ] && [ "\${2:-}" = -gq ] && [ "\$#" -ge 4 ]; then
      put "\$3" "\$4"
      shift 4
      continue
    fi
    shift
  done
}
case "\$1" in
-V)
  IFS= read -r version <"${FAKE}/version"
  printf 'tmux %s\n' "\${version}"
  ;;
display-message)
  [ "\$2" != -p ] || expanded "\$3"
  ;;
show-option)
  looked "\$3"
  ;;
list-keys)
  [ ! -f "${FAKE}/keys" ] || cat "${FAKE}/keys"
  ;;
list-clients)
  [ ! -f "${FAKE}/clients" ] || cat "${FAKE}/clients"
  ;;
*)
  case "\$*" in
  *" ; "*) [ ! -f "${FAKE}/refused" ] || exit 1 ;;
  *) [ ! -f "${FAKE}/refused" ] || ! grep -qF -- "\$*" "${FAKE}/refused" || exit 1 ;;
  esac
  written "\$@"
  ;;
esac
exit 0
EOF
  chmod +x "${BATS_TEST_TMPDIR}/stubs/tmux"
}

tmux_is() {
  printf '%s\n' "$1" >"${FAKE}/version"
}

planned() {
  lib_run disk "${1:-}"'disk_revamped_plan; disk_revamped_lines'
}

sends() {
  grep -v -e '^display-message -p' -e '^-V' -e '^list-' -e '^show-option' "${FAKE}/log" || :
}

sent() {
  grep -c -- "$1" "${FAKE}/log" || :
}

tool() {
  # shellcheck disable=SC2086
  run ${REVAMPED_TEST_SHELL:-sh} "${REVAMPED_TESTS_DIR}/../bin/disk-revamped" "$@"
}

tool_path() {
  printf "'%s'" "${REVAMPED_TESTS_DIR}/../bin/disk-revamped"
}

bin_path() {
  printf "'%s'" "${REVAMPED_TESTS_DIR%/test}/bin/disk-revamped"
}

has_line() {
  local line
  for line in "${lines[@]}"; do
    [[ "${line}" == "$1" ]] && return 0
  done
  return 1
}

answers() {
  export REVAMPED_TEST_GUM_ANSWERS="${BATS_TEST_TMPDIR}/answers"
  printf '%s\n' "$@" >"${REVAMPED_TEST_GUM_ANSWERS}"
}

eventually() {
  local delay
  for delay in 0.01 0.02 0.05 0.1 0.1 0.2 0.2 0.5 0.5 1 1 1 2 2; do
    "$@" && return 0
    /bin/sleep "${delay}"
  done
  "$@"
}

holds() {
  local now
  now=$(held "$1")
  [[ "${now}" == "$2" ]]
}
