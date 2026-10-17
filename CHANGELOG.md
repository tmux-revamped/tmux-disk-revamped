# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.0.0] - 2026-10-17

### Changed

- **Breaking:** the detail popup is now bound to `prefix + M-d` by default, the
  key the family allocation gives this plugin, where it used to stay unbound
  until `@disk_revamped_popup_key` was set. Set the option to `off` to keep it
  unbound. The what-is-eating-space popup stays opt-in behind
  `@disk_revamped_eat_key`.
- The options-mode background process reads every option it needs in one tmux
  call per tick, sends its cache writes and published values in a second, and
  keeps its functions out of the environment of the commands it runs. The all-
  disks listing refreshes every `@disk_revamped_detail_interval` seconds, 60
  by default, and options mode ticks every `@disk_revamped_interval` seconds,
  30 by default.

### Fixed

- A mount path holding `#`, from the all-disks listing or
  `@disk_revamped_mounts`, reached the status line as a tmux format, so
  `#(...)` in a path ran a command and `#[...]` restyled the bar. Every `#` in
  a mount path is now doubled before tmux sees it.
- The what-is-eating-space scan descended into other filesystems mounted below
  the scan path and ignored dot entries, so a network mount could stall it and
  `~/.cache` never showed. It now stays on one filesystem and includes dot
  entries.
- Every refresh ran `df -i`, `diskutil info`, a kilobyte `df` and one `df` per
  pinned mount even when the status line showed none of the inode, purgeable,
  fill or mounts values. Each of those probes now runs only when a metric that
  needs it is on the status line.
- The fill rate compared used space in whole gigabytes across one tick, so a
  disk either showed nothing or jumped to about `+120G/h` the moment the
  rounded figure moved by one. Used and available space for the fill rate and
  time-until-full are now read in kilobytes.
- On Linux the read and write rates summed every line of `/proc/diskstats`, so
  a write was counted once for the disk, again for its partition, and again
  for any device-mapper, loop or zram device above it. Only whole block
  devices listed in `/sys/block`, other than loop, ram, dm and zram devices,
  are counted now.
- In options mode, running the entry point a second time, as two overlapping
  config reloads do, found no placeholders left in the status line and
  published nothing, which froze every value. A metric whose option read is
  already on the status line now counts as used.
- A comma-decimal locale such as pt_BR printed rates as `2,0MB/s`. The
  formatters now run under the C locale.
- On macOS every value rendered empty when GNU coreutils came first on PATH,
  because the BSD-only `df -g` reached GNU `df`, which rejects it. The macOS
  readers now call `/bin/df`.

### Added

- `@disk_revamped_render 'options'` replaces the `#()` calls with tmux option
  reads, written by one background process per server every
  `@disk_revamped_interval` seconds, 30 by default. tmux reruns a `#()` call on every redraw, so a
  shared bar ran each one about once a second and painted values one by one.
- `@disk_revamped_fixed_width 'on'` pads each value to its widest form, and
  `@disk_revamped_<metric>_width` sets one metric's width, so a value changing
  length no longer shifts the rest of the status line.
- Metric labels. `@disk_revamped_<metric>_label` prints an icon or word before a value
  only when the value is not empty, and `@disk_revamped_icons` set to `nerd` labels
  every metric from a Nerd Font set. The default adds no labels.

## [1.2.0] - 2026-06-29

### Added

- Free-space placeholder `#{disk_free}` reporting available space, the figure
  most people look for.
- Auto-scaling size units: `#{disk_used}`, `#{disk_total}`, and `#{disk_free}`
  switch from gigabytes to terabytes once a value reaches 1024G.
- Inode usage placeholder `#{disk_inodes}` from `df -i`, so a disk that is "free
  but cannot write" is visible.
- Fill-rate and time-until-full placeholders `#{disk_fill_rate}` and
  `#{disk_full_eta}`, computed from the change in used space with the previous
  reading kept in a tmux option.
- Usage sparkline `#{disk_graph}` backed by a bounded ring buffer in a tmux
  option, never a temp file.
- Pinned-mount placeholder `#{disk_mounts}` listing usage for the mounts named in
  `@disk_revamped_mounts`.
- APFS purgeable-space placeholder `#{disk_purgeable}` on macOS via `diskutil`,
  empty on other platforms.
- Full-disk desktop notification, off by default, enabled with
  `@disk_revamped_notify`, fired once per threshold crossing through a single
  notifier seam.
- Detail popup and a what-is-eating-space popup. The space scan runs `du` in a
  detached worker and caches the result; both popups are gated on tmux 3.2 and
  bound only when `@disk_revamped_popup_key` or `@disk_revamped_eat_key` is set.
- A `doctor` subcommand that reports the detected platform, usage source, and
  available tools, and explains why a value is empty on this host.

## [1.1.1] - 2026-06-23

### Changed

- Self-audit for the family hardening pass. Usage, per-disk listing, and the I/O
  read and write rates are covered on both macOS and Linux, and the default
  segment colors are named colors that survive the tmux 3.7 format-expansion
  change. No code change needed.

## [1.1.0] - 2026-06-20

### Added

- Disk read and write I/O rate placeholders `#{disk_read}` and `#{disk_write}`
  from /proc/diskstats deltas on Linux, with previous counters kept in tmux
  options so no temp file is needed.
- Multi-disk placeholder `#{disk_all}` listing every mounted real disk, joined by
  a configurable separator.

## [1.0.0] - 2026-06-19

### Added

- Disk usage placeholders: `#{disk_percentage}`, `#{disk_icon}`,
  `#{disk_fg_color}`, `#{disk_bg_color}`, `#{disk_used}`, `#{disk_total}`.
- Non-blocking design: `df` runs in a background worker and the values are read
  from tmux user-options, with no temp files.
- Configurable mount point, thresholds, icons, colors, and formats.
- macOS via `df -g`, Linux via `df -BG`.
