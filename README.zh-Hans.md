<div align="center">

# tmux-disk-revamped

<strong>在 tmux 状态栏显示磁盘用量，绝不阻塞状态栏渲染。</strong>

[English](README.md) &nbsp;|&nbsp; [日本語](README.ja.md) &nbsp;|&nbsp; 简体中文 &nbsp;|&nbsp; [繁體中文（香港）](README.zh-HK.md)

[![ci](https://img.shields.io/github/actions/workflow/status/tmux-revamped/tmux-disk-revamped/ci.yml?branch=main&style=flat-square&label=ci)](https://github.com/tmux-revamped/tmux-disk-revamped/actions/workflows/ci.yml)
[![release](https://img.shields.io/github/v/release/tmux-revamped/tmux-disk-revamped?style=flat-square&label=release)](https://github.com/tmux-revamped/tmux-disk-revamped/releases/latest)
[![openssf scorecard](https://img.shields.io/ossf-scorecard/github.com/tmux-revamped/tmux-disk-revamped?style=flat-square&label=openssf%20scorecard)](https://scorecard.dev/viewer/?uri=github.com/tmux-revamped/tmux-disk-revamped)
[![license](https://img.shields.io/github/license/tmux-revamped/tmux-disk-revamped?style=flat-square&label=license)](LICENSE)

<p align="center">
  <a href="#quick-start"><strong>快速开始</strong></a> &nbsp;|&nbsp;
  <a href="#usage">使用</a> &nbsp;|&nbsp;
  <a href="#how-it-works">工作原理</a> &nbsp;|&nbsp;
  <a href="#screens">截图</a>
</p>

</div>

<p align="center">
  <img src="screens/hero.gif" alt="disk-revamped 展示按层级着色的用量和容量、打开详情弹窗、切换到 Nerd Font 标签、带增长速度的图表以及 options 渲染模式" width="800">
</p>

```console
$ disk-revamped refresh
Refreshed. 45% of / is used.
$ disk-revamped status percentage
45%
```

**16** 个占位符，**2** 种渲染模式，**2** 个弹窗，支持 macOS 和 Linux，需要 tmux **3.2** 或更高版本。

---

<a id="quick-start"></a>

## 快速开始

### 前提条件

| 工具 | 版本 | 用途 |
|:----|:----|:----|
| tmux | 3.2 或更高 | 家族的最低版本，以及弹窗 |
| gum | 可选 | `disk-revamped` 的菜单、表格和颜色；没有它时所有命令输出纯文本 |
| `df`、`du`、`sort` | 任意 | 用量和扫描，两个平台都自带 |
| `osascript` 或 `notify-send` | 可选 | 达到高阈值时的通知 |

它可以在使用 BSD、GNU、uutils 或 BusyBox 工具的 Linux 和 macOS 上运行。每个数值都来自系统自带的工具：

| 数值 | Linux | macOS |
|:----|:------|:------|
| 用量、已用、总量、可用、增长速度 | `df -Pk` | `/bin/df -Pk` |
| inode | `df -i` | `/bin/df -i` |
| 所有磁盘 | `df -h` | `/bin/df -h` |
| 读写速度 | `/proc/diskstats`，来自 `/sys/block` 的整盘设备 | 无 |
| 可清除空间 | 无 | `diskutil info` |

macOS 读取 `/bin/df`，因此 `PATH` 里 GNU coreutils 排在前面也不受影响。缺少来源时对应的占位符为空，`disk-revamped doctor` 会指出。

### 安装

使用 [TPM](https://github.com/tmux-plugins/tpm) 时，把插件加入 `~/.tmux.conf`，然后按 `prefix + I`：

```tmux
set -g @plugin 'tmux-revamped/tmux-disk-revamped'
```

手动安装时，克隆仓库，并在 `~/.tmux.conf` 中运行入口文件：

```bash
git clone https://github.com/tmux-revamped/tmux-disk-revamped ~/.tmux/plugins/tmux-disk-revamped
```

```tmux
run-shell ~/.tmux/plugins/tmux-disk-revamped/disk-revamped.tmux
```

请在插件加载之前设置 `status-left` 或 `status-right`。插件在加载时只替换一次其中的占位符。

在克隆目录里运行 `make install`，还会把 `disk-revamped` 放到 `~/.local/bin`，手册页和补全放到 `~/.local/share`。

### 验证

```bash
~/.tmux/plugins/tmux-disk-revamped/bin/disk-revamped doctor
```

<a id="usage"></a>

## 使用

插件显示磁盘用了多少，包括已用、可用和总空间、inode 用量、最近读数的图表、增长速度、写满所需时间以及所有磁盘的列表。状态栏打印 tmux 已持有的值，由后台读取来刷新它。

| 占位符 | 输出 |
|:----|:----|
| `#{disk_percentage}` | 已用百分比，例如 `55%` |
| `#{disk_icon}` | 当前用量层级的图标 |
| `#{disk_fg_color}` | 用量层级的前景样式 |
| `#{disk_bg_color}` | 用量层级的背景样式 |
| `#{disk_used}` | 已用空间，单位 G，例如 `55G`，从 1024G 起用 T，例如 `1.8T` |
| `#{disk_total}` | 总空间，形式相同 |
| `#{disk_free}` | 可用空间，形式相同 |
| `#{disk_read}` | Linux 上的读取速度，例如 `1.2MB/s`；macOS 上为空 |
| `#{disk_write}` | Linux 上的写入速度，形式相同；macOS 上为空 |
| `#{disk_all}` | 所有已挂载的真实磁盘，例如 `/ 55%, /data 30%` |
| `#{disk_inodes}` | inode 用量，例如 `i12%` |
| `#{disk_purgeable}` | macOS 上 APFS 的可清除空间；Linux 上为空 |
| `#{disk_graph}` | 最近的用量读数，例如 `▄▄▆▆█` |
| `#{disk_fill_rate}` | 已用空间的变化，例如 `+2.1G/h`，稳定时为空 |
| `#{disk_full_eta}` | 按该速度写满所需的时间，例如 `3d`，未在增长时为空 |
| `#{disk_mounts}` | `@disk_revamped_mounts` 中指定的挂载点，形式与 `#{disk_all}` 相同 |

把占位符放进状态栏：

```tmux
set -g @disk_revamped_low_fg_color '#[fg=green]'
set -g @disk_revamped_medium_fg_color '#[fg=yellow]'
set -g @disk_revamped_high_fg_color '#[fg=red]'

set -g status-right '#{disk_fg_color}#{disk_icon} #{disk_percentage}#[default] #{disk_used}/#{disk_total} '
```

同一个示例加上几个选项，见 [examples/status-right.tmux.conf](examples/status-right.tmux.conf)。

### 标签和宽度

`@disk_revamped_<metric>_label` 在某个指标的值不为空时，在它之前打印图标或文字。把 `@disk_revamped_icons` 设为 `nerd`，会给下面每个指标加上 Nerd Font 图标。指标自己的标签优先于整套图标，留空的标签表示默认值，所以图标仍然保留。默认的 `ascii` 不加标签。指标有 `percentage`、`used`、`total`、`free`、`read`、`write`、`inodes`、`purgeable`、`graph`、`fill_rate`、`full_eta`、`mounts` 和 `all`，在命令选项中用连字符书写，例如 `--fill-rate-label`。

| 指标 | `nerd` 图标 |
|:----|:----------|
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

把 `@disk_revamped_fixed_width` 设为 `on`，会把每个数值在左侧补到自然宽度：用量和 inode 为四个字符，读写速度为九个字符，所以从 `9%` 变成 `42%` 时其余部分不会移位。`@disk_revamped_<metric>_width` 设置单个指标的宽度，并优先于固定宽度。更长的值不会被截断。

### 渲染模式

默认情况下每个占位符变成一次 `#()` 调用，tmux 在每次重绘状态栏时重新运行它。把 `@disk_revamped_render` 设为 `options` 后，每个占位符变成对选项的读取，例如 `#{E:@disk_revamped_out_percentage}`。每个服务器随后由一个后台进程每隔 `@disk_revamped_interval` 秒读取磁盘，并用一次 tmux 调用写入所有值，所以它们同时变化。

```tmux
set -g @disk_revamped_render 'options'
set -g @disk_revamped_fixed_width 'on'
```

### 层级颜色

层级样式默认为空，所以在你设置之前 `#{disk_fg_color}` 和 `#{disk_bg_color}` 不会输出任何内容。下面的配色把低映射为绿色，中为黄色，高为红色：

| 主题 | 低 | 中 | 高 |
|:----|:----|:----|:----|
| Catppuccin Mocha | `#a6e3a1` | `#f9e2af` | `#f38ba8` |
| Dracula | `#50fa7b` | `#f1fa8c` | `#ff5555` |
| Nord | `#a3be8c` | `#ebcb8b` | `#bf616a` |
| Gruvbox Dark | `#b8bb26` | `#fabd2f` | `#fb4934` |
| Tokyo Night | `#9ece6a` | `#e0af68` | `#f7768e` |
| Solarized Dark | `#859900` | `#b58900` | `#dc322f` |

每个值放进一个样式里，例如 `set -g @disk_revamped_low_fg_color '#[fg=#a6e3a1]'`。

| 命令 | 作用 |
|:----|:----|
| `disk-revamped apply` | 绑定弹窗按键并立即填充占位符；入口文件在 tmux 加载插件时运行它 |
| `disk-revamped list` | 打印 `apply` 会发送的所有命令，不做任何改动；`--json` 输出一个对象 |
| `disk-revamped status NAME` | 打印一个占位符，例如 `percentage`、`used` 或 `graph`；状态栏运行它 |
| `disk-revamped refresh` | 立即读取磁盘并说明用了多少 |
| `disk-revamped card` | 立即读取全部内容，每个数值一行，然后是所有磁盘，按终端大小裁剪 |
| `disk-revamped scan` | 列出扫描路径下最大的项目及其大小 |
| `disk-revamped popup` | 在 tmux 弹窗中打开卡片；弹窗按键运行它 |
| `disk-revamped eat` | 在 tmux 弹窗中打开扫描；eat 按键运行它 |
| `disk-revamped daemon` | 为 `options` 渲染模式在每个周期发布占位符；`apply` 会启动它 |
| `disk-revamped doctor` | 每个依赖一行：各数值的来源工具或文件、终端大小、通知方式以及被放过的按键 |
| `disk-revamped version` | 版本，然后是 tmux 版本 |
| `disk-revamped help` | 帮助页；`man disk-revamped` 记录相同的命令和设置 |
| `disk-revamped` | 在终端中显示菜单 |

<a id="configuration"></a>

## 配置

每个选项也是带连字符的命令选项，例如 `--interval 2`，也是环境变量，例如 `DISK_REVAMPED_INTERVAL`；命令行优先于环境变量，环境变量优先于 tmux 选项。空的 tmux 选项表示默认值，命令行或环境变量中的空值按原样使用。`doctor` 会指出持有插件不认识的值的设置。传给 `apply` 的设置会带到按键和每一次状态调用上。

### 读取

| 选项 | 默认值 | 含义 |
|:----|:----|:----|
| `@disk_revamped_mount` | `/` | 用量类占位符报告的挂载点；macOS 上 `/` 是只读的系统卷，设为 `/System/Volumes/Data` 才能看到你的文件占用的空间 |
| `@disk_revamped_mounts` | empty | `#{disk_mounts}` 的挂载点，空格或逗号分隔；不存在的会被忽略 |
| `@disk_revamped_interval` | `30` | 读数保持新鲜的秒数 |
| `@disk_revamped_detail_interval` | `60` | 所有磁盘列表保持新鲜的秒数 |
| `@disk_revamped_render` | `jobs` | `options` 读取已发布的选项，而不是运行 `#()` 调用；其他值都按 `jobs` 处理 |
| `@disk_revamped_history_length` | `20` | `#{disk_graph}` 保留的读数个数 |
| `@disk_revamped_notify` | `0` | `1` 表示用量达到 `@disk_revamped_high_thresh` 时发送通知，回落后再次达到时会再发 |

### 层级

| 选项 | 默认值 | 含义 |
|:----|:----|:----|
| `@disk_revamped_medium_thresh` | `70` | 层级变为中的用量百分比 |
| `@disk_revamped_high_thresh` | `90` | 层级变为高的用量百分比，也是发送通知的阈值 |
| `@disk_revamped_low_icon` | `▰▱▱` | 低层级的图标 |
| `@disk_revamped_medium_icon` | `▰▰▱` | 中层级的图标 |
| `@disk_revamped_high_icon` | `▰▰▰` | 高层级的图标 |
| `@disk_revamped_low_fg_color` | empty | 低层级的前景样式，例如 `#[fg=green]` |
| `@disk_revamped_medium_fg_color` | empty | 中层级的前景样式 |
| `@disk_revamped_high_fg_color` | empty | 高层级的前景样式 |
| `@disk_revamped_low_bg_color` | empty | 低层级的背景样式 |
| `@disk_revamped_medium_bg_color` | empty | 中层级的背景样式 |
| `@disk_revamped_high_bg_color` | empty | 高层级的背景样式 |

### 格式和标签

| 选项 | 默认值 | 含义 |
|:----|:----|:----|
| `@disk_revamped_percentage_format` | `%s%%` | 用量的 printf 格式 |
| `@disk_revamped_size_format` | `%sG` | 低于 1024G 的容量的 printf 格式；从 1024G 起是带一位小数的 T |
| `@disk_revamped_inodes_format` | `i%s%%` | `#{disk_inodes}` 的 printf 格式 |
| `@disk_revamped_separator` | `, ` | `#{disk_all}` 和 `#{disk_mounts}` 中磁盘之间的文本 |
| `@disk_revamped_icons` | `ascii` | `nerd` 给每个值加上 Nerd Font 图标 |
| `@disk_revamped_<metric>_label` | empty | 打印在某个值之前的文本，仅在值不为空时 |
| `@disk_revamped_fixed_width` | `off` | `on` 把每个数值在左侧补到自然宽度，从 `9%` 变成 `42%` 时其余部分不会移位 |
| `@disk_revamped_<metric>_width` | empty | 把某个值补到这个字符数。更长的值不会被截断 |

### 按键和扫描

| 选项 | 默认值 | 含义 |
|:----|:----|:----|
| `@disk_revamped_popup_key` | `M-d` | 打开详情弹窗的前缀键。`off` 表示不绑定 |
| `@disk_revamped_eat_key` | empty | 打开最大项目弹窗的前缀键；留空或 `off` 表示不绑定 |
| `@disk_revamped_eat_path` | the mount | 扫描所列出的文件夹 |
| `@disk_revamped_eat_count` | `10` | 扫描列出多少个最大的项目 |
| `@disk_revamped_eat_interval` | `60` | 扫描结果保持新鲜的秒数 |

### 内部状态

插件自己写入这些选项，请不要设置它们。

| 选项 | 内容 |
|:----|:----|
| `@disk_revamped_published` | 状态栏使用的指标，加载时记录，只读取这些 |
| `@disk_revamped_history` | `#{disk_graph}` 背后的最近读数 |
| `@disk_revamped_out_<metric>` | options 模式下每个指标的渲染结果 |
| `@disk_revamped_ticker_pid` | options 模式后台进程的进程号 |
| `@disk_revamped_notified` | 发出通知后为 `1`，直到用量回落到阈值以下 |
| `@disk_revamped_percent` and the other figures, `_ts`, `_lock` | 保存的读数、每次读取的时间和刷新锁；`@disk_revamped_mounts_list` 保存设置 `@disk_revamped_mounts` 的读数 |

## 按键绑定

| 按键 | 作用 | 默认 |
|:----|:----|:----|
| `prefix + M-d` | 在弹窗中打开卡片：各数值和所有磁盘，按弹窗大小裁剪。按 Enter 关闭 | 已绑定 |
| 未绑定 | 打开最大项目弹窗。按 Enter 关闭 | `@disk_revamped_eat_key` |

`@disk_revamped_popup_key` 可以指定另一个按键，`off` 表示不绑定。当默认按键已被别的功能占用时会被放过，`disk-revamped doctor` 会说明。`@disk_revamped_eat_key` 绑定最大项目弹窗，需要自行开启。

```tmux
set -g @disk_revamped_eat_key 'M-u'
```

<a id="how-it-works"></a>

## 工作原理

[`disk-revamped.tmux`](disk-revamped.tmux) 在 tmux 加载插件时运行一次。它把 `status-left` 和 `status-right` 用到的指标记录到 `@disk_revamped_published`，然后把每个占位符替换为对 [`bin/disk-revamped`](bin/disk-revamped) 的调用，在 `options` 模式下则替换为对选项的读取并启动后台进程。

在默认模式下，每个 `#()` 调用立即返回已保存的读数。读数超过间隔后，调用会在后台启动一次刷新并加锁，所以同一时间只有一次刷新在运行。一次 `df -Pk` 给出用量和容量，容量向上取整到整数 G；inode、可清除空间、分盘速度、增长速度和磁盘列表读取成本更高，所以只在状态栏用到对应占位符时才运行。一个 `awk` 把读数转换成所有数值，一次 tmux 调用把它们存起来。

读写速度和增长速度把每次读数与上一次比较。挂载路径来自外部，所以其中的每个 `#` 在到达状态栏之前都会加倍。读取、数值和格式化位于 [`lib/disk.sh`](lib/disk.sh)，设置表位于 [`lib/state.sh`](lib/state.sh)。

<a id="screens"></a>

## 截图

<details>
<summary>每一张截图都在真实的 tmux 中用 <code>make screens</code> 录制，并在状态栏上显示每个按键</summary>
<br>

<table>
<tr>
<td width="50%" valign="top"><img src="screens/status.png" alt="disk-revamped: 带层级图标和颜色的用量，以及容量和可用空间"><br><sub>带层级图标和颜色的用量，以及容量和可用空间，来自 <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/popup.png" alt="disk-revamped: prefix M-d 在弹窗中打开详情卡片"><br><sub><code>prefix M-d</code> 在弹窗中打开详情卡片，来自 <code>hero.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/icons.png" alt="disk-revamped: @disk_revamped_icons 设为 nerd 会给每个指标加上图标"><br><sub><code>@disk_revamped_icons</code> 设为 <code>nerd</code> 会给每个指标加上图标，来自 <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/graph.png" alt="disk-revamped: 图表、用量、增长速度和写满所需时间"><br><sub>图表、用量、增长速度和写满所需时间，来自 <code>hero.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/options.png" alt="disk-revamped: 在 options 渲染模式下，每个占位符读取一个 tmux 选项"><br><sub>在 <code>options</code> 渲染模式下，每个占位符读取一个 tmux 选项，来自 <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/card.png" alt="disk-revamped: card 打印每个数值和每块磁盘"><br><sub><code>card</code> 打印每个数值和每块磁盘，来自 <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/sizes.png" alt="disk-revamped: 已用、可用和总空间，以及 macOS 上的可清除空间"><br><sub>已用、可用和总空间，以及 macOS 上的可清除空间，来自 <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/size-format.png" alt="disk-revamped: @disk_revamped_size_format 决定低于 1024G 的容量格式"><br><sub><code>@disk_revamped_size_format</code> 决定低于 1024G 的容量格式，来自 <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/colors.png" alt="disk-revamped: 自定义的层级图标和颜色"><br><sub>自定义的层级图标和颜色，来自 <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/tiers.png" alt="disk-revamped: @disk_revamped_medium_thresh、@disk_revamped_high_thresh 和各层级图标"><br><sub><code>@disk_revamped_medium_thresh</code>、<code>@disk_revamped_high_thresh</code> 和各层级图标，来自 <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/format.png" alt="disk-revamped: @disk_revamped_percentage_format 决定用量的格式"><br><sub><code>@disk_revamped_percentage_format</code> 决定用量的格式，来自 <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/inodes-format.png" alt="disk-revamped: inode 用量和 @disk_revamped_inodes_format"><br><sub>inode 用量和 <code>@disk_revamped_inodes_format</code>，来自 <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/fixed.png" alt="disk-revamped: @disk_revamped_fixed_width 把每个数值补到自然宽度"><br><sub><code>@disk_revamped_fixed_width</code> 把每个数值补到自然宽度，来自 <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/width.png" alt="disk-revamped: @disk_revamped_inodes_width 把单个指标补到自己的宽度"><br><sub><code>@disk_revamped_inodes_width</code> 把单个指标补到自己的宽度，来自 <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/labels.png" alt="disk-revamped: 单个指标之前的自定义标签"><br><sub>单个指标之前的自定义标签，来自 <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/mounts.png" alt="disk-revamped: @disk_revamped_mounts 列出你指定的挂载点"><br><sub><code>@disk_revamped_mounts</code> 列出你指定的挂载点，来自 <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/separator.png" alt="disk-revamped: @disk_revamped_separator 位于磁盘之间"><br><sub><code>@disk_revamped_separator</code> 位于磁盘之间，来自 <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/all.png" alt="disk-revamped: 一个占位符显示所有磁盘"><br><sub>一个占位符显示所有磁盘，来自 <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/mount.png" alt="disk-revamped: @disk_revamped_mount 选择用量报告的挂载点"><br><sub><code>@disk_revamped_mount</code> 选择用量报告的挂载点，来自 <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/history.png" alt="disk-revamped: @disk_revamped_history_length 决定图表保留多少读数"><br><sub><code>@disk_revamped_history_length</code> 决定图表保留多少读数，来自 <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/fill.png" alt="disk-revamped: 增长速度和写满所需时间"><br><sub>增长速度和写满所需时间，来自 <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/notify.png" alt="disk-revamped: @disk_revamped_notify 在达到高阈值时发送通知"><br><sub><code>@disk_revamped_notify</code> 在达到高阈值时发送通知，来自 <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/popup-key.png" alt="disk-revamped: @disk_revamped_popup_key 为弹窗指定另一个按键"><br><sub><code>@disk_revamped_popup_key</code> 为弹窗指定另一个按键，来自 <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/eat.png" alt="disk-revamped: @disk_revamped_eat_key 打开最大项目弹窗，由 @disk_revamped_eat_path、@disk_revamped_eat_count 和 @disk_revamped_eat_interval 调整"><br><sub><code>@disk_revamped_eat_key</code> 打开最大项目弹窗，由 <code>@disk_revamped_eat_path</code>、<code>@disk_revamped_eat_count</code> 和 <code>@disk_revamped_eat_interval</code> 调整，来自 <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/version.png" alt="disk-revamped: 版本"><br><sub>版本，来自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/error.png" alt="disk-revamped: 未知命令"><br><sub>未知命令，来自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/status-command.png" alt="disk-revamped: status percentage 和 status graph 各打印一个占位符"><br><sub><code>status percentage</code> 和 <code>status graph</code> 各打印一个占位符，来自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/refresh.png" alt="disk-revamped: refresh 立即读取磁盘"><br><sub><code>refresh</code> 立即读取磁盘，来自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/list.png" alt="disk-revamped: list 打印每一个绑定"><br><sub><code>list</code> 打印每一个绑定，来自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/json.png" alt="disk-revamped: list --json 把同一个计划作为一个对象打印"><br><sub><code>list --json</code> 把同一个计划作为一个对象打印，来自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/doctor.png" alt="disk-revamped: doctor"><br><sub><code>doctor</code>，来自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/menu.png" alt="disk-revamped: 菜单"><br><sub>菜单，来自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/menu-card.png" alt="disk-revamped: 从菜单打开的卡片"><br><sub>从菜单打开的卡片，来自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/scan.png" alt="disk-revamped: scan 列出最大的项目"><br><sub><code>scan</code> 列出最大的项目，来自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/accent.png" alt="disk-revamped: 来自 DISK_REVAMPED_ACCENT 的强调色"><br><sub>来自 <code>DISK_REVAMPED_ACCENT</code> 的强调色，来自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/plain-menu.png" alt="disk-revamped: 没有 gum 的菜单"><br><sub>没有 gum 的菜单，来自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/plain-card.png" alt="disk-revamped: 没有 gum 时从菜单打开的 card"><br><sub>没有 gum 时从菜单打开的 <code>card</code>，来自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/plain-doctor.png" alt="disk-revamped: 没有 gum 的 doctor"><br><sub>没有 gum 的 <code>doctor</code>，来自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/themes.png" alt="disk-revamped: 六个主题下的标题"><br><sub>六个主题下的标题，来自 <code>themes.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/help.png" alt="disk-revamped: 帮助页"><br><sub>帮助页，来自 <code>help.tape</code></sub></td>
</tr>
</table>

录制运行的是真实的插件和 tmux。`df`、`diskutil`、`osascript` 和 `du` 由小脚本代替，所以画面上的数值来自它们。录制在 macOS 上进行，macOS 没有分盘计数器，所以 `#{disk_read}` 和 `#{disk_write}` 在那里不显示内容。`@disk_revamped_interval` 和 `@disk_revamped_detail_interval` 设置在录制用的 tmux 配置中。

</details>

## 可移植性

插件使用 POSIX `sh`。CI 在下面每一行上运行所有测试套件。

| Shell | 状态 |
|:------|:----|
| `dash`、macOS 上的 `/bin/sh` | 支持 |
| `bash` 3.2 和 5.x，系统自带的 `zsh` 和 Homebrew 的 `zsh` | 支持 |

| 系统 | 状态 |
|:----|:----|
| macOS | Apple Silicon 和 Intel 上的 Tahoe，分别使用系统自带工具、Homebrew 的 GNU 工具和 Homebrew 的 uutils |
| Linux | x86_64 和 arm64 上的 Ubuntu 26.04，分别使用 GNU coreutils、uutils 和 BusyBox |

## 开发

| 命令 | 运行内容 |
|:----|:-----|
| `make fmt` | 对每个脚本运行 shfmt `-i 2` |
| `make lint` | shfmt、ShellCheck、mandoc、yamllint 和 actionlint，结果必须为零 |
| `make test` | 用系统 `sh` 运行 bats 测试套件 |
| `make test-all` | 用每个已安装的 shell 运行套件，macOS 上包括 bash 和 zsh 的两种版本 |
| `make test-linux` | 在 Ubuntu 容器中运行套件 |
| `make coverage` | 在这台 Mac 和 Ubuntu 容器中运行 bashcov，合并后要求达到 100% |
| `make screens` | 在 macOS 上用 VHS 在 tmux 中录制上面的截图，运行的是真实的插件 |
| `make install` | 把命令、手册页和补全安装到 `PREFIX` 下 |

在 macOS 上，`brew bundle` 会按 [`Brewfile`](Brewfile) 安装这些目标调用的所有工具。

提交遵循 Conventional Commits 格式，直接进入 `main`。`main` 上的 `ci` 通过后，`release.yml` 运行 semantic-release：自上一个标签以来的每个 `feat` 或 `fix` 都会发布一个版本，更新版本常量，并把说明加入 [`CHANGELOG.md`](CHANGELOG.md)。

## 许可证

[MIT](LICENSE)，copyright Gustavo Franco。

<!-- family:begin -->

## tmux-revamped 插件家族

这个插件是 tmux-revamped 插件家族的一员。每个成员都带有 [`FAMILY.md`](FAMILY.md) 中相同的约定和相同的共享库，并且设计为一起安装：没有成员占用另一个成员占用的按键或 tmux 选项。

在一个成员中发现的缺陷，要在全部成员中排查之后才算修复完成。

| 成员 | 功能 |
|---|---|
| [`tmux-autoreload-revamped`](https://github.com/tmux-revamped/tmux-autoreload-revamped) | 编辑并保存 tmux 配置后，它会自动重新加载，无需按键，也无需命令 |
| [`tmux-battery-revamped`](https://github.com/tmux-revamped/tmux-battery-revamped) | 在 tmux 状态栏显示电池状态，从不阻塞状态栏渲染 |
| [`tmux-bluetooth-revamped`](https://github.com/tmux-revamped/tmux-bluetooth-revamped) | 在 tmux 状态栏显示每个已连接的蓝牙设备及其电量，不阻塞渲染 |
| [`tmux-cpu-revamped`](https://github.com/tmux-revamped/tmux-cpu-revamped) | 在 tmux 状态栏显示 CPU 负载、温度和频率，从不阻塞渲染 |
| [`tmux-disk-revamped`](https://github.com/tmux-revamped/tmux-disk-revamped) | **本插件**，在 tmux 状态栏显示磁盘用量，从不阻塞状态栏渲染 |
| [`tmux-extract-revamped`](https://github.com/tmux-revamped/tmux-extract-revamped) | 用 fzf 从屏幕上挑选 URL、路径、哈希或任意其他词元，并输入到光标处，全部用纯 shell 实现 |
| [`tmux-fzf-revamped`](https://github.com/tmux-revamped/tmux-fzf-revamped) | 在弹出窗口中的 fzf 选择器里切换、关闭、重命名或创建 tmux 会话、窗口和窗格 |
| [`tmux-git-revamped`](https://github.com/tmux-revamped/tmux-git-revamped) | 在 tmux 状态栏中显示活动窗格的 git 分支、改动和托管平台计数，且不阻塞渲染 |
| [`tmux-gpu-revamped`](https://github.com/tmux-revamped/tmux-gpu-revamped) | 在 tmux 状态栏中显示 NVIDIA、AMD、Intel 和 Apple GPU 的负载、温度、频率、功耗和显存 |
| [`tmux-kube-revamped`](https://github.com/tmux-revamped/tmux-kube-revamped) | 在 tmux 状态栏中显示当前的 Kubernetes 上下文和命名空间，不依赖 kubectl，直接解析 kubeconfig |
| [`tmux-launcher-revamped`](https://github.com/tmux-revamped/tmux-launcher-revamped) | 在弹出窗口或新窗口中启动任意 TUI 应用，从当前窗格的目录开始，每个应用可配置一个按键 |
| [`tmux-logging-revamped`](https://github.com/tmux-revamped/tmux-logging-revamped) | 将任意窗格保存到文件：实时日志、完整回滚缓冲区或一次性截图 |
| [`tmux-music-revamped`](https://github.com/tmux-revamped/tmux-music-revamped) | 在 tmux 状态栏显示正在播放的曲目，从不阻塞状态栏渲染 |
| [`tmux-network-revamped`](https://github.com/tmux-revamped/tmux-network-revamped) | 在 tmux 状态栏显示网络吞吐量，从不阻塞渲染 |
| [`tmux-pain-control-revamped`](https://github.com/tmux-revamped/tmux-pain-control-revamped) | tmux 的窗格和窗口管理按键，适配 tmux 版本，兼容 vim，每个 prefix 按键都可禁用 |
| [`tmux-persist-revamped`](https://github.com/tmux-revamped/tmux-persist-revamped) | 保存 tmux 的所有会话、窗口和窗格，按定时器自动保存，并在重启后全部恢复 |
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | tmux-revamped 插件的起点：共享库、bats 测试框架和 CI |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | tmux 状态栏中的番茄钟计时器，所有状态都保存在 tmux 选项中，不使用临时文件 |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | 在 tmux 状态栏显示内存、交换空间和内存压力，在后台采样，渲染从不等待 |
| [`tmux-reorder-revamped`](https://github.com/tmux-revamped/tmux-reorder-revamped) | 用鼠标在 tmux 状态栏上拖动窗口标签来移动该窗口 |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | 将鼠标滚轮交给能自行滚动的应用，其他情况下进入 tmux 复制模式 |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | 按 tmux 版本和终端区分的合理默认设置，不改动你自己设置的选项 |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | tmux 的平铺窗口管理：八种布局，包括 BSP dwindle 和 spiral，并支持撤销布局 |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | 状态栏中的本地时钟和世界时钟，按一天中的时段着色，并提供倒计时和夏令时提醒 |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | 在后台从 wttr.in 获取天气并显示在状态栏，状态栏无需等待 |

<!-- family:end -->
