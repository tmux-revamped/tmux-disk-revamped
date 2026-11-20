#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/disk_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/disk_helpers.bash"

DISKSTATS_FIRST='   8       0 sda 100 0 20480 0 100 0 40960 0 0 0 0
   8       1 sda1 50 0 10000 0 50 0 10000 0 0 0 0
   7       0 loop0 10 0 99999 0 10 0 99999 0 0 0 0
 253       0 dm-0 10 0 88888 0 10 0 88888 0 0 0 0
   8      16 sdb 1 0 7777 0 1 0 7777 0 0 0 0'

DISKSTATS_SECOND='   8       0 sda 200 0 225280 0 200 0 43008 0 0 0 0
   8       1 sda1 50 0 10000 0 50 0 10000 0 0 0 0
   7       0 loop0 10 0 99999 0 10 0 99999 0 0 0 0
 253       0 dm-0 10 0 88888 0 10 0 88888 0 0 0 0
   8      16 sdb 1 0 7777 0 1 0 7777 0 0 0 0'

@test "readers - a GNU df reading gives the percent and the sizes in gigabytes" {
  # Arrange
  df_says "-Pk /" "${GNU_USAGE}"

  # Act
  tool refresh

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "Refreshed. 55% of / is used." ]]
  holds percent 55
  holds used 55
  holds total 100
  holds free 45
  holds history 55
}

@test "readers - a BSD df on macOS reads through the system df" {
  # Arrange
  macos
  df_says "-Pk /" "${BSD_USAGE}"

  # Act
  tool refresh

  # Assert
  [[ "${output}" == "Refreshed. 55% of / is used." ]]
  holds used 55
  run grep -c '^bsd-df -Pk /$' "${FAKE}/asked"
  [[ "${output}" == "1" ]]
  run grep -c '^df ' "${FAKE}/asked"
  [[ "${output}" == "0" ]]
}

@test "readers - sizes round up to the next gigabyte like df -BG did" {
  # Arrange
  df_usage 104857601 57671681 47185919 55

  # Act
  tool refresh

  # Assert
  holds total 101
  holds used 56
  holds free 45
}

@test "readers - a BusyBox or uutils header and a device name with spaces still parse" {
  # Arrange
  df_says "-Pk /" 'Filesystem           1K-blocks      Used Available Use% Mounted on
my disk image    104857600  57671680  47185920  55% /'

  # Act
  tool refresh

  # Assert
  holds percent 55
  holds total 100
}

@test "readers - a mount df cannot read leaves every figure empty and the history alone" {
  # Arrange
  option history "10 20"
  option percent 99
  option used 9

  # Act
  tool refresh

  # Assert
  [[ "${output}" == "Refreshed. / has no reading." ]]
  holds percent ""
  holds used ""
  holds history "10 20"
}

@test "readers - a row without a percentage is no reading" {
  # Arrange
  df_says "-Pk /" 'Filesystem 1024-blocks Used Available Capacity Mounted on
none 0 0 0 - /'

  # Act
  tool refresh

  # Assert
  holds percent ""
}

@test "readers - the mount setting is what df is asked about" {
  # Arrange
  df_says "-Pk /home" "${GNU_USAGE}"
  option mount /home

  # Act
  tool refresh

  # Assert
  [[ "${output}" == "Refreshed. 55% of /home is used." ]]
  run grep -c '^df -Pk /home$' "${FAKE}/asked"
  [[ "${output}" == "1" ]]
}

@test "readers - each reading joins the history, which keeps the newest history_length of them" {
  # Arrange
  option history_length 3
  option history "10 20 30"

  # Act
  df_says "-Pk /" "${GNU_USAGE}"
  tool refresh

  # Assert
  holds history "20 30 55"
}

@test "readers - a history length that is not a positive number keeps 20" {
  # Arrange
  option history_length 0
  option history "1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20"
  df_says "-Pk /" "${GNU_USAGE}"

  # Act
  tool refresh

  # Assert
  holds history "2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 55"
}

@test "readers - inodes are read only when the status line shows them, and a GNU df has one percent" {
  # Arrange
  df_says "-Pk /" "${GNU_USAGE}"
  df_says "-i /" 'Filesystem      Inodes  IUsed   IFree IUse% Mounted on
/dev/sda1      6553600 345678 6207922    6% /'
  tool refresh
  holds inodes ""
  option published "percentage inodes"

  # Act
  tool refresh

  # Assert
  holds inodes 6
}

@test "readers - macOS df -i has two percentages and the inode one is the last" {
  # Arrange
  macos
  df_says "-Pk /" "${BSD_USAGE}"
  df_says "-i /" 'Filesystem   512-blocks      Used Available Capacity iused      ifree %iused  Mounted on
/dev/disk3s1s1 1953125000 114000000 80000000    59% 426983 1627000000     3%   /'
  option published inodes

  # Act
  tool refresh

  # Assert
  holds inodes 3
}

@test "readers - purgeable space comes from diskutil on macOS, in gigabytes or megabytes" {
  # Arrange
  macos
  df_says "-Pk /" "${BSD_USAGE}"
  says diskutil '   Volume Name:              Macintosh HD
   Purgeable Space:          12.5 GB (13421772800 Bytes)'
  option published purgeable
  tool refresh
  holds purgeable 12
  says diskutil '   Purgeable Space:          2048 MB (2147483648 Bytes)'

  # Act
  tool refresh

  # Assert
  holds purgeable 2
  run grep -c '^diskutil info /$' "${FAKE}/asked"
  [[ "${output}" == "2" ]]
}

@test "readers - a diskutil answer with no purgeable figure leaves it empty, and Linux never asks" {
  # Arrange
  macos
  df_says "-Pk /" "${BSD_USAGE}"
  says diskutil '   Container Free Space:     16.0 GB
   Purgeable:                unknown'
  option published purgeable
  tool refresh
  holds purgeable ""
  : >"${FAKE}/asked"
  linux
  df_says "-Pk /" "${GNU_USAGE}"

  # Act
  tool refresh

  # Assert
  run grep -c '^diskutil' "${FAKE}/asked"
  [[ "${output}" == "0" ]]
}

@test "readers - the first sample of the counters has no rate, the next one measures it from whole devices only" {
  # Arrange
  df_says "-Pk /" "${GNU_USAGE}"
  block_device sda
  block_device loop0
  block_device dm-0
  diskstats "${DISKSTATS_FIRST}"
  option published "read write"
  tool refresh
  holds read ""
  holds rd_raw 10240
  holds wr_raw 20480
  diskstats "${DISKSTATS_SECOND}"
  later 10

  # Act
  tool refresh

  # Assert
  holds read "10.0MB/s"
  holds write "102KB/s"
  holds io_ts 1000010
}

@test "readers - a counter that went backwards is a rate of zero" {
  # Arrange
  df_says "-Pk /" "${GNU_USAGE}"
  block_device sda
  diskstats "${DISKSTATS_SECOND}"
  option published "read write"
  tool refresh
  diskstats "${DISKSTATS_FIRST}"
  later 10

  # Act
  tool refresh

  # Assert
  holds read "0KB/s"
  holds write "0KB/s"
}

@test "readers - a reading in the same second keeps the rates it had" {
  # Arrange
  df_says "-Pk /" "${GNU_USAGE}"
  block_device sda
  diskstats "${DISKSTATS_FIRST}"
  option published "read write"
  tool refresh
  diskstats "${DISKSTATS_SECOND}"
  later 10
  tool refresh
  holds read "10.0MB/s"

  # Act
  tool refresh

  # Assert
  holds read "10.0MB/s"
  holds write "102KB/s"
  holds io_ts 1000010
}

@test "readers - macOS has no counters, so read and write stay empty" {
  # Arrange
  macos
  df_says "-Pk /" "${BSD_USAGE}"
  option published "read write"

  # Act
  tool refresh

  # Assert
  holds read ""
  run grep -c 'diskstats' "${FAKE}/asked"
  [[ "${output}" == "0" ]]
}

@test "readers - every disk is listed with its usage, without /boot and /snap on Linux" {
  # Arrange
  df_says "-Pk /" "${GNU_USAGE}"
  df_says "-h" "${GNU_ALL}"
  option published all

  # Act
  tool refresh

  # Assert
  run held all
  [[ "${output}" == $'/ 55%\037/data 30%' ]]
  holds all_ts 1000000
}

@test "readers - every disk on macOS leaves out the Volumes folder" {
  # Arrange
  macos
  df_says "-Pk /" "${BSD_USAGE}"
  df_says "-h" "${BSD_ALL}"
  option published all

  # Act
  tool refresh

  # Assert
  run held all
  [[ "${output}" == $'/ 45%\037/System/Volumes/Data 99%' ]]
}

@test "readers - the list of every disk is read again only after the detail interval" {
  # Arrange
  df_says "-Pk /" "${GNU_USAGE}"
  df_says "-h" "${GNU_ALL}"
  option published all
  tool refresh
  : >"${FAKE}/asked"
  later 30
  tool refresh
  run grep -c '^df -h$' "${FAKE}/asked"
  [[ "${output}" == "0" ]]
  later 40

  # Act
  tool refresh

  # Assert
  run grep -c '^df -h$' "${FAKE}/asked"
  [[ "${output}" == "1" ]]
}

@test "readers - the mounts setting lists its mounts that exist, in one df call, and the setting survives" {
  # Arrange
  mkdir -p "${BATS_TEST_TMPDIR}/one" "${BATS_TEST_TMPDIR}/two"
  local one="${BATS_TEST_TMPDIR}/one" two="${BATS_TEST_TMPDIR}/two"
  df_says "-Pk /" "${GNU_USAGE}"
  df_says "-Pk ${one} ${two}" "Filesystem 1024-blocks Used Available Capacity Mounted on
/dev/a 100 50 50 50% /x
/dev/b 100 20 80 20% /y"
  option mounts "${one},/does/not/exist ${two}"
  option published mounts

  # Act
  tool refresh

  # Assert
  run held mounts_list
  [[ "${output}" == "${one} 50%"$'\037'"${two} 20%" ]]
  holds mounts "${one},/does/not/exist ${two}"
  run grep -c '^df -Pk /.*one' "${FAKE}/asked"
  [[ "${output}" == "1" ]]
}

@test "readers - mounts that all fail to exist ask df nothing" {
  # Arrange
  df_says "-Pk /" "${GNU_USAGE}"
  option mounts "/does/not/exist"
  option published mounts

  # Act
  tool refresh

  # Assert
  holds mounts_list ""
  run grep -c '^df ' "${FAKE}/asked"
  [[ "${output}" == "1" ]]
}

@test "readers - the fill rate is the change in used space per hour, and the time to full follows from it" {
  # Arrange
  df_usage 104857600 52428800 52428800 50
  option published "fill_rate full_eta"
  tool refresh
  holds fill_rate ""
  holds used_raw 52428800
  df_usage 104857600 53477376 51380224 51
  later 3600

  # Act
  tool refresh

  # Assert
  holds fill_rate "1.0"
  holds full_eta 49
  holds fill_ts 1003600
}

@test "readers - a shrinking disk has a negative rate and no time to full" {
  # Arrange
  df_usage 104857600 52428800 52428800 50
  option published "fill_rate full_eta"
  tool refresh
  df_usage 104857600 51380224 53477376 49
  later 3600

  # Act
  tool refresh

  # Assert
  holds fill_rate "-1.0"
  holds full_eta ""
}

@test "readers - a reading in the same second keeps the rate and the time to full it had" {
  # Arrange
  df_usage 104857600 52428800 52428800 50
  option published "fill_rate full_eta"
  tool refresh
  df_usage 104857600 53477376 51380224 51
  later 3600
  tool refresh
  holds fill_rate "1.0"

  # Act
  tool refresh

  # Assert
  holds fill_rate "1.0"
  holds full_eta 49
  holds fill_ts 1003600
  holds used_raw 53477376
}

@test "readers - a fill rate and a time to full are not measured when the status line does not show them" {
  # Arrange
  df_says "-Pk /" "${GNU_USAGE}"

  # Act
  tool refresh

  # Assert
  holds used_raw ""
  holds fill_ts ""
}

@test "readers - crossing the high threshold sends one notification, and falling below it rearms it" {
  # Arrange
  quiet notify-send 'printf "%s|%s\n" "$2" "$3" >>"'"${FAKE}"'/notified"'
  df_usage 100 95 5 95
  option notify 1
  option high_thresh 90
  tool refresh
  tool refresh
  run cat "${FAKE}/notified"
  [[ "${output}" == "Disk almost full|Usage at 95% on /" ]]
  holds notified 1
  df_says "-Pk /" "${GNU_USAGE}"

  # Act
  tool refresh

  # Assert
  holds notified 0
  run grep -c . "${FAKE}/notified"
  [[ "${output}" == "1" ]]
}

@test "readers - without the notify switch, or with a threshold that is not a number, nothing is sent" {
  # Arrange
  quiet notify-send 'printf "sent\n" >>"'"${FAKE}"'/notified"'
  df_usage 100 95 5 95
  tool refresh
  option notify 1
  option high_thresh high
  tool refresh
  df_says "-Pk /" "${GNU_USAGE}"

  # Act
  tool refresh

  # Assert
  [[ ! -e "${FAKE}/notified" ]]
  holds notified ""
}

@test "readers - a notification waits for the percent to be a number" {
  # Arrange
  quiet notify-send 'printf "sent\n" >>"'"${FAKE}"'/notified"'
  option notify 1

  # Act
  tool refresh

  # Assert
  [[ ! -e "${FAKE}/notified" ]]
}
