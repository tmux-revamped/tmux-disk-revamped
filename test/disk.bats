#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/disk_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/disk_helpers.bash"

bats_require_minimum_version 1.5.0

shows() {
  tool status "$1"
  [[ "${status}" -eq 0 ]]
}

@test "disk - the percentage is the stored percent in the default format, and an empty format option means the default" {
  # Arrange
  sampled 55
  option percentage_format ''

  # Act
  tool status percentage

  # Assert
  [[ "${output}" == "55%" ]]
}

@test "disk - the percentage takes the format the option gives" {
  # Arrange
  sampled 55
  option percentage_format 'disk %s percent'

  # Act
  tool status percentage

  # Assert
  [[ "${output}" == "disk 55 percent" ]]
}

@test "disk - with nothing stored every placeholder prints nothing" {
  # Arrange
  option percent_ts 1000000
  local name

  # Act
  for name in percentage icon fg_color bg_color used total free read write inodes purgeable graph fill_rate full_eta mounts all; do
    tool status "${name}"

    # Assert
    [[ "${status}" -eq 0 ]]
    [[ -z "${output}" ]]
  done
}

@test "disk - the icon and the colours follow the usage tier, with the medium tier from 70 and the high from 90" {
  # Arrange
  option low_icon L
  option medium_icon M
  option high_icon H
  option low_fg_color '#[fg=green]'
  option medium_fg_color '#[fg=yellow]'
  option high_fg_color '#[fg=red]'
  option low_bg_color '#[bg=black]'
  option medium_bg_color '#[bg=grey]'
  option high_bg_color '#[bg=white]'
  local line percent icon fg bg

  # Act
  for line in "69 L green black" "70 M yellow grey" "89 M yellow grey" "90 H red white"; do
    read -r percent icon fg bg <<<"${line}"
    option percent "${percent}"
    option percent_ts 1000000
    tool status icon
    [[ "${output}" == "${icon}" ]]
    tool status fg_color
    [[ "${output}" == "#[fg=${fg}]" ]]
    tool status bg_color

    # Assert
    [[ "${output}" == "#[bg=${bg}]" ]]
  done
}

@test "disk - the default icons are one, two and three bars, and the thresholds are the options" {
  # Arrange
  option high_thresh 50
  option medium_thresh 20
  sampled 25
  tool status icon
  [[ "${output}" == "▰▰▱" ]]
  sampled 10
  tool status icon
  [[ "${output}" == "▰▱▱" ]]
  sampled 60

  # Act
  tool status icon

  # Assert
  [[ "${output}" == "▰▰▰" ]]
}

@test "disk - a threshold that is not a number is the default" {
  # Arrange
  option medium_thresh many
  option high_thresh most
  sampled 75

  # Act
  tool status icon

  # Assert
  [[ "${output}" == "▰▰▱" ]]
}

@test "disk - a colour with no reading is empty" {
  # Arrange
  option low_fg_color '#[fg=green]'
  option percent_ts 1000000

  # Act
  tool status fg_color

  # Assert
  [[ -z "${output}" ]]
}

@test "disk - sizes are gigabytes, and from 1024G they are terabytes with one decimal" {
  # Arrange
  option used 55
  option total 1843
  option free 1024
  option purgeable 12
  sampled 55
  tool status used
  [[ "${output}" == "55G" ]]
  tool status total
  [[ "${output}" == "1.8T" ]]
  tool status free
  [[ "${output}" == "1.0T" ]]

  # Act
  tool status purgeable

  # Assert
  [[ "${output}" == "12G" ]]
}

@test "disk - a size below 1024G takes the size format, and a size that is not a number is printed as it is" {
  # Arrange
  option size_format '%s GB'
  option used 55
  option free many
  sampled 55
  tool status used
  [[ "${output}" == "55 GB" ]]

  # Act
  tool status free

  # Assert
  [[ "${output}" == "many GB" ]]
}

@test "disk - terabytes print with a decimal point under a locale that has a decimal comma" {
  # Arrange
  option total 1843
  sampled 55

  # Act
  # shellcheck disable=SC2086
  run --separate-stderr env LC_ALL=pt_BR.UTF-8 ${REVAMPED_TEST_SHELL:-sh} "${REVAMPED_TESTS_DIR}/../bin/disk-revamped" status total

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "1.8T" ]]
}

@test "disk - the fill rate prints under a locale that has a decimal comma" {
  # Arrange
  option fill_rate 2.1
  sampled 55

  # Act
  # shellcheck disable=SC2086
  run --separate-stderr env LC_ALL=pt_BR.UTF-8 ${REVAMPED_TEST_SHELL:-sh} "${REVAMPED_TESTS_DIR}/../bin/disk-revamped" status fill_rate

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "+2.1G/h" ]]
}

@test "disk - the rates print as they were stored" {
  # Arrange
  option read "1.2MB/s"
  option write "12KB/s"
  sampled 55
  tool status read
  [[ "${output}" == "1.2MB/s" ]]

  # Act
  tool status write

  # Assert
  [[ "${output}" == "12KB/s" ]]
}

@test "disk - the inodes take their format" {
  # Arrange
  option inodes 12
  sampled 55
  tool status inodes
  [[ "${output}" == "i12%" ]]
  option inodes_format 'inodes %s'

  # Act
  tool status inodes

  # Assert
  [[ "${output}" == "inodes 12" ]]
}

@test "disk - the graph draws one bar of five for each stored reading" {
  # Arrange
  option history "0 25 50 75 100 150 12.7 x"
  sampled 55

  # Act
  tool status graph

  # Assert
  [[ "${output}" == $'\xe2\x96\x81\xe2\x96\x82\xe2\x96\x84\xe2\x96\x86\xe2\x96\x88\xe2\x96\x88\xe2\x96\x81\xe2\x96\x81' ]]
}

@test "disk - the fill rate is signed, and a steady or unreadable one prints nothing" {
  # Arrange
  sampled 55
  option fill_rate 2.1
  tool status fill_rate
  [[ "${output}" == "+2.1G/h" ]]
  option fill_rate -1.5
  tool status fill_rate
  [[ "${output}" == "-1.5G/h" ]]
  option fill_rate 0.0
  tool status fill_rate
  [[ -z "${output}" ]]

  # Act
  option fill_rate fast
  tool status fill_rate

  # Assert
  [[ -z "${output}" ]]
}

@test "disk - the time to full is days from a day, hours from an hour, and under an hour otherwise" {
  # Arrange
  sampled 55
  option full_eta 72
  tool status full_eta
  [[ "${output}" == "3d" ]]
  option full_eta 5
  tool status full_eta
  [[ "${output}" == "5h" ]]
  option full_eta 0
  tool status full_eta
  [[ "${output}" == "<1h" ]]

  # Act
  option full_eta soon
  tool status full_eta

  # Assert
  [[ -z "${output}" ]]
}

@test "disk - a list of disks joins its rows with the separator, and an empty separator option means the default" {
  # Arrange
  sampled 55
  option all $'/ 55%\037/data 30%'
  option mounts_list $'/ 55%\037/home 10%'
  option separator ''
  tool status all
  [[ "${output}" == "/ 55%, /data 30%" ]]
  option separator ' | '
  tool status all
  [[ "${output}" == "/ 55% | /data 30%" ]]

  # Act
  tool status mounts

  # Assert
  [[ "${output}" == "/ 55% | /home 10%" ]]
}

@test "disk - a hash in a mount path is doubled, and a style in the separator is kept" {
  # Arrange
  sampled 55
  option all $'/mnt/#S 55%\037/b 3%'
  option separator '#[fg=red] '

  # Act
  tool status all

  # Assert
  [[ "${output}" == '/mnt/##S 55%#[fg=red] /b 3%' ]]
}

@test "disk - a label comes before the value, and not before nothing" {
  # Arrange
  sampled 55
  option percentage_label 'disk:'
  tool status percentage
  [[ "${output}" == "disk: 55%" ]]
  option percent ''
  option percent_ts 1000000

  # Act
  tool status percentage

  # Assert
  [[ -z "${output}" ]]
}

@test "disk - the nerd icon set labels every metric with its glyph, and a label of its own wins" {
  # Arrange
  option icons nerd
  option used 55
  option fill_rate 1.0
  option full_eta 9
  option inodes 4
  option read 1KB/s
  option write 1KB/s
  option purgeable 2
  option total 2
  option free 2
  option history "10"
  option all "/ 1%"
  option mounts_list "/ 1%"
  sampled 55
  local metric name bytes glyph

  # Act
  for metric in "percentage F3B08B8A" "used F3B086BC" "total F3B086BC" "free F3B09DB0" "read F3B0879A" "write F3B09592" "inodes F3B09985" "purgeable F3B083A2" "graph F3B09EB1" "fill_rate F3B094B5" "full_eta F3B0949F" "mounts F3B08993" "all F3B08993"; do
    read -r name bytes <<<"${metric}"
    tool status "${name}"
    glyph=$(printf '%s' "${bytes}" | sed 's/../\\x&/g')

    # Assert
    [[ "${output}" == "$(printf '%b' "${glyph}") "* ]]
  done
  option used_label 'U'
  tool status used
  [[ "${output}" == "U 55G" ]]
}

@test "disk - the icon and the colours take no label even in the nerd set" {
  # Arrange
  option icons nerd
  option low_icon L
  sampled 10

  # Act
  tool status icon

  # Assert
  [[ "${output}" == "L" ]]
}

@test "disk - fixed width pads every value to its natural width, and a width of its own wins" {
  # Arrange
  option fixed_width on
  option read 1KB/s
  option inodes 4
  sampled 5
  tool status percentage
  [[ "${output}" == "  5%" ]]
  tool status read
  [[ "${output}" == "    1KB/s" ]]
  tool status inodes
  [[ "${output}" == " i4%" ]]
  option percentage_width 6

  # Act
  tool status percentage

  # Assert
  [[ "${output}" == "    5%" ]]
}

@test "disk - a width that is not a number is ignored, and a value longer than its width is never cut" {
  # Arrange
  option percentage_width wide
  option inodes_width 2
  option inodes 50
  sampled 5
  tool status percentage
  [[ "${output}" == "5%" ]]

  # Act
  tool status inodes

  # Assert
  [[ "${output}" == "i50%" ]]
}

@test "disk - a name that is not a placeholder prints nothing and succeeds" {
  # Arrange
  sampled 55

  # Act
  tool status bogus

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ -z "${output}" ]]
}

@test "disk - an old reading starts one background refresh, which stores the new one" {
  # Arrange
  df_says "-Pk /" "${GNU_USAGE}"
  option percent 10
  option percent_ts 900000

  # Act
  tool status percentage

  # Assert
  [[ "${output}" == "10%" ]]
  eventually holds percent 55
  eventually holds percent_lock 0
}

@test "disk - a refresh under way, or a reading still fresh, starts nothing" {
  # Arrange
  df_says "-Pk /" "${GNU_USAGE}"
  option percent 10
  option percent_ts 900000
  option percent_lock 1
  option percent_lock_ts 999990
  tool status percentage
  option percent_lock_ts 1
  sampled 10 999990

  # Act
  tool status percentage

  # Assert
  run grep -c '^df' "${FAKE}/asked"
  [[ "${output}" == "0" ]]
}

@test "disk - a lock that has run too long no longer holds the next refresh back" {
  # Arrange
  df_says "-Pk /" "${GNU_USAGE}"
  option percent 10
  option percent_ts 900000
  option percent_lock 1
  option percent_lock_ts 900000

  # Act
  tool status percentage

  # Assert
  eventually holds percent 55
}

@test "disk - an interval that is not a number is the default of 30 seconds" {
  # Arrange
  df_says "-Pk /" "${GNU_USAGE}"
  option interval soon
  sampled 10 999980

  # Act
  tool status percentage

  # Assert
  run grep -c '^df' "${FAKE}/asked"
  [[ "${output}" == "0" ]]
}

@test "disk - a tmux version is read out of its banner and compared part by part" {
  # Arrange
  local script='for banner in "tmux 3.6a" "tmux next-3.7" "nonsense"; do printf "[%s]" "$(disk_revamped_parse_version "${banner}")"; done; for pair in "3.6 3.2" "3.2 3.2" "3.1 3.2" "4.0 3.2" "2.9 3.2" " 3.2" "x 3.2"; do if disk_revamped_version_ge ${pair}; then printf y; else printf n; fi; done'

  # Act
  lib_run disk "${script}"

  # Assert
  [[ "${output}" == "[3.6][3.7][]yynynnn" ]]
}
