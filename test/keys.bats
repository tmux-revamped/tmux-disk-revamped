#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/server_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/server_helpers.bash"

bats_require_minimum_version 1.5.0

loaded_with_status() {
  tmux set-option -g status-right '#{disk_percentage} end'
  load_plugin
  wait_for host_shows "55% end"
}

pane_is_plain() {
  local mode
  mode=$(tmux display-message -p -t test:0.0 '#{pane_in_mode}')
  [[ "${mode}" == "0" ]]
}

scanned() {
  mkdir -p "${BATS_TEST_TMPDIR}/scan"
  : >"${BATS_TEST_TMPDIR}/scan/marker-file"
  setting eat_path "${BATS_TEST_TMPDIR}/scan"
}

@test "keys - prefix M-d opens the card in a popup with the figures and every disk" {
  # Arrange
  loaded_with_status

  # Act
  press C-b M-d

  # Assert
  wait_for host_shows "Usage"
  wait_for host_shows "Total"
  wait_for host_shows "/data"
}

@test "keys - Enter closes the card and keeps the status line running" {
  # Arrange
  loaded_with_status
  press C-b M-d
  wait_for host_shows "Usage"

  # Act
  press Enter

  # Assert
  wait_for host_lacks "Usage"
  wait_for host_shows "55% end"
  pane_is_plain
}

@test "keys - a key the person names opens the card, and the default one then does nothing" {
  # Arrange
  setting popup_key F8
  loaded_with_status
  press C-b M-d
  host_lacks "Usage"

  # Act
  press C-b F8

  # Assert
  wait_for host_shows "Usage"
}

@test "keys - the eat key opens the largest items popup, which lists the folder it scans" {
  # Arrange
  scanned
  setting eat_key M-u
  loaded_with_status

  # Act
  press C-b M-u

  # Assert
  wait_for host_shows "marker-file"
  wait_for host_shows "Listed."
}

@test "keys - the eat popup closes on Enter" {
  # Arrange
  scanned
  setting eat_key M-u
  loaded_with_status
  press C-b M-u
  wait_for host_shows "marker-file"

  # Act
  press Enter

  # Assert
  wait_for host_lacks "marker-file"
  pane_is_plain
}

@test "keys - the eat key is unbound until the person sets it" {
  # Arrange
  scanned
  loaded_with_status

  # Act
  press C-b M-u

  # Assert
  host_lacks "marker-file"
  pane_is_plain
}

@test "keys - in options mode the status line reads options a daemon fills" {
  # Arrange
  setting render options
  tmux set-option -g status-right '#{disk_percentage} | #{disk_used} end'

  # Act
  load_plugin

  # Assert
  run tmux show-option -gqv status-right
  [[ "${output}" == "#{E:@disk_revamped_out_percentage} | #{E:@disk_revamped_out_used} end" ]]
  wait_for host_shows "55% | 55G end"
  run tmux show-option -gqv @disk_revamped_ticker_pid
  [[ "${output}" =~ ^[0-9]+$ ]]
}

@test "keys - in options mode the popup key still opens the card" {
  # Arrange
  setting render options
  tmux set-option -g status-right '#{disk_percentage} end'
  load_plugin
  wait_for host_shows "55% end"

  # Act
  press C-b M-d

  # Assert
  wait_for host_shows "Usage"
}

@test "keys - the card draws every figure at a popup of the default size" {
  # Arrange
  loaded_with_status

  # Act
  press C-b M-d

  # Assert
  wait_for host_shows "Mount"
  wait_for host_shows "Read. 55% of / is used."
}
