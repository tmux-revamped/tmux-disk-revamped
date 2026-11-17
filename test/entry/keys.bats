#!/usr/bin/env bats
# shellcheck disable=SC2030,SC2031,SC2154

# shellcheck source=test/tmux_helpers.bash
source "${BATS_TEST_DIRNAME}/../tmux_helpers.bash"

wait_for() {
  local delay
  for delay in 0.01 0.02 0.05 0.1 0.1 0.2 0.2 0.5 0.5 1 1 1 2 2; do
    "$@" && return 0
    sleep "${delay}"
  done
  "$@" && return 0
  command tmux -S "${HOST}" capture-pane -p -t host || :
  return 1
}

attached() {
  local clients
  clients=$(tmux list-clients -F x 2>/dev/null)
  [[ -n "${clients}" ]]
}

host_shows() {
  local screen
  screen=$(command tmux -S "${HOST}" capture-pane -p -t host)
  [[ "${screen}" == *"$1"* ]]
}

host_matches() {
  local screen
  screen=$(command tmux -S "${HOST}" capture-pane -p -t host)
  [[ "${screen}" =~ $1 ]]
}

host_lacks() {
  ! host_shows "$1"
}

stays() {
  local delay
  for delay in 0.1 0.2 0.3 0.4; do
    sleep "${delay}"
    host_shows "$1" || return 1
  done
}

scanned() {
  local value
  value=$(tmux show-option -gqv @disk_revamped_eat)
  [[ "${value}" == *"big-folder"* ]]
}

setup() {
  unset BASH_ENV
  ROOT="$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)"
  export HOME="${BATS_TEST_TMPDIR}/home"
  DATA="${BATS_TEST_TMPDIR}/data"
  mkdir -p "${HOME}" "${DATA}/big-folder" "${DATA}/small-folder"
  printf '%2000s' x >"${DATA}/big-folder/file"
  HOST="${TMUX_SOCKET}-host"
  setup_tmux_server
  tmux set-option -g default-command "env PS1='$ ' sh"
  tmux set-option -g @disk_revamped_eat_key F5
  tmux set-option -g @disk_revamped_eat_path "${DATA}"
  command tmux -S "${HOST}" -f /dev/null new-session -d -s host -x 120 -y 40 \
    "env -u TMUX TERM=xterm-256color tmux -S '${TMUX_SOCKET}' attach-session -t test"
  wait_for attached
  tmux run-shell "'${ROOT}/disk-revamped.tmux'"
}

teardown() {
  command tmux -S "${HOST}" kill-server 2>/dev/null || :
  rm -f "${HOST}"
  teardown_tmux_server
}

press() {
  local key
  for key in "$@"; do
    command tmux -S "${HOST}" send-keys -t host "${key}"
  done
}

@test "keys - prefix M-d shows the disk card with a fresh reading, and it stays until Enter" {
  # Arrange
  local usage='Usage [0-9]+%'

  # Act
  press C-b M-d

  # Assert
  wait_for host_shows "Disk /"
  wait_for host_matches "${usage}"
  stays "Disk /"
  press Enter
  wait_for host_lacks "Disk /"
}

@test "keys - the eat key opens a popup that waits for Enter, and a second press lists the largest items" {
  # Arrange
  local either='Scanning|Largest items under'
  press C-b F5
  wait_for host_matches "${either}"
  press Enter
  wait_for scanned
  wait_for host_lacks "Largest items under"

  # Act
  press C-b F5

  # Assert
  wait_for host_shows "Largest items under"
  stays "Largest items under"
}
