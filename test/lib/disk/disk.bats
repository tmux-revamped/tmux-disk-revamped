#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../helpers.bash"

MAC_DF=$'Filesystem 1G-blocks Used Avail Capacity iused ifree %iused Mounted on\n/dev/disk3s1 466 100 366 22% 1000 2000 1% /'
LINUX_DF=$'Filesystem 1G-blocks Used Avail Use% Mounted on\n/dev/sda1 100G 40G 60G 40% /'

setup() {
  setup_test_environment
  unset _DISK_REVAMPED_DISK_LOADED
  source "${BATS_TEST_DIRNAME}/../../../src/lib/disk/disk.sh"
}

teardown() {
  cleanup_test_environment
}

@test "disk.sh - disk_parse_df parses macOS df output" {
  [[ "$(disk_parse_df "${MAC_DF}")" == "22 100 466" ]]
}

@test "disk.sh - disk_parse_df parses Linux df output" {
  [[ "$(disk_parse_df "${LINUX_DF}")" == "40 40 100" ]]
}

@test "disk.sh - disk_parse_df is empty without a data line" {
  [[ -z "$(disk_parse_df "Filesystem Size Used")" ]]
}

@test "disk.sh - read_disk uses macOS df" {
  _PLATFORM_OS_CACHE="Darwin"
  _read_df_macos() { echo "${MAC_DF}"; }
  [[ "$(read_disk /)" == "22 100 466" ]]
}

@test "disk.sh - read_disk uses Linux df" {
  _PLATFORM_OS_CACHE="Linux"
  _read_df_linux() { echo "${LINUX_DF}"; }
  [[ "$(read_disk /)" == "40 40 100" ]]
}

@test "disk.sh - read_disk is empty on an unknown platform" {
  _PLATFORM_OS_CACHE="Plan9"
  [[ -z "$(read_disk /)" ]]
}
