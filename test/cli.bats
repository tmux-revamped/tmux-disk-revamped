#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031

# shellcheck source=test/helpers.bash
source "${BATS_TEST_DIRNAME:-.}/helpers.bash"

setup() {
  harness_setup
  local name
  for name in $(compgen -v DISK_REVAMPED_); do
    unset "${name}"
  done
  unset KODOUGU_THEME KODOUGU_ACCENT NO_COLOR
  export HOME="${BATS_TEST_TMPDIR}/home" REVAMPED_TEST_UNAME_S=Linux
  mkdir -p "${HOME}" "${BATS_TEST_TMPDIR}/stubs"
  harness_hide diskutil notify-send osascript
  no_proc
  usage_df
  export REVAMPED_TEST_GUM_LOG="${BATS_TEST_TMPDIR}/gum.log"
  : >"${REVAMPED_TEST_GUM_LOG}"
}

no_proc() {
  cat >"${BATS_TEST_TMPDIR}/stubs/cat" <<STUB
#!/bin/sh
{ set +x; } 2>/dev/null
case "\${1:-}" in
/proc/* | /sys/*) exit 1 ;;
*) exec "${BATS_TEST_TMPDIR}/farm/cat" "\$@" ;;
esac
STUB
  chmod +x "${BATS_TEST_TMPDIR}/stubs/cat"
}

usage_df() {
  cat >"${BATS_TEST_TMPDIR}/stubs/df" <<'STUB'
#!/bin/sh
{ set +x; } 2>/dev/null
printf 'Filesystem 1024-blocks Used Available Capacity Mounted on\n/dev/sda1 104857600 57671680 47185920 55%% /\n'
STUB
  chmod +x "${BATS_TEST_TMPDIR}/stubs/df"
  export REVAMPED_TEST_DF="${BATS_TEST_TMPDIR}/stubs/df"
}

hide() {
  local name
  for name in "$@"; do
    rm -f "${BATS_TEST_TMPDIR}/farm/${name}"
  done
}

tool() {
  # shellcheck disable=SC2086
  run ${REVAMPED_TEST_SHELL:-sh} "${REVAMPED_TESTS_DIR}/../bin/disk-revamped" "$@"
}

tool_by_name() {
  # shellcheck disable=SC2086
  run ${REVAMPED_TEST_SHELL:-sh} disk-revamped version
}

on_tty() {
  local shell_words
  read -r -a shell_words <<<"${REVAMPED_TEST_SHELL:-sh}"
  run python3 "${REVAMPED_TESTS_DIR}/on_tty.py" "${shell_words[@]}" "${REVAMPED_TESTS_DIR}/../bin/disk-revamped"
}

answers() {
  export REVAMPED_TEST_GUM_ANSWERS="${BATS_TEST_TMPDIR}/answers"
  printf '%s\n' "$@" >"${REVAMPED_TEST_GUM_ANSWERS}"
}

@test "cli - version prints the name and version, then the tmux version" {
  # Arrange
  export REVAMPED_TEST_TMUX_VERSION=3.8

  # Act
  tool version

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${lines[0]}" =~ ^disk-revamped\ [0-9]+\.[0-9]+\.[0-9]+$ ]]
  [[ "${lines[1]}" == "tmux: 3.8" ]]
}

@test "cli - version says tmux is missing when it cannot run" {
  # Arrange
  export REVAMPED_TEST_TMUX_FAIL=1

  # Act
  tool --version

  # Assert
  [[ "${lines[1]}" == "tmux: missing" ]]
}

@test "cli - -V is the version too" {
  # Arrange
  local flag=-V

  # Act
  tool "${flag}"

  # Assert
  [[ "${lines[0]}" == disk-revamped\ * ]]
}

@test "cli - help prints the plain page" {
  # Arrange
  local command=help

  # Act
  tool "${command}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${lines[0]}" == "disk-revamped - usage, free space and fill rate in the status bar" ]]
  [[ "${output}" == *"tmux options:"* ]]
}

@test "cli - help is drawn with gum format where gum draws" {
  # Arrange
  export REVAMPED_TEST_GUM=1

  # Act
  tool --help

  # Assert
  [[ "${status}" -eq 0 ]]
  grep -q '^format --theme pink' "${REVAMPED_TEST_GUM_LOG}"
}

@test "cli - doctor lists every tool and exits 0" {
  # Arrange
  export REVAMPED_TEST_TMUX_VERSION=3.6

  # Act
  tool doctor

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${lines[0]}" =~ ^tmux\ +ok\ +.*,\ 3\.6$ ]]
  [[ "${output}" =~ df\ +ok ]]
  [[ "${output}" =~ purgeable\ +warn\ +only\ APFS ]]
  [[ "${output}" =~ diskstats\ +warn\ +/proc/diskstats\ cannot\ be\ read ]]
  [[ "${output}" =~ terminal\ +warn ]]
  [[ "${output}" =~ awk\ +ok ]]
}

@test "cli - doctor exits 1 when a required tool is missing" {
  # Arrange
  hide date

  # Act
  tool doctor

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" =~ date\ +missing\ +required ]]
}

@test "cli - doctor draws a table and a closing sentence where gum draws" {
  # Arrange
  export REVAMPED_TEST_GUM=1

  # Act
  tool doctor

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"Ready. Every tool disk-revamped needs is here."* ]]
}

@test "cli - doctor names the missing tools where gum draws" {
  # Arrange
  export REVAMPED_TEST_GUM=1
  hide date

  # Act
  tool doctor

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"1 required tool(s) missing"* ]]
}

@test "cli - an unknown command is a usage error" {
  # Arrange
  local command=bogus

  # Act
  tool "${command}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "disk-revamped: unknown command 'bogus'. run 'disk-revamped help' for usage." ]]
}

@test "cli - an unknown option is a usage error" {
  # Arrange
  local option=--bogus

  # Act
  tool "${option}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "disk-revamped: unknown option '--bogus'. run 'disk-revamped help' for usage." ]]
}

@test "cli - --theme without a value is a usage error" {
  # Arrange
  local option=--theme

  # Act
  tool "${option}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "disk-revamped: option '--theme' needs a value. run 'disk-revamped help' for usage." ]]
}

@test "cli - an unknown theme names the themes" {
  # Arrange
  local theme=solarized

  # Act
  tool --theme "${theme}" version

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "disk-revamped: --theme must be one of kodougu, catppuccin-mocha, catppuccin-latte, dracula, nord, gruvbox, tokyo-night, mono, got: solarized" ]]
}

@test "cli - --theme=NAME picks the theme" {
  # Arrange
  export REVAMPED_TEST_GUM=1

  # Act
  tool --theme=nord help

  # Assert
  [[ "${status}" -eq 0 ]]
  grep -q '^format --theme dark' "${REVAMPED_TEST_GUM_LOG}"
}

@test "cli - the tool's environment variable picks the theme" {
  # Arrange
  export REVAMPED_TEST_GUM=1 DISK_REVAMPED_THEME=catppuccin-latte

  # Act
  tool help

  # Assert
  grep -q '^format --theme light' "${REVAMPED_TEST_GUM_LOG}"
}

@test "cli - KODOUGU_THEME picks the theme when the tool's variable is unset" {
  # Arrange
  export REVAMPED_TEST_GUM=1 KODOUGU_THEME=dracula

  # Act
  tool help

  # Assert
  grep -q '^format --theme dracula' "${REVAMPED_TEST_GUM_LOG}"
}

@test "cli - the tmux option picks the theme when nothing else does" {
  # Arrange
  export REVAMPED_TEST_GUM=1
  tmux set-option -gq @revamped_theme tokyo-night

  # Act
  tool help

  # Assert
  grep -q '^format --theme tokyo-night' "${REVAMPED_TEST_GUM_LOG}"
}

@test "cli - a bare run without a terminal is a usage error" {
  # Arrange
  local stdin=/dev/null

  # Act
  tool <"${stdin}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "disk-revamped: no command given. run 'disk-revamped help' for usage." ]]
}

@test "cli - the gum menu runs doctor" {
  # Arrange
  export REVAMPED_TEST_GUM=1
  answers "Check this machine"

  # Act
  tool

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"Ready. Every tool disk-revamped needs is here."* ]]
}

@test "cli - the gum menu shows help" {
  # Arrange
  export REVAMPED_TEST_GUM=1
  answers Help

  # Act
  tool

  # Assert
  [[ "${status}" -eq 0 ]]
  grep -q '^format ' "${REVAMPED_TEST_GUM_LOG}"
}

@test "cli - a cancelled gum menu exits 1" {
  # Arrange
  export REVAMPED_TEST_GUM=1
  answers '<cancel>'

  # Act
  tool

  # Assert
  [[ "${status}" -eq 1 ]]
}

@test "cli - the plain menu on a terminal takes a numbered choice" {
  # Arrange
  hide gum

  # Act
  on_tty <<<"6"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"What would you like to do?"* ]]
  [[ "${output}" == *"disk-revamped - usage, free space and fill rate"* ]]
}

@test "cli - the menu's second choice lists the largest items under the scanned path" {
  # Arrange
  local tree="${BATS_TEST_TMPDIR}/tree"
  mkdir -p "${tree}"
  : >"${tree}/only"
  printf '#!/bin/sh\n{ set +x; } 2>/dev/null\nshift 2\nfor item in "$@"; do printf "12\\t%%s\\n" "${item}"; done\n' >"${BATS_TEST_TMPDIR}/stubs/du"
  chmod +x "${BATS_TEST_TMPDIR}/stubs/du"
  export DISK_REVAMPED_EAT_PATH="${tree}"
  hide gum

  # Act
  on_tty <<<"2"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"12K"*"only"* ]]
  [[ "${output}" == *"Listed. 1 largest items under ${tree}."* ]]
}

@test "cli - the menu's third choice lists the bindings" {
  # Arrange
  hide gum

  # Act
  on_tty <<<"3"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"bind-key -N Disk details M-d run-shell"* ]]
}

@test "cli - the menu's fourth choice applies the bindings and counts one key" {
  # Arrange
  hide gum

  # Act
  on_tty <<<"4"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"Applied. 1 key is bound."* ]]
}

@test "cli - the menu's fourth choice counts no key when the popup key is off" {
  # Arrange
  export DISK_REVAMPED_POPUP_KEY=off
  hide gum

  # Act
  on_tty <<<"4"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"Applied. 0 keys are bound."* ]]
}

@test "cli - the menu's fifth choice checks this machine" {
  # Arrange
  local row='purgeable +warn +only APFS'
  hide gum

  # Act
  on_tty <<<"5"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" =~ ${row} ]]
}

@test "cli - the plain menu refuses a number it does not list" {
  # Arrange
  hide gum

  # Act
  on_tty <<<"9"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"unknown choice '9'"* ]]
}

@test "cli - the plain menu refuses a word" {
  # Arrange
  hide gum

  # Act
  on_tty <<<"two"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"unknown choice 'two'"* ]]
}

@test "cli - the plain menu takes the first choice on Enter" {
  # Arrange
  hide gum

  # Act
  on_tty <<<""

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"Read. 55% of / is used."* ]]
}

@test "cli - a usage error is a log line where gum draws" {
  # Arrange
  export REVAMPED_TEST_GUM=1

  # Act
  tool bogus

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "ERROR disk-revamped: unknown command 'bogus'. run 'disk-revamped help' for usage." ]]
  grep -q -- '--bold -- ERROR$' "${REVAMPED_TEST_GUM_LOG}"
}

@test "cli - the tool runs from PATH by its bare name" {
  # Arrange
  local bin="${REVAMPED_TESTS_DIR}/../bin"
  PATH="${bin}:${PATH}"
  cd "${bin}"

  # Act
  tool_by_name

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${lines[0]}" == disk-revamped\ * ]]
}

@test "cli - an inherited internal variable is ignored" {
  # Arrange
  export REVAMPED_UI_THEME=solarized REVAMPED_UI_NAME=impostor

  # Act
  tool version

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${lines[0]}" == disk-revamped\ * ]]
}

@test "cli - the tool's accent variable colours the header" {
  # Arrange
  export REVAMPED_TEST_GUM=1 DISK_REVAMPED_ACCENT="#112233" KODOUGU_ACCENT="#445566"
  answers Help

  # Act
  tool

  # Assert
  [[ "${status}" -eq 0 ]]
  grep -q -- '--foreground #112233 --bold -- disk-revamped' "${REVAMPED_TEST_GUM_LOG}"
}

@test "cli - KODOUGU_ACCENT colours the header when the tool's accent is unset" {
  # Arrange
  export REVAMPED_TEST_GUM=1 KODOUGU_ACCENT="#445566"
  answers Help

  # Act
  tool

  # Assert
  grep -q -- '--foreground #445566 --bold -- disk-revamped' "${REVAMPED_TEST_GUM_LOG}"
}

@test "cli - a malformed accent is a bad value" {
  # Arrange
  export DISK_REVAMPED_ACCENT=purple

  # Act
  tool version

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "disk-revamped: DISK_REVAMPED_ACCENT must be a colour such as #CBA6F7, got: purple" ]]
}
