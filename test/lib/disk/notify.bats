#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../helpers.bash"

setup() {
  setup_test_environment
  unset _DISK_REVAMPED_NOTIFY_LOADED
  source "${BATS_TEST_DIRNAME}/../../../src/lib/disk/notify.sh"
  _PLATFORM_OS_CACHE="Linux"
  NOTIFY_CALLS="${TEST_TMPDIR}/calls"
  mkdir -p "${TEST_TMPDIR}/bin"
  printf '#!/bin/sh\nprintf "%%s|" "$@" >>"%s"\nprintf "\\n" >>"%s"\n' "${NOTIFY_CALLS}" "${NOTIFY_CALLS}" >"${TEST_TMPDIR}/bin/notify-send"
  chmod +x "${TEST_TMPDIR}/bin/notify-send"
  PATH="${TEST_TMPDIR}/bin:${PATH}"
}

teardown() {
  cleanup_test_environment
}

@test "notify.sh - functions are defined" {
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

@test "notify.sh - disk_notify_check sends nothing while the option is off" {
  # Arrange
  set_tmux_option "@disk_revamped_mount" "/data"

  # Act
  disk_notify_check 95 90

  # Assert
  [ ! -e "${NOTIFY_CALLS}" ]
}

@test "notify.sh - disk_notify_check notifies once through the shared notifier" {
  # Arrange
  set_tmux_option "@disk_revamped_notify" "1"
  set_tmux_option "@disk_revamped_mount" "/data"

  # Act
  disk_notify_check 95 90
  disk_notify_check 96 90

  # Assert
  [ "$(cat "${NOTIFY_CALLS}")" = "--|Disk almost full|Usage at 95% on /data|" ]
  [ "$(get_tmux_option @disk_revamped_notified)" = "1" ]
}

@test "notify.sh - disk_notify_check resets below the threshold" {
  # Arrange
  set_tmux_option "@disk_revamped_notify" "1"
  set_tmux_option "@disk_revamped_notified" "1"

  # Act
  disk_notify_check 50 90

  # Assert
  [ "$(get_tmux_option @disk_revamped_notified)" = "0" ]
  [ ! -e "${NOTIFY_CALLS}" ]
}

@test "notify.sh - disk_notify_check is a no-op for a steady disk" {
  # Arrange
  set_tmux_option "@disk_revamped_notify" "1"

  # Act
  run disk_notify_check 50 90

  # Assert
  [ "${status}" -eq 0 ]
  [ ! -e "${NOTIFY_CALLS}" ]
}
