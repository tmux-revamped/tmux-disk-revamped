# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
