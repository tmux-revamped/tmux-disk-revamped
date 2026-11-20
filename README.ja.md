<div align="center">

# tmux-disk-revamped

<strong>tmuxのステータスバーにディスク使用量を表示し、ステータスの描画を一切止めません。</strong>

[English](README.md) &nbsp;|&nbsp; 日本語 &nbsp;|&nbsp; [简体中文](README.zh-Hans.md) &nbsp;|&nbsp; [繁體中文（香港）](README.zh-HK.md)

[![ci](https://img.shields.io/github/actions/workflow/status/tmux-revamped/tmux-disk-revamped/ci.yml?branch=main&style=flat-square&label=ci)](https://github.com/tmux-revamped/tmux-disk-revamped/actions/workflows/ci.yml)
[![release](https://img.shields.io/github/v/release/tmux-revamped/tmux-disk-revamped?style=flat-square&label=release)](https://github.com/tmux-revamped/tmux-disk-revamped/releases/latest)
[![openssf scorecard](https://img.shields.io/ossf-scorecard/github.com/tmux-revamped/tmux-disk-revamped?style=flat-square&label=openssf%20scorecard)](https://scorecard.dev/viewer/?uri=github.com/tmux-revamped/tmux-disk-revamped)
[![license](https://img.shields.io/github/license/tmux-revamped/tmux-disk-revamped?style=flat-square&label=license)](LICENSE)

<p align="center">
  <a href="#quick-start"><strong>クイックスタート</strong></a> &nbsp;|&nbsp;
  <a href="#usage">使い方</a> &nbsp;|&nbsp;
  <a href="#how-it-works">仕組み</a> &nbsp;|&nbsp;
  <a href="#screens">スクリーン</a>
</p>

</div>

<p align="center">
  <img src="screens/hero.gif" alt="階層で色分けした使用率と容量の表示、詳細ポップアップ、Nerd Fontラベルへの切り替え、増加速度付きのグラフ、optionsレンダーモードを示すdisk-revamped" width="800">
</p>

```console
$ disk-revamped refresh
Refreshed. 45% of / is used.
$ disk-revamped status percentage
45%
```

プレースホルダー**16**個、レンダーモード**2**種類、ポップアップ**2**種類、macOSとLinux、tmux **3.2**以降。

---

<a id="quick-start"></a>

## クイックスタート

### 前提条件

| ツール | バージョン | 用途 |
|:----|:------|:----|
| tmux | 3.2以降 | ファミリーの下限、およびポップアップ |
| gum | 任意 | `disk-revamped`のメニュー、表、色。なければすべてのコマンドが平文で出力 |
| `df`、`du`、`sort` | 任意 | 使用量とスキャン。どちらのプラットフォームにも標準搭載 |
| `osascript`または`notify-send` | 任意 | 高の閾値での通知 |

BSD、GNU、uutils、BusyBoxのツールを使うLinuxとmacOSで動作します。各値はOSに標準で入っているものから取得します。

| 値 | Linux | macOS |
|:----|:------|:------|
| 使用率、使用量、総容量、空き容量、増加速度 | `df -Pk` | `/bin/df -Pk` |
| inode | `df -i` | `/bin/df -i` |
| すべてのディスク | `df -h` | `/bin/df -h` |
| 読み書きの速度 | `/proc/diskstats`、`/sys/block`のデバイス全体 | なし |
| パージ可能な容量 | なし | `diskutil info` |

macOSは`/bin/df`を読むため、`PATH`の先頭にGNU coreutilsがあっても影響しません。情報源がなければプレースホルダーは空になり、`disk-revamped doctor`がそれを示します。

### インストール

[TPM](https://github.com/tmux-plugins/tpm)を使う場合は、`~/.tmux.conf`にプラグインを追加して`prefix + I`を押します。

```tmux
set -g @plugin 'tmux-revamped/tmux-disk-revamped'
```

手動でインストールするには、リポジトリをクローンして`~/.tmux.conf`からエントリーポイントを実行します。

```bash
git clone https://github.com/tmux-revamped/tmux-disk-revamped ~/.tmux/plugins/tmux-disk-revamped
```

```tmux
run-shell ~/.tmux/plugins/tmux-disk-revamped/disk-revamped.tmux
```

プラグインを読み込む前に`status-left`または`status-right`を設定してください。プラグインは読み込み時に一度だけ、そこにあるプレースホルダーを置き換えます。

クローン内で`make install`を実行すると、`disk-revamped`が`~/.local/bin`に、そのmanページと補完が`~/.local/share`に入ります。

### 確認

```bash
~/.tmux/plugins/tmux-disk-revamped/bin/disk-revamped doctor
```

<a id="usage"></a>

## 使い方

ディスクがどれだけ埋まっているかを、使用量・空き容量・総容量、inodeの使用率、最近の読み取りのグラフ、増加速度、満杯までの時間、すべてのディスクの一覧とともに表示します。ステータスラインはtmuxがすでに持っている値を出力し、バックグラウンドの読み取りがそれを更新します。

| プレースホルダー | 出力 |
|:---------|:----|
| `#{disk_percentage}` | 使用率。例: `55%` |
| `#{disk_icon}` | 現在の使用率の階層のアイコン |
| `#{disk_fg_color}` | 使用率の階層の前景スタイル |
| `#{disk_bg_color}` | 使用率の階層の背景スタイル |
| `#{disk_used}` | 使用量(ギガバイト)。例: `55G`。1024Gからは`1.8T`のようにテラバイト |
| `#{disk_total}` | 総容量。同じ形式 |
| `#{disk_free}` | 空き容量。同じ形式 |
| `#{disk_read}` | 読み取り速度(Linux)。例: `1.2MB/s`。macOSでは空 |
| `#{disk_write}` | 書き込み速度(Linux)。同じ形式。macOSでは空 |
| `#{disk_all}` | マウントされているすべての実ディスク。例: `/ 55%, /data 30%` |
| `#{disk_inodes}` | inodeの使用率。例: `i12%` |
| `#{disk_purgeable}` | macOSのAPFSのパージ可能な容量。Linuxでは空 |
| `#{disk_graph}` | 最近の使用率の履歴。例: `▄▄▆▆█` |
| `#{disk_fill_rate}` | 使用量の変化。例: `+2.1G/h`。変化がなければ空 |
| `#{disk_full_eta}` | その速度で満杯になるまでの時間。例: `3d`。増えていなければ空 |
| `#{disk_mounts}` | `@disk_revamped_mounts`で指定したマウント。`#{disk_all}`と同じ形式 |

ステータスラインにプレースホルダーを置きます。

```tmux
set -g @disk_revamped_low_fg_color '#[fg=green]'
set -g @disk_revamped_medium_fg_color '#[fg=yellow]'
set -g @disk_revamped_high_fg_color '#[fg=red]'

set -g status-right '#{disk_fg_color}#{disk_icon} #{disk_percentage}#[default] #{disk_used}/#{disk_total} '
```

オプションをいくつか足した同じ例は[examples/status-right.tmux.conf](examples/status-right.tmux.conf)にあります。

### ラベルと幅

`@disk_revamped_<metric>_label`は、値が空でないときだけ、メトリクスの前にアイコンや語を出力します。`@disk_revamped_icons`を`nerd`にすると、下のすべてのメトリクスにNerd Fontのグリフが付きます。メトリクス自身のラベルがセットより優先され、空に設定したラベルは既定値を意味するのでグリフが残ります。既定の`ascii`ではラベルを付けません。メトリクスは`percentage`、`used`、`total`、`free`、`read`、`write`、`inodes`、`purgeable`、`graph`、`fill_rate`、`full_eta`、`mounts`、`all`で、コマンドのオプションでは`--fill-rate-label`のようにダッシュで書きます。

| メトリクス | `nerd`のグリフ |
|:------|:-----------|
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

`@disk_revamped_fixed_width`を`on`にすると、各値を左側で自然な幅まで埋めます。使用率とinodeは4文字、読み書きの速度は9文字で、`9%`から`42%`に変わっても行の残りがずれません。`@disk_revamped_<metric>_width`は1つのメトリクスの幅を決め、固定幅より優先されます。それより長い値は切り詰めません。

### レンダーモード

既定では各プレースホルダーが`#()`の呼び出しになり、tmuxはステータスの再描画のたびにそれを再実行します。`@disk_revamped_render`を`options`にすると、各プレースホルダーは`#{E:@disk_revamped_out_percentage}`のようなオプションの読み取りになります。サーバーごとに1つのバックグラウンドプロセスが`@disk_revamped_interval`秒ごとにディスクを読み取り、すべての値を1回のtmux呼び出しで書き込むので、値は同時に変わります。

```tmux
set -g @disk_revamped_render 'options'
set -g @disk_revamped_fixed_width 'on'
```

### 階層の色

階層のスタイルは既定では空なので、設定するまで`#{disk_fg_color}`と`#{disk_bg_color}`は何も出力しません。次のパレットは、低を緑、中を黄、高を赤に割り当てます。

| テーマ | 低 | 中 | 高 |
|:----|:----|:----|:----|
| Catppuccin Mocha | `#a6e3a1` | `#f9e2af` | `#f38ba8` |
| Dracula | `#50fa7b` | `#f1fa8c` | `#ff5555` |
| Nord | `#a3be8c` | `#ebcb8b` | `#bf616a` |
| Gruvbox Dark | `#b8bb26` | `#fabd2f` | `#fb4934` |
| Tokyo Night | `#9ece6a` | `#e0af68` | `#f7768e` |
| Solarized Dark | `#859900` | `#b58900` | `#dc322f` |

各値はスタイルに入れます。例: `set -g @disk_revamped_low_fg_color '#[fg=#a6e3a1]'`

| コマンド | 動作 |
|:-----|:----|
| `disk-revamped apply` | ポップアップのキーを割り当ててプレースホルダーを今すぐ埋める。エントリーポイントがtmux読み込み時に実行 |
| `disk-revamped list` | `apply`が送るコマンドをすべて表示し、何も変更しない。`--json`なら1つのオブジェクトを表示 |
| `disk-revamped status NAME` | `percentage`、`used`、`graph`などのプレースホルダーを1つ表示。ステータスラインが実行 |
| `disk-revamped refresh` | 今すぐディスクを読み取り、どれだけ埋まっているかを表示 |
| `disk-revamped card` | すべてを今すぐ読み取り、値ごとに1行、続けてすべてのディスクをターミナルに収めて表示 |
| `disk-revamped scan` | スキャン対象のパスにある大きな項目をサイズ付きで一覧表示 |
| `disk-revamped popup` | カードをtmuxのポップアップで開く。ポップアップのキーが実行 |
| `disk-revamped eat` | スキャンをtmuxのポップアップで開く。eatキーが実行 |
| `disk-revamped daemon` | `options`レンダーモード用に、毎ティックでプレースホルダーを公開。`apply`が起動 |
| `disk-revamped doctor` | 依存関係ごとに1行。値の取得元のツールやファイル、ターミナルのサイズ、通知手段、割り当てを見送ったキー |
| `disk-revamped version` | バージョン、続けてtmuxのバージョン |
| `disk-revamped help` | ヘルプページ。`man disk-revamped`が同じコマンドと設定を説明 |
| `disk-revamped` | ターミナルではメニューを表示 |

<a id="configuration"></a>

## 設定

すべてのオプションは、`--interval 2`のようなダッシュ付きのコマンドオプション、および`DISK_REVAMPED_INTERVAL`のような環境変数としても使えます。コマンドラインが環境変数より、環境変数がtmuxのオプションより優先されます。空のtmuxオプションは既定値を意味し、コマンドラインや環境変数の空の値はそのまま使われます。`doctor`は、プラグインが知らない値を持つ設定を示します。`apply`に渡した設定はキーとすべてのステータス呼び出しに引き継がれます。

### 読み取り

| オプション | 既定値 | 意味 |
|:------|:----|:----|
| `@disk_revamped_mount` | `/` | 使用率系のプレースホルダーが報告するマウント。macOSでは`/`は封印されたシステムボリュームなので、ファイルの使用量を見るには`/System/Volumes/Data`を指定 |
| `@disk_revamped_mounts` | empty | `#{disk_mounts}`のマウント。空白またはカンマ区切り。存在しないものは除外 |
| `@disk_revamped_interval` | `30` | 読み取りが新しいと見なされる秒数 |
| `@disk_revamped_detail_interval` | `60` | すべてのディスクの一覧が新しいと見なされる秒数 |
| `@disk_revamped_render` | `jobs` | `options`は`#()`の呼び出しの代わりに公開済みオプションを読む。それ以外の値は`jobs` |
| `@disk_revamped_history_length` | `20` | `#{disk_graph}`が保持する読み取りの数 |
| `@disk_revamped_notify` | `0` | `1`にすると使用率が`@disk_revamped_high_thresh`に達したときに通知する。下回ったあとは再び通知 |

### 階層

| オプション | 既定値 | 意味 |
|:------|:----|:----|
| `@disk_revamped_medium_thresh` | `70` | 階層が中になる使用率(%) |
| `@disk_revamped_high_thresh` | `90` | 階層が高になる使用率(%)。通知もこの値で送る |
| `@disk_revamped_low_icon` | `▰▱▱` | 低の階層のアイコン |
| `@disk_revamped_medium_icon` | `▰▰▱` | 中の階層のアイコン |
| `@disk_revamped_high_icon` | `▰▰▰` | 高の階層のアイコン |
| `@disk_revamped_low_fg_color` | empty | 低の階層の前景スタイル。例: `#[fg=green]` |
| `@disk_revamped_medium_fg_color` | empty | 中の階層の前景スタイル |
| `@disk_revamped_high_fg_color` | empty | 高の階層の前景スタイル |
| `@disk_revamped_low_bg_color` | empty | 低の階層の背景スタイル |
| `@disk_revamped_medium_bg_color` | empty | 中の階層の背景スタイル |
| `@disk_revamped_high_bg_color` | empty | 高の階層の背景スタイル |

### 書式とラベル

| オプション | 既定値 | 意味 |
|:------|:----|:----|
| `@disk_revamped_percentage_format` | `%s%%` | 使用率のprintf書式 |
| `@disk_revamped_size_format` | `%sG` | 1024G未満の容量のprintf書式。1024Gからは小数1桁のテラバイト |
| `@disk_revamped_inodes_format` | `i%s%%` | `#{disk_inodes}`のprintf書式 |
| `@disk_revamped_separator` | `, ` | `#{disk_all}`と`#{disk_mounts}`でディスクの間に入れる文字列 |
| `@disk_revamped_icons` | `ascii` | `nerd`にするとすべての値にNerd Fontのグリフを付ける |
| `@disk_revamped_<metric>_label` | empty | 値の前に出す文字列。値が空でないときだけ |
| `@disk_revamped_fixed_width` | `off` | `on`にすると各値を自然な幅まで左側で埋める。`9%`から`42%`に変わっても行の残りがずれない |
| `@disk_revamped_<metric>_width` | empty | 1つの値をこの文字数まで埋める。それより長い値は切り詰めない |

### キーとスキャン

| オプション | 既定値 | 意味 |
|:------|:----|:----|
| `@disk_revamped_popup_key` | `M-d` | 詳細ポップアップを開くプレフィックスキー。`off`なら何も割り当てない |
| `@disk_revamped_eat_key` | empty | 大きな項目のポップアップを開くプレフィックスキー。空または`off`なら何も割り当てない |
| `@disk_revamped_eat_path` | the mount | スキャンが一覧にするフォルダー |
| `@disk_revamped_eat_count` | `10` | スキャンが一覧にする大きな項目の数 |
| `@disk_revamped_eat_interval` | `60` | スキャン結果が新しいと見なされる秒数 |

### 内部状態

プラグインがこれらのオプションを自分で書き込みます。設定しないでください。

| オプション | 内容 |
|:------|:----|
| `@disk_revamped_published` | ステータスラインが使うメトリクス。読み込み時に記録され、それだけを読む |
| `@disk_revamped_history` | `#{disk_graph}`の元になる最近の読み取り |
| `@disk_revamped_out_<metric>` | optionsモードでの各メトリクスの描画済みの値 |
| `@disk_revamped_ticker_pid` | optionsモードのバックグラウンドプロセスのプロセスID |
| `@disk_revamped_notified` | 通知を送ったあと、使用率が閾値を下回るまで`1` |
| `@disk_revamped_percent` and the other figures, `_ts`, `_lock` | 保存された読み取り、各読み取りの時刻、更新ロック。`@disk_revamped_mounts_list`は設定`@disk_revamped_mounts`の読み取りを保持 |

## キーバインド

| キー | 動作 | 既定 |
|:----|:----|:----|
| `prefix + M-d` | カードをポップアップで開く。値とすべてのディスクがポップアップに収まる。Enterで閉じる | 割り当て済み |
| 未割り当て | 大きな項目のポップアップを開く。Enterで閉じる | `@disk_revamped_eat_key` |

`@disk_revamped_popup_key`で別のキーを指定でき、`off`なら何も割り当てません。既定のキーはすでに別のものが使っている場合は触れず、`disk-revamped doctor`がそれを示します。`@disk_revamped_eat_key`は大きな項目のポップアップを割り当てます。これは任意です。

```tmux
set -g @disk_revamped_eat_key 'M-u'
```

<a id="how-it-works"></a>

## 仕組み

[`disk-revamped.tmux`](disk-revamped.tmux)はtmuxがプラグインを読み込むときに一度だけ実行されます。`status-left`と`status-right`が使うメトリクスを`@disk_revamped_published`に記録し、各プレースホルダーを[`bin/disk-revamped`](bin/disk-revamped)の呼び出しに、`options`モードではオプションの読み取りに置き換えて、バックグラウンドプロセスを起動します。

既定のモードでは、各`#()`の呼び出しが保存済みの読み取りを即座に返します。読み取りが間隔より古いと、呼び出しがバックグラウンドで更新を始めてロックを取るので、同時に動く更新は1つだけです。1回の`df -Pk`で使用率と容量(切り上げた整数のギガバイト)が分かります。inode、パージ可能な容量、ディスクごとの速度、増加速度、ディスクの一覧は読み取りの負荷が高いので、ステータスラインが使うプレースホルダーのときだけ実行します。1つの`awk`が読み取りをすべての値に変換し、1回のtmux呼び出しで保存します。

読み書きの速度と増加速度は、それぞれの読み取りを直前のものと比べます。マウントのパスは外部から来るので、ステータスラインに渡す前にすべての`#`を二重にします。読み取り、値、書式は[`lib/disk.sh`](lib/disk.sh)に、設定の表は[`lib/state.sh`](lib/state.sh)にあります。

<a id="screens"></a>

## スクリーン

<details>
<summary>すべてのスクリーン。実際のtmux内で<code>make screens</code>により録画し、各キーをステータスラインに表示</summary>
<br>

<table>
<tr>
<td width="50%" valign="top"><img src="screens/status.png" alt="disk-revamped: 階層のアイコンと色、容量、空き容量付きの使用率"><br><sub>階層のアイコンと色、容量、空き容量付きの使用率(<code>hero.tape</code>)</sub></td>
<td width="50%" valign="top"><img src="screens/popup.png" alt="disk-revamped: prefix M-dで詳細カードをポップアップで開く"><br><sub><code>prefix M-d</code>で詳細カードをポップアップで開く(<code>hero.tape</code>)</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/icons.png" alt="disk-revamped: @disk_revamped_iconsをnerdにすると、すべてのメトリクスにグリフが付く"><br><sub><code>@disk_revamped_icons</code>を<code>nerd</code>にすると、すべてのメトリクスにグリフが付く(<code>hero.tape</code>)</sub></td>
<td width="50%" valign="top"><img src="screens/graph.png" alt="disk-revamped: グラフ、使用率、増加速度、満杯までの時間"><br><sub>グラフ、使用率、増加速度、満杯までの時間(<code>hero.tape</code>)</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/options.png" alt="disk-revamped: optionsレンダーモードでは各プレースホルダーがtmuxのオプションを読む"><br><sub><code>options</code>レンダーモードでは各プレースホルダーがtmuxのオプションを読む(<code>hero.tape</code>)</sub></td>
<td width="50%" valign="top"><img src="screens/card.png" alt="disk-revamped: cardはすべての値とすべてのディスクを表示する"><br><sub><code>card</code>はすべての値とすべてのディスクを表示する(<code>features.tape</code>)</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/sizes.png" alt="disk-revamped: 使用量、空き容量、総容量、macOSではパージ可能な容量"><br><sub>使用量、空き容量、総容量、macOSではパージ可能な容量(<code>features.tape</code>)</sub></td>
<td width="50%" valign="top"><img src="screens/size-format.png" alt="disk-revamped: @disk_revamped_size_formatは1024G未満の容量の書式を決める"><br><sub><code>@disk_revamped_size_format</code>は1024G未満の容量の書式を決める(<code>features.tape</code>)</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/colors.png" alt="disk-revamped: 独自の階層アイコンと色"><br><sub>独自の階層アイコンと色(<code>features.tape</code>)</sub></td>
<td width="50%" valign="top"><img src="screens/tiers.png" alt="disk-revamped: @disk_revamped_medium_thresh、@disk_revamped_high_thresh、階層のアイコン"><br><sub><code>@disk_revamped_medium_thresh</code>、<code>@disk_revamped_high_thresh</code>、階層のアイコン(<code>features.tape</code>)</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/format.png" alt="disk-revamped: @disk_revamped_percentage_formatは使用率の書式を決める"><br><sub><code>@disk_revamped_percentage_format</code>は使用率の書式を決める(<code>features.tape</code>)</sub></td>
<td width="50%" valign="top"><img src="screens/inodes-format.png" alt="disk-revamped: inodeの使用率と@disk_revamped_inodes_format"><br><sub>inodeの使用率と<code>@disk_revamped_inodes_format</code>(<code>features.tape</code>)</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/fixed.png" alt="disk-revamped: @disk_revamped_fixed_widthは各値を自然な幅まで埋める"><br><sub><code>@disk_revamped_fixed_width</code>は各値を自然な幅まで埋める(<code>features.tape</code>)</sub></td>
<td width="50%" valign="top"><img src="screens/width.png" alt="disk-revamped: @disk_revamped_inodes_widthは1つのメトリクスを独自の幅まで埋める"><br><sub><code>@disk_revamped_inodes_width</code>は1つのメトリクスを独自の幅まで埋める(<code>features.tape</code>)</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/labels.png" alt="disk-revamped: 1つのメトリクスの前に独自のラベル"><br><sub>1つのメトリクスの前に独自のラベル(<code>features.tape</code>)</sub></td>
<td width="50%" valign="top"><img src="screens/mounts.png" alt="disk-revamped: @disk_revamped_mountsは指定したマウントを一覧にする"><br><sub><code>@disk_revamped_mounts</code>は指定したマウントを一覧にする(<code>features.tape</code>)</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/separator.png" alt="disk-revamped: @disk_revamped_separatorはディスクの間に入る"><br><sub><code>@disk_revamped_separator</code>はディスクの間に入る(<code>features.tape</code>)</sub></td>
<td width="50%" valign="top"><img src="screens/all.png" alt="disk-revamped: すべてのディスクを1つのプレースホルダーで"><br><sub>すべてのディスクを1つのプレースホルダーで(<code>features.tape</code>)</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/mount.png" alt="disk-revamped: @disk_revamped_mountは使用率が報告するマウントを選ぶ"><br><sub><code>@disk_revamped_mount</code>は使用率が報告するマウントを選ぶ(<code>features.tape</code>)</sub></td>
<td width="50%" valign="top"><img src="screens/history.png" alt="disk-revamped: @disk_revamped_history_lengthはグラフが保持する読み取りの数を決める"><br><sub><code>@disk_revamped_history_length</code>はグラフが保持する読み取りの数を決める(<code>features.tape</code>)</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/fill.png" alt="disk-revamped: 増加速度と満杯までの時間"><br><sub>増加速度と満杯までの時間(<code>features.tape</code>)</sub></td>
<td width="50%" valign="top"><img src="screens/notify.png" alt="disk-revamped: @disk_revamped_notifyは高の閾値で通知を送る"><br><sub><code>@disk_revamped_notify</code>は高の閾値で通知を送る(<code>features.tape</code>)</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/popup-key.png" alt="disk-revamped: @disk_revamped_popup_keyはポップアップに別のキーを割り当てる"><br><sub><code>@disk_revamped_popup_key</code>はポップアップに別のキーを割り当てる(<code>features.tape</code>)</sub></td>
<td width="50%" valign="top"><img src="screens/eat.png" alt="disk-revamped: @disk_revamped_eat_keyは大きな項目のポップアップを開く。@disk_revamped_eat_path、@disk_revamped_eat_count、@disk_revamped_eat_intervalで調整"><br><sub><code>@disk_revamped_eat_key</code>は大きな項目のポップアップを開く。<code>@disk_revamped_eat_path</code>、<code>@disk_revamped_eat_count</code>、<code>@disk_revamped_eat_interval</code>で調整(<code>features.tape</code>)</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/version.png" alt="disk-revamped: バージョン"><br><sub>バージョン(<code>stills.tape</code>)</sub></td>
<td width="50%" valign="top"><img src="screens/error.png" alt="disk-revamped: 不明なコマンド"><br><sub>不明なコマンド(<code>stills.tape</code>)</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/status-command.png" alt="disk-revamped: status percentageとstatus graphはそれぞれ1つのプレースホルダーを表示する"><br><sub><code>status percentage</code>と<code>status graph</code>はそれぞれ1つのプレースホルダーを表示する(<code>stills.tape</code>)</sub></td>
<td width="50%" valign="top"><img src="screens/refresh.png" alt="disk-revamped: refreshは今すぐディスクを読み取る"><br><sub><code>refresh</code>は今すぐディスクを読み取る(<code>stills.tape</code>)</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/list.png" alt="disk-revamped: listはすべてのバインディングを表示する"><br><sub><code>list</code>はすべてのバインディングを表示する(<code>stills.tape</code>)</sub></td>
<td width="50%" valign="top"><img src="screens/json.png" alt="disk-revamped: list --jsonは同じ計画を1つのオブジェクトで表示する"><br><sub><code>list --json</code>は同じ計画を1つのオブジェクトで表示する(<code>stills.tape</code>)</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/doctor.png" alt="disk-revamped: doctor"><br><sub><code>doctor</code>(<code>stills.tape</code>)</sub></td>
<td width="50%" valign="top"><img src="screens/menu.png" alt="disk-revamped: メニュー"><br><sub>メニュー(<code>stills.tape</code>)</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/menu-card.png" alt="disk-revamped: メニューからのカード"><br><sub>メニューからのカード(<code>stills.tape</code>)</sub></td>
<td width="50%" valign="top"><img src="screens/scan.png" alt="disk-revamped: scanは大きな項目を一覧にする"><br><sub><code>scan</code>は大きな項目を一覧にする(<code>stills.tape</code>)</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/accent.png" alt="disk-revamped: DISK_REVAMPED_ACCENTによるアクセント"><br><sub><code>DISK_REVAMPED_ACCENT</code>によるアクセント(<code>stills.tape</code>)</sub></td>
<td width="50%" valign="top"><img src="screens/plain-menu.png" alt="disk-revamped: gumなしのメニュー"><br><sub>gumなしのメニュー(<code>stills.tape</code>)</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/plain-card.png" alt="disk-revamped: gumなしで、メニューからのcard"><br><sub>gumなしで、メニューからの<code>card</code>(<code>stills.tape</code>)</sub></td>
<td width="50%" valign="top"><img src="screens/plain-doctor.png" alt="disk-revamped: gumなしのdoctor"><br><sub>gumなしの<code>doctor</code>(<code>stills.tape</code>)</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/themes.png" alt="disk-revamped: 6つのテーマのヘッダー"><br><sub>6つのテーマのヘッダー(<code>themes.tape</code>)</sub></td>
<td width="50%" valign="top"><img src="screens/help.png" alt="disk-revamped: ヘルプページ"><br><sub>ヘルプページ(<code>help.tape</code>)</sub></td>
</tr>
</table>

録画は本物のプラグインとtmuxで行います。`df`、`diskutil`、`osascript`、`du`は小さなスクリプトで置き換えているので、画面の値はそれらのものです。録画はmacOSで行い、macOSにはディスクごとのカウンターがないため、`#{disk_read}`と`#{disk_write}`は何も表示しません。`@disk_revamped_interval`と`@disk_revamped_detail_interval`は録画用のtmux設定で指定しています。

</details>

## 移植性

プラグインはPOSIX `sh`です。CIは次の各行ですべてのスイートを実行します。

| シェル | 状態 |
|:----|:----|
| `dash`、macOSの`/bin/sh` | 対応 |
| `bash` 3.2と5.x、システムの`zsh`とHomebrewの`zsh` | 対応 |

| システム | 状態 |
|:-----|:----|
| macOS | Apple SiliconとIntelのTahoe。標準のツール、HomebrewのGNUツール、Homebrewのuutilsの各構成 |
| Linux | x86_64とarm64のUbuntu 26.04。GNU coreutils、uutils、BusyBoxの各構成 |

## 開発

| コマンド | 実行内容 |
|:-----|:-----|
| `make fmt` | すべてのスクリプトにshfmt `-i 2` |
| `make lint` | shfmt、ShellCheck、mandoc、yamllint、actionlintを指摘ゼロで実行 |
| `make test` | システムの`sh`でbatsのスイート |
| `make test-all` | インストール済みのすべてのシェル(macOSではbashとzshの両ビルド)でスイート |
| `make test-linux` | Ubuntuコンテナ内でスイート |
| `make coverage` | このMacとUbuntuコンテナでbashcovを実行し、統合して100パーセントを要求 |
| `make screens` | 上のスクリーンを、macOS上でVHSにより実際のプラグインをtmux内で録画 |
| `make install` | コマンドとmanページ、補完を`PREFIX`以下へ |

macOSでは、`brew bundle`が[`Brewfile`](Brewfile)にあるこれらのターゲットが呼ぶすべてのツールをインストールします。

コミットはConventional Commitsの形式で、直接`main`に入ります。`main`で`ci`が成功すると、`release.yml`がsemantic-releaseを実行します。前回のタグ以降の`feat`や`fix`ごとにリリースを公開し、バージョン定数を更新して、ノートを[`CHANGELOG.md`](CHANGELOG.md)に追加します。

## ライセンス

[MIT](LICENSE)、copyright Gustavo Franco。

<!-- family:begin -->

## tmux-revamped ファミリー

このプラグインは tmux-revamped ファミリーの一員です。すべてのメンバーが [`FAMILY.md`](FAMILY.md) の同じ規約と同じ共有ライブラリを持ちます。メンバーは一緒にインストールする前提で作られており、ほかのメンバーが使うキーや tmux オプションを使うメンバーはありません。

あるメンバーで見つかった不具合は、修正完了とする前に全メンバーで同じ不具合を探します。

| メンバー | 機能 |
|---|---|
| [`tmux-autoreload-revamped`](https://github.com/tmux-revamped/tmux-autoreload-revamped) | tmuxの設定を編集して保存するだけで、キーもコマンドも使わずに自動で再読み込みされます |
| [`tmux-battery-revamped`](https://github.com/tmux-revamped/tmux-battery-revamped) | tmuxのステータスバーに電池の状態を表示し、ステータスの描画を一切止めません |
| [`tmux-bluetooth-revamped`](https://github.com/tmux-revamped/tmux-bluetooth-revamped) | 接続中のすべてのBluetooth機器とその電池残量をtmuxのステータスバーに表示し、描画を止めません |
| [`tmux-cpu-revamped`](https://github.com/tmux-revamped/tmux-cpu-revamped) | CPUの負荷、温度、周波数をtmuxのステータスバーに表示し、描画を一切止めません |
| [`tmux-disk-revamped`](https://github.com/tmux-revamped/tmux-disk-revamped) | **このプラグイン**、tmuxのステータスバーにディスク使用量を表示し、ステータスの描画を一切止めません |
| [`tmux-extract-revamped`](https://github.com/tmux-revamped/tmux-extract-revamped) | 画面上の URL、パス、ハッシュなどのトークンを fzf で選び、カーソル位置に入力します。純粋なシェルだけで動きます |
| [`tmux-fzf-revamped`](https://github.com/tmux-revamped/tmux-fzf-revamped) | ポップアップ内の fzf ピッカーから、tmux のセッション、ウィンドウ、ペインの切り替え、終了、名前変更、作成を行います |
| [`tmux-git-revamped`](https://github.com/tmux-revamped/tmux-git-revamped) | アクティブなペインのgitブランチ、変更、プロバイダーの件数を、描画を止めずにtmuxのステータスバーに表示します |
| [`tmux-gpu-revamped`](https://github.com/tmux-revamped/tmux-gpu-revamped) | NVIDIA、AMD、Intel、Apple の GPU の負荷、温度、クロック、電力、メモリを tmux のステータスバーに表示します |
| [`tmux-kube-revamped`](https://github.com/tmux-revamped/tmux-kube-revamped) | 現在の Kubernetes コンテキストと名前空間を、kubectl を使わずに kubeconfig から解析して tmux のステータスバーに表示します |
| [`tmux-launcher-revamped`](https://github.com/tmux-revamped/tmux-launcher-revamped) | 任意の TUI アプリを、現在のペインのディレクトリでポップアップまたはウィンドウとして起動します。アプリごとにキーを設定できます |
| [`tmux-logging-revamped`](https://github.com/tmux-revamped/tmux-logging-revamped) | 任意のペインをファイルに保存します。ライブのログ記録、スクロールバック全体、1 回限りのスクリーンショットに対応します |
| [`tmux-music-revamped`](https://github.com/tmux-revamped/tmux-music-revamped) | 再生中の曲をステータスバーに表示し、ステータスの描画を止めません |
| [`tmux-network-revamped`](https://github.com/tmux-revamped/tmux-network-revamped) | ネットワークのスループットをステータスバーに表示し、描画を止めません |
| [`tmux-pain-control-revamped`](https://github.com/tmux-revamped/tmux-pain-control-revamped) | tmux のペインとウィンドウの操作キー。tmux のバージョンに対応し、vim と共存でき、どの prefix キーも無効にできます |
| [`tmux-persist-revamped`](https://github.com/tmux-revamped/tmux-persist-revamped) | tmuxのすべてのセッション、ウィンドウ、ペインを保存し、タイマーで自動保存して、再起動後にすべて復元します |
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | tmux-revampedプラグインの出発点です。共有ライブラリ、batsハーネス、CIを含みます |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | すべての状態をtmuxオプションに保持し、一時ファイルを使わない、tmuxステータスバーのポモドーロタイマーです |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | RAM、スワップ、メモリプレッシャーをtmuxのステータスバーに表示します。計測はバックグラウンドで行うため描画を待たせません |
| [`tmux-reorder-revamped`](https://github.com/tmux-revamped/tmux-reorder-revamped) | tmuxのステータスバー上でウィンドウのタブをマウスでドラッグして、そのウィンドウを移動します |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | 自分でスクロールできるアプリにはマウスホイールを渡し、それ以外ではtmuxのコピーモードに入ります |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | tmuxのバージョンと端末に合わせて適用され、ユーザーが設定したオプションには触れない、妥当な初期設定です |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | tmuxのタイル型ウィンドウ管理です。BSPのdwindleとspiralを含む8つのレイアウトと、レイアウトの取り消しがあります |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | ステータスバーにローカル時計と世界時計を時間帯ごとの色で表示し、カウントダウンと夏時間の警告も出します |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | wttr.inの天気をバックグラウンドで取得し、ステータスバーを待たせずに表示します |

<!-- family:end -->
