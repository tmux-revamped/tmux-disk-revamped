#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../helpers.bash"

setup() {
  setup_test_environment
  unset _DISK_REVAMPED_NOTIFY_LOADED
  source "${BATS_TEST_DIRNAME}/../../../src/lib/disk/notify.sh"
}

teardown() {
  cleanup_test_environment
}

@test "notify.sh - functions are defined" {
  function_exists _disk_notify
  function_exists _disk_notify_decide
  function_exists disk_notify_check
}

@test "notify.sh - _disk_notify_decide fires when crossing the threshold" {
  [[ "$(_disk_notify_decide 95 90 0)" == "fire" ]]
}

@test "notify.sh - _disk_notify_decide stays quiet when already notified" {
  [[ "$(_disk_notify_decide 95 90 1)" == "none" ]]
}

@test "notify.sh - _disk_notify_decide resets below the threshold" {
  [[ "$(_disk_notify_decide 50 90 1)" == "reset" ]]
}

@test "notify.sh - _disk_notify_decide is none below threshold and not notified" {
  [[ "$(_disk_notify_decide 50 90 0)" == "none" ]]
}

@test "notify.sh - _disk_notify_decide is none for bad input" {
  [[ "$(_disk_notify_decide xx 90 0)" == "none" ]]
  [[ "$(_disk_notify_decide 95 yy 0)" == "none" ]]
}

@test "notify.sh - _disk_notify uses osascript on macOS" {
  _PLATFORM_OS_CACHE="Darwin"
  local marker="${TEST_TMPDIR}/note"
  osascript() { echo "$*" > "${marker}"; }
  _disk_notify "Title" "Message"
  [[ -f "${marker}" ]]
}

@test "notify.sh - _disk_notify uses notify-send on Linux" {
  _PLATFORM_OS_CACHE="Linux"
  local marker="${TEST_TMPDIR}/note"
  notify-send() { echo "$*" > "${marker}"; }
  _disk_notify "Title" "Message"
  [[ -f "${marker}" ]]
}

@test "notify.sh - _disk_notify is a no-op when no notifier exists" {
  _PLATFORM_OS_CACHE="Plan9"
  has_command() { return 1; }
  run _disk_notify "Title" "Message"
  [[ "${status}" -eq 0 ]]
}

@test "notify.sh - disk_notify_check does nothing when disabled" {
  local marker="${TEST_TMPDIR}/fired"
  _disk_notify() { echo fired > "${marker}"; }
  disk_notify_check 95 90
  [[ ! -f "${marker}" ]]
}

@test "notify.sh - disk_notify_check fires once when enabled" {
  set_tmux_option "@disk_revamped_notify" "1"
  local marker="${TEST_TMPDIR}/fired"
  _disk_notify() { echo fired > "${marker}"; }
  disk_notify_check 95 90
  [[ -f "${marker}" ]]
  [[ "$(get_tmux_option @disk_revamped_notified)" == "1" ]]
  rm -f "${marker}"
  disk_notify_check 95 90
  [[ ! -f "${marker}" ]]
}

@test "notify.sh - disk_notify_check resets below the threshold" {
  set_tmux_option "@disk_revamped_notify" "1"
  set_tmux_option "@disk_revamped_notified" "1"
  _disk_notify() { :; }
  disk_notify_check 50 90
  [[ "$(get_tmux_option @disk_revamped_notified)" == "0" ]]
}

@test "notify.sh - disk_notify_check is a no-op for a steady disk" {
  set_tmux_option "@disk_revamped_notify" "1"
  _disk_notify() { :; }
  run disk_notify_check 50 90
  [[ "${status}" -eq 0 ]]
}
