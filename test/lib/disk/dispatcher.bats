#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../helpers.bash"

setup() {
  setup_test_environment
  unset _DISK_REVAMPED_DISK_LOADED _DISK_REVAMPED_RENDER_LOADED
  export CACHE_SYNC=1
  source "${BATS_TEST_DIRNAME}/../../../src/disk.sh"
  read_disk() { echo "55 100 466"; }
}

teardown() {
  cleanup_test_environment
}

@test "disk.sh dispatcher - functions are defined" {
  function_exists main
  function_exists disk_refresh
  function_exists disk_tick
  function_exists disk_max_age
  function_exists disk_mount
}

@test "disk.sh dispatcher - disk_max_age default is 30" {
  [[ "$(disk_max_age)" == "30" ]]
}

@test "disk.sh dispatcher - disk_mount default is root" {
  [[ "$(disk_mount)" == "/" ]]
}

@test "disk.sh dispatcher - disk_mount honors the option" {
  set_tmux_option "@disk_revamped_mount" "/home"
  [[ "$(disk_mount)" == "/home" ]]
}

@test "disk.sh dispatcher - disk_refresh caches percent, used, total" {
  disk_refresh
  [[ "$(cache_get percent)" == "55" ]]
  [[ "$(cache_get used)" == "100" ]]
  [[ "$(cache_get total)" == "466" ]]
}

@test "disk.sh dispatcher - refresh subcommand caches values" {
  main refresh
  [[ "$(cache_get percent)" == "55" ]]
}

@test "disk.sh dispatcher - percentage renders the cached value" {
  run main percentage
  [[ "${output}" == "55%" ]]
}

@test "disk.sh dispatcher - icon maps the cached value" {
  run main icon
  [[ "${output}" == "▰▱▱" ]]
}

@test "disk.sh dispatcher - used and total render with a suffix" {
  run main used
  [[ "${output}" == "100G" ]]
  run main total
  [[ "${output}" == "466G" ]]
}

@test "disk.sh dispatcher - unknown subcommand produces no output" {
  run main bogus
  [[ -z "${output}" ]]
}
