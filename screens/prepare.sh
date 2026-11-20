#!/bin/sh
set -eu

: "${SCREENS_REPO:?}"
demo=/Users/Shared/demo
rm -rf "${demo}"
mkdir -p "${demo}/home" "${demo}/bin" "${demo}/tmux-disk-revamped" "${demo}/data" "${demo}/backup"
cp -Rpf "${SCREENS_REPO}/bin" "${SCREENS_REPO}/lib" "${SCREENS_REPO}/disk-revamped.tmux" "${demo}/tmux-disk-revamped/"
for tool in tmux gum; do
  tool_path=$(command -v "${tool}")
  ln -s "${tool_path}" "${demo}/bin/${tool}"
done
for item in Library Movies Projects Downloads .cache Documents; do
  mkdir -p "${demo}/data/${item}"
done
date +%s >"${demo}/start"

cat >"${demo}/bin/df" <<'DF'
#!/bin/sh
phase=$(cat /Users/Shared/demo/phase 2>/dev/null) || phase=1
[ "${phase}" != rotate ] || phase=$((($(date +%s) / 6) % 3))
case "${phase}" in
0) percent=45 ;;
1) percent=76 ;;
*) percent=93 ;;
esac
start=$(cat /Users/Shared/demo/start)
total=1932735488
grown=$((($(date +%s) - start) * 700))
used=$((total / 100 * percent + grown))
avail=$((total - used))
row() {
  printf '%s %s %s %s %s%% %s\n' "$1" "${total}" "$2" "$3" "$4" "$5"
}
usage() {
  case "$1" in
  /System/Volumes/Data) row /dev/disk3s5 "$((total / 100 * 99))" "$((total / 100 * 1))" 99 "$1" ;;
  */data) row /dev/disk4s1 "$((total / 100 * 62))" "$((total / 100 * 38))" 62 "$1" ;;
  */backup) row /dev/disk5s1 "$((total / 100 * 31))" "$((total / 100 * 69))" 31 "$1" ;;
  *) row /dev/disk3s1s1 "${used}" "${avail}" "${percent}" "$1" ;;
  esac
}
case "$1" in
-Pk)
  shift
  printf 'Filesystem 1024-blocks Used Available Capacity Mounted on\n'
  for mount in "$@"; do
    usage "${mount}"
  done
  ;;
-i)
  printf 'Filesystem 512-blocks Used Available Capacity iused ifree %%iused Mounted on\n'
  printf '/dev/disk3s1s1 3865470976 3500000000 365470976 %s%% 426983 1627000000 12%% %s\n' "${percent}" "$2"
  ;;
-h)
  printf 'Filesystem Size Used Avail Capacity iused ifree %%iused Mounted on\n'
  printf '/dev/disk3s1s1 1.8Ti 829Gi 1.0Ti %s%% 426k 157M 12%% /\n' "${percent}"
  printf 'devfs 200Ki 200Ki 0Bi 100%% 692 0 100%% /dev\n'
  printf '/dev/disk3s5 1.8Ti 1.7Ti 24Gi 99%% 2.1M 157M 1%% /System/Volumes/Data\n'
  printf '/dev/disk4s1 931Gi 577Gi 354Gi 62%% 1k 4M 0%% /Volumes/Backup\n'
  ;;
*) exit 1 ;;
esac
DF

cat >"${demo}/bin/diskutil" <<'DISKUTIL'
#!/bin/sh
printf '   Volume Name:               Macintosh HD\n'
printf '   Container Free Space:      120.0 GB (120259084288 Bytes)\n'
printf '   Purgeable Space:           31.2 GB (33497229312 Bytes)\n'
DISKUTIL

cat >"${demo}/bin/osascript" <<'OSASCRIPT'
#!/bin/sh
printf '%s: %s\n' "$7" "$8" >>/Users/Shared/demo/notifications.log
OSASCRIPT

cat >"${demo}/bin/du" <<'DU'
#!/bin/sh
shift 2
for item in "$@"; do
  case "${item##*/}" in
  Library) size=25165824 ;;
  Movies) size=9437184 ;;
  Projects) size=4194304 ;;
  Downloads) size=2097152 ;;
  .cache) size=1048576 ;;
  *) size=524288 ;;
  esac
  printf '%s\t%s\n' "${size}" "${item}"
done
DU

chmod +x "${demo}/bin/df" "${demo}/bin/diskutil" "${demo}/bin/osascript" "${demo}/bin/du"
