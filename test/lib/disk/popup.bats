#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../helpers.bash"

setup() {
  setup_test_environment
  unset _DISK_REVAMPED_POPUP_LOADED
  export CACHE_PREFIX="disk_revamped"
  export CACHE_SYNC=1
  export DISK_SELF="/bin/disk.sh"
  source "${BATS_TEST_DIRNAME}/../../../src/lib/disk/popup.sh"
}

teardown() {
  cleanup_test_environment
}

@test "popup.sh - functions are defined" {
  function_exists _tmux
  function_exists _run_du
  function_exists disk_eat_path
  function_exists disk_eat_refresh
  function_exists disk_eat_view
  function_exists disk_show_eat
  function_exists disk_card
  function_exists disk_show_popup
}

@test "popup.sh - _tmux routes through tmux" {
  run _tmux set-option -gq @x y
  [[ "${status}" -eq 0 ]]
}

@test "popup.sh - _run_du is callable with stubbed binaries" {
  du() { echo "10M /a"; }
  sort() { cat; }
  head() { cat; }
  run _run_du /tmp
  [[ "${status}" -eq 0 ]]
}

@test "popup.sh - disk_eat_path defaults to the mount" {
  [[ "$(disk_eat_path)" == "/" ]]
  set_tmux_option "@disk_revamped_mount" "/home"
  [[ "$(disk_eat_path)" == "/home" ]]
}

@test "popup.sh - disk_eat_path honors an explicit scan path" {
  set_tmux_option "@disk_revamped_eat_path" "/data"
  [[ "$(disk_eat_path)" == "/data" ]]
}

@test "popup.sh - disk_eat_refresh caches the scan output" {
  _run_du() { printf '20G /big\n10G /med\n'; }
  disk_eat_refresh
  [[ "$(cache_get eat)" == $'20G /big\n10G /med' ]]
}

@test "popup.sh - disk_eat_view shows the cached scan" {
  cache_set eat $'20G /big\n10G /med'
  run disk_eat_view
  [[ "${output}" == *"Largest items under /"* ]]
  [[ "${output}" == *"20G /big"* ]]
}

@test "popup.sh - disk_eat_view shows a placeholder before the scan lands" {
  run disk_eat_view
  [[ "${output}" == *"Scanning"* ]]
}

@test "popup.sh - disk_show_eat scans then opens the popup" {
  _run_du() { echo "5G /x"; }
  local marker="${TEST_TMPDIR}/popup"
  _tmux() { echo "$*" > "${marker}"; }
  disk_show_eat
  [[ "$(cache_get eat)" == "5G /x" ]]
  grep -q "display-popup" "${marker}"
  grep -q "eat_view" "${marker}"
}

@test "popup.sh - disk_card prints a card from cached values" {
  cache_set percent 55
  cache_set used 100
  cache_set free 366
  cache_set total 466
  cache_set all $'/ 55%\n/home 30%'
  run disk_card
  [[ "${output}" == *"Usage 55%"* ]]
  [[ "${output}" == *"Free  366G"* ]]
  [[ "${output}" == *"Mounts"* ]]
}

@test "popup.sh - disk_card omits the mounts block when empty" {
  cache_set percent 55
  run disk_card
  [[ "${output}" != *"Mounts"* ]]
}

@test "popup.sh - disk_show_popup opens the card popup" {
  local marker="${TEST_TMPDIR}/popup"
  _tmux() { echo "$*" > "${marker}"; }
  disk_show_popup
  grep -q "display-popup" "${marker}"
  grep -q "card" "${marker}"
}
