#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../helpers.bash"

setup() {
  setup_test_environment
  unset _DISK_REVAMPED_DISK_LOADED _DISK_REVAMPED_RENDER_LOADED
  export CACHE_SYNC=1
  source "${BATS_TEST_DIRNAME}/../../../src/disk.sh"
  read_disk() { echo "55 100 466 366"; }
  read_disk_io() { echo ""; }
  read_all_disks() { printf '/ 55%%\n/home 30%%\n'; }
  read_inodes() { echo "12"; }
  read_purgeable() { echo ""; }
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

@test "disk.sh dispatcher - disk_refresh_io stores then computes rates" {
  read_disk_io() { echo "1000 2000"; }
  export MOCK_EPOCH=1000
  disk_refresh_io
  [[ "$(cache_get rd_raw)" == "1000" ]]
  read_disk_io() { echo "3048 6096"; }
  export MOCK_EPOCH=1002
  disk_refresh_io
  [[ "$(cache_get read)" == "1.0MB/s" ]]
  [[ "$(cache_get write)" == "2.0MB/s" ]]
}

@test "disk.sh dispatcher - read and write subcommands echo the cache" {
  cache_set read "5.0MB/s"
  cache_set write "1.0MB/s"
  run main read
  [[ "${output}" == "5.0MB/s" ]]
  run main write
  [[ "${output}" == "1.0MB/s" ]]
}

@test "disk.sh dispatcher - all subcommand joins every disk" {
  run main all
  [[ "${output}" == "/ 55%, /home 30%" ]]
}

@test "disk.sh dispatcher - unknown subcommand produces no output" {
  run main bogus
  [[ -z "${output}" ]]
}

@test "disk.sh dispatcher - new helper functions are defined" {
  function_exists disk_high_thresh
  function_exists disk_refresh_fill
  function_exists disk_refresh_inodes
  function_exists disk_refresh_mounts
  function_exists disk_refresh_purgeable
  function_exists disk_doctor
  function_exists disk_show_popup
  function_exists disk_show_eat
}

@test "disk.sh dispatcher - disk_refresh caches free space" {
  disk_refresh
  [[ "$(cache_get free)" == "366" ]]
}

@test "disk.sh dispatcher - free subcommand renders cached free space" {
  cache_set free "366"
  run main free
  [[ "${output}" == "366G" ]]
}

@test "disk.sh dispatcher - free subcommand auto-scales to terabytes" {
  cache_set percent "55"
  cache_set free "2048"
  run main free
  [[ "${output}" == "2.0T" ]]
}

@test "disk.sh dispatcher - disk_refresh caches inode usage" {
  disk_refresh
  [[ "$(cache_get inodes)" == "12" ]]
}

@test "disk.sh dispatcher - inodes subcommand renders the cached value" {
  cache_set inodes "12"
  run main inodes
  [[ "${output}" == "i12%" ]]
}

@test "disk.sh dispatcher - purgeable subcommand renders cached gigabytes" {
  cache_set percent "55"
  cache_set purgeable "8"
  run main purgeable
  [[ "${output}" == "8G" ]]
  cache_set percent "55"
  cache_set purgeable ""
  run main purgeable
  [[ -z "${output}" ]]
}

@test "disk.sh dispatcher - disk_refresh pushes history and graph renders" {
  disk_refresh
  [[ -n "$(get_tmux_option @disk_revamped_history)" ]]
  run main graph
  [[ -n "${output}" ]]
}

@test "disk.sh dispatcher - disk_refresh_fill computes rate and eta" {
  export MOCK_EPOCH=1000
  disk_refresh_fill 100 366
  [[ "$(cache_get used_raw)" == "100" ]]
  export MOCK_EPOCH=4600
  disk_refresh_fill 110 356
  [[ "$(cache_get fill_rate)" == "10.0" ]]
  cache_set percent "55"
  run main fill_rate
  [[ "${output}" == "+10.0G/h" ]]
  run main full_eta
  [[ "${output}" == *"h" || "${output}" == *"d" ]]
}

@test "disk.sh dispatcher - disk_refresh_fill ignores non-numeric used" {
  run disk_refresh_fill abc 100
  [[ "${status}" -eq 0 ]]
}

@test "disk.sh dispatcher - disk_refresh_mounts lists pinned mounts" {
  set_tmux_option "@disk_revamped_mounts" "/ /home"
  cache_set percent "55"
  disk_refresh_mounts
  run main mounts
  [[ "${output}" == "/ 55%, /home 55%" ]]
}

@test "disk.sh dispatcher - disk_refresh_mounts is empty without configuration" {
  run disk_refresh_mounts
  [[ "${status}" -eq 0 ]]
  [[ -z "$(cache_get mounts)" ]]
}

@test "disk.sh dispatcher - disk_high_thresh default is 90" {
  [[ "$(disk_high_thresh)" == "90" ]]
}

@test "disk.sh dispatcher - doctor subcommand prints a report" {
  _PLATFORM_OS_CACHE="Linux"
  has_command() { return 0; }
  run main doctor
  [[ "${output}" == *"tmux-disk-revamped doctor"* ]]
}

@test "disk.sh dispatcher - card subcommand prints a card" {
  cache_set percent 55
  run main card
  [[ "${output}" == *"Usage 55%"* ]]
}

@test "disk.sh dispatcher - eat_view subcommand prints the scan view" {
  cache_set eat "5G /x"
  run main eat_view
  [[ "${output}" == *"5G /x"* ]]
}

@test "disk.sh dispatcher - popup subcommand opens a popup" {
  local marker="${TEST_TMPDIR}/p"
  _tmux() { echo "$*" > "${marker}"; }
  main popup
  grep -q "display-popup" "${marker}"
}

@test "disk.sh dispatcher - eat subcommand scans and opens a popup" {
  _run_du() { echo "9G /y"; }
  local marker="${TEST_TMPDIR}/p"
  _tmux() { echo "$*" > "${marker}"; }
  main eat
  [[ "$(cache_get eat)" == "9G /y" ]]
  grep -q "display-popup" "${marker}"
}

@test "disk.sh dispatcher - disk_refresh_purgeable caches the seam value" {
  read_purgeable() { echo "4"; }
  disk_refresh_purgeable
  [[ "$(cache_get purgeable)" == "4" ]]
}

@test "disk.sh dispatcher - fg_color and bg_color render from the cached percent" {
  set_tmux_option "@disk_revamped_high_fg_color" "#[fg=red]"
  set_tmux_option "@disk_revamped_high_bg_color" "#[bg=red]"
  cache_set percent "95"
  run main fg_color
  [[ "${output}" == "#[fg=red]" ]]
  cache_set percent "95"
  run main bg_color
  [[ "${output}" == "#[bg=red]" ]]
}
