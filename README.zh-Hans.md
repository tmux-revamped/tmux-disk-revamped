<div align="center">

# tmux-disk-revamped

<strong>在 tmux 状态栏显示磁盘用量，从不阻塞状态栏渲染。</strong>

[English](README.md) | [日本語](README.ja.md) | 简体中文 | [繁體中文（香港）](README.zh-HK.md)

[![Tests](https://github.com/tmux-revamped/tmux-disk-revamped/actions/workflows/tests.yml/badge.svg)](https://github.com/tmux-revamped/tmux-disk-revamped/actions/workflows/tests.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)](CHANGELOG.md)

<p align="center">
  <a href="#what-it-does">功能</a> |
  <a href="#requirements">环境要求</a> |
  <a href="#installation">安装</a> |
  <a href="#usage">用法</a> |
  <a href="#configuration">配置</a> |
  <a href="#key-bindings">快捷键</a> |
  <a href="#how-it-works">工作原理</a>
</p>

</div>

**16** 个占位符。**2** 种渲染模式。**2** 个弹窗。CI 在 **10** 种 Linux 和 macOS 工具链组合上运行测试。

---

<a id="what-it-does"></a>

## 功能

插件把 `status-left` 和 `status-right` 中的 `#{disk_*}` 占位符替换为某个挂载点的使用率、可用空间、inode 使用率、读写速度、增长速度、写满剩余时间和使用率历史，以及所有真实磁盘的列表。每个占位符读取缓存在 tmux 选项中的值。`df` 在后台运行，状态栏从不等待。不向磁盘写入任何内容。

它还通过 `prefix + M-d` 打开详情弹窗，另有一个可选的弹窗列出磁盘上最大的项目，以及磁盘越过高阈值时的可选通知。

<a id="requirements"></a>

## 环境要求

| 工具 | 版本 | 用途 |
|:-----|:--------|:-----------|
| tmux | 3.2 或更高 | 两个弹窗所用的 `display-popup` |
| bash | 3.2 或更高 | 所有脚本，包括 macOS 的 `/bin/bash` |
| `df`、`du` | 任意 | 用量和空间扫描，两个平台都自带 |
| `osascript` 或 `notify-send` | 任意 | 可选，磁盘将满的通知 |

| 数值 | Linux，x86_64 和 arm64 | macOS，Intel 和 Apple Silicon |
|:------|:------------------------|:-------------------------------|
| 使用率、已用、总量、可用 | `df -BG` | `/bin/df -g` |
| 增长速度和写满剩余时间 | `df -Pk` | `/bin/df -Pk` |
| inode | `df -i` | `df -i` |
| 读写速度 | `/proc/diskstats`，取 `/sys/block` 中的整块设备 | 无 |
| 可清除空间 | 无 | `diskutil info` |

macOS 的读取调用 `/bin/df`，因此 `PATH` 中排在前面的 GNU coreutils 不会让它们出错。主机没有数据源的数值显示为空。运行 `src/disk.sh doctor` 可以查看本机提供了什么。

<a id="installation"></a>

## 安装

### 使用 TPM

把插件和占位符加入 `~/.tmux.conf`，然后按 `prefix + I`：

```tmux
set -g @plugin 'tmux-revamped/tmux-disk-revamped'
set -g status-right '#{disk_icon} #{disk_percentage}'
```

### 手动安装

```bash
git clone https://github.com/tmux-revamped/tmux-disk-revamped ~/.tmux/plugins/tmux-disk-revamped
```

然后把这一行加到 `~/.tmux.conf` 中设置 `status-left` 和 `status-right` 的行之后，并重新加载 tmux：

```tmux
run-shell ~/.tmux/plugins/tmux-disk-revamped/disk-revamped.tmux
```

<a id="usage"></a>

## 用法

在 `status-left` 或 `status-right` 中写入占位符，插件加载时会替换它们。完整示例见 [`examples/status-right.tmux.conf`](examples/status-right.tmux.conf)。

```tmux
set -g status-right '#{disk_fg_color}#{disk_icon} #{disk_percentage}#[default] #{disk_used}/#{disk_total} '
```

| 占位符 | 输出 |
|:------------|:-------|
| `#{disk_percentage}` | 使用率，例如 `55%` |
| `#{disk_icon}` | 当前使用率档位的图标 |
| `#{disk_fg_color}`、`#{disk_bg_color}` | 当前使用率档位的颜色 |
| `#{disk_used}`、`#{disk_total}`、`#{disk_free}` | 以 GB 为单位的大小，例如 `100G`，达到 1024G 后切换为 TB，例如 `1.8T` |
| `#{disk_inodes}` | inode 使用率，例如 `i12%` |
| `#{disk_purgeable}` | macOS 上 APFS 的可清除空间 |
| `#{disk_read}`、`#{disk_write}` | Linux 上的读写速度，例如 `1.2MB/s` |
| `#{disk_fill_rate}` | 已用空间的变化，例如 `+2.1G/h`，没有变化时为空 |
| `#{disk_full_eta}` | 按该速度写满的剩余时间，例如 `3d`，没有增长时为空 |
| `#{disk_graph}` | 最近的使用率读数，例如 `▄▄▆▆█` |
| `#{disk_all}` | 每个已挂载的真实磁盘，例如 `/ 55%, /home 30%` |
| `#{disk_mounts}` | `@disk_revamped_mounts` 中列出的挂载点，格式相同 |

`#{disk_all}` 列出 `/dev/` 文件系统，在 macOS 上排除 `/Volumes/`，在 Linux 上排除 `/boot` 和 `/snap`。

<a id="configuration"></a>

## 配置

| 选项 | 默认值 | 含义 |
|:-------|:--------|:--------|
| `@disk_revamped_mount` | `/` | 用量占位符报告的挂载点；在 macOS 上 `/` 是密封的系统卷，要查看你的文件所占的空间，请设置为 `/System/Volumes/Data` |
| `@disk_revamped_interval` | `30` | 用量读数保持有效的秒数 |
| `@disk_revamped_detail_interval` | `60` | `#{disk_all}` 列表保持有效的秒数 |
| `@disk_revamped_render` | 空 | `options` 开启选项渲染模式，见[工作原理](#how-it-works) |
| `@disk_revamped_percentage_format` | `%s%%` | 使用率的 printf 格式 |
| `@disk_revamped_size_format` | `%sG` | 小于 1024G 的大小的 printf 格式 |
| `@disk_revamped_medium_thresh`、`@disk_revamped_high_thresh` | `70`、`90` | 中档和高档开始的使用率百分比 |
| `@disk_revamped_low_icon` | `▰▱▱` | 低档的图标 |
| `@disk_revamped_medium_icon` | `▰▰▱` | 中档的图标 |
| `@disk_revamped_high_icon` | `▰▰▰` | 高档的图标 |
| `@disk_revamped_{low,medium,high}_{fg,bg}_color` | 空 | 每个档位的颜色 |
| `@disk_revamped_separator` | `, ` | `#{disk_all}` 和 `#{disk_mounts}` 中磁盘之间的文字 |
| `@disk_revamped_mounts` | 空 | `#{disk_mounts}` 的挂载点，用空格或逗号分隔 |
| `@disk_revamped_inodes_format` | `i%s%%` | `#{disk_inodes}` 的 printf 格式 |
| `@disk_revamped_history_length` | `20` | `#{disk_graph}` 保留的读数个数 |
| `@disk_revamped_icons` | `ascii` | `nerd` 为每个指标加上 Nerd Font 字形标签 |
| `@disk_revamped_<metric>_label` | 空 | 值不为空时显示在某个指标前的文字；`''` 去掉 `nerd` 标签 |
| `@disk_revamped_fixed_width` | `off` | `on` 在左侧填充每个值到其最大宽度 |
| `@disk_revamped_<metric>_width` | 空 | 某个指标的填充宽度，优先于固定宽度 |
| `@disk_revamped_notify` | `0` | `1` 在使用率达到 `@disk_revamped_high_thresh` 时发送通知 |
| `@disk_revamped_popup_key` | `M-d` | 详情弹窗的 prefix 按键；`off` 不绑定 |
| `@disk_revamped_eat_key` | 空 | 最大项目弹窗的 prefix 按键；为空时不绑定 |
| `@disk_revamped_eat_path` | 挂载点 | 空间扫描列出的目录 |
| `@disk_revamped_eat_count` | `10` | 扫描列出的最大项目个数 |
| `@disk_revamped_eat_interval` | `60` | 扫描结果保持有效的秒数 |

除图标和两个颜色外，标签适用于所有占位符。宽度设置不会截断较长的值。

### 主题配色

颜色选项默认为空，因此在设置之前插件不添加颜色。下面每个配色把低、中、高三档分别设为绿色、黄色和红色：

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

### 内部状态

以下选项由插件自己写入，请不要设置。

| 选项 | 内容 |
|:-------|:------|
| `@disk_revamped_published` | 加载时在 `status-left` 和 `status-right` 中找到的指标；inode、可清除空间、增长速度和挂载点的探测只在其指标列在这里时运行 |
| `@disk_revamped_out_<metric>` | 选项模式中每个指标发布的值 |
| `@disk_revamped_ticker_pid` | 选项模式后台进程的 pid |
| `@disk_revamped_option_names` | 后台进程每个周期用一次调用读取的选项 |
| `@disk_revamped_notified` | 发送通知后为 `1`，直到使用率降到阈值以下 |
| `@disk_revamped_history` | `#{disk_graph}` 所用的最近使用率读数 |
| `@disk_revamped_{percent,used,total,free,all,read,write,inodes,purgeable,mounts,fill_rate,full_eta,eat}` | 缓存的读数，各带一个 `_ts` 时间戳 |
| `@disk_revamped_{rd_raw,wr_raw,io_ts,used_raw,fill_ts}` | 计算速度所依据的上一次计数 |

<a id="key-bindings"></a>

## 快捷键

| 按键 | 操作 | 选项 |
|:----|:-------|:-------|
| `prefix + M-d` | 打开详情弹窗 | `@disk_revamped_popup_key` |
| 未绑定 | 打开最大项目弹窗 | `@disk_revamped_eat_key` |

详情弹窗显示挂载点、使用率、已用、可用和总空间，以及 `#{disk_all}` 列表。最大项目弹窗在后台运行 `du`，只在同一个文件系统内扫描，并包含以点开头的项目。第一次打开时，在结果缓存之前显示 `Scanning`。两个弹窗都按 Enter 关闭。

```tmux
set -g @disk_revamped_eat_key 'M-u'
```

<a id="how-it-works"></a>

## 工作原理

在默认的作业模式中，每个占位符都会变成调用 [`src/disk.sh`](src/disk.sh) 的 `#()`。调用会立即输出缓存的值。当缓存的用量比 `@disk_revamped_interval` 旧时，它还会启动一次后台刷新；刷新受锁保护，并行的调用不会再启动第二次。

tmux 每次重绘状态栏都会运行所有 `#()`。一条状态栏上有多个插件时，大约每秒一次。选项模式去掉了这些调用：

```tmux
set -g @disk_revamped_render 'options'
set -g @disk_revamped_fixed_width 'on'
```

此时每个占位符变成类似 `#{E:@disk_revamped_out_percentage}` 的选项读取。每个服务器有一个后台进程，每 `@disk_revamped_interval` 秒读取一次磁盘，用一次 tmux 调用写入状态栏用到的所有值，然后只重绘一次。服务器停止，或重新加载配置启动了接替的进程时，它就会退出。

读写速度和增长速度都把每次读数与上一次比较。挂载路径在缓存前会把每个 `#` 加倍，因此路径无法注入 tmux 格式。

<a id="development"></a>

## 开发

| 命令 | 运行内容 |
|:--------|:-------------|
| `make test` | [`test/`](test) 下的 bats 测试 |
| `make lint` | 对所有 shell 文件运行 shellcheck |
| `make coverage` | 在 Linux 上用 kcov 统计行覆盖率，低于 95% 时失败 |

<a id="license"></a>

## 许可证

[MIT](LICENSE)，copyright Gustavo Franco。

<!-- family:begin -->

## tmux-revamped 插件家族

本插件是 tmux-revamped 插件家族的一员。每个成员都带有 [`FAMILY.md`](FAMILY.md) 中的同一份约定、`family/` 下的同一套工具和同一个共享库，并由校验和清单保证逐字节一致。这些成员可以一起安装：任何成员都不会占用其他成员使用的按键或 tmux 选项。

在一个成员中发现的缺陷，要在全部成员中排查之后才算修复完成。这项义务写在约定里，而不是靠记忆，`family/bin/sweep` 负责执行它。

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
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | tmux-revamped 插件的起点：共享库、bats 测试框架、CI 和系列工具 |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | tmux 状态栏中的番茄钟计时器，所有状态都保存在 tmux 选项中，不使用临时文件 |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | 在 tmux 状态栏显示内存、交换空间和内存压力，在后台采样，渲染从不等待 |
| [`tmux-reorder-revamped`](https://github.com/tmux-revamped/tmux-reorder-revamped) | 用鼠标在 tmux 状态栏上拖动窗口标签来移动该窗口 |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | 将鼠标滚轮交给能自行滚动的应用，其他情况下进入 tmux 复制模式 |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | 按 tmux 版本和终端区分的合理默认设置，不改动你自己设置的选项 |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | tmux 的平铺窗口管理：八种布局，包括 BSP dwindle 和 spiral，并支持撤销布局 |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | 状态栏中的本地时钟和世界时钟，按一天中的时段着色，并提供倒计时和夏令时提醒 |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | 在后台从 wttr.in 获取天气并显示在状态栏，状态栏无需等待 |

### 检查安装

所有成员都在磁盘上时，一条命令即可报告它们之间的任何冲突：

```sh
family/bin/doctor --live
```

它读取每个成员和正在运行的 tmux 服务器，报告重复的按键、重复的状态占位符、不符合命名规则的选项，以及约定版本落后的成员。

<!-- family:end -->
