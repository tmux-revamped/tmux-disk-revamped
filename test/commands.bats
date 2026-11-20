#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/disk_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/disk_helpers.bash"

everything() {
  df_says "-Pk /" "${GNU_USAGE}"
  df_says "-h" "${GNU_ALL}"
  df_says "-i /" 'Filesystem      Inodes  IUsed   IFree IUse% Mounted on
/dev/sda1      6553600 345678 6207922    6% /'
  option history "10 20"
}

folder() {
  mkdir -p "${BATS_TEST_TMPDIR}/tree/big" "${BATS_TEST_TMPDIR}/tree/mid" "${BATS_TEST_TMPDIR}/tree/.hidden" "${BATS_TEST_TMPDIR}/tree/..odd"
  : >"${BATS_TEST_TMPDIR}/tree/small"
  quiet du 'printf "du %s\n" "$*" >>"'"${FAKE}"'/asked"
shift 2
for item in "$@"; do
  case "${item##*/}" in
  big) printf "3145728\t%s\n" "${item}" ;;
  mid) printf "5120\t%s\n" "${item}" ;;
  .hidden) printf "9999\t%s\n" "${item}" ;;
  *) printf "12\t%s\n" "${item}" ;;
  esac
done'
}

@test "commands - status without a name is a usage error" {
  # Arrange
  local args=(status)

  # Act
  tool "${args[@]}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "disk-revamped: no placeholder given. run 'disk-revamped help' for usage." ]]
}

@test "commands - refresh reads the disk now and says how full it is" {
  # Arrange
  df_says "-Pk /" "${GNU_USAGE}"

  # Act
  tool refresh

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "Refreshed. 55% of / is used." ]]
  holds percent 55
}

@test "commands - refresh reads the details only when the status line shows them" {
  # Arrange
  everything
  tool refresh
  run asked
  [[ "${output}" == "df -Pk /"* ]]
  [[ "${output}" != *"df -i"* ]]
  [[ "${output}" != *"df -h"* ]]
  : >"${FAKE}/asked"
  option published "inodes all"

  # Act
  tool refresh

  # Assert
  run asked
  [[ "${output}" == *"df -i /"* ]]
  [[ "${output}" == *"df -h"* ]]
}

@test "commands - refresh fails when no tmux server takes the reading" {
  # Arrange
  df_says "-Pk /" "${GNU_USAGE}"
  printf 'refused\n' >"${FAKE}/refused"

  # Act
  tool refresh

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "disk-revamped: no tmux server is running, so the reading has nowhere to go" ]]
}

@test "commands - card reads everything now and prints one row per figure, then the disks" {
  # Arrange
  everything

  # Act
  tool card

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${lines[0]}" == "Mount              /" ]]
  [[ "${lines[1]}" == "Usage              55%" ]]
  [[ "${lines[2]}" == "Used               55G" ]]
  [[ "${lines[3]}" == "Free               45G" ]]
  [[ "${lines[4]}" == "Total              100G" ]]
  [[ "${lines[5]}" == "Inodes             i6%" ]]
  [[ "${lines[6]}" == "Read               -" ]]
  [[ "${lines[7]}" == "Write              -" ]]
  [[ "${lines[8]}" == "Purgeable          -" ]]
  [[ "${lines[9]}" == "Fill rate          -" ]]
  [[ "${lines[10]}" == "Full in            -" ]]
  [[ "${lines[11]}" == $'History            \xe2\x96\x81\xe2\x96\x81\xe2\x96\x84' ]]
  [[ "${lines[12]}" == "/                  55%" ]]
  [[ "${lines[13]}" == "/data              30%" ]]
  [[ "${lines[14]}" == "Read. 55% of / is used." ]]
  [[ "${#lines[@]}" -eq 15 ]]
}

@test "commands - with no reading the card has a dash in every row" {
  # Arrange
  local mount=/nowhere
  option mount "${mount}"

  # Act
  tool card

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${lines[1]}" == "Usage              -" ]]
  [[ "${output}" == *"Read. /nowhere has no reading." ]]
}

@test "commands - the card fits its disks to the rows and the width of the terminal and counts the rest" {
  # Arrange
  everything
  quiet stty 'printf "19 24\n"'
  df_says "-h" 'Filesystem Size Used Avail Use% Mounted on
/dev/a 1G 1G 1G 10% /a-very-long-mount-point-name
/dev/b 1G 1G 1G 20% /b
/dev/c 1G 1G 1G 30% /c
/dev/d 1G 1G 1G 40% /d'

  # Act
  tool card

  # Assert
  [[ "${lines[12]}" == "$(printf '%-18s %s' '/a-very-long' '10%')" ]]
  [[ "${lines[13]}" == "$(printf '%-18s %s' 'and 3 more' '-')" ]]
}

@test "commands - a card that fits its terminal lists every disk" {
  # Arrange
  everything
  quiet stty 'printf "50 120\n"'

  # Act
  tool card

  # Assert
  [[ "${lines[12]}" == "/                  55%" ]]
  [[ "${lines[13]}" == "/data              30%" ]]
  [[ "${#lines[@]}" -eq 15 ]]
}

@test "commands - a card on a terminal too small for its head lists no disk and counts them all" {
  # Arrange
  everything
  quiet stty 'printf "5 10\n"'

  # Act
  tool card

  # Assert
  [[ "${lines[12]}" == "$(printf '%-18s %s' 'and 2 more' '-')" ]]
}

@test "commands - where gum draws the card is a table and a closing sentence" {
  # Arrange
  everything
  export REVAMPED_TEST_GUM=1

  # Act
  tool card

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"Figure"*"Value"* ]]
  [[ "${output}" == *"Total"*"100G"* ]]
  [[ "${output}" == *"Read. 55% of / is used."* ]]
}

@test "commands - scan lists the largest items under the mount, biggest first, dot entries included" {
  # Arrange
  folder
  option eat_path "${BATS_TEST_TMPDIR}/tree"

  # Act
  tool scan

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${lines[0]}" == "Scanning ${BATS_TEST_TMPDIR}/tree ..." ]]
  [[ "${lines[1]}" == "3.0G     big" ]]
  [[ "${lines[2]}" == "9.8M     .hidden" ]]
  [[ "${lines[3]}" == "5.0M     mid" ]]
}

@test "commands - scan keeps the count of items the setting gives and caches the result for the scan interval" {
  # Arrange
  folder
  option eat_path "${BATS_TEST_TMPDIR}/tree"
  option eat_count 2
  tool scan
  [[ "${output}" == *"Listed. 2 largest items under ${BATS_TEST_TMPDIR}/tree."* ]]
  : >"${FAKE}/asked"
  later 30
  tool scan
  [[ "${lines[0]}" == "3.0G     big" ]]
  run grep -c '^du' "${FAKE}/asked"
  [[ "${output}" == "0" ]]
  later 31

  # Act
  tool scan

  # Assert
  run grep -c '^du' "${FAKE}/asked"
  [[ "${output}" == "1" ]]
}

@test "commands - an eat count that is not a positive number lists ten, and an empty folder lists nothing" {
  # Arrange
  folder
  option eat_count 0
  option eat_path "${BATS_TEST_TMPDIR}/tree"
  tool scan
  [[ "${output}" == *"Listed. 5 largest items"* ]]
  mkdir -p "${BATS_TEST_TMPDIR}/empty"
  option eat_path "${BATS_TEST_TMPDIR}/empty"
  option eat ''

  # Act
  tool scan

  # Assert
  [[ "${output}" == *"Nothing to list under ${BATS_TEST_TMPDIR}/empty."* ]]
}

@test "commands - scan without an eat path lists the mount" {
  # Arrange
  folder
  option mount "${BATS_TEST_TMPDIR}/tree"

  # Act
  tool scan

  # Assert
  [[ "${output}" == *"Scanning ${BATS_TEST_TMPDIR}/tree ..."* ]]
}

@test "commands - where gum draws the scan is a table and a closing sentence" {
  # Arrange
  folder
  option eat_path "${BATS_TEST_TMPDIR}/tree"
  export REVAMPED_TEST_GUM=1

  # Act
  tool scan

  # Assert
  [[ "${output}" == *"Size"*"Item"* ]]
  [[ "${output}" == *"3.0G"*"big"* ]]
  [[ "${output}" == *"Listed. 5 largest items under ${BATS_TEST_TMPDIR}/tree."* ]]
}

@test "commands - apply binds the popup key and prints nothing" {
  # Arrange
  local started='^bind-key -N Disk details M-d run-shell'

  # Act
  tool apply

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ -z "${output}" ]]
  run sent "${started}"
  [[ "${output}" == "1" ]]
}

@test "commands - popup opens the card in a tmux popup and prints nothing" {
  # Arrange
  local opened='^display-popup -E -w 80% -h 80% .*disk-revamped. card; read -r disk_revamped_wait$'

  # Act
  tool popup

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ -z "${output}" ]]
  run sent "${opened}"
  [[ "${output}" == "1" ]]
}

@test "commands - eat opens the scan in a tmux popup and prints nothing" {
  # Arrange
  local opened='^display-popup -E -w 80% -h 80% .*disk-revamped. scan; read -r disk_revamped_wait$'

  # Act
  tool eat

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ -z "${output}" ]]
  run sent "${opened}"
  [[ "${output}" == "1" ]]
}

@test "commands - list prints what apply would send, and --json the same plan as one object" {
  # Arrange
  local path
  path=$(bin_path)
  option popup_key 'C-"'
  tool list
  [[ "${output}" == "bind-key -N Disk details C-\" run-shell ${path} popup" ]]

  # Act
  tool list --json

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == '{"bindings":[["bind-key","-N","Disk details","C-\"","run-shell","'*' popup"]]}' ]]
  run sends
  [[ -z "${output}" ]]
}

@test "commands - --json with any command but list is a usage error" {
  # Arrange
  sampled

  # Act
  tool --json card

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "disk-revamped: option '--json' works only with list. run 'disk-revamped help' for usage." ]]
}

@test "commands - the command line wins over the environment, and the environment over the tmux option" {
  # Arrange
  sampled 42 1000000
  option percentage_format 'option %s'
  tool status percentage
  [[ "${output}" == "option 42" ]]
  export DISK_REVAMPED_PERCENTAGE_FORMAT='environment %s'
  tool status percentage
  [[ "${output}" == "environment 42" ]]

  # Act
  tool --percentage-format 'line %s' status percentage

  # Assert
  [[ "${output}" == "line 42" ]]
}

@test "commands - an option takes its value after a space or an equals sign, and an empty value is used as given" {
  # Arrange
  sampled 42 1000000
  option all $'/ 55%\037/data 30%'
  tool --percentage-label=C: status percentage
  [[ "${output}" == "C: 42%" ]]
  tool --separator '' status all
  [[ "${output}" == "/ 55%/data 30%" ]]

  # Act
  tool --size-format '' --separator=- -- status all

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "/ 55%-/data 30%" ]]
}

@test "commands - an option the tool does not know, or one without its value, is a usage error" {
  # Arrange
  tool --frobnicate status percentage
  [[ "${output}" == "disk-revamped: unknown option '--frobnicate'. run 'disk-revamped help' for usage." ]]
  tool -z
  [[ "${output}" == "disk-revamped: unknown option '-z'. run 'disk-revamped help' for usage." ]]
  tool --mount=/ --frobnicate=1 status percentage
  [[ "${output}" == "disk-revamped: unknown option '--frobnicate'. run 'disk-revamped help' for usage." ]]

  # Act
  tool status percentage --interval

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "disk-revamped: option '--interval' needs a value. run 'disk-revamped help' for usage." ]]
}

@test "commands - a number setting that is not a whole number is a bad value, and so is a choice it does not list" {
  # Arrange
  tool --interval soon status percentage
  [[ "${output}" == "disk-revamped: --interval must be a whole number, got: soon" ]]
  tool --fill-rate-width=-1 status percentage
  [[ "${output}" == "disk-revamped: --fill-rate-width must be a whole number, got: -1" ]]
  tool --render both apply
  [[ "${output}" == "disk-revamped: --render must be jobs or options, got: both" ]]
  tool --icons emoji apply
  [[ "${output}" == "disk-revamped: --icons must be ascii or nerd, got: emoji" ]]
  tool --fixed-width yes apply
  [[ "${output}" == "disk-revamped: --fixed-width must be on or off, got: yes" ]]

  # Act
  tool --notify 2 apply

  # Assert
  [[ "${output}" == "disk-revamped: --notify must be 0 or 1, got: 2" ]]
}

@test "commands - a fixed width flag is not a number setting" {
  # Arrange
  sampled 5

  # Act
  tool --fixed-width on status percentage

  # Assert
  [[ "${output}" == "  5%" ]]
}

@test "commands - the stored mount list does not leak into the reading of the mount" {
  # Arrange
  everything
  option mounts "/"
  option published mounts
  tool refresh

  # Act
  tool refresh

  # Assert
  holds mounts "/"
  run held mounts_list
  [[ "${output}" == "/ 55%" ]]
}

@test "commands - doctor on Linux checks the counters file, names what stays empty and sizes the card from the terminal" {
  # Arrange
  quiet stty 'printf "30 100\n"'
  diskstats "${DISKSTATS_SAMPLE:-8 0 sda 1 0 2 0 1 0 2 0 0 0 0}"

  # Act
  tool doctor

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" =~ df\ +ok ]]
  [[ "${output}" =~ diskstats\ +ok\ +/proc/diskstats,\ holds\ the\ read\ and\ write\ counters ]]
  [[ "${output}" =~ purgeable\ +warn\ +only\ APFS ]]
  [[ "${output}" =~ terminal\ +ok\ +the\ card\ fits\ its\ mounts\ to\ the\ popup ]]
}

@test "commands - doctor on macOS checks diskutil and says macOS has no per-disk counters" {
  # Arrange
  macos
  quiet diskutil ':'

  # Act
  tool doctor

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" =~ diskutil\ +ok\ +.*,\ reads\ the\ purgeable\ space ]]
  [[ "${output}" =~ io\ +warn\ +macOS\ has\ no\ per-disk\ counters ]]
}

@test "commands - doctor says what a missing diskutil costs" {
  # Arrange
  macos

  # Act
  tool doctor

  # Assert
  [[ "${output}" =~ diskutil\ +warn\ +without\ it\ \#\{disk_purgeable\}\ stays\ empty ]]
}

@test "commands - doctor exits 1 when df is missing" {
  # Arrange
  macos
  export REVAMPED_TEST_DF="${BATS_TEST_TMPDIR}/none/df"

  # Act
  tool doctor

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" =~ df\ +missing\ +required ]]
}

@test "commands - doctor names a key it left alone and a value it does not know" {
  # Arrange
  printf 'bind-key    -T prefix M-d     display-message mine\n' >"${FAKE}/keys"
  export DISK_REVAMPED_HISTORY_LENGTH=0

  # Act
  tool doctor

  # Assert
  [[ "${output}" =~ keys\ +warn\ +already\ bound\ and\ left\ alone:\ M-d ]]
  [[ "${output}" =~ settings\ +warn\ +unknown\ values:\ history_length=0 ]]
}

@test "commands - doctor says a tmux older than 3.2 has no popups" {
  # Arrange
  tmux_is 3.1

  # Act
  tool doctor

  # Assert
  [[ "${output}" =~ popup\ +warn\ +the\ popups\ need\ tmux\ 3.2\ or\ later ]]
}
