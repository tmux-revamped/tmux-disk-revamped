<div align="center">

# tmux-disk-revamped

<strong>在 tmux 狀態列顯示磁碟用量，絕不阻塞狀態列繪製。</strong>

[English](README.md) &nbsp;|&nbsp; [日本語](README.ja.md) &nbsp;|&nbsp; [简体中文](README.zh-Hans.md) &nbsp;|&nbsp; 繁體中文（香港）

[![ci](https://img.shields.io/github/actions/workflow/status/tmux-revamped/tmux-disk-revamped/ci.yml?branch=main&style=flat-square&label=ci)](https://github.com/tmux-revamped/tmux-disk-revamped/actions/workflows/ci.yml)
[![release](https://img.shields.io/github/v/release/tmux-revamped/tmux-disk-revamped?style=flat-square&label=release)](https://github.com/tmux-revamped/tmux-disk-revamped/releases/latest)
[![openssf scorecard](https://img.shields.io/ossf-scorecard/github.com/tmux-revamped/tmux-disk-revamped?style=flat-square&label=openssf%20scorecard)](https://scorecard.dev/viewer/?uri=github.com/tmux-revamped/tmux-disk-revamped)
[![license](https://img.shields.io/github/license/tmux-revamped/tmux-disk-revamped?style=flat-square&label=license)](LICENSE)

<p align="center">
  <a href="#quick-start"><strong>快速開始</strong></a> &nbsp;|&nbsp;
  <a href="#usage">使用</a> &nbsp;|&nbsp;
  <a href="#how-it-works">運作原理</a> &nbsp;|&nbsp;
  <a href="#screens">截圖</a>
</p>

</div>

<p align="center">
  <img src="screens/hero.gif" alt="disk-revamped 展示按層級着色的用量和容量、開啟詳情彈窗、切換到 Nerd Font 標籤、帶增長速度的圖表以及 options 繪製模式" width="800">
</p>

```console
$ disk-revamped refresh
Refreshed. 45% of / is used.
$ disk-revamped status percentage
45%
```

**16** 個佔位符，**2** 種繪製模式，**2** 個彈窗，支援 macOS 和 Linux，需要 tmux **3.2** 或以上版本。

---

<a id="quick-start"></a>

## 快速開始

### 前提條件

| 工具 | 版本 | 用途 |
|:----|:----|:----|
| tmux | 3.2 或以上 | 家族的最低版本，以及彈窗 |
| gum | 可選 | `disk-revamped` 的選單、表格和顏色；沒有它時所有指令輸出純文字 |
| `df`、`du`、`sort` | 任意 | 用量和掃描，兩個平台都內建 |
| `osascript` 或 `notify-send` | 可選 | 達到高閾值時的通知 |

它可以在使用 BSD、GNU、uutils 或 BusyBox 工具的 Linux 和 macOS 上執行。每個數值都來自系統內建的工具：

| 數值 | Linux | macOS |
|:----|:------|:------|
| 用量、已用、總量、可用、增長速度 | `df -Pk` | `/bin/df -Pk` |
| inode | `df -i` | `/bin/df -i` |
| 所有磁碟 | `df -h` | `/bin/df -h` |
| 讀寫速度 | `/proc/diskstats`，來自 `/sys/block` 的整碟裝置 | 無 |
| 可清除空間 | 無 | `diskutil info` |

macOS 讀取 `/bin/df`，因此 `PATH` 裏 GNU coreutils 排在前面也不受影響。缺少來源時對應的佔位符為空，`disk-revamped doctor` 會指出。

### 安裝

使用 [TPM](https://github.com/tmux-plugins/tpm) 時，把插件加入 `~/.tmux.conf`，然後按 `prefix + I`：

```tmux
set -g @plugin 'tmux-revamped/tmux-disk-revamped'
```

手動安裝時，複製儲存庫，並在 `~/.tmux.conf` 中執行入口檔案：

```bash
git clone https://github.com/tmux-revamped/tmux-disk-revamped ~/.tmux/plugins/tmux-disk-revamped
```

```tmux
run-shell ~/.tmux/plugins/tmux-disk-revamped/disk-revamped.tmux
```

請在插件載入之前設定 `status-left` 或 `status-right`。插件在載入時只替換一次其中的佔位符。

在複製的目錄裏執行 `make install`，還會把 `disk-revamped` 放到 `~/.local/bin`，手冊頁和補全放到 `~/.local/share`。

### 驗證

```bash
~/.tmux/plugins/tmux-disk-revamped/bin/disk-revamped doctor
```

<a id="usage"></a>

## 使用

插件顯示磁碟用了多少，包括已用、可用和總空間、inode 用量、最近讀數的圖表、增長速度、寫滿所需時間以及所有磁碟的列表。狀態列列印 tmux 已持有的值，由背景讀取來更新它。

| 佔位符 | 輸出 |
|:----|:----|
| `#{disk_percentage}` | 已用百分比，例如 `55%` |
| `#{disk_icon}` | 目前用量層級的圖示 |
| `#{disk_fg_color}` | 用量層級的前景樣式 |
| `#{disk_bg_color}` | 用量層級的背景樣式 |
| `#{disk_used}` | 已用空間，單位 G，例如 `55G`，從 1024G 起用 T，例如 `1.8T` |
| `#{disk_total}` | 總空間，形式相同 |
| `#{disk_free}` | 可用空間，形式相同 |
| `#{disk_read}` | Linux 上的讀取速度，例如 `1.2MB/s`；macOS 上為空 |
| `#{disk_write}` | Linux 上的寫入速度，形式相同；macOS 上為空 |
| `#{disk_all}` | 所有已掛載的真實磁碟，例如 `/ 55%, /data 30%` |
| `#{disk_inodes}` | inode 用量，例如 `i12%` |
| `#{disk_purgeable}` | macOS 上 APFS 的可清除空間；Linux 上為空 |
| `#{disk_graph}` | 最近的用量讀數，例如 `▄▄▆▆█` |
| `#{disk_fill_rate}` | 已用空間的變化，例如 `+2.1G/h`，穩定時為空 |
| `#{disk_full_eta}` | 按該速度寫滿所需的時間，例如 `3d`，未在增長時為空 |
| `#{disk_mounts}` | `@disk_revamped_mounts` 中指定的掛載點，形式與 `#{disk_all}` 相同 |

把佔位符放進狀態列：

```tmux
set -g @disk_revamped_low_fg_color '#[fg=green]'
set -g @disk_revamped_medium_fg_color '#[fg=yellow]'
set -g @disk_revamped_high_fg_color '#[fg=red]'

set -g status-right '#{disk_fg_color}#{disk_icon} #{disk_percentage}#[default] #{disk_used}/#{disk_total} '
```

同一個示例加上幾個選項，見 [examples/status-right.tmux.conf](examples/status-right.tmux.conf)。

### 標籤和寬度

`@disk_revamped_<metric>_label` 在某個指標的值不為空時，在它之前列印圖示或文字。把 `@disk_revamped_icons` 設為 `nerd`，會給下面每個指標加上 Nerd Font 圖示。指標自己的標籤優先於整套圖示，留空的標籤表示預設值，所以圖示仍然保留。預設的 `ascii` 不加標籤。指標有 `percentage`、`used`、`total`、`free`、`read`、`write`、`inodes`、`purgeable`、`graph`、`fill_rate`、`full_eta`、`mounts` 和 `all`，在指令選項中用連字號書寫，例如 `--fill-rate-label`。

| 指標 | `nerd` 圖示 |
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

把 `@disk_revamped_fixed_width` 設為 `on`，會把每個數值在左側補到自然寬度：用量和 inode 為四個字元，讀寫速度為九個字元，所以從 `9%` 變成 `42%` 時其餘部分不會移位。`@disk_revamped_<metric>_width` 設定單個指標的寬度，並優先於固定寬度。更長的值不會被截斷。

### 繪製模式

預設情況下每個佔位符變成一次 `#()` 呼叫，tmux 在每次重繪狀態列時重新執行它。把 `@disk_revamped_render` 設為 `options` 後，每個佔位符變成對選項的讀取，例如 `#{E:@disk_revamped_out_percentage}`。每個伺服器隨後由一個背景程序每隔 `@disk_revamped_interval` 秒讀取磁碟，並用一次 tmux 呼叫寫入所有值，所以它們同時變化。

```tmux
set -g @disk_revamped_render 'options'
set -g @disk_revamped_fixed_width 'on'
```

### 層級顏色

層級樣式預設為空，所以在你設定之前 `#{disk_fg_color}` 和 `#{disk_bg_color}` 不會輸出任何內容。下面的配色把低對應為綠色，中為黃色，高為紅色：

| 主題 | 低 | 中 | 高 |
|:----|:----|:----|:----|
| Catppuccin Mocha | `#a6e3a1` | `#f9e2af` | `#f38ba8` |
| Dracula | `#50fa7b` | `#f1fa8c` | `#ff5555` |
| Nord | `#a3be8c` | `#ebcb8b` | `#bf616a` |
| Gruvbox Dark | `#b8bb26` | `#fabd2f` | `#fb4934` |
| Tokyo Night | `#9ece6a` | `#e0af68` | `#f7768e` |
| Solarized Dark | `#859900` | `#b58900` | `#dc322f` |

每個值放進一個樣式裏，例如 `set -g @disk_revamped_low_fg_color '#[fg=#a6e3a1]'`。

| 指令 | 作用 |
|:----|:----|
| `disk-revamped apply` | 綁定彈窗按鍵並立即填充佔位符；入口檔案在 tmux 載入插件時執行它 |
| `disk-revamped list` | 列印 `apply` 會發送的所有指令，不做任何改動；`--json` 輸出一個物件 |
| `disk-revamped status NAME` | 列印一個佔位符，例如 `percentage`、`used` 或 `graph`；狀態列執行它 |
| `disk-revamped refresh` | 立即讀取磁碟並說明用了多少 |
| `disk-revamped card` | 立即讀取全部內容，每個數值一行，然後是所有磁碟，按終端機大小裁剪 |
| `disk-revamped scan` | 列出掃描路徑下最大的項目及其大小 |
| `disk-revamped popup` | 在 tmux 彈窗中開啟卡片；彈窗按鍵執行它 |
| `disk-revamped eat` | 在 tmux 彈窗中開啟掃描；eat 按鍵執行它 |
| `disk-revamped daemon` | 為 `options` 繪製模式在每個週期發佈佔位符；`apply` 會啟動它 |
| `disk-revamped doctor` | 每個依賴一行：各數值的來源工具或檔案、終端機大小、通知方式以及被放過的按鍵 |
| `disk-revamped version` | 版本，然後是 tmux 版本 |
| `disk-revamped help` | 說明頁；`man disk-revamped` 記錄相同的指令和設定 |
| `disk-revamped` | 在終端機中顯示選單 |

<a id="configuration"></a>

## 設定

每個選項也是帶連字號的指令選項，例如 `--interval 2`，也是環境變數，例如 `DISK_REVAMPED_INTERVAL`；指令列優先於環境變數，環境變數優先於 tmux 選項。空的 tmux 選項表示預設值，指令列或環境變數中的空值按原樣使用。`doctor` 會指出持有插件不認識的值的設定。傳給 `apply` 的設定會帶到按鍵和每一次狀態呼叫上。

### 讀取

| 選項 | 預設值 | 含義 |
|:----|:----|:----|
| `@disk_revamped_mount` | `/` | 用量類佔位符報告的掛載點；macOS 上 `/` 是唯讀的系統卷，設為 `/System/Volumes/Data` 才能看到你的檔案佔用的空間 |
| `@disk_revamped_mounts` | empty | `#{disk_mounts}` 的掛載點，空格或逗號分隔；不存在的會被忽略 |
| `@disk_revamped_interval` | `30` | 讀數保持新鮮的秒數 |
| `@disk_revamped_detail_interval` | `60` | 所有磁碟列表保持新鮮的秒數 |
| `@disk_revamped_render` | `jobs` | `options` 讀取已發布的選項，而不是執行 `#()` 呼叫；其他值都按 `jobs` 處理 |
| `@disk_revamped_history_length` | `20` | `#{disk_graph}` 保留的讀數個數 |
| `@disk_revamped_notify` | `0` | `1` 表示用量達到 `@disk_revamped_high_thresh` 時發送通知，回落後再次達到時會再發 |

### 層級

| 選項 | 預設值 | 含義 |
|:----|:----|:----|
| `@disk_revamped_medium_thresh` | `70` | 層級變為中的用量百分比 |
| `@disk_revamped_high_thresh` | `90` | 層級變為高的用量百分比，也是發送通知的閾值 |
| `@disk_revamped_low_icon` | `▰▱▱` | 低層級的圖示 |
| `@disk_revamped_medium_icon` | `▰▰▱` | 中層級的圖示 |
| `@disk_revamped_high_icon` | `▰▰▰` | 高層級的圖示 |
| `@disk_revamped_low_fg_color` | empty | 低層級的前景樣式，例如 `#[fg=green]` |
| `@disk_revamped_medium_fg_color` | empty | 中層級的前景樣式 |
| `@disk_revamped_high_fg_color` | empty | 高層級的前景樣式 |
| `@disk_revamped_low_bg_color` | empty | 低層級的背景樣式 |
| `@disk_revamped_medium_bg_color` | empty | 中層級的背景樣式 |
| `@disk_revamped_high_bg_color` | empty | 高層級的背景樣式 |

### 格式和標籤

| 選項 | 預設值 | 含義 |
|:----|:----|:----|
| `@disk_revamped_percentage_format` | `%s%%` | 用量的 printf 格式 |
| `@disk_revamped_size_format` | `%sG` | 低於 1024G 的容量的 printf 格式；從 1024G 起是帶一位小數的 T |
| `@disk_revamped_inodes_format` | `i%s%%` | `#{disk_inodes}` 的 printf 格式 |
| `@disk_revamped_separator` | `, ` | `#{disk_all}` 和 `#{disk_mounts}` 中磁碟之間的文字 |
| `@disk_revamped_icons` | `ascii` | `nerd` 給每個值加上 Nerd Font 圖示 |
| `@disk_revamped_<metric>_label` | empty | 列印在某個值之前的文字，僅在值不為空時 |
| `@disk_revamped_fixed_width` | `off` | `on` 把每個數值在左側補到自然寬度，從 `9%` 變成 `42%` 時其餘部分不會移位 |
| `@disk_revamped_<metric>_width` | empty | 把某個值補到這個字元數。更長的值不會被截斷 |

### 按鍵和掃描

| 選項 | 預設值 | 含義 |
|:----|:----|:----|
| `@disk_revamped_popup_key` | `M-d` | 開啟詳情彈窗的前綴鍵。`off` 表示不綁定 |
| `@disk_revamped_eat_key` | empty | 開啟最大項目彈窗的前綴鍵；留空或 `off` 表示不綁定 |
| `@disk_revamped_eat_path` | the mount | 掃描所列出的資料夾 |
| `@disk_revamped_eat_count` | `10` | 掃描列出多少個最大的項目 |
| `@disk_revamped_eat_interval` | `60` | 掃描結果保持新鮮的秒數 |

### 內部狀態

插件自己寫入這些選項，請不要設定它們。

| 選項 | 內容 |
|:----|:----|
| `@disk_revamped_published` | 狀態列使用的指標，載入時記錄，只讀取這些 |
| `@disk_revamped_history` | `#{disk_graph}` 背後的最近讀數 |
| `@disk_revamped_out_<metric>` | options 模式下每個指標的繪製結果 |
| `@disk_revamped_ticker_pid` | options 模式背景程序的程序號 |
| `@disk_revamped_notified` | 發出通知後為 `1`，直到用量回落到閾值以下 |
| `@disk_revamped_percent` and the other figures, `_ts`, `_lock` | 儲存的讀數、每次讀取的時間和更新鎖；`@disk_revamped_mounts_list` 儲存設定 `@disk_revamped_mounts` 的讀數 |

## 按鍵綁定

| 按鍵 | 作用 | 預設 |
|:----|:----|:----|
| `prefix + M-d` | 在彈窗中開啟卡片：各數值和所有磁碟，按彈窗大小裁剪。按 Enter 關閉 | 已綁定 |
| 未綁定 | 開啟最大項目彈窗。按 Enter 關閉 | `@disk_revamped_eat_key` |

`@disk_revamped_popup_key` 可以指定另一個按鍵，`off` 表示不綁定。當預設按鍵已被別的功能佔用時會被放過，`disk-revamped doctor` 會說明。`@disk_revamped_eat_key` 綁定最大項目彈窗，需要自行啟用。

```tmux
set -g @disk_revamped_eat_key 'M-u'
```

<a id="how-it-works"></a>

## 運作原理

[`disk-revamped.tmux`](disk-revamped.tmux) 在 tmux 載入插件時執行一次。它把 `status-left` 和 `status-right` 用到的指標記錄到 `@disk_revamped_published`，然後把每個佔位符替換為對 [`bin/disk-revamped`](bin/disk-revamped) 的呼叫，在 `options` 模式下則替換為對選項的讀取並啟動背景程序。

在預設模式下，每個 `#()` 呼叫立即返回已儲存的讀數。讀數超過間隔後，呼叫會在背景啟動一次更新並加鎖，所以同一時間只有一次更新在執行。一次 `df -Pk` 給出用量和容量，容量向上取整到整數 G；inode、可清除空間、分碟速度、增長速度和磁碟列表讀取成本更高，所以只在狀態列用到對應佔位符時才執行。一個 `awk` 把讀數轉換成所有數值，一次 tmux 呼叫把它們儲存起來。

讀寫速度和增長速度把每次讀數與上一次比較。掛載路徑來自外部，所以其中的每個 `#` 在到達狀態列之前都會加倍。讀取、數值和格式化位於 [`lib/disk.sh`](lib/disk.sh)，設定表位於 [`lib/state.sh`](lib/state.sh)。

<a id="screens"></a>

## 截圖

<details>
<summary>每一張截圖都在真實的 tmux 中用 <code>make screens</code> 錄製，並在狀態列上顯示每個按鍵</summary>
<br>

<table>
<tr>
<td width="50%" valign="top"><img src="screens/status.png" alt="disk-revamped: 帶層級圖示和顏色的用量，以及容量和可用空間"><br><sub>帶層級圖示和顏色的用量，以及容量和可用空間，來自 <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/popup.png" alt="disk-revamped: prefix M-d 在彈窗中開啟詳情卡片"><br><sub><code>prefix M-d</code> 在彈窗中開啟詳情卡片，來自 <code>hero.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/icons.png" alt="disk-revamped: @disk_revamped_icons 設為 nerd 會給每個指標加上圖示"><br><sub><code>@disk_revamped_icons</code> 設為 <code>nerd</code> 會給每個指標加上圖示，來自 <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/graph.png" alt="disk-revamped: 圖表、用量、增長速度和寫滿所需時間"><br><sub>圖表、用量、增長速度和寫滿所需時間，來自 <code>hero.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/options.png" alt="disk-revamped: 在 options 繪製模式下，每個佔位符讀取一個 tmux 選項"><br><sub>在 <code>options</code> 繪製模式下，每個佔位符讀取一個 tmux 選項，來自 <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/card.png" alt="disk-revamped: card 列印每個數值和每個磁碟"><br><sub><code>card</code> 列印每個數值和每個磁碟，來自 <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/sizes.png" alt="disk-revamped: 已用、可用和總空間，以及 macOS 上的可清除空間"><br><sub>已用、可用和總空間，以及 macOS 上的可清除空間，來自 <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/size-format.png" alt="disk-revamped: @disk_revamped_size_format 決定低於 1024G 的容量格式"><br><sub><code>@disk_revamped_size_format</code> 決定低於 1024G 的容量格式，來自 <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/colors.png" alt="disk-revamped: 自訂的層級圖示和顏色"><br><sub>自訂的層級圖示和顏色，來自 <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/tiers.png" alt="disk-revamped: @disk_revamped_medium_thresh、@disk_revamped_high_thresh 和各層級圖示"><br><sub><code>@disk_revamped_medium_thresh</code>、<code>@disk_revamped_high_thresh</code> 和各層級圖示，來自 <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/format.png" alt="disk-revamped: @disk_revamped_percentage_format 決定用量的格式"><br><sub><code>@disk_revamped_percentage_format</code> 決定用量的格式，來自 <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/inodes-format.png" alt="disk-revamped: inode 用量和 @disk_revamped_inodes_format"><br><sub>inode 用量和 <code>@disk_revamped_inodes_format</code>，來自 <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/fixed.png" alt="disk-revamped: @disk_revamped_fixed_width 把每個數值補到自然寬度"><br><sub><code>@disk_revamped_fixed_width</code> 把每個數值補到自然寬度，來自 <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/width.png" alt="disk-revamped: @disk_revamped_inodes_width 把單個指標補到自己的寬度"><br><sub><code>@disk_revamped_inodes_width</code> 把單個指標補到自己的寬度，來自 <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/labels.png" alt="disk-revamped: 單個指標之前的自訂標籤"><br><sub>單個指標之前的自訂標籤，來自 <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/mounts.png" alt="disk-revamped: @disk_revamped_mounts 列出你指定的掛載點"><br><sub><code>@disk_revamped_mounts</code> 列出你指定的掛載點，來自 <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/separator.png" alt="disk-revamped: @disk_revamped_separator 位於磁碟之間"><br><sub><code>@disk_revamped_separator</code> 位於磁碟之間，來自 <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/all.png" alt="disk-revamped: 一個佔位符顯示所有磁碟"><br><sub>一個佔位符顯示所有磁碟，來自 <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/mount.png" alt="disk-revamped: @disk_revamped_mount 選擇用量報告的掛載點"><br><sub><code>@disk_revamped_mount</code> 選擇用量報告的掛載點，來自 <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/history.png" alt="disk-revamped: @disk_revamped_history_length 決定圖表保留多少讀數"><br><sub><code>@disk_revamped_history_length</code> 決定圖表保留多少讀數，來自 <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/fill.png" alt="disk-revamped: 增長速度和寫滿所需時間"><br><sub>增長速度和寫滿所需時間，來自 <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/notify.png" alt="disk-revamped: @disk_revamped_notify 在達到高閾值時發送通知"><br><sub><code>@disk_revamped_notify</code> 在達到高閾值時發送通知，來自 <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/popup-key.png" alt="disk-revamped: @disk_revamped_popup_key 為彈窗指定另一個按鍵"><br><sub><code>@disk_revamped_popup_key</code> 為彈窗指定另一個按鍵，來自 <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/eat.png" alt="disk-revamped: @disk_revamped_eat_key 開啟最大項目彈窗，由 @disk_revamped_eat_path、@disk_revamped_eat_count 和 @disk_revamped_eat_interval 調整"><br><sub><code>@disk_revamped_eat_key</code> 開啟最大項目彈窗，由 <code>@disk_revamped_eat_path</code>、<code>@disk_revamped_eat_count</code> 和 <code>@disk_revamped_eat_interval</code> 調整，來自 <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/version.png" alt="disk-revamped: 版本"><br><sub>版本，來自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/error.png" alt="disk-revamped: 未知指令"><br><sub>未知指令，來自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/status-command.png" alt="disk-revamped: status percentage 和 status graph 各列印一個佔位符"><br><sub><code>status percentage</code> 和 <code>status graph</code> 各列印一個佔位符，來自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/refresh.png" alt="disk-revamped: refresh 立即讀取磁碟"><br><sub><code>refresh</code> 立即讀取磁碟，來自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/list.png" alt="disk-revamped: list 列印每一個綁定"><br><sub><code>list</code> 列印每一個綁定，來自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/json.png" alt="disk-revamped: list --json 把同一個計畫作為一個物件列印"><br><sub><code>list --json</code> 把同一個計畫作為一個物件列印，來自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/doctor.png" alt="disk-revamped: doctor"><br><sub><code>doctor</code>，來自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/menu.png" alt="disk-revamped: 選單"><br><sub>選單，來自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/menu-card.png" alt="disk-revamped: 從選單開啟的卡片"><br><sub>從選單開啟的卡片，來自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/scan.png" alt="disk-revamped: scan 列出最大的項目"><br><sub><code>scan</code> 列出最大的項目，來自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/accent.png" alt="disk-revamped: 來自 DISK_REVAMPED_ACCENT 的強調色"><br><sub>來自 <code>DISK_REVAMPED_ACCENT</code> 的強調色，來自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/plain-menu.png" alt="disk-revamped: 沒有 gum 的選單"><br><sub>沒有 gum 的選單，來自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/plain-card.png" alt="disk-revamped: 沒有 gum 時從選單開啟的 card"><br><sub>沒有 gum 時從選單開啟的 <code>card</code>，來自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/plain-doctor.png" alt="disk-revamped: 沒有 gum 的 doctor"><br><sub>沒有 gum 的 <code>doctor</code>，來自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/themes.png" alt="disk-revamped: 六個主題下的標題"><br><sub>六個主題下的標題，來自 <code>themes.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/help.png" alt="disk-revamped: 說明頁"><br><sub>說明頁，來自 <code>help.tape</code></sub></td>
</tr>
</table>

錄製執行的是真實的插件和 tmux。`df`、`diskutil`、`osascript` 和 `du` 由小指令碼代替，所以畫面上的數值來自它們。錄製在 macOS 上進行，macOS 沒有分碟計數器，所以 `#{disk_read}` 和 `#{disk_write}` 在那裏不顯示內容。`@disk_revamped_interval` 和 `@disk_revamped_detail_interval` 設定在錄製用的 tmux 設定中。

</details>

## 可移植性

插件使用 POSIX `sh`。CI 在下面每一行上執行所有測試套件。

| Shell | 狀態 |
|:------|:----|
| `dash`、macOS 上的 `/bin/sh` | 支援 |
| `bash` 3.2 和 5.x，系統內建的 `zsh` 和 Homebrew 的 `zsh` | 支援 |

| 系統 | 狀態 |
|:----|:----|
| macOS | Apple Silicon 和 Intel 上的 Tahoe，分別使用系統內建工具、Homebrew 的 GNU 工具和 Homebrew 的 uutils |
| Linux | x86_64 和 arm64 上的 Ubuntu 26.04，分別使用 GNU coreutils、uutils 和 BusyBox |

## 開發

| 指令 | 執行內容 |
|:----|:-----|
| `make fmt` | 對每個指令碼執行 shfmt `-i 2` |
| `make lint` | shfmt、ShellCheck、mandoc、yamllint 和 actionlint，結果必須為零 |
| `make test` | 用系統 `sh` 執行 bats 測試套件 |
| `make test-all` | 用每個已安裝的 shell 執行套件，macOS 上包括 bash 和 zsh 的兩種版本 |
| `make test-linux` | 在 Ubuntu 容器中執行套件 |
| `make coverage` | 在這部 Mac 和 Ubuntu 容器中執行 bashcov，合併後要求達到 100% |
| `make screens` | 在 macOS 上用 VHS 在 tmux 中錄製上面的截圖，執行的是真實的插件 |
| `make install` | 把指令、手冊頁和補全安裝到 `PREFIX` 下 |

在 macOS 上，`brew bundle` 會按 [`Brewfile`](Brewfile) 安裝這些目標呼叫的所有工具。

提交遵循 Conventional Commits 格式，直接進入 `main`。`main` 上的 `ci` 通過後，`release.yml` 執行 semantic-release：自上一個標籤以來的每個 `feat` 或 `fix` 都會發佈一個版本，更新版本常數，並把說明加入 [`CHANGELOG.md`](CHANGELOG.md)。

## 授權

[MIT](LICENSE)，copyright Gustavo Franco。

<!-- family:begin -->

## tmux-revamped 插件家族

這個插件是 tmux-revamped 插件家族的一員。每個成員都帶有 [`FAMILY.md`](FAMILY.md) 中相同的約定和相同的共用程式庫，並且設計為一起安裝：沒有成員佔用另一個成員佔用的按鍵或 tmux 選項。

在一個成員中發現的缺陷，要在全部成員中排查後才算修正完成。

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
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | tmux-revamped 插件的起點：共用程式庫、bats 測試框架和 CI |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | tmux 狀態列中的番茄鐘計時器，所有狀態都儲存在 tmux 選項中，不使用暫存檔 |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | 在 tmux 狀態列顯示記憶體、交換空間及記憶體壓力，在背景取樣，繪製從不等待 |
| [`tmux-reorder-revamped`](https://github.com/tmux-revamped/tmux-reorder-revamped) | 用滑鼠在 tmux 狀態列上拖動視窗標籤來移動該視窗 |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | 將滑鼠滾輪交給能自行捲動的應用程式，其他情況下進入 tmux 複製模式 |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | 按 tmux 版本和終端機區分的合理預設設定，不會改動你自己設定的選項 |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | tmux 的平鋪視窗管理：八種版面，包括 BSP dwindle 和 spiral，並支援復原版面 |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | 狀態列中的本地時鐘和世界時鐘，按一天中的時段著色，並提供倒數和夏令時間提示 |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | 在背景從 wttr.in 取得天氣並顯示在狀態列，狀態列毋須等待 |

<!-- family:end -->
