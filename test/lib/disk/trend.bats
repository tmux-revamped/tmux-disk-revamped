#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../helpers.bash"

setup() {
  setup_test_environment
  unset _DISK_REVAMPED_TREND_LOADED
  source "${BATS_TEST_DIRNAME}/../../../src/lib/disk/trend.sh"
}

teardown() {
  cleanup_test_environment
}

@test "trend.sh - functions are defined" {
  function_exists disk_fill_rate_compute
  function_exists disk_render_fill_rate
  function_exists disk_eta_compute
  function_exists disk_render_eta
}

@test "trend.sh - disk_fill_rate_compute is gigabytes per hour" {
  [[ "$(disk_fill_rate_compute 110 100 3600)" == "10.0" ]]
  [[ "$(disk_fill_rate_compute 100 110 3600)" == "-10.0" ]]
}

@test "trend.sh - disk_fill_rate_compute is empty for bad input" {
  [[ -z "$(disk_fill_rate_compute x 100 3600)" ]]
  [[ -z "$(disk_fill_rate_compute 110 100 0)" ]]
}

@test "trend.sh - disk_render_fill_rate signs the rate" {
  [[ "$(disk_render_fill_rate 2.1)" == "+2.1G/h" ]]
  [[ "$(disk_render_fill_rate -1.0)" == "-1.0G/h" ]]
}

@test "trend.sh - disk_render_fill_rate is empty for zero or bad input" {
  [[ -z "$(disk_render_fill_rate 0)" ]]
  [[ -z "$(disk_render_fill_rate "")" ]]
  [[ -z "$(disk_render_fill_rate abc)" ]]
}

@test "trend.sh - disk_eta_compute divides available by the rate" {
  [[ "$(disk_eta_compute 100 10)" == "10" ]]
}

@test "trend.sh - disk_eta_compute is empty when not filling" {
  [[ -z "$(disk_eta_compute 100 0)" ]]
  [[ -z "$(disk_eta_compute 100 -5)" ]]
  [[ -z "$(disk_eta_compute x 10)" ]]
  [[ -z "$(disk_eta_compute 100 bad)" ]]
}

@test "trend.sh - disk_render_eta formats days, hours, and sub-hour" {
  [[ "$(disk_render_eta 72)" == "3d" ]]
  [[ "$(disk_render_eta 5)" == "5h" ]]
  [[ "$(disk_render_eta 0)" == "<1h" ]]
}

@test "trend.sh - disk_render_eta is empty for bad input" {
  [[ -z "$(disk_render_eta "")" ]]
  [[ -z "$(disk_render_eta abc)" ]]
}
