# tmux-disk-revamped

Guidance for anyone, human or agent, changing tmux-disk-revamped. What it is and how to use it lives in [README.md](README.md).

[FAMILY.md](FAMILY.md) holds everything this plugin shares with the rest of the tmux-revamped family, and it is the same in every member. This file holds only what is exclusive to tmux-disk-revamped, under the same headings as the agent guide of every member. Read both before changing anything; a rule that would serve the other members goes into [`FAMILY.md`](FAMILY.md) instead of here.

## Layout

| Path | Holds |
|:-----|:------|
| [`disk-revamped.tmux`](disk-revamped.tmux) | The entry point TPM runs: it runs `bin/disk-revamped apply` |
| [`bin/disk-revamped`](bin/disk-revamped) | The command: `apply`, `list`, `status`, `refresh`, `card`, `scan`, `popup`, `eat`, `daemon`, `doctor`, `version`, `help` and the menu. `apply`, `status`, `popup`, `eat` and `daemon` run without loading the interface modules |
| [`lib/disk.sh`](lib/disk.sh) | Reading the settings and the stored reading, the readers for both systems, the figures, the placeholders with their labels and widths, the publisher's tick, the scan, the popups and the binding |
| [`lib/state.sh`](lib/state.sh) | Every global, including `DISK_REVAMPED_SETTINGS`, the table of setting names and defaults, `DISK_REVAMPED_LIVE`, the names of the options that hold the reading, and `DISK_REVAMPED_KINDS` |
| [`lib/core.sh`](lib/core.sh) | The version |
| [`lib/`](lib) | Every other file is the shared library, identical in every member |
| [`test/readers.bats`](test/readers.bats), [`test/disk.bats`](test/disk.bats), [`test/plan.bats`](test/plan.bats), [`test/commands.bats`](test/commands.bats) | The readers on both systems, every placeholder with its labels and widths, the binding with both render modes, the daemon and the popups, and every command, against a stand-in tmux from [`test/disk_helpers.bash`](test/disk_helpers.bash) that keeps options in a file, with stand-ins for `df`, `diskutil`, `du`, `stty` and `notify-send`, a `cat` that serves `/proc/diskstats`, and a `date` that follows a clock the test sets |
| [`test/entrypoint.bats`](test/entrypoint.bats), [`test/keys.bats`](test/keys.bats) | The plugin on a private tmux server, with each key pressed through a second tmux attached to it, in both render modes; both share [`test/server_helpers.bash`](test/server_helpers.bash), whose stand-ins give the same figures on macOS and Linux |
| [`screens/`](screens) | The tapes and the recording's tmux config. `prepare.sh` copies the plugin to a neutral folder and writes stand-ins for `df`, `diskutil`, `osascript` and `du` |
| [`examples/`](examples) | A status line to copy |

## Names

- Settings are the tmux options `@disk_revamped_<setting>` listed in `DISK_REVAMPED_SETTINGS`, the long options with dashes, such as `--fill-rate-label`, and the environment variables `DISK_REVAMPED_<SETTING>`.
- The stored reading is `@disk_revamped_percent`, `_used`, `_total`, `_free`, `_read`, `_write`, `_inodes`, `_purgeable`, `_mounts_list`, `_all`, `_fill_rate`, `_full_eta`, `_history` and `_eat`, with `_percent_ts`, `_all_ts`, `_eat_ts`, `_percent_lock`, `_percent_lock_ts`, the counters `_rd_raw`, `_wr_raw`, `_io_ts`, `_used_raw` and `_fill_ts`, and `_notified`. `@disk_revamped_mounts` is the setting that names the mounts and `@disk_revamped_mounts_list` holds their reading; the reading never overwrites the setting. `apply` writes `@disk_revamped_published`, the daemon `@disk_revamped_out_<name>` and `@disk_revamped_ticker_pid`. None of them is a setting.
- The placeholders are `#{disk_percentage}`, `#{disk_icon}`, `#{disk_fg_color}`, `#{disk_bg_color}`, `#{disk_used}`, `#{disk_total}`, `#{disk_free}`, `#{disk_read}`, `#{disk_write}`, `#{disk_all}`, `#{disk_inodes}`, `#{disk_purgeable}`, `#{disk_graph}`, `#{disk_fill_rate}`, `#{disk_full_eta}` and `#{disk_mounts}`; `status` names each one without the `disk_`.
- The version constant is `DISK_REVAMPED_VERSION`.
- The command's own functions and the library's never share a name, because the command is sourced after the library and would replace it.
- `REVAMPED_TEST_DF` and `REVAMPED_TEST_SYS` are test switches: they replace the `/bin/df` that macOS reads through and the `/sys` folder, and they survive the entry point's clearing of inherited variables.

## Behaviour

- `apply` reads every setting and the stored reading with one `tmux display-message` call and one `env` read, reads the prefix table once, and sends the bindings and the replaced status strings in one tmux call. When that call fails, it sends each command alone and `apply` exits 1.
- In `jobs` mode each placeholder in `status-left` or `status-right` becomes `#(<tool> status <name>)`, with the tool's path and every carried value quoted for a shell and every `#` and `%` doubled, since tmux reads the status line as a format and as a time format. In `options` mode it becomes `#{E:@disk_revamped_out_<name>}`, `apply` starts the daemon, and a status refresh starts no process. A render mode other than `options` means `jobs`. A string already rewritten is not written again, and the names it uses stay in `@disk_revamped_published`, so loading twice changes nothing.
- `status` makes one tmux read and one `date` call, and prints the stored reading at once. Only when the reading is older than `@disk_revamped_interval` and no reading is under way does it start one in the background through the shared cache module. A name that is not a placeholder prints nothing and succeeds.
- A reading runs `df -Pk` for the mount every time, and the rest only when due: the inodes, the purgeable space, the per-disk rates, the fill rate and the mounts list for a placeholder in `@disk_revamped_published`, or the one `status` was asked for, uses them; the list of every disk when a placeholder uses it and `@disk_revamped_detail_interval` has passed. `card` reads them all. One `awk` turns the readings into every figure, and everything is written in one tmux call.
- The daemon is the shared ticker: it claims `@disk_revamped_ticker_pid`, reads and publishes every name in `@disk_revamped_published` in one tmux call per tick, sleeps for the interval, and ends when another process holds the claim or the server is gone. At the ticker's tick cap it starts itself again.
- `M-d` opens the card in a popup of 80 percent by 80 percent; `card` measures the terminal it runs in, lists as many disks as its rows hold, each cut at its width, and counts the rest, so its head never scrolls away. `@disk_revamped_eat_key`, unbound by default, opens the scan the same way. Enter closes either popup. A tmux older than 3.2 gets a message that says so.
- A key set to `off` binds nothing. Only the default key is skipped when someone else holds it, and `doctor` names it; a key the person names is bound whoever holds it.
- A setting `apply` got from the command line or the environment rides, as an option, on the keys and on every status call; `DISK_REVAMPED_CARRIED` lists the ones that ride. The daemon inherits the environment of the `apply` that started it.
- With `@disk_revamped_notify` at `1`, a reading that reaches `@disk_revamped_high_thresh` sends one notification through the shared notifier, and a reading below it rearms it; a threshold that is not a number sends nothing.

## Domain rules

- The macOS readers call `/bin/df`, so GNU coreutils first on `PATH` does not break them. Linux and macOS both read `df -Pk`, and a size is the used, available or total kilobytes rounded up to a whole gigabyte, as GNU `df -BG` rounds. From 1024G a size prints as terabytes with one decimal, whatever `@disk_revamped_size_format` says.
- On macOS `/` is the sealed system volume, so `@disk_revamped_mount` set to `/System/Volumes/Data` shows the space the person's files use.
- The usage is the first `NN%` field from the fifth field on, with the three fields before it as total, used and available, so a device name that holds spaces still parses. The inode usage is the last `NN%` of the first row of `df -i` that has one: a Linux row has one, a macOS row has the block usage and the inode usage.
- The read and write rates are Linux only: `/proc/diskstats` summed over the devices in `/sys/block`, leaving out `loop`, `ram`, `dm-` and `zram`, in kilobytes, each reading compared with the one before it. A counter that went backwards is a rate of zero, and a reading in the same second as the one before keeps the rates it had. The rate prints in `KB/s`, or in `MB/s` with one decimal from 1024.
- The fill rate is the change in used kilobytes since the previous reading, in gigabytes per hour with one decimal, signed; a rate of zero prints nothing. The time until full is the available space over the rate as printed, in whole hours, and only while the disk is filling. The first reading has neither, and a reading in the same second as the one before keeps the rate and the time until full it had.
- The list of every disk keeps the rows of `df -h` whose filesystem starts with `/dev/`, leaving out `/Volumes/` on macOS and `/boot` and `/snap` on Linux, as `mount usage`; a mount name that holds spaces is cut at its first space.
- `@disk_revamped_mounts` lists its mounts that exist, space or comma separated, in one `df -Pk` call, and labels each row with the name given.
- A mount path has every `#` doubled when a placeholder prints it, and the separator is printed as given.
- A label is printed only before a value. In the `nerd` set each labelled metric gets its glyph unless its own label is set; an empty tmux option means its default, so a label set to nothing keeps the glyph. The colour and icon placeholders are never labelled or padded.
- A value is padded on the left to its own `_width`, else, with `@disk_revamped_fixed_width` at `on`, to its natural width: 4 for the usage and the inodes, 9 for the read and write rates. Width counts characters, and a longer value is never cut.
- The history keeps the newest `@disk_revamped_history_length` readings; zero or junk there means 20. The graph draws one of five bars per reading at the reading times four over 100.
- The scan lists the entries of the scanned folder with `du -xsk`, dot entries included, biggest first, by their names with the size rounded to one decimal under ten, and stays fresh for `@disk_revamped_eat_interval` seconds. The scanned folder is `@disk_revamped_eat_path`, else the mount.
- An argument that ends in `;` is sent as `\;`: tmux reads a bare trailing semicolon in an argument as a command separator. The command list keeps an empty argument as the marker in `DISK_REVAMPED_EMPTY`; only an empty line ends a command.

## Release

- `DISK_REVAMPED_VERSION` in [`lib/core.sh`](lib/core.sh) holds the version. Nobody edits it by hand.
- After a green `ci` run on `main`, [`release.yml`](.github/workflows/release.yml) runs semantic-release: a `feat` or `fix` since the last tag publishes a release, [`set-version.sh`](.github/scripts/set-version.sh) stamps the constant, and the notes go into [`CHANGELOG.md`](CHANGELOG.md).

## Gaps against FAMILY.md

As of 2026-11-19:

- `#{disk_read}` and `#{disk_write}` work on Linux only, from `/proc/diskstats`: macOS has no per-disk read and write counters. No screen records them, because the screens are recorded on macOS.
- `#{disk_purgeable}` works on macOS only, from `diskutil info`, and a macOS whose `diskutil info` prints no purgeable line gives an empty value. No Linux source exists.
- The popups end in `read -r`, which a `default-shell` such as fish does not take.
