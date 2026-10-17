#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../helpers.bash"

ENTRY="${BATS_TEST_DIRNAME}/../../disk-revamped.tmux"

setup() {
  setup_test_environment
  export SPAWN_LOG="${TEST_TMPDIR}/spawn.log"
  nohup() { printf '%s\n' "$*" >> "${SPAWN_LOG}"; }
  export -f nohup
}

teardown() {
  cleanup_test_environment
}

@test "entry - jobs mode turns a placeholder into a dispatcher call" {
  tmux set-option -gq "status-right" "[#{disk_percentage}]"

  bash "${ENTRY}"

  [[ "$(cat "$(_mock_opt_file status-right)")" == "[#($(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/src/disk.sh percentage)]" ]]
}

@test "entry - options mode turns a placeholder into an option read" {
  tmux set-option -gq "@disk_revamped_render" "options"
  tmux set-option -gq "status-right" "[#{disk_percentage}]"

  bash "${ENTRY}"

  [[ "$(cat "$(_mock_opt_file status-right)")" == "[#{E:@disk_revamped_out_percentage}]" ]]
}

@test "entry - options mode starts the ticker" {
  tmux set-option -gq "@disk_revamped_render" "options"
  tmux set-option -gq "status-right" "[#{disk_percentage}]"

  bash "${ENTRY}"

  [[ "$(cat "${SPAWN_LOG}")" == *"/src/disk.sh daemon" ]]
}

@test "entry - jobs mode starts no ticker" {
  tmux set-option -gq "status-right" "[#{disk_percentage}]"

  bash "${ENTRY}"

  [ ! -f "${SPAWN_LOG}" ]
}

@test "entry - only metrics on the status line are published" {
  tmux set-option -gq "status-right" "#{disk_percentage}"

  bash "${ENTRY}"

  [[ "$(cat "$(_mock_opt_file @disk_revamped_published)")" == "percentage" ]]
}

@test "entry - a second run keeps metrics already turned into option reads" {
  tmux set-option -gq "@disk_revamped_render" "options"
  tmux set-option -gq "status-right" "[#{E:@disk_revamped_out_percentage}]"

  bash "${ENTRY}"

  [[ "$(cat "$(_mock_opt_file @disk_revamped_published)")" == "percentage" ]]
}

record_bind_keys() {
  export BIND_LOG="${TEST_TMPDIR}/bind.log"
  eval "_base_tmux() $(declare -f tmux | tail -n +2)"
  tmux() {
    if [[ "${1}" == "bind-key" ]]; then
      printf '%s\n' "$*" >> "${BIND_LOG}"
      return 0
    fi
    _base_tmux "$@"
  }
  export -f _base_tmux tmux
}

@test "entry - the popup key defaults to M-d" {
  # Arrange
  record_bind_keys

  # Act
  bash "${ENTRY}"

  # Assert
  [[ "$(cat "${BIND_LOG}")" == "bind-key M-d run-shell "*"/src/disk.sh popup" ]]
}

@test "entry - a popup key of off binds nothing" {
  # Arrange
  record_bind_keys
  tmux set-option -gq "@disk_revamped_popup_key" "off"

  # Act
  bash "${ENTRY}"

  # Assert
  [ ! -e "${BIND_LOG}" ]
}

@test "entry - the space popup stays unbound by default" {
  # Arrange
  record_bind_keys

  # Act
  bash "${ENTRY}"

  # Assert
  [[ "$(cat "${BIND_LOG}")" != *" eat"* ]]
}

@test "entry - the space popup binds the key it is given" {
  # Arrange
  record_bind_keys
  tmux set-option -gq "@disk_revamped_popup_key" "off"
  tmux set-option -gq "@disk_revamped_eat_key" "M-E"

  # Act
  bash "${ENTRY}"

  # Assert
  [[ "$(cat "${BIND_LOG}")" == "bind-key M-E run-shell "*"/src/disk.sh eat" ]]
}

@test "entry - jobs mode quotes a plugin path with a space, a quote and a hash" {
  # Arrange
  local dir="${TEST_TMPDIR}/it's #x dir"
  mkdir -p "${dir}"
  cp -f "${ENTRY}" "${dir}/disk-revamped.tmux"
  tmux set-option -gq "status-right" "[#{disk_percentage}]"

  # Act
  bash "${dir}/disk-revamped.tmux"

  # Assert
  [[ "$(cat "$(_mock_opt_file status-right)")" == "[#($(cd "${TEST_TMPDIR}" && pwd)/it\\'s\\ ##x\\ dir/src/disk.sh percentage)]" ]]
}

@test "entry - the popup key quotes a plugin path with a space, a quote and a hash" {
  # Arrange
  record_bind_keys
  local dir="${TEST_TMPDIR}/it's #x dir"
  mkdir -p "${dir}"
  cp -f "${ENTRY}" "${dir}/disk-revamped.tmux"

  # Act
  bash "${dir}/disk-revamped.tmux"

  # Assert
  [[ "$(cat "${BIND_LOG}")" == "bind-key M-d run-shell $(cd "${TEST_TMPDIR}" && pwd)/it\\'s\\ ##x\\ dir/src/disk.sh popup" ]]
}

@test "entry - jobs mode releases a running ticker so the daemon exits" {
  # Arrange
  tmux set-option -gq "@disk_revamped_ticker_pid" "4242"
  tmux set-option -gq "status-right" "[#{disk_percentage}]"

  # Act
  bash "${ENTRY}"

  # Assert
  [ ! -f "$(_mock_opt_file @disk_revamped_ticker_pid)" ]
}
