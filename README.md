<div align="center">

# tmux-disk-revamped

<strong>Disk usage for your tmux status bar, without ever blocking the status render.</strong>

English | [日本語](README.ja.md) | [简体中文](README.zh-Hans.md) | [繁體中文（香港）](README.zh-HK.md)

[![Tests](https://github.com/tmux-revamped/tmux-disk-revamped/actions/workflows/tests.yml/badge.svg)](https://github.com/tmux-revamped/tmux-disk-revamped/actions/workflows/tests.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)](CHANGELOG.md)

<p align="center">
  <a href="#what-it-does">What it does</a> |
  <a href="#requirements">Requirements</a> |
  <a href="#installation">Installation</a> |
  <a href="#usage">Usage</a> |
  <a href="#configuration">Configuration</a> |
  <a href="#key-bindings">Key bindings</a> |
  <a href="#how-it-works">How it works</a>
</p>

</div>

**16** placeholders. **2** render modes. **2** popups. CI runs the suite on **10** Linux and macOS toolchain combinations.

---

## What it does

The plugin replaces `#{disk_*}` placeholders in `status-left` and `status-right` with usage, free space, inode usage, read and write rates, fill rate, time until full and a usage history for one mount, plus a list of every real disk. Every placeholder reads a value cached in a tmux option. `df` runs in the background, so the status line never waits for it. Nothing is written to disk.

It also opens a detail popup on `prefix + M-d`, an optional popup that lists the largest items on the disk, and an optional notification when the disk crosses the high threshold.

## Requirements

| Tool | Version | Needed for |
|:-----|:--------|:-----------|
| tmux | 3.2 or later | `display-popup` for both popups |
| bash | 3.2 or later | every script, including macOS `/bin/bash` |
| `df`, `du` | any | usage and the space scan, built in on both platforms |
| `osascript` or `notify-send` | any | optional, the full-disk notification |

| Value | Linux, x86_64 and arm64 | macOS, Intel and Apple Silicon |
|:------|:------------------------|:-------------------------------|
| Usage, used, total, free | `df -BG` | `/bin/df -g` |
| Fill rate and time until full | `df -Pk` | `/bin/df -Pk` |
| Inodes | `df -i` | `df -i` |
| Read and write rates | `/proc/diskstats`, whole devices from `/sys/block` | none |
| Purgeable space | none | `diskutil info` |

The macOS readers call `/bin/df`, so GNU coreutils first on `PATH` does not break them. A value the host has no source for renders empty. Run `src/disk.sh doctor` to see what this host provides.

## Installation

### With TPM

Add the plugin and a placeholder to `~/.tmux.conf`, then press `prefix + I`:

```tmux
set -g @plugin 'tmux-revamped/tmux-disk-revamped'
set -g status-right '#{disk_icon} #{disk_percentage}'
```

### Manual

```bash
git clone https://github.com/tmux-revamped/tmux-disk-revamped ~/.tmux/plugins/tmux-disk-revamped
```

Then add this line to `~/.tmux.conf`, after the lines that set `status-left` and `status-right`, and reload tmux:

```tmux
run-shell ~/.tmux/plugins/tmux-disk-revamped/disk-revamped.tmux
```

## Usage

Put placeholders in `status-left` or `status-right`. The plugin replaces them when it loads. [`examples/status-right.tmux.conf`](examples/status-right.tmux.conf) has a complete example.

```tmux
set -g status-right '#{disk_fg_color}#{disk_icon} #{disk_percentage}#[default] #{disk_used}/#{disk_total} '
```

| Placeholder | Output |
|:------------|:-------|
| `#{disk_percentage}` | used space, for example `55%` |
| `#{disk_icon}` | the icon of the current usage tier |
| `#{disk_fg_color}`, `#{disk_bg_color}` | the colors of the current usage tier |
| `#{disk_used}`, `#{disk_total}`, `#{disk_free}` | sizes in gigabytes, for example `100G`, switching to terabytes such as `1.8T` from 1024G |
| `#{disk_inodes}` | inode usage, for example `i12%` |
| `#{disk_purgeable}` | APFS purgeable space on macOS |
| `#{disk_read}`, `#{disk_write}` | read and write rates on Linux, for example `1.2MB/s` |
| `#{disk_fill_rate}` | change in used space, for example `+2.1G/h`, empty when steady |
| `#{disk_full_eta}` | time until full at that rate, for example `3d`, empty when not filling |
| `#{disk_graph}` | recent usage readings, for example `▄▄▆▆█` |
| `#{disk_all}` | every mounted real disk, for example `/ 55%, /home 30%` |
| `#{disk_mounts}` | the mounts named in `@disk_revamped_mounts`, in the same form |

`#{disk_all}` lists `/dev/` filesystems, leaving out `/Volumes/` on macOS and `/boot` and `/snap` on Linux.

## Configuration

| Option | Default | Meaning |
|:-------|:--------|:--------|
| `@disk_revamped_mount` | `/` | the mount the usage placeholders report; on macOS `/` is the sealed system volume, so set `/System/Volumes/Data` to see the space your files use |
| `@disk_revamped_interval` | `30` | seconds a usage reading stays fresh |
| `@disk_revamped_detail_interval` | `60` | seconds the `#{disk_all}` listing stays fresh |
| `@disk_revamped_render` | empty | `options` turns on options render mode, see [How it works](#how-it-works) |
| `@disk_revamped_percentage_format` | `%s%%` | printf format for the usage |
| `@disk_revamped_size_format` | `%sG` | printf format for sizes below 1024G |
| `@disk_revamped_medium_thresh`, `@disk_revamped_high_thresh` | `70`, `90` | usage percent where the medium and high tiers start |
| `@disk_revamped_low_icon` | `▰▱▱` | icon for the low tier |
| `@disk_revamped_medium_icon` | `▰▰▱` | icon for the medium tier |
| `@disk_revamped_high_icon` | `▰▰▰` | icon for the high tier |
| `@disk_revamped_{low,medium,high}_{fg,bg}_color` | empty | colors per tier |
| `@disk_revamped_separator` | `, ` | text between disks in `#{disk_all}` and `#{disk_mounts}` |
| `@disk_revamped_mounts` | empty | mounts for `#{disk_mounts}`, space or comma separated |
| `@disk_revamped_inodes_format` | `i%s%%` | printf format for `#{disk_inodes}` |
| `@disk_revamped_history_length` | `20` | readings kept for `#{disk_graph}` |
| `@disk_revamped_icons` | `ascii` | `nerd` labels every metric with a Nerd Font glyph |
| `@disk_revamped_<metric>_label` | empty | text printed before one metric's value when the value is not empty; `''` removes the `nerd` label |
| `@disk_revamped_fixed_width` | `off` | `on` pads each value on the left to its widest form |
| `@disk_revamped_<metric>_width` | empty | pad width for one metric, which wins over the fixed width |
| `@disk_revamped_notify` | `0` | `1` sends a notification when usage reaches `@disk_revamped_high_thresh` |
| `@disk_revamped_popup_key` | `M-d` | prefix key for the detail popup; `off` binds nothing |
| `@disk_revamped_eat_key` | empty | prefix key for the largest-items popup; empty binds nothing |
| `@disk_revamped_eat_path` | the mount | directory the space scan lists |
| `@disk_revamped_eat_count` | `10` | how many of the largest items the scan lists |
| `@disk_revamped_eat_interval` | `60` | seconds a scan result stays fresh |

Labels apply to every placeholder except the icon and the two colors. A longer value is never cut by a width.

### Theme colors

The color options are empty by default, so the plugin adds no color until you set one. Each block below colors the low, medium and high tiers green, yellow and red:

<details>
<summary>Catppuccin Mocha</summary>

```tmux
set -g @disk_revamped_low_fg_color '#[fg=#a6e3a1]'
set -g @disk_revamped_medium_fg_color '#[fg=#f9e2af]'
set -g @disk_revamped_high_fg_color '#[fg=#f38ba8]'
```

</details>

<details>
<summary>Dracula</summary>

```tmux
set -g @disk_revamped_low_fg_color '#[fg=#50fa7b]'
set -g @disk_revamped_medium_fg_color '#[fg=#f1fa8c]'
set -g @disk_revamped_high_fg_color '#[fg=#ff5555]'
```

</details>

<details>
<summary>Nord</summary>

```tmux
set -g @disk_revamped_low_fg_color '#[fg=#a3be8c]'
set -g @disk_revamped_medium_fg_color '#[fg=#ebcb8b]'
set -g @disk_revamped_high_fg_color '#[fg=#bf616a]'
```

</details>

<details>
<summary>Gruvbox Dark</summary>

```tmux
set -g @disk_revamped_low_fg_color '#[fg=#b8bb26]'
set -g @disk_revamped_medium_fg_color '#[fg=#fabd2f]'
set -g @disk_revamped_high_fg_color '#[fg=#fb4934]'
```

</details>

<details>
<summary>Tokyo Night</summary>

```tmux
set -g @disk_revamped_low_fg_color '#[fg=#9ece6a]'
set -g @disk_revamped_medium_fg_color '#[fg=#e0af68]'
set -g @disk_revamped_high_fg_color '#[fg=#f7768e]'
```

</details>

<details>
<summary>Solarized Dark</summary>

```tmux
set -g @disk_revamped_low_fg_color '#[fg=#859900]'
set -g @disk_revamped_medium_fg_color '#[fg=#b58900]'
set -g @disk_revamped_high_fg_color '#[fg=#dc322f]'
```

</details>

### Internal state

The plugin writes these options itself. Do not set them.

| Option | Holds |
|:-------|:------|
| `@disk_revamped_published` | the metrics found in `status-left` and `status-right` at load; the inode, purgeable, fill and mounts probes run only when one of their metrics is listed |
| `@disk_revamped_out_<metric>` | the published value of each metric in options mode |
| `@disk_revamped_ticker_pid` | pid of the options-mode background process |
| `@disk_revamped_option_names` | the options the background process reads in one call per tick |
| `@disk_revamped_notified` | `1` after a notification fired, until usage drops below the threshold |
| `@disk_revamped_history` | recent usage readings for `#{disk_graph}` |
| `@disk_revamped_{percent,used,total,free,all,read,write,inodes,purgeable,mounts,fill_rate,full_eta,eat}` | cached readings, each with a `_ts` timestamp |
| `@disk_revamped_{rd_raw,wr_raw,io_ts,used_raw,fill_ts}` | the previous counters the rates are measured from |

## Key bindings

| Key | Action | Option |
|:----|:-------|:-------|
| `prefix + M-d` | open the detail popup | `@disk_revamped_popup_key` |
| unbound | open the largest-items popup | `@disk_revamped_eat_key` |

The detail popup shows the mount, its usage, used, free and total space, and the `#{disk_all}` listing. The largest-items popup runs `du` in the background, staying on one filesystem and including dot entries. The first open shows `Scanning` until the result is cached. Enter closes either popup.

```tmux
set -g @disk_revamped_eat_key 'M-u'
```

## How it works

In the default jobs mode, each placeholder becomes a `#()` call to [`src/disk.sh`](src/disk.sh). The call prints the cached value at once. When the cached usage is older than `@disk_revamped_interval`, it also starts one background refresh, guarded by a lock so parallel calls do not start a second one.

tmux runs every `#()` call on every status redraw. With several plugins on one bar that can be about once a second. Options mode removes those calls:

```tmux
set -g @disk_revamped_render 'options'
set -g @disk_revamped_fixed_width 'on'
```

Each placeholder then becomes an option read such as `#{E:@disk_revamped_out_percentage}`. One background process per server reads the disk every `@disk_revamped_interval` seconds and writes every value the status line uses in a single tmux call, followed by one redraw. The process exits when the server stops or a config reload starts its replacement.

The read and write rates and the fill rate compare each reading with the one before it. Mount paths have every `#` doubled before they are cached, so a path cannot inject a tmux format.

## Development

| Command | What it runs |
|:--------|:-------------|
| `make test` | the bats suite under [`test/`](test) |
| `make lint` | shellcheck on every shell file |
| `make coverage` | kcov line coverage on Linux, failing below 95% |

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
| [`tmux-extract-revamped`](https://github.com/tmux-revamped/tmux-extract-revamped) | Pick a URL, path, hash or any other token off the screen with fzf and type it at the cursor, in pure shell |
| [`tmux-fzf-revamped`](https://github.com/tmux-revamped/tmux-fzf-revamped) | Switch to, kill, rename or create tmux sessions, windows and panes from fzf pickers in a popup |
| [`tmux-git-revamped`](https://github.com/tmux-revamped/tmux-git-revamped) | Show the active pane's git branch, changes and provider counts in the tmux status bar without blocking it |
| [`tmux-gpu-revamped`](https://github.com/tmux-revamped/tmux-gpu-revamped) | GPU load, temperature, clock, power and memory in the tmux status bar, from NVIDIA, AMD, Intel and Apple GPUs |
| [`tmux-kube-revamped`](https://github.com/tmux-revamped/tmux-kube-revamped) | Current Kubernetes context and namespace in the tmux status bar, parsed from kubeconfig without kubectl |
| [`tmux-launcher-revamped`](https://github.com/tmux-revamped/tmux-launcher-revamped) | Launch any TUI app in a popup or a window, scoped to the current pane's directory, with one configurable bindi |
| [`tmux-logging-revamped`](https://github.com/tmux-revamped/tmux-logging-revamped) | Capture any pane to a file: live logging, full scrollback, or a one-shot screenshot |
| [`tmux-music-revamped`](https://github.com/tmux-revamped/tmux-music-revamped) | Now playing in your tmux status bar, without ever blocking the status render |
| [`tmux-network-revamped`](https://github.com/tmux-revamped/tmux-network-revamped) | Network throughput in your tmux status bar, without ever blocking the render |
| [`tmux-pain-control-revamped`](https://github.com/tmux-revamped/tmux-pain-control-revamped) | Pane and window management bindings for tmux, version aware, vim friendly, every prefix key can be disabled |
| [`tmux-persist-revamped`](https://github.com/tmux-revamped/tmux-persist-revamped) | Save every tmux session, window and pane, auto-save on a timer, and restore it all after a reboot |
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | The starting point for a tmux-revamped plugin: shared library, bats harness, CI and family tooling |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | A Pomodoro timer in the tmux status bar that keeps all of its state in tmux options, with no temp files |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | RAM, swap and memory pressure in the tmux status bar, sampled in the background so the render never waits |
| [`tmux-reorder-revamped`](https://github.com/tmux-revamped/tmux-reorder-revamped) | Drag a window tab along the tmux status bar with the mouse to move that window |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | Send the mouse wheel to apps that scroll themselves and into tmux copy-mode everywhere else |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | Sensible tmux defaults, gated by tmux version and terminal, that leave the options you set alone |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | Tiling window management for tmux: eight layouts including BSP dwindle and spiral, with layout undo |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | Local and world clocks for the tmux status bar, colored by time of day, with countdowns and a DST warning |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | Weather for the tmux status bar from wttr.in, fetched in the background so the status line never waits |

### Checking an installation

With every member on disk, one command reports any conflict between them:

```sh
family/bin/doctor --live
```

It reads each member and the running tmux server, and reports duplicate keys,
duplicate status placeholders, options outside the naming grammar, and any
member whose contract version has fallen behind.

<!-- family:end -->
