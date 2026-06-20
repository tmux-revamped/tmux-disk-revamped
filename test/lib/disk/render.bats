#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../helpers.bash"

setup() {
  setup_test_environment
  unset _DISK_REVAMPED_RENDER_LOADED
  source "${BATS_TEST_DIRNAME}/../../../src/lib/disk/render.sh"
}

teardown() {
  cleanup_test_environment
}

@test "render.sh - _disk_level classifies by thresholds" {
  [[ "$(_disk_level 10 70 90)" == "low" ]]
  [[ "$(_disk_level 75 70 90)" == "medium" ]]
  [[ "$(_disk_level 95 70 90)" == "high" ]]
}

@test "render.sh - _disk_level treats non-numeric as zero" {
  [[ "$(_disk_level zz 70 90)" == "low" ]]
}

@test "render.sh - disk_render_percentage is empty on cold start" {
  [[ -z "$(disk_render_percentage "")" ]]
}

@test "render.sh - disk_render_percentage uses the default format" {
  [[ "$(disk_render_percentage 55)" == "55%" ]]
}

@test "render.sh - disk_render_percentage honors a custom format" {
  set_tmux_option "@disk_revamped_percentage_format" "disk %s%%"
  [[ "$(disk_render_percentage 55)" == "disk 55%" ]]
}

@test "render.sh - disk_render_icon maps levels" {
  [[ "$(disk_render_icon 95)" == "▰▰▰" ]]
  [[ "$(disk_render_icon 75)" == "▰▰▱" ]]
  [[ "$(disk_render_icon 10)" == "▰▱▱" ]]
}

@test "render.sh - disk_render_icon is empty on cold start" {
  [[ -z "$(disk_render_icon "")" ]]
}

@test "render.sh - disk_render_icon honors a custom icon" {
  set_tmux_option "@disk_revamped_high_icon" "FULL"
  [[ "$(disk_render_icon 95)" == "FULL" ]]
}

@test "render.sh - disk_render_fg returns the configured color" {
  set_tmux_option "@disk_revamped_high_fg_color" "#[fg=red]"
  [[ "$(disk_render_fg 95)" == "#[fg=red]" ]]
}

@test "render.sh - disk_render_fg is empty on cold start" {
  [[ -z "$(disk_render_fg "")" ]]
}

@test "render.sh - disk_render_bg returns the configured color" {
  set_tmux_option "@disk_revamped_low_bg_color" "#[bg=green]"
  [[ "$(disk_render_bg 10)" == "#[bg=green]" ]]
}

@test "render.sh - disk_render_size formats with a gigabyte suffix" {
  [[ -z "$(disk_render_size "")" ]]
  [[ "$(disk_render_size 466)" == "466G" ]]
}

@test "render.sh - disk_render_size honors a custom format" {
  set_tmux_option "@disk_revamped_size_format" "%s GiB"
  [[ "$(disk_render_size 100)" == "100 GiB" ]]
}
