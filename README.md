<div align="center">

<h1>tmux-disk-revamped</h1>

**Disk usage for your tmux status bar, without ever blocking the status render.**

[![Tests](https://github.com/tmux-revamped/tmux-disk-revamped/actions/workflows/tests.yml/badge.svg)](https://github.com/tmux-revamped/tmux-disk-revamped/actions/workflows/tests.yml) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE) [![Version](https://img.shields.io/badge/version-1.2.0-blue.svg)](CHANGELOG.md)

</div>

**16** placeholders · **2** platforms · **186** tests · **95%+** coverage

Disk usage for your tmux status bar, without ever blocking the status render. The value is read from a tmux server user-option and returns instantly, while a detached worker runs `df` in the background. No temp files are used.

Built from [tmux-plugin-template](https://github.com/tmux-revamped/tmux-plugin-template).

<table>
<tr>
<td><strong>Non-blocking</strong><br/>The render reads a cached user-option and returns instantly while a detached worker refreshes in the background.</td>
<td><strong>No temp files</strong><br/>Cached values and I/O counters live in tmux server options, so nothing touches the filesystem.</td>
</tr>
<tr>
<td><strong>Cross-platform</strong><br/>Works on macOS and Linux with built-in tools, no extra package required.</td>
<td><strong>Tested</strong><br/>186 tests with 95%+ coverage run on every push.</td>
</tr>
</table>

## Placeholders

| Placeholder | Output |
|-------------|--------|
| `#{disk_percentage}` | used space, for example `55%` |
| `#{disk_icon}` | a tier icon for the current usage |
| `#{disk_fg_color}` / `#{disk_bg_color}` | colors for the current tier |
| `#{disk_used}` | used space in gigabytes, for example `100G` |
| `#{disk_total}` | total space in gigabytes, for example `466G` |
| `#{disk_read}` | disk read rate, Linux only, for example `1.2MB/s` |
| `#{disk_write}` | disk write rate, Linux only |
| `#{disk_all}` | every mounted real disk, for example `/ 55%, /home 30%` |
| `#{disk_free}` | available space, for example `366G`, auto-scales to `T` |
| `#{disk_inodes}` | inode usage, for example `i12%` |
| `#{disk_purgeable}` | APFS purgeable space on macOS, empty elsewhere |
| `#{disk_graph}` | usage sparkline from recent readings |
| `#{disk_fill_rate}` | fill rate, for example `+2.1G/h`, empty when steady |
| `#{disk_full_eta}` | time until full, for example `3d`, empty when not filling |
| `#{disk_mounts}` | usage for the mounts pinned in `@disk_revamped_mounts` |

## Install

With [TPM](https://github.com/tmux-plugins/tpm):

```tmux
set -g @plugin 'tmux-revamped/tmux-disk-revamped'
set -g status-right '#{disk_icon} #{disk_percentage}'
```

Press `prefix + I` to install.

## Configuration

| Option | Default | Meaning |
|--------|---------|---------|
| `@disk_revamped_mount` | `/` | the mount point to report |
| `@disk_revamped_interval` | `30` | seconds a reading stays fresh |
| `@disk_revamped_percentage_format` | `%s%%` | format for the value |
| `@disk_revamped_size_format` | `%sG` | format for used and total sizes |
| `@disk_revamped_medium_thresh` | `70` | usage percent for the medium tier |
| `@disk_revamped_high_thresh` | `90` | usage percent for the high tier |
| `@disk_revamped_{low,medium,high}_icon` | `▰▱▱`, `▰▰▱`, `▰▰▰` | tier icons |
| `@disk_revamped_{low,medium,high}_{fg,bg}_color` | empty | tier colors |
| `@disk_revamped_separator` | `, ` | separator between disks in `#{disk_all}` |
| `@disk_revamped_mounts` | empty | space or comma list of mounts for `#{disk_mounts}` |
| `@disk_revamped_inodes_format` | `i%s%%` | format for `#{disk_inodes}` |
| `@disk_revamped_history_length` | `20` | readings kept for `#{disk_graph}` |
| `@disk_revamped_notify` | `0` | set to `1` to send a full-disk desktop notification |
| `@disk_revamped_popup_key` | empty | key bound to the detail popup |
| `@disk_revamped_eat_key` | empty | key bound to the what-is-eating-space popup |
| `@disk_revamped_eat_path` | the mount | directory the space scan starts from |
| `@disk_revamped_enable_logging` | `0` | set to `1` to log under `~/.tmux/disk-revamped-logs` |

## Theme color suggestions

The defaults leave the tier colors empty and rely on the 16 ANSI names remapped by the active tmux theme, so the plugin matches any theme out of the box. For exact hex values, copy one block below. The low tier maps to green, the medium tier to yellow, and the high tier to red.

### Catppuccin Mocha

```tmux
set -g @disk_revamped_low_fg_color '#[fg=#a6e3a1]'
set -g @disk_revamped_medium_fg_color '#[fg=#f9e2af]'
set -g @disk_revamped_high_fg_color '#[fg=#f38ba8]'
```

### Dracula

```tmux
set -g @disk_revamped_low_fg_color '#[fg=#50fa7b]'
set -g @disk_revamped_medium_fg_color '#[fg=#f1fa8c]'
set -g @disk_revamped_high_fg_color '#[fg=#ff5555]'
```

### Nord

```tmux
set -g @disk_revamped_low_fg_color '#[fg=#a3be8c]'
set -g @disk_revamped_medium_fg_color '#[fg=#ebcb8b]'
set -g @disk_revamped_high_fg_color '#[fg=#bf616a]'
```

### Gruvbox Dark

```tmux
set -g @disk_revamped_low_fg_color '#[fg=#b8bb26]'
set -g @disk_revamped_medium_fg_color '#[fg=#fabd2f]'
set -g @disk_revamped_high_fg_color '#[fg=#fb4934]'
```

### Tokyo Night

```tmux
set -g @disk_revamped_low_fg_color '#[fg=#9ece6a]'
set -g @disk_revamped_medium_fg_color '#[fg=#e0af68]'
set -g @disk_revamped_high_fg_color '#[fg=#f7768e]'
```

### Solarized Dark

```tmux
set -g @disk_revamped_low_fg_color '#[fg=#859900]'
set -g @disk_revamped_medium_fg_color '#[fg=#b58900]'
set -g @disk_revamped_high_fg_color '#[fg=#dc322f]'
```

## Popups, notifications, and doctor

Bind a key to the detail popup or the what-is-eating-space popup. Both need tmux
3.2 or newer for `display-popup`, and a binding is created only when you set the
key. The space scan runs `du` in a detached worker and caches the result, so the
popup opens instantly and never blocks tmux.

```tmux
set -g @disk_revamped_popup_key 'D'
set -g @disk_revamped_eat_key 'E'
```

Enable a one-shot desktop notification when usage crosses the high threshold. It
fires once and stays quiet until usage drops back below the threshold.

```tmux
set -g @disk_revamped_notify '1'
```

Run the doctor for a capability report:

```bash
~/.tmux/plugins/tmux-disk-revamped/src/disk.sh doctor
```

## Support by platform and architecture

Works on every supported platform and architecture with built-in tools, no extra
package required. macOS (Intel and Apple Silicon) uses `df -g`; Linux (x86_64 and
arm64) uses `df -BG`. Sizes are reported in gigabytes.

Disk read and write I/O rates come from `/proc/diskstats` deltas and are Linux
only. macOS does not expose cumulative per-disk read and write byte counters
without a blocking sampler, so the I/O placeholders stay empty there.

## Development

```bash
make test
make lint
make coverage
```

## License

[MIT](LICENSE), copyright Gustavo Franco.

<!-- family:begin -->

## The tmux-revamped family

This plugin is one member of the tmux-revamped family. Every member carries the
same contract in [`FAMILY.md`](FAMILY.md), the same tooling under `family/`, and
the same shared library, all held byte-identical by a checksum manifest. They are
built to be installed together: no member claims a key or a tmux option that
another member claims.

A defect found in one member is hunted across all of them before the fix is
called done. That obligation is written into the contract rather than left to
memory, and `family/bin/sweep` is how it is discharged.

| Member | What it does |
|---|---|
| [`tmux-autoreload-revamped`](https://github.com/tmux-revamped/tmux-autoreload-revamped) | Edit your tmux config, save, and watch it reload itself, no key, no command |
| [`tmux-battery-revamped`](https://github.com/tmux-revamped/tmux-battery-revamped) | Battery status for your tmux status bar, without ever blocking the status render |
| [`tmux-bluetooth-revamped`](https://github.com/tmux-revamped/tmux-bluetooth-revamped) | Every connected Bluetooth device and its battery in your tmux status bar, without blocking the render |
| [`tmux-cpu-revamped`](https://github.com/tmux-revamped/tmux-cpu-revamped) | CPU load, temperature, and frequency in your tmux status bar, without ever blocking the render |
| [`tmux-disk-revamped`](https://github.com/tmux-revamped/tmux-disk-revamped) | **this plugin**, Disk usage for your tmux status bar, without ever blocking the status render |
| [`tmux-extract-revamped`](https://github.com/tmux-revamped/tmux-extract-revamped) | Fuzzy-grab any URL, path, or word off the screen and paste it, pure shell, no Python |
| [`tmux-fzf-revamped`](https://github.com/tmux-revamped/tmux-fzf-revamped) | Jump to any session, window, or pane, or kill it, from one fzf popup |
| [`tmux-git-revamped`](https://github.com/tmux-revamped/tmux-git-revamped) | Git repository status in your tmux status bar, without ever blocking the render |
| [`tmux-gpu-revamped`](https://github.com/tmux-revamped/tmux-gpu-revamped) | GPU load, temperature, frequency, and memory for your tmux status bar |
| [`tmux-kube-revamped`](https://github.com/tmux-revamped/tmux-kube-revamped) | Current Kubernetes context and namespace in your tmux status bar, async, kubectl-free, never blocking |
| [`tmux-launcher-revamped`](https://github.com/tmux-revamped/tmux-launcher-revamped) | Launch any TUI app in a popup or a window, scoped to the current pane's directory, with one configurable bindi |
| [`tmux-logging-revamped`](https://github.com/tmux-revamped/tmux-logging-revamped) | Capture any pane to a file: live logging, full scrollback, or a one-shot screenshot |
| [`tmux-music-revamped`](https://github.com/tmux-revamped/tmux-music-revamped) | Now playing in your tmux status bar, without ever blocking the status render |
| [`tmux-network-revamped`](https://github.com/tmux-revamped/tmux-network-revamped) | Network throughput in your tmux status bar, without ever blocking the render |
| [`tmux-pain-control-revamped`](https://github.com/tmux-revamped/tmux-pain-control-revamped) | Standard pane and window management bindings for tmux, version aware, vim friendly, and fully configurable |
| [`tmux-persist-revamped`](https://github.com/tmux-revamped/tmux-persist-revamped) | One plugin that captures every session, window, pane, layout, and working |
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | A template for building non-blocking tmux status plugins |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | A Pomodoro timer in your tmux status bar, with zero temp files: all state lives in tmux options |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | RAM usage for your tmux status bar, without ever blocking the status render |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | Mouse wheel that does the right thing: scroll the app directly, copy-mode everywhere else. No app names to con |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | Sensible tmux defaults that normalize behavior across every tmux version, OS, and terminal, without clobbering |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | --- |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | Local clock and world clocks in your tmux status bar, without ever blocking the render |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | Weather in your tmux status bar, fetched in the background so the render never waits on the network |

### Checking an installation

With every member on disk, one command reports any conflict between them:

```sh
family/bin/doctor --live
```

It reads each member and the running tmux server, and reports duplicate keys,
duplicate status placeholders, options outside the naming grammar, and any
member whose contract version has fallen behind.

<!-- family:end -->
