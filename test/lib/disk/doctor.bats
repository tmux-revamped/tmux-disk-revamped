#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../helpers.bash"

setup() {
  setup_test_environment
  unset _DISK_REVAMPED_DOCTOR_LOADED
  source "${BATS_TEST_DIRNAME}/../../../src/lib/disk/doctor.sh"
}

teardown() {
  cleanup_test_environment
}

@test "doctor.sh - functions are defined" {
  function_exists disk_doctor
  function_exists _doctor_tool
}

@test "doctor.sh - _doctor_tool reports found and not found" {
  has_command() { [[ "$1" == "df" ]]; }
  run _doctor_tool df
  [[ "${output}" == *"df: found"* ]]
  run _doctor_tool nope
  [[ "${output}" == *"nope: not found"* ]]
}

@test "doctor.sh - disk_doctor reports macOS sources" {
  _PLATFORM_OS_CACHE="Darwin"
  has_command() { return 0; }
  run disk_doctor
  [[ "${output}" == *"platform: Darwin"* ]]
  [[ "${output}" == *"df -g"* ]]
  [[ "${output}" == *"purgeable: APFS"* ]]
}

@test "doctor.sh - disk_doctor reports Linux sources" {
  _PLATFORM_OS_CACHE="Linux"
  has_command() { return 0; }
  run disk_doctor
  [[ "${output}" == *"df -BG"* ]]
  [[ "${output}" == *"/proc/diskstats"* ]]
}

@test "doctor.sh - disk_doctor reports an unsupported platform" {
  _PLATFORM_OS_CACHE="Plan9"
  has_command() { return 1; }
  run disk_doctor
  [[ "${output}" == *"unsupported platform"* ]]
}

@test "doctor.sh - disk_doctor reports the notification setting" {
  _PLATFORM_OS_CACHE="Linux"
  has_command() { return 0; }
  set_tmux_option "@disk_revamped_notify" "1"
  run disk_doctor
  [[ "${output}" == *"notifications: on"* ]]
}
