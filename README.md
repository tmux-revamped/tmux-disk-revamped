<div align="center">

# tmux-disk-revamped

<strong>Disk usage for your tmux status bar, without ever blocking the status render.</strong>

English &nbsp;|&nbsp; [日本語](README.ja.md) &nbsp;|&nbsp; [简体中文](README.zh-Hans.md) &nbsp;|&nbsp; [繁體中文（香港）](README.zh-HK.md)

[![ci](https://img.shields.io/github/actions/workflow/status/tmux-revamped/tmux-disk-revamped/ci.yml?branch=main&style=flat-square&label=ci)](https://github.com/tmux-revamped/tmux-disk-revamped/actions/workflows/ci.yml)
[![release](https://img.shields.io/github/v/release/tmux-revamped/tmux-disk-revamped?style=flat-square&label=release)](https://github.com/tmux-revamped/tmux-disk-revamped/releases/latest)
[![openssf scorecard](https://img.shields.io/ossf-scorecard/github.com/tmux-revamped/tmux-disk-revamped?style=flat-square&label=openssf%20scorecard)](https://scorecard.dev/viewer/?uri=github.com/tmux-revamped/tmux-disk-revamped)
[![license](https://img.shields.io/github/license/tmux-revamped/tmux-disk-revamped?style=flat-square&label=license)](LICENSE)

<p align="center">
  <a href="#quick-start"><strong>Quick start</strong></a> &nbsp;|&nbsp;
  <a href="#usage">Usage</a> &nbsp;|&nbsp;
  <a href="#how-it-works">How it works</a> &nbsp;|&nbsp;
  <a href="#screens">Screens</a>
</p>

</div>

<p align="center">
  <img src="screens/hero.gif" alt="disk-revamped showing the usage coloured by tier with the sizes, opening the detail popup, switching to Nerd Font labels, the graph with the fill rate and the options render mode" width="800">
</p>

```console
$ disk-revamped refresh
Refreshed. 45% of / is used.
$ disk-revamped status percentage
45%
```

**16** placeholders, **2** render modes, **2** popups, macOS and Linux, tmux **3.2** or later.

---

<a id="quick-start"></a>

## Quick start

### Prerequisites

| Tool | Version | Used for |
|:-----|:--------|:---------|
| tmux | 3.2 or later | the family floor, and the popups |
| gum | optional | the menu, tables and colours of `disk-revamped`; without it every command prints plain text |
| `df`, `du`, `sort` | any | usage and the scan, built in on both platforms |
| `osascript` or `notify-send` | optional | the notification at the high threshold |

It runs on Linux and macOS with BSD, GNU, uutils or BusyBox tools. Each figure comes from something the OS ships:

| Value | Linux | macOS |
|:------|:------|:------|
| Usage, used, total, free, fill rate | `df -Pk` | `/bin/df -Pk` |
| Inodes | `df -i` | `/bin/df -i` |
| Every disk | `df -h` | `/bin/df -h` |
| Read and write rates | `/proc/diskstats`, whole devices from `/sys/block` | none |
| Purgeable space | none | `diskutil info` |

macOS reads `/bin/df`, so GNU coreutils first on `PATH` does not change it. A missing source leaves its placeholder empty, and `disk-revamped doctor` names it.

### Install

With [TPM](https://github.com/tmux-plugins/tpm), add the plugin to `~/.tmux.conf` and press `prefix + I`:

```tmux
set -g @plugin 'tmux-revamped/tmux-disk-revamped'
```

To install by hand, clone the repository and run the entrypoint from `~/.tmux.conf`:

```bash
git clone https://github.com/tmux-revamped/tmux-disk-revamped ~/.tmux/plugins/tmux-disk-revamped
```

```tmux
run-shell ~/.tmux/plugins/tmux-disk-revamped/disk-revamped.tmux
```

Set `status-left` or `status-right` before the plugin loads. The plugin replaces the placeholders it finds there once, at load time.

`make install` in the clone also puts `disk-revamped` in `~/.local/bin`, with its man page and completions under `~/.local/share`.

### Verify

```bash
~/.tmux/plugins/tmux-disk-revamped/bin/disk-revamped doctor
```

<a id="usage"></a>

## Usage

The plugin shows how full a disk is, with its used, free and total space, the inode usage, a graph of the recent readings, the fill rate and the time until full, and a list of every disk. The status line prints a value tmux already holds, and a background reading refreshes it.

| Placeholder | Output |
|:------------|:-------|
| `#{disk_percentage}` | used space, for example `55%` |
| `#{disk_icon}` | the icon of the current usage tier |
| `#{disk_fg_color}` | the foreground style of the usage tier |
| `#{disk_bg_color}` | the background style of the usage tier |
| `#{disk_used}` | used space in gigabytes, for example `55G`, and in terabytes such as `1.8T` from 1024G |
| `#{disk_total}` | total space, in the same form |
| `#{disk_free}` | free space, in the same form |
| `#{disk_read}` | read rate on Linux, for example `1.2MB/s`; empty on macOS |
| `#{disk_write}` | write rate on Linux, in the same form; empty on macOS |
| `#{disk_all}` | every mounted real disk, for example `/ 55%, /data 30%` |
| `#{disk_inodes}` | inode usage, for example `i12%` |
| `#{disk_purgeable}` | APFS purgeable space on macOS; empty on Linux |
| `#{disk_graph}` | recent usage readings, for example `▄▄▆▆█` |
| `#{disk_fill_rate}` | change in used space, for example `+2.1G/h`, empty when steady |
| `#{disk_full_eta}` | time until full at that rate, for example `3d`, empty when not filling |
| `#{disk_mounts}` | the mounts named in `@disk_revamped_mounts`, in the same form as `#{disk_all}` |

Put placeholders in the status line:

```tmux
set -g @disk_revamped_low_fg_color '#[fg=green]'
set -g @disk_revamped_medium_fg_color '#[fg=yellow]'
set -g @disk_revamped_high_fg_color '#[fg=red]'

set -g status-right '#{disk_fg_color}#{disk_icon} #{disk_percentage}#[default] #{disk_used}/#{disk_total} '
```

The same example, with a few more options, is in [examples/status-right.tmux.conf](examples/status-right.tmux.conf).

### Labels and widths

`@disk_revamped_<metric>_label` prints an icon or word before one metric, only when its value is not empty. `@disk_revamped_icons` set to `nerd` labels every metric below with a Nerd Font glyph. A metric's own label wins over the set, and a label set to nothing means the default, so the glyph stays. The default, `ascii`, adds no labels. The metrics are `percentage`, `used`, `total`, `free`, `read`, `write`, `inodes`, `purgeable`, `graph`, `fill_rate`, `full_eta`, `mounts` and `all`, written with dashes in a command option, such as `--fill-rate-label`.

| Metric | `nerd` glyph |
|:-------|:-------------|
| `percentage` | U+F02CA |
| `used` | U+F01BC |
| `total` | U+F01BC |
| `free` | U+F0770 |
| `read` | U+F01DA |
| `write` | U+F0552 |
| `inodes` | U+F0645 |
| `purgeable` | U+F00E2 |
| `graph` | U+F07B1 |
| `fill_rate` | U+F0535 |
| `full_eta` | U+F051F |
| `mounts` | U+F0253 |
| `all` | U+F0253 |

`@disk_revamped_fixed_width` set to `on` pads each figure on the left to its natural width, four characters for the usage and the inodes and nine for the read and write rates, so a change from `9%` to `42%` does not shift the rest of the line. `@disk_revamped_<metric>_width` sets one metric's width and wins over the fixed width. A longer value is never cut.

### Render mode

By default each placeholder becomes a `#()` call, which tmux reruns on status redraws. With `@disk_revamped_render` set to `options`, each placeholder becomes an option read such as `#{E:@disk_revamped_out_percentage}`. One background process per server then reads the disk every `@disk_revamped_interval` seconds and writes all values in one tmux call, so they change together.

```tmux
set -g @disk_revamped_render 'options'
set -g @disk_revamped_fixed_width 'on'
```

### Tier colors

The tier styles are empty by default, so `#{disk_fg_color}` and `#{disk_bg_color}` print nothing until you set them. These palettes map low to green, medium to yellow and high to red:

| Theme | Low | Medium | High |
|:------|:----|:-------|:-----|
| Catppuccin Mocha | `#a6e3a1` | `#f9e2af` | `#f38ba8` |
| Dracula | `#50fa7b` | `#f1fa8c` | `#ff5555` |
| Nord | `#a3be8c` | `#ebcb8b` | `#bf616a` |
| Gruvbox Dark | `#b8bb26` | `#fabd2f` | `#fb4934` |
| Tokyo Night | `#9ece6a` | `#e0af68` | `#f7768e` |
| Solarized Dark | `#859900` | `#b58900` | `#dc322f` |

Each value goes in a style, such as `set -g @disk_revamped_low_fg_color '#[fg=#a6e3a1]'`.

| Command | What it does |
|:--------|:-------------|
| `disk-revamped apply` | Binds the popup keys and fills the placeholders now; the entry point runs it when tmux loads the plugin |
| `disk-revamped list` | Prints every command `apply` would send and changes nothing; `--json` prints one object |
| `disk-revamped status NAME` | Prints one placeholder, such as `percentage`, `used` or `graph`; the status line runs it |
| `disk-revamped refresh` | Reads the disk now and says how full it is |
| `disk-revamped card` | Reads everything now and prints one row per figure, then every disk, cut to the terminal |
| `disk-revamped scan` | Lists the largest items under the scanned path with their sizes |
| `disk-revamped popup` | Opens the card in a tmux popup; the popup key runs it |
| `disk-revamped eat` | Opens the scan in a tmux popup; the eat key runs it |
| `disk-revamped daemon` | Publishes the placeholders on every tick, for the `options` render mode; `apply` starts it |
| `disk-revamped doctor` | One row per dependency: each tool or file a figure comes from, the terminal size, the notifier and any key left alone |
| `disk-revamped version` | The version, then the tmux version |
| `disk-revamped help` | The help page; `man disk-revamped` documents the same commands and settings |
| `disk-revamped` | On a terminal, a menu |

<a id="configuration"></a>

## Configuration

Every option is also a command option with dashes, such as `--interval 2`, and an environment variable, such as `DISK_REVAMPED_INTERVAL`; the command line wins over the environment, and the environment over the tmux option. An empty tmux option means its default, and an empty value on the command line or in the environment is used as given. `doctor` names any setting that holds a value the plugin does not know. One given to `apply` rides on the keys and on every status call.

### Reading

| Option | Default | Meaning |
|:-------|:--------|:--------|
| `@disk_revamped_mount` | `/` | The mount the usage placeholders report; on macOS `/` is the sealed system volume, so set `/System/Volumes/Data` to see the space your files use |
| `@disk_revamped_mounts` | empty | Mounts for `#{disk_mounts}`, space or comma separated; one that does not exist is left out |
| `@disk_revamped_interval` | `30` | Seconds a reading stays fresh |
| `@disk_revamped_detail_interval` | `60` | Seconds the list of every disk stays fresh |
| `@disk_revamped_render` | `jobs` | `options` reads published options instead of running `#()` calls; any other value means `jobs` |
| `@disk_revamped_history_length` | `20` | Readings kept for `#{disk_graph}` |
| `@disk_revamped_notify` | `0` | `1` sends a notification when the usage reaches `@disk_revamped_high_thresh`, and again after it has fallen below it |

### Tiers

| Option | Default | Meaning |
|:-------|:--------|:--------|
| `@disk_revamped_medium_thresh` | `70` | Usage percent at which the tier becomes medium |
| `@disk_revamped_high_thresh` | `90` | Usage percent at which the tier becomes high, and at which a notification is sent |
| `@disk_revamped_low_icon` | `▰▱▱` | Icon for the low tier |
| `@disk_revamped_medium_icon` | `▰▰▱` | Icon for the medium tier |
| `@disk_revamped_high_icon` | `▰▰▰` | Icon for the high tier |
| `@disk_revamped_low_fg_color` | empty | Foreground style for the low tier, such as `#[fg=green]` |
| `@disk_revamped_medium_fg_color` | empty | Foreground style for the medium tier |
| `@disk_revamped_high_fg_color` | empty | Foreground style for the high tier |
| `@disk_revamped_low_bg_color` | empty | Background style for the low tier |
| `@disk_revamped_medium_bg_color` | empty | Background style for the medium tier |
| `@disk_revamped_high_bg_color` | empty | Background style for the high tier |

### Formats and labels

| Option | Default | Meaning |
|:-------|:--------|:--------|
| `@disk_revamped_percentage_format` | `%s%%` | printf format for the usage |
| `@disk_revamped_size_format` | `%sG` | printf format for a size below 1024G; from 1024G a size is terabytes with one decimal |
| `@disk_revamped_inodes_format` | `i%s%%` | printf format for `#{disk_inodes}` |
| `@disk_revamped_separator` | `, ` | Text between disks in `#{disk_all}` and `#{disk_mounts}` |
| `@disk_revamped_icons` | `ascii` | `nerd` labels every value with a Nerd Font glyph |
| `@disk_revamped_<metric>_label` | empty | Text printed before one value, only when the value is not empty |
| `@disk_revamped_fixed_width` | `off` | `on` pads each figure to its natural width, so a change from `9%` to `42%` does not shift the rest of the line |
| `@disk_revamped_<metric>_width` | empty | Pad one value to this many characters. A longer value is never cut |

### Keys and the scan

| Option | Default | Meaning |
|:-------|:--------|:--------|
| `@disk_revamped_popup_key` | `M-d` | Prefix key that opens the detail popup. `off` binds nothing |
| `@disk_revamped_eat_key` | empty | Prefix key that opens the largest items popup; empty or `off` binds nothing |
| `@disk_revamped_eat_path` | the mount | Folder the scan lists |
| `@disk_revamped_eat_count` | `10` | How many of the largest items the scan lists |
| `@disk_revamped_eat_interval` | `60` | Seconds a scan result stays fresh |

### Internal state

The plugin writes these options itself. Do not set them.

| Option | Holds |
|:-------|:------|
| `@disk_revamped_published` | The metrics the status line uses, recorded at load so only those are read |
| `@disk_revamped_history` | The recent readings behind `#{disk_graph}` |
| `@disk_revamped_out_<metric>` | The rendered value of each metric in options mode |
| `@disk_revamped_ticker_pid` | The process id of the options-mode background process |
| `@disk_revamped_notified` | `1` after a notification fired, until the usage falls below the threshold |
| `@disk_revamped_percent` and the other figures, `_ts`, `_lock` | The stored reading, the time of each reading and the refresh lock; `@disk_revamped_mounts_list` holds the reading of the `@disk_revamped_mounts` setting |

## Key bindings

| Key | Action | Default |
|:----|:-------|:--------|
| `prefix + M-d` | Opens the card in a popup: the figures and every disk, cut to the popup. Enter closes it | Bound |
| unbound | Opens the largest items popup. Enter closes it | `@disk_revamped_eat_key` |

`@disk_revamped_popup_key` names another key, and `off` binds none. The default key is left alone when something else already holds it, and `disk-revamped doctor` says so. `@disk_revamped_eat_key` binds the largest items popup, which is opt-in.

```tmux
set -g @disk_revamped_eat_key 'M-u'
```

<a id="how-it-works"></a>

## How it works

[`disk-revamped.tmux`](disk-revamped.tmux) runs once when tmux loads the plugin. It records which metrics `status-left` and `status-right` use in `@disk_revamped_published`, then replaces each placeholder with a call to [`bin/disk-revamped`](bin/disk-revamped) or, in `options` mode, with an option read and starts the background process.

In the default mode, each `#()` call returns the stored reading at once. When the reading is older than its interval, the call starts a refresh in the background and takes a lock, so only one refresh runs at a time. One `df -Pk` gives the usage and the sizes, rounded up to a whole gigabyte; the inodes, the purgeable space, the per-disk rates, the fill rate and the list of disks cost more reads, so each runs only for a placeholder the status line uses. One `awk` turns the readings into every figure, and one tmux call stores them.

The read and write rates and the fill rate compare each reading with the one before it. Mount paths come from outside, so every `#` in one is doubled before it reaches the status line. The readers, the figures and the formatting live in [`lib/disk.sh`](lib/disk.sh), and the settings table in [`lib/state.sh`](lib/state.sh).

<a id="screens"></a>

## Screens

<details>
<summary>Every screen, recorded inside a real tmux with <code>make screens</code>, with each key on the status line</summary>
<br>

<table>
<tr>
<td width="50%" valign="top"><img src="screens/status.png" alt="disk-revamped: The usage with its tier icon and colour, the sizes and the free space"><br><sub>The usage with its tier icon and colour, the sizes and the free space, from <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/popup.png" alt="disk-revamped: prefix M-d opens the detail card in a popup"><br><sub><code>prefix M-d</code> opens the detail card in a popup, from <code>hero.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/icons.png" alt="disk-revamped: @disk_revamped_icons set to nerd labels every metric with a glyph"><br><sub><code>@disk_revamped_icons</code> set to <code>nerd</code> labels every metric with a glyph, from <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/graph.png" alt="disk-revamped: The graph, the usage, the fill rate and the time until full"><br><sub>The graph, the usage, the fill rate and the time until full, from <code>hero.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/options.png" alt="disk-revamped: In the options render mode each placeholder reads a tmux option"><br><sub>In the <code>options</code> render mode each placeholder reads a tmux option, from <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/card.png" alt="disk-revamped: card prints every figure and every disk"><br><sub><code>card</code> prints every figure and every disk, from <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/sizes.png" alt="disk-revamped: The used, free and total space, and the purgeable space on macOS"><br><sub>The used, free and total space, and the purgeable space on macOS, from <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/size-format.png" alt="disk-revamped: @disk_revamped_size_format shapes a size below 1024G"><br><sub><code>@disk_revamped_size_format</code> shapes a size below 1024G, from <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/colors.png" alt="disk-revamped: A tier icon and colours of your own"><br><sub>A tier icon and colours of your own, from <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/tiers.png" alt="disk-revamped: @disk_revamped_medium_thresh, @disk_revamped_high_thresh and the icons of the tiers"><br><sub><code>@disk_revamped_medium_thresh</code>, <code>@disk_revamped_high_thresh</code> and the icons of the tiers, from <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/format.png" alt="disk-revamped: @disk_revamped_percentage_format shapes the usage"><br><sub><code>@disk_revamped_percentage_format</code> shapes the usage, from <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/inodes-format.png" alt="disk-revamped: The inode usage and @disk_revamped_inodes_format"><br><sub>The inode usage and <code>@disk_revamped_inodes_format</code>, from <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/fixed.png" alt="disk-revamped: @disk_revamped_fixed_width pads each figure to its natural width"><br><sub><code>@disk_revamped_fixed_width</code> pads each figure to its natural width, from <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/width.png" alt="disk-revamped: @disk_revamped_inodes_width pads one metric to its own width"><br><sub><code>@disk_revamped_inodes_width</code> pads one metric to its own width, from <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/labels.png" alt="disk-revamped: A label of its own before one metric"><br><sub>A label of its own before one metric, from <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/mounts.png" alt="disk-revamped: @disk_revamped_mounts lists the mounts you name"><br><sub><code>@disk_revamped_mounts</code> lists the mounts you name, from <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/separator.png" alt="disk-revamped: @disk_revamped_separator sits between disks"><br><sub><code>@disk_revamped_separator</code> sits between disks, from <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/all.png" alt="disk-revamped: Every disk in one placeholder"><br><sub>Every disk in one placeholder, from <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/mount.png" alt="disk-revamped: @disk_revamped_mount picks the mount the usage reports"><br><sub><code>@disk_revamped_mount</code> picks the mount the usage reports, from <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/history.png" alt="disk-revamped: @disk_revamped_history_length sets how many readings the graph keeps"><br><sub><code>@disk_revamped_history_length</code> sets how many readings the graph keeps, from <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/fill.png" alt="disk-revamped: The fill rate and the time until full"><br><sub>The fill rate and the time until full, from <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/notify.png" alt="disk-revamped: @disk_revamped_notify sends a notification at the high threshold"><br><sub><code>@disk_revamped_notify</code> sends a notification at the high threshold, from <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/popup-key.png" alt="disk-revamped: @disk_revamped_popup_key names another key for the popup"><br><sub><code>@disk_revamped_popup_key</code> names another key for the popup, from <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/eat.png" alt="disk-revamped: @disk_revamped_eat_key opens the largest items popup, sized by @disk_revamped_eat_path, @disk_revamped_eat_count and @disk_revamped_eat_interval"><br><sub><code>@disk_revamped_eat_key</code> opens the largest items popup, sized by <code>@disk_revamped_eat_path</code>, <code>@disk_revamped_eat_count</code> and <code>@disk_revamped_eat_interval</code>, from <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/version.png" alt="disk-revamped: The version"><br><sub>The version, from <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/error.png" alt="disk-revamped: An unknown command"><br><sub>An unknown command, from <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/status-command.png" alt="disk-revamped: status percentage and status graph print one placeholder each"><br><sub><code>status percentage</code> and <code>status graph</code> print one placeholder each, from <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/refresh.png" alt="disk-revamped: refresh reads the disk now"><br><sub><code>refresh</code> reads the disk now, from <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/list.png" alt="disk-revamped: list prints every binding"><br><sub><code>list</code> prints every binding, from <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/json.png" alt="disk-revamped: list --json prints the same plan as one object"><br><sub><code>list --json</code> prints the same plan as one object, from <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/doctor.png" alt="disk-revamped: doctor"><br><sub><code>doctor</code>, from <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/menu.png" alt="disk-revamped: The menu"><br><sub>The menu, from <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/menu-card.png" alt="disk-revamped: The card from the menu"><br><sub>The card from the menu, from <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/scan.png" alt="disk-revamped: scan lists the largest items"><br><sub><code>scan</code> lists the largest items, from <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/accent.png" alt="disk-revamped: An accent from DISK_REVAMPED_ACCENT"><br><sub>An accent from <code>DISK_REVAMPED_ACCENT</code>, from <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/plain-menu.png" alt="disk-revamped: The menu without gum"><br><sub>The menu without gum, from <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/plain-card.png" alt="disk-revamped: card from the menu, without gum"><br><sub><code>card</code> from the menu, without gum, from <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/plain-doctor.png" alt="disk-revamped: doctor without gum"><br><sub><code>doctor</code> without gum, from <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/themes.png" alt="disk-revamped: The header in six themes"><br><sub>The header in six themes, from <code>themes.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/help.png" alt="disk-revamped: The help page"><br><sub>The help page, from <code>help.tape</code></sub></td>
</tr>
</table>

The recordings run the real plugin and tmux. Small scripts stand in for `df`, `diskutil`, `osascript` and `du`, so the figures on screen are theirs. The recordings run on macOS, which has no per-disk counters, so `#{disk_read}` and `#{disk_write}` show nothing there. `@disk_revamped_interval` and `@disk_revamped_detail_interval` are set in the recording's tmux config.

</details>

## Portability

The plugin is POSIX `sh`. CI runs every suite on each row below.

| Shell | Status |
|:------|:-------|
| `dash`, `/bin/sh` on macOS | Supported |
| `bash` 3.2 and 5.x, the system's `zsh` and Homebrew's | Supported |

| System | Status |
|:-------|:-------|
| macOS | Tahoe on Apple Silicon and Intel, with the tools it ships, Homebrew's GNU tools and Homebrew's uutils |
| Linux | Ubuntu 26.04 on x86_64 and arm64, with GNU coreutils, uutils and BusyBox |

## Development

| Command | What it runs |
|:--------|:-------------|
| `make fmt` | shfmt `-i 2` on every script |
| `make lint` | shfmt, ShellCheck, mandoc, yamllint and actionlint, at zero findings |
| `make test` | The bats suites under the system `sh` |
| `make test-all` | The suites under every installed shell, both builds of bash and zsh on macOS |
| `make test-linux` | The suites in an Ubuntu container |
| `make coverage` | bashcov on this Mac and in the Ubuntu container, merged and gated at 100 percent |
| `make screens` | The screens above, recorded from the real plugin inside tmux with VHS, on macOS |
| `make install` | The command, its man page and completions under `PREFIX` |

On macOS, `brew bundle` installs every tool these targets call, from the [`Brewfile`](Brewfile).

Commits follow the conventional commit format and go straight to `main`. After a green `ci` run on `main`, `release.yml` runs semantic-release: every `feat` or `fix` since the last tag publishes a release, stamps the version constant and adds the notes to [`CHANGELOG.md`](CHANGELOG.md).

## License

[MIT](LICENSE), copyright Gustavo Franco.

<!-- family:begin -->

## The tmux-revamped family

This plugin is one member of the tmux-revamped family. Every member carries the same contract in [`FAMILY.md`](FAMILY.md) and the same shared library, and they are built to be installed together: no member claims a key or a tmux option that another member claims.

A defect found in one member is hunted across all of them before the fix is called done.

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
| [`tmux-launcher-revamped`](https://github.com/tmux-revamped/tmux-launcher-revamped) | Open any terminal app in a tmux popup, window or split from one menu, starting at the project root |
| [`tmux-logging-revamped`](https://github.com/tmux-revamped/tmux-logging-revamped) | Capture any pane to a file: live logging, full scrollback, or a one-shot screenshot |
| [`tmux-music-revamped`](https://github.com/tmux-revamped/tmux-music-revamped) | Now playing in your tmux status bar, without ever blocking the status render |
| [`tmux-network-revamped`](https://github.com/tmux-revamped/tmux-network-revamped) | Network throughput in your tmux status bar, without ever blocking the render |
| [`tmux-pain-control-revamped`](https://github.com/tmux-revamped/tmux-pain-control-revamped) | Pane and window management bindings for tmux, version aware, vim friendly, every prefix key can be disabled |
| [`tmux-persist-revamped`](https://github.com/tmux-revamped/tmux-persist-revamped) | Save every tmux session, window and pane, auto-save on a timer, and restore it all after a reboot |
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | The starting point for a tmux-revamped plugin: shared library, bats harness and CI |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | A Pomodoro timer in the tmux status bar that keeps all of its state in tmux options, with no temp files |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | RAM, swap and memory pressure in the tmux status bar, sampled in the background so the render never waits |
| [`tmux-reorder-revamped`](https://github.com/tmux-revamped/tmux-reorder-revamped) | Drag a window tab along the tmux status bar with the mouse to move that window |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | Send the mouse wheel to apps that scroll themselves and into tmux copy-mode everywhere else |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | Sensible tmux defaults, gated by tmux version and terminal, that leave the options you set alone |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | Tiling window management for tmux: eight layouts including BSP dwindle and spiral, with layout undo |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | Local and world clocks for the tmux status bar, colored by time of day, with countdowns and a DST warning |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | Weather for the tmux status bar from wttr.in, fetched in the background so the status line never waits |

<!-- family:end -->
