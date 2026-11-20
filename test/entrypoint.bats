#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/server_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/server_helpers.bash"

bats_require_minimum_version 1.5.0

everything() {
  local options
  options=$(tmux show-options -g)
  grep -vE '@disk_revamped_(percent|used|total|free|all|inodes|history|[a-z_]+_ts|percent_lock|[a-z_]+_raw|fill_ts) ' <<<"${options}"
  tmux list-keys
}

@test "entrypoint - git tracks the entry point and the tool as executable" {
  # Arrange
  local modes

  # Act
  modes=$(git -C "${ROOT}" ls-files --stage -- disk-revamped.tmux bin/disk-revamped)

  # Assert
  run awk '$1 != "100755" { bad++ } END { print NR ":" bad + 0 }' <<<"${modes}"
  [[ "${output}" == "2:0" ]]
}

@test "entrypoint - loading binds the popup on M-d and turns the placeholder into its job, which shows the usage" {
  # Arrange
  local keys
  tmux set-option -g status-right '#{disk_percentage} #{disk_used}/#{disk_total} end'

  # Act
  load_plugin

  # Assert
  keys=$(prefix_keys)
  run grep -c -x 'M-d' <<<"${keys}"
  [[ "${output}" == "1" ]]
  run tmux show-option -gqv status-right
  [[ "${output}" == "#('${ROOT}/bin/disk-revamped' status percentage) #('${ROOT}/bin/disk-revamped' status used)/#('${ROOT}/bin/disk-revamped' status total) end" ]]
  wait_for host_shows "55% 55G/100G end"
}

@test "entrypoint - loading twice changes nothing" {
  # Arrange
  local before after
  tmux set-option -g status-right '#{disk_percentage} end'
  load_plugin
  before=$(everything)

  # Act
  load_plugin

  # Assert
  after=$(everything)
  [[ "${before}" == "${after}" ]]
}

@test "entrypoint - the list of every disk and the graph reach the status line" {
  # Arrange
  tmux set-option -g status-right '#{disk_all} #{disk_graph} end'

  # Act
  load_plugin

  # Assert
  wait_for host_shows "/ 55%, /data 30% "
  wait_for host_shows $'\xe2\x96\x84 end'
}

@test "entrypoint - in the nerd set a label set to nothing on a real server means the default, so every metric keeps its glyph" {
  # Arrange
  tmux set-option -g @disk_revamped_icons nerd
  tmux set-option -g @disk_revamped_percentage_label ''
  tmux set-option -g status-right '#{disk_percentage} #{disk_used} end'

  # Act
  load_plugin

  # Assert
  wait_for host_shows $'\xf3\xb0\x8b\x8a 55% \xf3\xb0\x86\xbc 55G end'
}

@test "entrypoint - a format given in the environment reaches the status job with its percent signs whole" {
  # Arrange
  tmux set-environment -g DISK_REVAMPED_PERCENTAGE_FORMAT 'disk %s%%'
  tmux set-option -g status-right '#{disk_percentage} end'

  # Act
  load_plugin

  # Assert
  wait_for host_shows "disk 55% end"
}

@test "entrypoint - a checkout whose path holds a space, a quote, a hash and a percent sign loads, shows the usage and takes its key" {
  # Arrange
  local copy="${BATS_TEST_TMPDIR}/it's #1 50% plug in"
  mkdir -p "${copy}"
  cp -R "${ROOT}/bin" "${ROOT}/lib" "${ROOT}/disk-revamped.tmux" "${copy}/"
  tmux set-option -g status-right '#{disk_percentage} end'
  load_plugin "${copy}"
  wait_for host_shows "55% end"

  # Act
  press C-b M-d

  # Assert
  wait_for host_shows "Usage"
}

@test "entrypoint - a default key someone else holds is left alone, and one the person names is bound" {
  # Arrange
  local table
  tmux bind-key -T prefix M-d display-message taken
  load_plugin
  table=$(tmux list-keys -T prefix)
  run grep -c 'M-d  *display-message taken' <<<"${table}"
  [[ "${output}" == "1" ]]
  run grep -c 'disk-revamped' <<<"${table}"
  [[ "${output}" == "0" ]]
  tmux bind-key -T prefix x display-message taken-too
  setting popup_key x

  # Act
  load_plugin

  # Assert
  table=$(tmux list-keys -T prefix)
  run grep -c 'disk-revamped. popup' <<<"${table}"
  [[ "${output}" == "1" ]]
}

@test "entrypoint - a key set to off binds nothing" {
  # Arrange
  local table
  setting popup_key off

  # Act
  load_plugin

  # Assert
  table=$(tmux list-keys -T prefix)
  run grep -c 'disk-revamped' <<<"${table}"
  [[ "${output}" == "0" ]]
}
