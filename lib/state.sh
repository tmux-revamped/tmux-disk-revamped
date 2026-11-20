#!/bin/sh
# shellcheck disable=SC2034

[ -n "${DISK_REVAMPED_STATE_LOADED:-}" ] && return 0
DISK_REVAMPED_STATE_LOADED=1

DISK_REVAMPED_SETTINGS='popup_key	M-d
eat_key
mount	/
interval	30
detail_interval	60
render	jobs
percentage_format	%s%%
size_format	%sG
medium_thresh	70
high_thresh	90
low_icon	▰▱▱
medium_icon	▰▰▱
high_icon	▰▰▰
low_fg_color
medium_fg_color
high_fg_color
low_bg_color
medium_bg_color
high_bg_color
separator	, 
mounts
inodes_format	i%s%%
history_length	20
icons	ascii
fixed_width	off
notify	0
eat_path
eat_count	10
eat_interval	60
percentage_label
used_label
total_label
free_label
read_label
write_label
inodes_label
purgeable_label
graph_label
fill_rate_label
full_eta_label
mounts_label
all_label
percentage_width
used_width
total_width
free_width
read_width
write_width
inodes_width
purgeable_width
graph_width
fill_rate_width
full_eta_width
mounts_width
all_width'
DISK_REVAMPED_NAMES='popup_key eat_key mount interval detail_interval render percentage_format size_format medium_thresh high_thresh low_icon medium_icon high_icon low_fg_color medium_fg_color high_fg_color low_bg_color medium_bg_color high_bg_color separator mounts inodes_format history_length icons fixed_width notify eat_path eat_count eat_interval percentage_label used_label total_label free_label read_label write_label inodes_label purgeable_label graph_label fill_rate_label full_eta_label mounts_label all_label percentage_width used_width total_width free_width read_width write_width inodes_width purgeable_width graph_width fill_rate_width full_eta_width mounts_width all_width'
DISK_REVAMPED_CARRIED='mount interval detail_interval render percentage_format size_format medium_thresh high_thresh low_icon medium_icon high_icon low_fg_color medium_fg_color high_fg_color low_bg_color medium_bg_color high_bg_color separator mounts inodes_format history_length icons fixed_width notify eat_path eat_count eat_interval percentage_label used_label total_label free_label read_label write_label inodes_label purgeable_label graph_label fill_rate_label full_eta_label mounts_label all_label percentage_width used_width total_width free_width read_width write_width inodes_width purgeable_width graph_width fill_rate_width full_eta_width mounts_width all_width'
DISK_REVAMPED_LIVE='percent used total free read write inodes purgeable mounts_list all fill_rate full_eta history rd_raw wr_raw io_ts used_raw fill_ts eat notified percent_ts percent_lock percent_lock_ts all_ts eat_ts published'
DISK_REVAMPED_S_popup_key='M-d'
DISK_REVAMPED_S_eat_key=''
DISK_REVAMPED_S_mount='/'
DISK_REVAMPED_S_interval='30'
DISK_REVAMPED_S_detail_interval='60'
DISK_REVAMPED_S_render='jobs'
DISK_REVAMPED_S_percentage_format='%s%%'
DISK_REVAMPED_S_size_format='%sG'
DISK_REVAMPED_S_medium_thresh='70'
DISK_REVAMPED_S_high_thresh='90'
DISK_REVAMPED_S_low_icon='▰▱▱'
DISK_REVAMPED_S_medium_icon='▰▰▱'
DISK_REVAMPED_S_high_icon='▰▰▰'
DISK_REVAMPED_S_low_fg_color=''
DISK_REVAMPED_S_medium_fg_color=''
DISK_REVAMPED_S_high_fg_color=''
DISK_REVAMPED_S_low_bg_color=''
DISK_REVAMPED_S_medium_bg_color=''
DISK_REVAMPED_S_high_bg_color=''
DISK_REVAMPED_S_separator=', '
DISK_REVAMPED_S_mounts=''
DISK_REVAMPED_S_inodes_format='i%s%%'
DISK_REVAMPED_S_history_length='20'
DISK_REVAMPED_S_icons='ascii'
DISK_REVAMPED_S_fixed_width='off'
DISK_REVAMPED_S_notify='0'
DISK_REVAMPED_S_eat_path=''
DISK_REVAMPED_S_eat_count='10'
DISK_REVAMPED_S_eat_interval='60'
DISK_REVAMPED_S_percentage_label=''
DISK_REVAMPED_S_used_label=''
DISK_REVAMPED_S_total_label=''
DISK_REVAMPED_S_free_label=''
DISK_REVAMPED_S_read_label=''
DISK_REVAMPED_S_write_label=''
DISK_REVAMPED_S_inodes_label=''
DISK_REVAMPED_S_purgeable_label=''
DISK_REVAMPED_S_graph_label=''
DISK_REVAMPED_S_fill_rate_label=''
DISK_REVAMPED_S_full_eta_label=''
DISK_REVAMPED_S_mounts_label=''
DISK_REVAMPED_S_all_label=''
DISK_REVAMPED_S_percentage_width=''
DISK_REVAMPED_S_used_width=''
DISK_REVAMPED_S_total_width=''
DISK_REVAMPED_S_free_width=''
DISK_REVAMPED_S_read_width=''
DISK_REVAMPED_S_write_width=''
DISK_REVAMPED_S_inodes_width=''
DISK_REVAMPED_S_purgeable_width=''
DISK_REVAMPED_S_graph_width=''
DISK_REVAMPED_S_fill_rate_width=''
DISK_REVAMPED_S_full_eta_width=''
DISK_REVAMPED_S_mounts_width=''
DISK_REVAMPED_S_all_width=''
DISK_REVAMPED_S_percent=''
DISK_REVAMPED_S_used=''
DISK_REVAMPED_S_total=''
DISK_REVAMPED_S_free=''
DISK_REVAMPED_S_read=''
DISK_REVAMPED_S_write=''
DISK_REVAMPED_S_inodes=''
DISK_REVAMPED_S_purgeable=''
DISK_REVAMPED_S_mounts_list=''
DISK_REVAMPED_S_all=''
DISK_REVAMPED_S_fill_rate=''
DISK_REVAMPED_S_full_eta=''
DISK_REVAMPED_S_history=''
DISK_REVAMPED_S_rd_raw=''
DISK_REVAMPED_S_wr_raw=''
DISK_REVAMPED_S_io_ts=''
DISK_REVAMPED_S_used_raw=''
DISK_REVAMPED_S_fill_ts=''
DISK_REVAMPED_S_eat=''
DISK_REVAMPED_S_notified=''
DISK_REVAMPED_S_percent_ts=''
DISK_REVAMPED_S_percent_lock=''
DISK_REVAMPED_S_percent_lock_ts=''
DISK_REVAMPED_S_all_ts=''
DISK_REVAMPED_S_eat_ts=''
DISK_REVAMPED_S_published=''
DISK_REVAMPED_METRICS='percentage icon fg_color bg_color used total read write all free inodes purgeable graph fill_rate full_eta mounts'
DISK_REVAMPED_LABELLED='percentage used total free read write inodes purgeable graph fill_rate full_eta mounts all'
DISK_REVAMPED_DEFAULT_POPUP_KEY='M-d'
DISK_REVAMPED_DEFAULT_INTERVAL=30
DISK_REVAMPED_DEFAULT_DETAIL=60
DISK_REVAMPED_DEFAULT_MEDIUM=70
DISK_REVAMPED_DEFAULT_HIGH=90
DISK_REVAMPED_DEFAULT_HISTORY=20
DISK_REVAMPED_DEFAULT_EAT_COUNT=10
DISK_REVAMPED_DEFAULT_EAT_INTERVAL=60
DISK_REVAMPED_POPUP_SINCE=3.2
DISK_REVAMPED_NOTES_SINCE=3.1
DISK_REVAMPED_SYS="${REVAMPED_TEST_SYS:-/sys}"
DISK_REVAMPED_BSD_DF="${REVAMPED_TEST_DF:-/bin/df}"
DISK_REVAMPED_DF='df'
DISK_REVAMPED_SEP=$(printf '\037')
DISK_REVAMPED_EMPTY='disk-revamped-empty-argument'
DISK_REVAMPED_MARK='disk-revamped-section:'
DISK_REVAMPED_CARD_ROOM=17
DISK_REVAMPED_TMUX=''
DISK_REVAMPED_NOTES=0
DISK_REVAMPED_TOOL=''
DISK_REVAMPED_JOB=''
DISK_REVAMPED_KEYS=''
DISK_REVAMPED_SKIPPED=''
DISK_REVAMPED_PLAN=''
DISK_REVAMPED_NOW=0
DISK_REVAMPED_LIMIT=30
DISK_REVAMPED_DETAIL=60
DISK_REVAMPED_NUMBER=0
DISK_REVAMPED_DOUBLED=''
DISK_REVAMPED_WANT=''
DISK_REVAMPED_RAW=''
DISK_REVAMPED_DUE=''
DISK_REVAMPED_POPUP_OK=0
DISK_REVAMPED_STORED=0
DISK_REVAMPED_TIER='low'
DISK_REVAMPED_OUT=''
DISK_REVAMPED_LABEL=''
DISK_REVAMPED_WIDTH=''
DISK_REVAMPED_GLYPH=''
DISK_REVAMPED_NATURAL=0
DISK_REVAMPED_CARD=''
DISK_REVAMPED_ROWS=''
DISK_REVAMPED_TARGET=''
DISK_REVAMPED_SIZE=''
DISK_REVAMPED_SCAN=''
DISK_REVAMPED_F_percent=''
DISK_REVAMPED_F_used=''
DISK_REVAMPED_F_total=''
DISK_REVAMPED_F_free=''
DISK_REVAMPED_F_read=''
DISK_REVAMPED_F_write=''
DISK_REVAMPED_F_inodes=''
DISK_REVAMPED_F_purgeable=''
DISK_REVAMPED_F_mounts_list=''
DISK_REVAMPED_F_all=''
DISK_REVAMPED_F_fill_rate=''
DISK_REVAMPED_F_full_eta=''
DISK_REVAMPED_F_history=''
DISK_REVAMPED_F_rd_raw=''
DISK_REVAMPED_F_wr_raw=''
DISK_REVAMPED_F_io_ts=''
DISK_REVAMPED_F_used_raw=''
DISK_REVAMPED_F_fill_ts=''
REVAMPED_CACHE_PREFIX=disk_revamped
DISK_REVAMPED_KINDS='interval	number
detail_interval	number
medium_thresh	number
high_thresh	number
history_length	number 1
eat_count	number 1
eat_interval	number
percentage_width	number
used_width	number
total_width	number
free_width	number
read_width	number
write_width	number
inodes_width	number
purgeable_width	number
graph_width	number
fill_rate_width	number
full_eta_width	number
mounts_width	number
all_width	number
render	jobs options
icons	ascii nerd
fixed_width	on off
notify	0 1'
