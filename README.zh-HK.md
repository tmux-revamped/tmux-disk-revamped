<div align="center">

# tmux-disk-revamped

<strong>在 tmux 狀態列顯示磁碟用量，從不阻塞狀態列繪製。</strong>

[English](README.md) &nbsp;|&nbsp; [日本語](README.ja.md) &nbsp;|&nbsp; [简体中文](README.zh-Hans.md) &nbsp;|&nbsp; 繁體中文（香港）

[![Tests](https://github.com/tmux-revamped/tmux-disk-revamped/actions/workflows/tests.yml/badge.svg)](https://github.com/tmux-revamped/tmux-disk-revamped/actions/workflows/tests.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)](CHANGELOG.md)

<p align="center">
  <a href="#what-it-does">功能</a> &nbsp;|&nbsp;
  <a href="#requirements">系統要求</a> &nbsp;|&nbsp;
  <a href="#installation">安裝</a> &nbsp;|&nbsp;
  <a href="#usage">用法</a> &nbsp;|&nbsp;
  <a href="#configuration">設定</a> &nbsp;|&nbsp;
  <a href="#key-bindings">快捷鍵</a> &nbsp;|&nbsp;
  <a href="#how-it-works">運作原理</a>
</p>

</div>

**16** 個佔位符。**2** 種繪製模式。**2** 個彈出視窗。CI 在 **10** 種 Linux 及 macOS 工具鏈組合上執行測試。

---

<a id="what-it-does"></a>

## 功能

插件把 `status-left` 及 `status-right` 中的 `#{disk_*}` 佔位符替換為某個掛載點的使用率、可用空間、inode 使用率、讀寫速度、增長速度、用滿剩餘時間及使用率記錄，以及所有實體磁碟的清單。每個佔位符讀取快取在 tmux 選項中的值。`df` 在背景運行，狀態列從不等待。不會寫入任何內容到磁碟。

它亦以 `prefix + M-d` 開啟詳情彈出視窗，另有一個可選的彈出視窗列出磁碟上最大的項目，以及磁碟越過高門檻時的可選通知。

<a id="requirements"></a>

## 系統要求

| 工具 | 版本 | 用途 |
|:-----|:--------|:-----------|
| tmux | 3.2 或以上 | 兩個彈出視窗所用的 `display-popup` |
| bash | 3.2 或以上 | 所有腳本，包括 macOS 的 `/bin/bash` |
| `df`、`du` | 任何 | 用量及空間掃描，兩個平台都內置 |
| `osascript` 或 `notify-send` | 任何 | 可選，磁碟將滿的通知 |

| 數值 | Linux，x86_64 及 arm64 | macOS，Intel 及 Apple Silicon |
|:------|:------------------------|:-------------------------------|
| 使用率、已用、總量、可用 | `df -BG` | `/bin/df -g` |
| 增長速度及用滿剩餘時間 | `df -Pk` | `/bin/df -Pk` |
| inode | `df -i` | `df -i` |
| 讀寫速度 | `/proc/diskstats`，取 `/sys/block` 中的整部裝置 | 沒有 |
| 可清除空間 | 沒有 | `diskutil info` |

macOS 的讀取會呼叫 `/bin/df`，因此 `PATH` 中排在前面的 GNU coreutils 不會令它們出錯。主機沒有資料來源的數值會顯示為空。執行 `src/disk.sh doctor` 可查看本機提供了甚麼。

<a id="installation"></a>

## 安裝

### 使用 TPM

把插件及佔位符加入 `~/.tmux.conf`，然後按 `prefix + I`：

```tmux
set -g @plugin 'tmux-revamped/tmux-disk-revamped'
set -g status-right '#{disk_icon} #{disk_percentage}'
```

### 手動安裝

```bash
git clone https://github.com/tmux-revamped/tmux-disk-revamped ~/.tmux/plugins/tmux-disk-revamped
```

然後把這一行加到 `~/.tmux.conf` 中設定 `status-left` 及 `status-right` 的行之後，並重新載入 tmux：

```tmux
run-shell ~/.tmux/plugins/tmux-disk-revamped/disk-revamped.tmux
```

<a id="usage"></a>

## 用法

在 `status-left` 或 `status-right` 中寫入佔位符，插件載入時會替換它們。完整範例見 [`examples/status-right.tmux.conf`](examples/status-right.tmux.conf)。

```tmux
set -g status-right '#{disk_fg_color}#{disk_icon} #{disk_percentage}#[default] #{disk_used}/#{disk_total} '
```

| 佔位符 | 輸出 |
|:------------|:-------|
| `#{disk_percentage}` | 使用率，例如 `55%` |
| `#{disk_icon}` | 目前使用率級別的圖示 |
| `#{disk_fg_color}`、`#{disk_bg_color}` | 目前使用率級別的顏色 |
| `#{disk_used}`、`#{disk_total}`、`#{disk_free}` | 以 GB 為單位的大小，例如 `100G`，達到 1024G 後轉為 TB，例如 `1.8T` |
| `#{disk_inodes}` | inode 使用率，例如 `i12%` |
| `#{disk_purgeable}` | macOS 上 APFS 的可清除空間 |
| `#{disk_read}`、`#{disk_write}` | Linux 上的讀寫速度，例如 `1.2MB/s` |
| `#{disk_fill_rate}` | 已用空間的變化，例如 `+2.1G/h`，沒有變化時為空 |
| `#{disk_full_eta}` | 按該速度用滿的剩餘時間，例如 `3d`，沒有增長時為空 |
| `#{disk_graph}` | 最近的使用率讀數，例如 `▄▄▆▆█` |
| `#{disk_all}` | 每個已掛載的實體磁碟，例如 `/ 55%, /home 30%` |
| `#{disk_mounts}` | `@disk_revamped_mounts` 中列出的掛載點，格式相同 |

`#{disk_all}` 列出 `/dev/` 檔案系統，在 macOS 上排除 `/Volumes/`，在 Linux 上排除 `/boot` 及 `/snap`。

<a id="configuration"></a>

## 設定

| 選項 | 預設值 | 意思 |
|:-------|:--------|:--------|
| `@disk_revamped_mount` | `/` | 用量佔位符報告的掛載點；在 macOS 上 `/` 是密封的系統卷宗，如要查看你的檔案所佔的空間，請設定為 `/System/Volumes/Data` |
| `@disk_revamped_interval` | `30` | 用量讀數保持有效的秒數 |
| `@disk_revamped_detail_interval` | `60` | `#{disk_all}` 清單保持有效的秒數 |
| `@disk_revamped_render` | 空 | `options` 開啟選項繪製模式，見[運作原理](#how-it-works) |
| `@disk_revamped_percentage_format` | `%s%%` | 使用率的 printf 格式 |
| `@disk_revamped_size_format` | `%sG` | 小於 1024G 的大小的 printf 格式 |
| `@disk_revamped_medium_thresh`、`@disk_revamped_high_thresh` | `70`、`90` | 中級及高級開始的使用率百分比 |
| `@disk_revamped_low_icon` | `▰▱▱` | 低級別的圖示 |
| `@disk_revamped_medium_icon` | `▰▰▱` | 中級別的圖示 |
| `@disk_revamped_high_icon` | `▰▰▰` | 高級別的圖示 |
| `@disk_revamped_{low,medium,high}_{fg,bg}_color` | 空 | 每個級別的顏色 |
| `@disk_revamped_separator` | `, ` | `#{disk_all}` 及 `#{disk_mounts}` 中磁碟之間的文字 |
| `@disk_revamped_mounts` | 空 | `#{disk_mounts}` 的掛載點，以空格或逗號分隔 |
| `@disk_revamped_inodes_format` | `i%s%%` | `#{disk_inodes}` 的 printf 格式 |
| `@disk_revamped_history_length` | `20` | `#{disk_graph}` 保留的讀數數目 |
| `@disk_revamped_icons` | `ascii` | `nerd` 為每個指標加上 Nerd Font 字符標籤 |
| `@disk_revamped_<metric>_label` | 空 | 值不為空時顯示在某個指標前的文字；`''` 移除 `nerd` 標籤 |
| `@disk_revamped_fixed_width` | `off` | `on` 在左邊填充每個值至其最大寬度 |
| `@disk_revamped_<metric>_width` | 空 | 某個指標的填充寬度，優先於固定寬度 |
| `@disk_revamped_notify` | `0` | `1` 在使用率達到 `@disk_revamped_high_thresh` 時發出通知 |
| `@disk_revamped_popup_key` | `M-d` | 詳情彈出視窗的 prefix 按鍵；`off` 不綁定 |
| `@disk_revamped_eat_key` | 空 | 最大項目彈出視窗的 prefix 按鍵；為空時不綁定 |
| `@disk_revamped_eat_path` | 掛載點 | 空間掃描列出的目錄 |
| `@disk_revamped_eat_count` | `10` | 掃描列出的最大項目數目 |
| `@disk_revamped_eat_interval` | `60` | 掃描結果保持有效的秒數 |

除圖示及兩個顏色外，標籤適用於所有佔位符。寬度設定不會截短較長的值。

### 主題配色

顏色選項預設為空，因此設定之前插件不會加上顏色。以下每個配色把低、中、高三級分別設為綠色、黃色及紅色：

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

### 內部狀態

以下選項由插件自行寫入，請勿設定。

| 選項 | 內容 |
|:-------|:------|
| `@disk_revamped_published` | 載入時在 `status-left` 及 `status-right` 中找到的指標；inode、可清除空間、增長速度及掛載點的探測只在其指標列於此處時執行 |
| `@disk_revamped_out_<metric>` | 選項模式中每個指標發佈的值 |
| `@disk_revamped_ticker_pid` | 選項模式背景進程的 pid |
| `@disk_revamped_option_names` | 背景進程每個週期以一次呼叫讀取的選項 |
| `@disk_revamped_notified` | 發出通知後為 `1`，直至使用率降至門檻以下 |
| `@disk_revamped_history` | `#{disk_graph}` 所用的最近使用率讀數 |
| `@disk_revamped_{percent,used,total,free,all,read,write,inodes,purgeable,mounts,fill_rate,full_eta,eat}` | 快取的讀數，各附一個 `_ts` 時間戳記 |
| `@disk_revamped_{rd_raw,wr_raw,io_ts,used_raw,fill_ts}` | 計算速度所依據的上一次計數 |

<a id="key-bindings"></a>

## 快捷鍵

| 按鍵 | 操作 | 選項 |
|:----|:-------|:-------|
| `prefix + M-d` | 開啟詳情彈出視窗 | `@disk_revamped_popup_key` |
| 未綁定 | 開啟最大項目彈出視窗 | `@disk_revamped_eat_key` |

詳情彈出視窗顯示掛載點、使用率、已用、可用及總空間，以及 `#{disk_all}` 清單。最大項目彈出視窗在背景執行 `du`，只在同一個檔案系統內掃描，並包括以點開頭的項目。第一次開啟時，在結果快取之前會顯示 `Scanning`。兩個彈出視窗都按 Enter 關閉。

```tmux
set -g @disk_revamped_eat_key 'M-u'
```

<a id="how-it-works"></a>

## 運作原理

在預設的工作模式中，每個佔位符都會變成呼叫 [`src/disk.sh`](src/disk.sh) 的 `#()`。呼叫會立即輸出快取的值。當快取的用量比 `@disk_revamped_interval` 舊時，它亦會啟動一次背景更新；更新受鎖保護，並行的呼叫不會再啟動第二次。

tmux 每次重繪狀態列都會執行所有 `#()`。一條狀態列上有多個插件時，大約每秒一次。選項模式取消了這些呼叫：

```tmux
set -g @disk_revamped_render 'options'
set -g @disk_revamped_fixed_width 'on'
```

此時每個佔位符會變成類似 `#{E:@disk_revamped_out_percentage}` 的選項讀取。每個伺服器有一個背景進程，每 `@disk_revamped_interval` 秒讀取一次磁碟，以一次 tmux 呼叫寫入狀態列用到的所有值，然後只重繪一次。伺服器停止，或重新載入設定啟動了接替的進程時，它便會結束。

讀寫速度及增長速度都把每次讀數與上一次比較。掛載路徑在快取前會把每個 `#` 加倍，因此路徑無法注入 tmux 格式。

<a id="development"></a>

## 開發

| 指令 | 執行內容 |
|:--------|:-------------|
| `make test` | [`test/`](test) 下的 bats 測試 |
| `make lint` | 對所有 shell 檔案執行 shellcheck |
| `make coverage` | 在 Linux 上以 kcov 計算行覆蓋率，低於 95% 時失敗 |

<a id="license"></a>

## 授權

[MIT](LICENSE)，copyright Gustavo Franco。

<!-- family:begin -->

## tmux-revamped 插件家族

本插件是 tmux-revamped 插件家族的成員。每個成員都帶有 [`FAMILY.md`](FAMILY.md) 中的同一份約定、`family/` 下的同一套工具和同一個共用程式庫，並由校驗和清單確保逐位元組一致。這些成員可以一併安裝：任何成員都不會佔用其他成員使用的按鍵或 tmux 選項。

在一個成員中發現的缺陷，要在全部成員中排查後才算修正完成。這項責任寫在約定之中，而不是依靠記憶，`family/bin/sweep` 負責執行。

| 成員 | 功能 |
|---|---|
| [`tmux-autoreload-revamped`](https://github.com/tmux-revamped/tmux-autoreload-revamped) | 編輯並儲存 tmux 設定後，它會自動重新載入，毋須按鍵，也毋須指令 |
| [`tmux-battery-revamped`](https://github.com/tmux-revamped/tmux-battery-revamped) | 在 tmux 狀態列顯示電池狀態，從不阻塞狀態列繪製 |
| [`tmux-bluetooth-revamped`](https://github.com/tmux-revamped/tmux-bluetooth-revamped) | 在 tmux 狀態列顯示每部已連接的藍牙裝置及其電量，不阻塞繪製 |
| [`tmux-cpu-revamped`](https://github.com/tmux-revamped/tmux-cpu-revamped) | 在 tmux 狀態列顯示 CPU 負載、溫度及頻率，從不阻塞繪製 |
| [`tmux-disk-revamped`](https://github.com/tmux-revamped/tmux-disk-revamped) | **本插件**，在 tmux 狀態列顯示磁碟用量，從不阻塞狀態列繪製 |
| [`tmux-extract-revamped`](https://github.com/tmux-revamped/tmux-extract-revamped) | 用 fzf 從畫面上揀選 URL、路徑、雜湊值或任何其他字詞，並輸入到游標位置，全部以純 shell 實現 |
| [`tmux-fzf-revamped`](https://github.com/tmux-revamped/tmux-fzf-revamped) | 在彈出視窗的 fzf 選擇器中切換、關閉、重新命名或建立 tmux 工作階段、視窗和窗格 |
| [`tmux-git-revamped`](https://github.com/tmux-revamped/tmux-git-revamped) | 在 tmux 狀態列顯示當前窗格的 git 分支、改動和託管平台數目，而不會阻塞顯示 |
| [`tmux-gpu-revamped`](https://github.com/tmux-revamped/tmux-gpu-revamped) | 在 tmux 狀態列顯示 NVIDIA、AMD、Intel 及 Apple GPU 的負載、溫度、時脈、功耗及記憶體 |
| [`tmux-kube-revamped`](https://github.com/tmux-revamped/tmux-kube-revamped) | 在 tmux 狀態列顯示目前的 Kubernetes 上下文及命名空間，毋須 kubectl，直接解析 kubeconfig |
| [`tmux-launcher-revamped`](https://github.com/tmux-revamped/tmux-launcher-revamped) | 在彈出視窗或新視窗中啟動任何 TUI 應用程式，從目前窗格的目錄開始，每個應用程式可設定一個按鍵 |
| [`tmux-logging-revamped`](https://github.com/tmux-revamped/tmux-logging-revamped) | 將任何窗格儲存到檔案：即時記錄、完整捲動緩衝區或一次性截圖 |
| [`tmux-music-revamped`](https://github.com/tmux-revamped/tmux-music-revamped) | 在 tmux 狀態列顯示正在播放的歌曲，從不阻塞狀態列的繪製 |
| [`tmux-network-revamped`](https://github.com/tmux-revamped/tmux-network-revamped) | 在 tmux 狀態列顯示網絡傳輸量，從不阻塞繪製 |
| [`tmux-pain-control-revamped`](https://github.com/tmux-revamped/tmux-pain-control-revamped) | tmux 的窗格和視窗管理按鍵，配合 tmux 版本，與 vim 相容，每個 prefix 按鍵都可停用 |
| [`tmux-persist-revamped`](https://github.com/tmux-revamped/tmux-persist-revamped) | 儲存 tmux 的所有工作階段、視窗及窗格，按計時器自動儲存，並在重新開機後全部還原 |
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | tmux-revamped 插件的起點：共用程式庫、bats 測試框架、CI 和系列工具 |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | tmux 狀態列中的番茄鐘計時器，所有狀態都儲存在 tmux 選項中，不使用暫存檔 |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | 在 tmux 狀態列顯示記憶體、交換空間及記憶體壓力，在背景取樣，繪製從不等待 |
| [`tmux-reorder-revamped`](https://github.com/tmux-revamped/tmux-reorder-revamped) | 用滑鼠在 tmux 狀態列上拖動視窗標籤來移動該視窗 |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | 將滑鼠滾輪交給能自行捲動的應用程式，其他情況下進入 tmux 複製模式 |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | 按 tmux 版本和終端機區分的合理預設設定，不會改動你自己設定的選項 |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | tmux 的平鋪視窗管理：八種版面，包括 BSP dwindle 和 spiral，並支援復原版面 |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | 狀態列中的本地時鐘和世界時鐘，按一天中的時段著色，並提供倒數和夏令時間提示 |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | 在背景從 wttr.in 取得天氣並顯示在狀態列，狀態列毋須等待 |

### 檢查安裝

所有成員都在磁碟上時，一個指令即可報告它們之間的任何衝突：

```sh
family/bin/doctor --live
```

它讀取每個成員和正在運行的 tmux 伺服器，報告重複的按鍵、重複的狀態佔位符、不符合命名規則的選項，以及約定版本落後的成員。

<!-- family:end -->
