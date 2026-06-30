#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../helpers.bash"

setup() {
  setup_test_environment
  unset _DISK_REVAMPED_HISTORY_LOADED
  source "${BATS_TEST_DIRNAME}/../../../src/lib/disk/history.sh"
}

teardown() {
  cleanup_test_environment
}

@test "history.sh - functions are defined" {
  function_exists disk_history_push
  function_exists disk_history_get
  function_exists disk_sparkline
  function_exists _disk_spark_glyph
  function_exists _disk_spark_level
  function_exists disk_history_length
}

@test "history.sh - _disk_spark_level maps values to levels" {
  [[ "$(_disk_spark_level 0 100)" == "0" ]]
  [[ "$(_disk_spark_level 50 100)" == "2" ]]
  [[ "$(_disk_spark_level 100 100)" == "4" ]]
}

@test "history.sh - _disk_spark_level clamps and defaults" {
  [[ "$(_disk_spark_level 200 100)" == "4" ]]
  [[ "$(_disk_spark_level -5 100)" == "0" ]]
  [[ "$(_disk_spark_level zz 100)" == "0" ]]
  [[ "$(_disk_spark_level 50 0)" == "2" ]]
}

@test "history.sh - _disk_spark_glyph returns a glyph for each level" {
  [[ -n "$(_disk_spark_glyph 0)" ]]
  [[ -n "$(_disk_spark_glyph 4)" ]]
  [[ "$(_disk_spark_glyph 0)" != "$(_disk_spark_glyph 4)" ]]
  [[ -n "$(_disk_spark_glyph 9)" ]]
}

@test "history.sh - disk_history_length default and override" {
  [[ "$(disk_history_length)" == "20" ]]
  set_tmux_option "@disk_revamped_history_length" "5"
  [[ "$(disk_history_length)" == "5" ]]
  set_tmux_option "@disk_revamped_history_length" "bad"
  [[ "$(disk_history_length)" == "20" ]]
}

@test "history.sh - disk_history_get is empty initially" {
  [[ -z "$(disk_history_get)" ]]
}

@test "history.sh - disk_history_push appends values" {
  disk_history_push 10
  disk_history_push 20
  [[ "$(disk_history_get)" == "10 20" ]]
}

@test "history.sh - disk_history_push ignores non-numeric input" {
  disk_history_push abc
  [[ -z "$(disk_history_get)" ]]
}

@test "history.sh - disk_history_push trims to the ring length" {
  set_tmux_option "@disk_revamped_history_length" "3"
  disk_history_push 1
  disk_history_push 2
  disk_history_push 3
  disk_history_push 4
  [[ "$(disk_history_get)" == "2 3 4" ]]
}

@test "history.sh - disk_sparkline renders the stored history" {
  disk_history_push 0
  disk_history_push 100
  run disk_sparkline
  [[ -n "${output}" ]]
}

@test "history.sh - disk_sparkline renders an explicit series" {
  run disk_sparkline "0 50 100" 100
  [[ -n "${output}" ]]
}

@test "history.sh - disk_sparkline is empty without data" {
  [[ -z "$(disk_sparkline)" ]]
  [[ -z "$(disk_sparkline "")" ]]
}

@test "history.sh - _disk_spark_glyph covers every level" {
  local a b c d e
  a="$(_disk_spark_glyph 0)"
  b="$(_disk_spark_glyph 1)"
  c="$(_disk_spark_glyph 2)"
  d="$(_disk_spark_glyph 3)"
  e="$(_disk_spark_glyph 4)"
  [[ -n "${a}" && -n "${b}" && -n "${c}" && -n "${d}" && -n "${e}" ]]
  [[ "${a}" != "${b}" && "${b}" != "${c}" && "${c}" != "${d}" && "${d}" != "${e}" ]]
}
