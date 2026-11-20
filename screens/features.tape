Source common.tape
Output scratch.gif
Hide
Type "tmux -L revamped-screens attach -t demo"
Enter
Sleep 1.5s
Show
Sleep 3500ms
Hide
Ctrl+]
Sleep 300ms
Type@5ms "disk-revamped card"
Enter
Show
Sleep 800ms
Type "disk-revamped card"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 4s
Screenshot card.png
Sleep 1s
Hide
Type "clear"
Enter
Sleep 600ms
Show
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g status-right #{disk_used} #{disk_free} #{disk_total} #{disk_purgeable} "
Enter
Show
Sleep 800ms
Type "tmux set -g status-right '#{disk_used} #{disk_free} #{disk_total} #{disk_purgeable} '"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1200ms
Hide
Ctrl+]
Sleep 300ms
Type@5ms "disk-revamped apply"
Enter
Show
Sleep 800ms
Type "disk-revamped apply"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 3500ms
Screenshot sizes.png
Sleep 1s
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g @disk_revamped_size_format %s GB"
Enter
Show
Sleep 800ms
Type "tmux set -g @disk_revamped_size_format '%s GB'"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 3500ms
Screenshot size-format.png
Sleep 1s
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g status-right #{disk_fg_color}#{disk_icon} #{disk_percentage}#[default] "
Enter
Show
Sleep 800ms
Type "tmux set -g status-right '#{disk_fg_color}#{disk_icon} #{disk_percentage}#[default] '"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1200ms
Hide
Ctrl+]
Sleep 300ms
Type@5ms "disk-revamped apply"
Enter
Show
Sleep 800ms
Type "disk-revamped apply"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1200ms
Hide
Ctrl+B
Type ":"
Sleep 300ms
Type "run-shell 'printf 2 >/Users/Shared/demo/phase'"
Enter
Show
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g @disk_revamped_high_icon FULL"
Enter
Show
Sleep 800ms
Type "tmux set -g @disk_revamped_high_icon FULL"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1200ms
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g @disk_revamped_high_fg_color fg=#ff6600"
Enter
Show
Sleep 800ms
Type "tmux set -g @disk_revamped_high_fg_color '#[fg=#ff6600]'"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1200ms
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g @disk_revamped_high_bg_color bg=#005f87"
Enter
Show
Sleep 800ms
Type "tmux set -g @disk_revamped_high_bg_color '#[bg=#005f87]'"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 4s
Screenshot colors.png
Sleep 1s
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g @disk_revamped_medium_thresh 40"
Enter
Show
Sleep 800ms
Type "tmux set -g @disk_revamped_medium_thresh 40"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1200ms
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g @disk_revamped_high_thresh 95"
Enter
Show
Sleep 800ms
Type "tmux set -g @disk_revamped_high_thresh 95"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1200ms
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g @disk_revamped_medium_icon WARN"
Enter
Show
Sleep 800ms
Type "tmux set -g @disk_revamped_medium_icon WARN"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1200ms
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g @disk_revamped_low_icon OK"
Enter
Show
Sleep 800ms
Type "tmux set -g @disk_revamped_low_icon OK"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 4s
Screenshot tiers.png
Sleep 1s
Hide
Ctrl+B
Type ":"
Sleep 300ms
Type "run-shell 'rm -f /Users/Shared/demo/phase'"
Enter
Show
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g @disk_revamped_percentage_format disk %s%%"
Enter
Show
Sleep 800ms
Type "tmux set -g @disk_revamped_percentage_format 'disk %s%%'"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 3500ms
Screenshot format.png
Sleep 1s
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g status-right #{disk_percentage} #{disk_inodes} "
Enter
Show
Sleep 800ms
Type "tmux set -g status-right '#{disk_percentage} #{disk_inodes} '"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1200ms
Hide
Ctrl+]
Sleep 300ms
Type@5ms "disk-revamped apply"
Enter
Show
Sleep 800ms
Type "disk-revamped apply"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 3s
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g @disk_revamped_inodes_format inodes %s"
Enter
Show
Sleep 800ms
Type "tmux set -g @disk_revamped_inodes_format 'inodes %s'"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 3500ms
Screenshot inodes-format.png
Sleep 1s
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g @disk_revamped_fixed_width on"
Enter
Show
Sleep 800ms
Type "tmux set -g @disk_revamped_fixed_width on"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 3500ms
Screenshot fixed.png
Sleep 1s
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g @disk_revamped_inodes_width 8"
Enter
Show
Sleep 800ms
Type "tmux set -g @disk_revamped_inodes_width 8"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 3500ms
Screenshot width.png
Sleep 1s
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g @disk_revamped_inodes_label i:"
Enter
Show
Sleep 800ms
Type "tmux set -g @disk_revamped_inodes_label i:"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 3500ms
Screenshot labels.png
Sleep 1s
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g status-right #{disk_mounts} #{disk_percentage} "
Enter
Show
Sleep 800ms
Type "tmux set -g status-right '#{disk_mounts} #{disk_percentage} '"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1200ms
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g @disk_revamped_mounts /Users/Shared/demo/data,/Users/Shared/demo/backup"
Enter
Show
Sleep 800ms
Type "tmux set -g @disk_revamped_mounts /Users/Shared/demo/data,/Users/Shared/demo/backup"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1200ms
Hide
Ctrl+]
Sleep 300ms
Type@5ms "disk-revamped apply"
Enter
Show
Sleep 800ms
Type "disk-revamped apply"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 4s
Screenshot mounts.png
Sleep 1s
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g @disk_revamped_separator  | "
Enter
Show
Sleep 800ms
Type "tmux set -g @disk_revamped_separator ' | '"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 3500ms
Screenshot separator.png
Sleep 1s
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g status-right #{disk_all} #{disk_percentage} "
Enter
Show
Sleep 800ms
Type "tmux set -g status-right '#{disk_all} #{disk_percentage} '"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1200ms
Hide
Ctrl+]
Sleep 300ms
Type@5ms "disk-revamped apply"
Enter
Show
Sleep 800ms
Type "disk-revamped apply"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 4s
Screenshot all.png
Sleep 1s
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g status-right #{disk_percentage} #{disk_used} "
Enter
Show
Sleep 800ms
Type "tmux set -g status-right '#{disk_percentage} #{disk_used} '"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1200ms
Hide
Ctrl+]
Sleep 300ms
Type@5ms "disk-revamped apply"
Enter
Show
Sleep 800ms
Type "disk-revamped apply"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1200ms
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g @disk_revamped_mount /System/Volumes/Data"
Enter
Show
Sleep 800ms
Type "tmux set -g @disk_revamped_mount /System/Volumes/Data"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 4s
Screenshot mount.png
Sleep 1s
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g @disk_revamped_mount /"
Enter
Show
Sleep 800ms
Type "tmux set -g @disk_revamped_mount /"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1200ms
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g status-right #{disk_graph} #{disk_percentage} "
Enter
Show
Sleep 800ms
Type "tmux set -g status-right '#{disk_graph} #{disk_percentage} '"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1200ms
Hide
Ctrl+]
Sleep 300ms
Type@5ms "disk-revamped apply"
Enter
Show
Sleep 800ms
Type "disk-revamped apply"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1200ms
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g @disk_revamped_history_length 6"
Enter
Show
Sleep 800ms
Type "tmux set -g @disk_revamped_history_length 6"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 9s
Screenshot history.png
Sleep 1s
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g status-right #{disk_fill_rate} #{disk_full_eta} #{disk_percentage} "
Enter
Show
Sleep 800ms
Type "tmux set -g status-right '#{disk_fill_rate} #{disk_full_eta} #{disk_percentage} '"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1200ms
Hide
Ctrl+]
Sleep 300ms
Type@5ms "disk-revamped apply"
Enter
Show
Sleep 800ms
Type "disk-revamped apply"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 8s
Screenshot fill.png
Sleep 1s
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g @disk_revamped_high_thresh 40"
Enter
Show
Sleep 800ms
Type "tmux set -g @disk_revamped_high_thresh 40"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1200ms
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g @disk_revamped_notify 1"
Enter
Show
Sleep 800ms
Type "tmux set -g @disk_revamped_notify 1"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1200ms
Hide
Ctrl+]
Sleep 300ms
Type@5ms "cat /Users/Shared/demo/notifications.log"
Enter
Show
Sleep 800ms
Type "cat /Users/Shared/demo/notifications.log"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 9s
Screenshot notify.png
Sleep 1s
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g @disk_revamped_notify 0"
Enter
Show
Sleep 800ms
Type "tmux set -g @disk_revamped_notify 0"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1200ms
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g @disk_revamped_popup_key M-y"
Enter
Show
Sleep 800ms
Type "tmux set -g @disk_revamped_popup_key M-y"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1200ms
Hide
Ctrl+]
Sleep 300ms
Type@5ms "disk-revamped apply"
Enter
Show
Sleep 800ms
Type "disk-revamped apply"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 2s
Hide
Type "clear"
Enter
Sleep 600ms
Ctrl+]
Sleep 300ms
Type@5ms "prefix M-y, Enter"
Enter
Show
Ctrl+B
Escape
Type@1ms "y"
Sleep 4s
Screenshot popup-key.png
Sleep 1s
Enter
Sleep 1500ms
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g @disk_revamped_eat_key M-u"
Enter
Show
Sleep 800ms
Type "tmux set -g @disk_revamped_eat_key M-u"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1200ms
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g @disk_revamped_eat_path /Users/Shared/demo/data"
Enter
Show
Sleep 800ms
Type "tmux set -g @disk_revamped_eat_path /Users/Shared/demo/data"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1200ms
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g @disk_revamped_eat_count 4"
Enter
Show
Sleep 800ms
Type "tmux set -g @disk_revamped_eat_count 4"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1200ms
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g @disk_revamped_eat_interval 5"
Enter
Show
Sleep 800ms
Type "tmux set -g @disk_revamped_eat_interval 5"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1200ms
Hide
Ctrl+]
Sleep 300ms
Type@5ms "disk-revamped apply"
Enter
Show
Sleep 800ms
Type "disk-revamped apply"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 2s
Hide
Type "clear"
Enter
Sleep 600ms
Ctrl+]
Sleep 300ms
Type@5ms "prefix M-u, Enter"
Enter
Show
Ctrl+B
Escape
Type@1ms "u"
Sleep 5s
Screenshot eat.png
Sleep 1s
Enter
Sleep 1500ms
