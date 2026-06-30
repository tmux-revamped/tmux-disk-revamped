# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
