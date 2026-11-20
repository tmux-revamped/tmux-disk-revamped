Source common.tape
Output hero.gif
Hide
Type "printf 1 >/Users/Shared/demo/phase; tmux -L revamped-screens attach -t demo"
Enter
Sleep 1.5s
Show
Sleep 7s
Screenshot status.png
Sleep 1s
Hide
Ctrl+B
Type ":"
Sleep 300ms
Type "run-shell 'rm -f /Users/Shared/demo/phase'"
Enter
Show
Sleep 3s
Hide
Ctrl+]
Sleep 300ms
Type@5ms "prefix M-d, Enter"
Enter
Show
Ctrl+B
Escape
Type@1ms "d"
Sleep 5s
Screenshot popup.png
Sleep 1s
Enter
Sleep 1500ms
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g @disk_revamped_icons nerd"
Enter
Show
Sleep 800ms
Type "tmux set -g @disk_revamped_icons nerd"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 3500ms
Screenshot icons.png
Sleep 1s
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g @disk_revamped_icons ascii"
Enter
Show
Sleep 800ms
Type "tmux set -g @disk_revamped_icons ascii"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1500ms
Hide
Ctrl+B
Type ":"
Sleep 300ms
Type "run-shell 'printf rotate >/Users/Shared/demo/phase'"
Enter
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g status-right #{disk_graph} #{disk_percentage} #{disk_fill_rate} #{disk_full_eta} "
Enter
Show
Sleep 800ms
Type "tmux set -g status-right '#{disk_graph} #{disk_percentage} #{disk_fill_rate} #{disk_full_eta} '"
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
Sleep 800ms
Hide
Ctrl+B
Type ":"
Sleep 300ms
Type "run-shell 'printf 2 >/Users/Shared/demo/phase'"
Enter
Show
Sleep 12s
Screenshot graph.png
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
Type@5ms "tmux set -g @disk_revamped_render options"
Enter
Show
Sleep 800ms
Type "tmux set -g @disk_revamped_render options"
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
Type@5ms "tmux set -g status-right #{disk_graph} #{disk_percentage} #{disk_all} "
Enter
Show
Sleep 800ms
Type "tmux set -g status-right '#{disk_graph} #{disk_percentage} #{disk_all} '"
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
Type@5ms "tmux show -gv status-right | cut -c1-90"
Enter
Show
Sleep 800ms
Type "tmux show -gv status-right | cut -c1-90"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 3s
Screenshot options.png
Sleep 1s
Sleep 1500ms
