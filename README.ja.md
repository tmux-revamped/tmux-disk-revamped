<div align="center">

# tmux-disk-revamped

<strong>tmuxのステータスバーにディスク使用量を表示し、ステータスの描画を一切止めません。</strong>

[English](README.md) &nbsp;|&nbsp; 日本語 &nbsp;|&nbsp; [简体中文](README.zh-Hans.md) &nbsp;|&nbsp; [繁體中文（香港）](README.zh-HK.md)

[![Tests](https://github.com/tmux-revamped/tmux-disk-revamped/actions/workflows/tests.yml/badge.svg)](https://github.com/tmux-revamped/tmux-disk-revamped/actions/workflows/tests.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)](CHANGELOG.md)

<p align="center">
  <a href="#what-it-does">機能</a> &nbsp;|&nbsp;
  <a href="#requirements">動作要件</a> &nbsp;|&nbsp;
  <a href="#installation">インストール</a> &nbsp;|&nbsp;
  <a href="#usage">使い方</a> &nbsp;|&nbsp;
  <a href="#configuration">設定</a> &nbsp;|&nbsp;
  <a href="#key-bindings">キーバインド</a> &nbsp;|&nbsp;
  <a href="#how-it-works">仕組み</a>
</p>

</div>

プレースホルダー**16**個。描画モード**2**種類。ポップアップ**2**種類。CIはLinuxとmacOSの**10**通りのツールチェーンの組み合わせでテストを実行します。

---

<a id="what-it-does"></a>

## 機能

`status-left`と`status-right`の`#{disk_*}`プレースホルダーを、1つのマウントの使用率、空き容量、inodeの使用率、読み書きの速度、増加速度、満杯までの時間、使用率の履歴と、すべての実ディスクの一覧に置き換えます。どのプレースホルダーもtmuxのオプションにキャッシュされた値を読みます。`df`はバックグラウンドで動くため、ステータスラインが待たされることはありません。ディスクには何も書き込みません。

`prefix + M-d`で詳細ポップアップを開くほか、ディスク上の大きな項目を一覧にする任意のポップアップと、高の閾値を超えたときの任意の通知もあります。

<a id="requirements"></a>

## 動作要件

| ツール | バージョン | 用途 |
|:-----|:--------|:-----------|
| tmux | 3.2以降 | 2つのポップアップの`display-popup` |
| bash | 3.2以降 | macOSの`/bin/bash`を含むすべてのスクリプト |
| `df`、`du` | 任意 | 使用量と容量の走査。どちらのプラットフォームにも標準搭載 |
| `osascript`または`notify-send` | 任意 | 任意。ディスクが満杯に近いときの通知 |

| 値 | Linux、x86_64とarm64 | macOS、IntelとApple Silicon |
|:------|:------------------------|:-------------------------------|
| 使用率、使用量、総容量、空き容量 | `df -BG` | `/bin/df -g` |
| 増加速度と満杯までの時間 | `df -Pk` | `/bin/df -Pk` |
| inode | `df -i` | `df -i` |
| 読み書きの速度 | `/proc/diskstats`、`/sys/block`のデバイス全体 | なし |
| パージ可能な容量 | なし | `diskutil info` |

macOSの読み取りは`/bin/df`を呼ぶため、`PATH`の先頭にGNU coreutilsがあっても壊れません。ホストに情報源がない値は空で表示されます。このホストで使えるものは`src/disk.sh doctor`で確認できます。

<a id="installation"></a>

## インストール

### TPMでインストール

`~/.tmux.conf`にプラグインとプレースホルダーを追加し、`prefix + I`を押します。

```tmux
set -g @plugin 'tmux-revamped/tmux-disk-revamped'
set -g status-right '#{disk_icon} #{disk_percentage}'
```

### 手動インストール

```bash
git clone https://github.com/tmux-revamped/tmux-disk-revamped ~/.tmux/plugins/tmux-disk-revamped
```

次の行を`~/.tmux.conf`の`status-left`と`status-right`を設定する行より後に追加し、tmuxを再読み込みします。

```tmux
run-shell ~/.tmux/plugins/tmux-disk-revamped/disk-revamped.tmux
```

<a id="usage"></a>

## 使い方

`status-left`か`status-right`にプレースホルダーを書きます。プラグインは読み込み時にそれを置き換えます。完全な例は[`examples/status-right.tmux.conf`](examples/status-right.tmux.conf)にあります。

```tmux
set -g status-right '#{disk_fg_color}#{disk_icon} #{disk_percentage}#[default] #{disk_used}/#{disk_total} '
```

| プレースホルダー | 出力 |
|:------------|:-------|
| `#{disk_percentage}` | 使用率。例：`55%` |
| `#{disk_icon}` | 現在の使用率段階のアイコン |
| `#{disk_fg_color}`、`#{disk_bg_color}` | 現在の使用率段階の色 |
| `#{disk_used}`、`#{disk_total}`、`#{disk_free}` | ギガバイト単位の容量。例：`100G`。1024Gからは`1.8T`のようにテラバイトに切り替わる |
| `#{disk_inodes}` | inodeの使用率。例：`i12%` |
| `#{disk_purgeable}` | macOSのAPFSのパージ可能な容量 |
| `#{disk_read}`、`#{disk_write}` | Linuxでの読み書きの速度。例：`1.2MB/s` |
| `#{disk_fill_rate}` | 使用量の変化。例：`+2.1G/h`。変化がなければ空 |
| `#{disk_full_eta}` | その速度で満杯になるまでの時間。例：`3d`。増えていなければ空 |
| `#{disk_graph}` | 最近の使用率の推移。例：`▄▄▆▆█` |
| `#{disk_all}` | マウントされているすべての実ディスク。例：`/ 55%, /home 30%` |
| `#{disk_mounts}` | `@disk_revamped_mounts`で指定したマウント。形式は同じ |

`#{disk_all}`は`/dev/`のファイルシステムを一覧にし、macOSでは`/Volumes/`、Linuxでは`/boot`と`/snap`を除きます。

<a id="configuration"></a>

## 設定

| オプション | 既定値 | 意味 |
|:-------|:--------|:--------|
| `@disk_revamped_mount` | `/` | 使用量のプレースホルダーが報告するマウント。macOSの`/`は封印されたシステムボリュームなので、自分のファイルが使う容量を見るには`/System/Volumes/Data`を設定する |
| `@disk_revamped_interval` | `30` | 使用量の読み取りを新しいとみなす秒数 |
| `@disk_revamped_detail_interval` | `60` | `#{disk_all}`の一覧を新しいとみなす秒数 |
| `@disk_revamped_render` | 空 | `options`でオプション描画モードにする。[仕組み](#how-it-works)を参照 |
| `@disk_revamped_percentage_format` | `%s%%` | 使用率のprintf書式 |
| `@disk_revamped_size_format` | `%sG` | 1024G未満の容量のprintf書式 |
| `@disk_revamped_medium_thresh`、`@disk_revamped_high_thresh` | `70`、`90` | 中と高の段階が始まる使用率のパーセント |
| `@disk_revamped_low_icon` | `▰▱▱` | 低の段階のアイコン |
| `@disk_revamped_medium_icon` | `▰▰▱` | 中の段階のアイコン |
| `@disk_revamped_high_icon` | `▰▰▰` | 高の段階のアイコン |
| `@disk_revamped_{low,medium,high}_{fg,bg}_color` | 空 | 段階ごとの色 |
| `@disk_revamped_separator` | `, ` | `#{disk_all}`と`#{disk_mounts}`のディスクの間の文字列 |
| `@disk_revamped_mounts` | 空 | `#{disk_mounts}`のマウント。空白またはカンマ区切り |
| `@disk_revamped_inodes_format` | `i%s%%` | `#{disk_inodes}`のprintf書式 |
| `@disk_revamped_history_length` | `20` | `#{disk_graph}`に残す読み取りの数 |
| `@disk_revamped_icons` | `ascii` | `nerd`ですべての指標にNerd Fontの記号のラベルを付ける |
| `@disk_revamped_<metric>_label` | 空 | 値が空でないときに1つの指標の値の前に出す文字列。`''`で`nerd`のラベルを消す |
| `@disk_revamped_fixed_width` | `off` | `on`で各値を最大幅まで左側に詰め物をする |
| `@disk_revamped_<metric>_width` | 空 | 1つの指標の幅。固定幅より優先 |
| `@disk_revamped_notify` | `0` | `1`で使用率が`@disk_revamped_high_thresh`に達したときに通知を送る |
| `@disk_revamped_popup_key` | `M-d` | 詳細ポップアップのprefixキー。`off`で割り当てない |
| `@disk_revamped_eat_key` | 空 | 大きな項目のポップアップのprefixキー。空なら割り当てない |
| `@disk_revamped_eat_path` | マウント | 容量の走査で一覧にするディレクトリ |
| `@disk_revamped_eat_count` | `10` | 走査で一覧にする大きな項目の数 |
| `@disk_revamped_eat_interval` | `60` | 走査結果を新しいとみなす秒数 |

ラベルはアイコンと2つの色を除くすべてのプレースホルダーに付きます。幅の設定で長い値が切り詰められることはありません。

### テーマの色

色のオプションは既定で空のため、設定するまで色は付きません。次の各ブロックは低、中、高の段階をそれぞれ緑、黄、赤にします。

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

### 内部状態

次のオプションはプラグインが自身で書き込みます。設定しないでください。

| オプション | 内容 |
|:-------|:------|
| `@disk_revamped_published` | 読み込み時に`status-left`と`status-right`で見つかった指標。inode、パージ可能な容量、増加速度、マウントの計測は、その指標がここにあるときだけ動く |
| `@disk_revamped_out_<metric>` | オプションモードで公開される各指標の値 |
| `@disk_revamped_ticker_pid` | オプションモードのバックグラウンドプロセスのpid |
| `@disk_revamped_option_names` | バックグラウンドプロセスが1周期に1回の呼び出しで読むオプション |
| `@disk_revamped_notified` | 通知を送った後は`1`。使用率が閾値を下回るまで続く |
| `@disk_revamped_history` | `#{disk_graph}`用の最近の使用率 |
| `@disk_revamped_{percent,used,total,free,all,read,write,inodes,purgeable,mounts,fill_rate,full_eta,eat}` | キャッシュされた読み取り。それぞれに`_ts`のタイムスタンプがある |
| `@disk_revamped_{rd_raw,wr_raw,io_ts,used_raw,fill_ts}` | 速度を測る基準となる前回のカウンター |

<a id="key-bindings"></a>

## キーバインド

| キー | 操作 | オプション |
|:----|:-------|:-------|
| `prefix + M-d` | 詳細ポップアップを開く | `@disk_revamped_popup_key` |
| 未割り当て | 大きな項目のポップアップを開く | `@disk_revamped_eat_key` |

詳細ポップアップはマウント、その使用率、使用量、空き容量、総容量と、`#{disk_all}`の一覧を表示します。大きな項目のポップアップはバックグラウンドで`du`を実行し、1つのファイルシステムの中に留まり、ドットで始まる項目も含めます。初めて開いたときは結果がキャッシュされるまで`Scanning`と表示されます。どちらのポップアップもEnterで閉じます。

```tmux
set -g @disk_revamped_eat_key 'M-u'
```

<a id="how-it-works"></a>

## 仕組み

既定のジョブモードでは、各プレースホルダーが[`src/disk.sh`](src/disk.sh)を呼ぶ`#()`になります。呼び出しはキャッシュされた値をすぐに出力します。キャッシュされた使用量が`@disk_revamped_interval`より古ければ、バックグラウンドでの更新を1つ開始します。更新はロックで守られ、並行した呼び出しが2つ目を開始することはありません。

tmuxはステータスを描き直すたびにすべての`#()`を実行します。1つのバーに複数のプラグインがあると、およそ1秒に1回になります。オプションモードはこの呼び出しをなくします。

```tmux
set -g @disk_revamped_render 'options'
set -g @disk_revamped_fixed_width 'on'
```

各プレースホルダーは`#{E:@disk_revamped_out_percentage}`のようなオプションの読み取りになります。サーバーごとに1つのバックグラウンドプロセスが`@disk_revamped_interval`秒ごとにディスクを読み、ステータスラインが使うすべての値を1回のtmux呼び出しで書き込み、1回だけ再描画します。このプロセスはサーバーが止まるか、設定の再読み込みで後継が起動すると終了します。

読み書きの速度と増加速度は、各読み取りを1つ前の読み取りと比べます。マウントのパスはキャッシュする前にすべての`#`を二重にするため、パスからtmuxの書式を注入することはできません。

<a id="development"></a>

## 開発

| コマンド | 実行内容 |
|:--------|:-------------|
| `make test` | [`test/`](test)以下のbatsテスト |
| `make lint` | すべてのシェルファイルへのshellcheck |
| `make coverage` | Linuxでのkcovによる行カバレッジ。95%未満で失敗します |

<a id="license"></a>

## ライセンス

[MIT](LICENSE)、copyright Gustavo Franco。

<!-- family:begin -->

## tmux-revamped ファミリー

このプラグインは tmux-revamped ファミリーの一員です。すべてのメンバーが [`FAMILY.md`](FAMILY.md) の同じ規約、`family/` 配下の同じツール、同じ共有ライブラリを持ち、チェックサムの一覧によってバイト単位で同一に保たれています。メンバーは一緒にインストールする前提で作られており、ほかのメンバーが使うキーや tmux オプションを使うメンバーはありません。

あるメンバーで見つかった不具合は、修正完了とする前に全メンバーで同じ不具合を探します。この義務は記憶に頼らず規約に書かれており、`family/bin/sweep` がその作業を行います。

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
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | tmux-revampedプラグインの出発点です。共有ライブラリ、batsハーネス、CI、ファミリーのツールを含みます |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | すべての状態をtmuxオプションに保持し、一時ファイルを使わない、tmuxステータスバーのポモドーロタイマーです |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | RAM、スワップ、メモリプレッシャーをtmuxのステータスバーに表示します。計測はバックグラウンドで行うため描画を待たせません |
| [`tmux-reorder-revamped`](https://github.com/tmux-revamped/tmux-reorder-revamped) | tmuxのステータスバー上でウィンドウのタブをマウスでドラッグして、そのウィンドウを移動します |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | 自分でスクロールできるアプリにはマウスホイールを渡し、それ以外ではtmuxのコピーモードに入ります |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | tmuxのバージョンと端末に合わせて適用され、ユーザーが設定したオプションには触れない、妥当な初期設定です |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | tmuxのタイル型ウィンドウ管理です。BSPのdwindleとspiralを含む8つのレイアウトと、レイアウトの取り消しがあります |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | ステータスバーにローカル時計と世界時計を時間帯ごとの色で表示し、カウントダウンと夏時間の警告も出します |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | wttr.inの天気をバックグラウンドで取得し、ステータスバーを待たせずに表示します |

### インストールの確認

全メンバーがディスク上にあれば、1 つのコマンドでメンバー間の衝突を報告できます。

```sh
family/bin/doctor --live
```

各メンバーと実行中の tmux サーバーを読み取り、重複したキー、重複したステータスのプレースホルダー、命名規則に合わないオプション、規約のバージョンが古いメンバーを報告します。

<!-- family:end -->
