#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/disk_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/disk_helpers.bash"

logged() {
  grep -qxF -- "$1" "${FAKE}/log"
}

other_owner() {
  quiet sleep 'kept=$(grep -v "^@disk_revamped_ticker_pid	" "'"${FAKE}"'/vars" || :)
printf "%s\n@disk_revamped_ticker_pid\tsomeone-else\n" "${kept}" | grep -v "^$" >"'"${FAKE}"'/vars.next"
mv -f "'"${FAKE}"'/vars.next" "'"${FAKE}"'/vars"'
}

settled() {
  local tries=0
  until "$@"; do
    tries=$((tries + 1))
    [[ "${tries}" -lt 200 ]] || return 1
    /bin/sleep 0.05
  done
}

@test "plan - a fresh install binds the detail popup to M-d and nothing else" {
  # Arrange
  local tool
  tool=$(tool_path)

  # Act
  planned

  # Assert
  [[ "${output}" == "bind-key -N Disk details M-d run-shell ${tool} popup" ]]
}

@test "plan - the eat key binds the largest items popup, and off binds nothing" {
  # Arrange
  local tool
  tool=$(tool_path)
  option eat_key M-u
  option popup_key off

  # Act
  planned

  # Assert
  [[ "${output}" == "bind-key -N Largest items M-u run-shell ${tool} eat" ]]
}

@test "plan - a key set to off binds nothing, and a key the person names is bound whoever holds it" {
  # Arrange
  local tool
  tool=$(tool_path)
  option popup_key off
  option eat_key off
  planned
  [[ -z "${output}" ]]
  printf 'bind-key    -T prefix F8     display-message mine\n' >"${FAKE}/keys"
  option popup_key F8

  # Act
  planned

  # Assert
  [[ "${output}" == "bind-key -N Disk details F8 run-shell ${tool} popup" ]]
}

@test "plan - a tmux older than 3.1 gets its key without a note" {
  # Arrange
  tmux_is 3.0

  # Act
  planned

  # Assert
  [[ "${output}" == "bind-key M-d run-shell "*" popup" ]]
}

@test "plan - the default key is left alone when something else holds it, and bound again when the binding is the plugin's own" {
  # Arrange
  printf 'bind-key    -T prefix M-d     display-message mine\n' >"${FAKE}/keys"
  planned 'disk_revamped_plan; printf "[%s]\n" "${DISK_REVAMPED_SKIPPED}"; '
  [[ "${output}" == "[M-d]" ]]
  printf 'bind-key -r -T prefix M-d     run-shell "/old/bin/disk-revamped popup"\n' >"${FAKE}/keys"

  # Act
  planned

  # Assert
  [[ "${output}" == "bind-key -N Disk details M-d run-shell "*" popup" ]]
}

@test "plan - each placeholder becomes a job that prints it, and the metrics in use are recorded" {
  # Arrange
  local tool
  tool=$(tool_path)
  option popup_key off
  var status-right '#{disk_fg_color}#{disk_icon} #{disk_percentage}#[default] #{disk_used}/#{disk_total} #{disk_fill_rate}'
  var status-left '#{disk_graph} #S'

  # Act
  planned

  # Assert
  [[ "${lines[0]}" == "set-option -gq status-left #(${tool} status graph) #S" ]]
  [[ "${lines[1]}" == "set-option -gq status-right #(${tool} status fg_color)#(${tool} status icon) #(${tool} status percentage)#[default] #(${tool} status used)/#(${tool} status total) #(${tool} status fill_rate)" ]]
  [[ "${lines[2]}" == "set-option -gq @disk_revamped_published percentage icon fg_color used total graph fill_rate" ]]
  [[ "${#lines[@]}" -eq 3 ]]
}

@test "plan - every placeholder has its job" {
  # Arrange
  local tool
  tool=$(tool_path)
  option popup_key off
  var status-right '#{disk_bg_color}#{disk_read}#{disk_write}#{disk_all}#{disk_free}#{disk_inodes}#{disk_purgeable}#{disk_full_eta}#{disk_mounts}'

  # Act
  planned

  # Assert
  [[ "${lines[0]}" == "set-option -gq status-right #(${tool} status bg_color)#(${tool} status read)#(${tool} status write)#(${tool} status all)#(${tool} status free)#(${tool} status inodes)#(${tool} status purgeable)#(${tool} status full_eta)#(${tool} status mounts)" ]]
  [[ "${lines[1]}" == "set-option -gq @disk_revamped_published bg_color read write all free inodes purgeable full_eta mounts" ]]
}

@test "plan - a status line that ends in a semicolon keeps it, escaped, so tmux does not read it as a separator" {
  # Arrange
  local tool
  tool=$(tool_path)
  option popup_key off
  var status-right '#{disk_percentage};'

  # Act
  planned

  # Assert
  [[ "${lines[0]}" == "set-option -gq status-right #(${tool} status percentage)\\;" ]]
}

@test "plan - in options mode each placeholder becomes a read of the option the daemon fills" {
  # Arrange
  option popup_key off
  option render options
  var status-right '#{disk_fg_color}#{disk_percentage} | #{disk_all}'

  # Act
  planned

  # Assert
  [[ "${lines[0]}" == "set-option -gq status-right #{E:@disk_revamped_out_fg_color}#{E:@disk_revamped_out_percentage} | #{E:@disk_revamped_out_all}" ]]
  [[ "${lines[1]}" == "set-option -gq @disk_revamped_published percentage fg_color all" ]]
}

@test "plan - a render mode the plugin does not know means jobs" {
  # Arrange
  local tool
  tool=$(tool_path)
  option popup_key off
  option render both
  var status-right '#{disk_percentage}'

  # Act
  planned

  # Assert
  [[ "${lines[0]}" == "set-option -gq status-right #(${tool} status percentage)" ]]
}

@test "plan - a status line already rewritten is left as it is, and its metrics stay recorded" {
  # Arrange
  local tool
  tool=$(tool_path)
  option popup_key off
  option render options
  option published "percentage used"
  var status-right '#{E:@disk_revamped_out_percentage} | #{E:@disk_revamped_out_used}'
  planned
  [[ -z "${output}" ]]
  option render jobs
  option published "icon used"
  var status-right "#(${tool} status icon) #(${tool} status used)"

  # Act
  planned

  # Assert
  [[ -z "${output}" ]]
}

@test "plan - a status line with no placeholder is not written, and an old list of metrics is emptied" {
  # Arrange
  option popup_key off
  option published "percentage"
  var status-right '%H:%M #{session_name}'

  # Act
  planned

  # Assert
  [[ "${output}" == 'set-option -gq @disk_revamped_published ""' ]]
}

@test "plan - a setting given in the environment rides on the key and on every job" {
  # Arrange
  var status-right '#{disk_percentage}'

  # Act
  planned 'export DISK_REVAMPED_INTERVAL=2; '

  # Assert
  [[ "${lines[0]}" == *"disk-revamped' --interval '2' popup" ]]
  [[ "${lines[1]}" == *"disk-revamped' --interval '2' status percentage)" ]]
}

@test "plan - settings given in the environment ride in the order of the settings table, and an empty one rides too" {
  # Arrange
  var status-right '#{disk_percentage}'

  # Act
  planned 'export DISK_REVAMPED_HIGH_THRESH=90 DISK_REVAMPED_ALL_LABEL= DISK_REVAMPED_INTERVAL=3 DISK_REVAMPED_POPUP_KEY=F8 DISK_REVAMPED_MOUNT=/home; '

  # Assert
  [[ "${lines[0]}" == "bind-key -N Disk details F8 run-shell "*"disk-revamped' --mount '/home' --interval '3' --high-thresh '90' --all-label '' popup" ]]
}

@test "plan - apply sends everything in one tmux call and clears a daemon's claim in jobs mode" {
  # Arrange
  var status-right '#{disk_percentage}'

  # Act
  lib_run disk 'disk_revamped_apply'

  # Assert
  [[ "${status}" -eq 0 ]]
  run sends
  [[ "${#lines[@]}" -eq 2 ]]
  [[ "${lines[0]}" == "bind-key -N Disk details M-d run-shell "*" popup ; set-option -gq status-right #("*" status percentage) ; set-option -gq @disk_revamped_published percentage" ]]
  [[ "${lines[1]}" == "set-option -gqu @disk_revamped_ticker_pid" ]]
}

@test "plan - when tmux refuses the batch each command is sent alone, and the bad one fails the run" {
  # Arrange
  local tool
  tool=$(tool_path)
  option popup_key F99
  var status-right '#{disk_percentage}'
  printf '%s\n' "bind-key -N Disk details F99 run-shell ${tool} popup" >"${FAKE}/refused"

  # Act
  lib_run disk 'disk_revamped_apply'

  # Assert
  [[ "${status}" -eq 1 ]]
  run sent '^set-option -gq status-right #(.* status percentage)$'
  [[ "${output}" == "1" ]]
  holds published percentage
}

@test "plan - in options mode apply starts the daemon, which claims the ticker and publishes until another takes over" {
  # Arrange
  df_says "-Pk /" "${GNU_USAGE}"
  option popup_key off
  option render options
  option interval 1
  var status-right '#{disk_percentage}'
  other_owner

  # Act
  lib_run disk 'disk_revamped_apply'

  # Assert
  [[ "${status}" -eq 0 ]]
  settled holds out_percentage "55%%"
  settled holds ticker_pid someone-else
  run sent '^set-option -gq @disk_revamped_ticker_pid [0-9][0-9]*$'
  [[ "${output}" == "1" ]]
}

@test "plan - the daemon ends when another process owns the ticker" {
  # Arrange
  df_says "-Pk /" "${GNU_USAGE}"
  option published "used"
  other_owner

  # Act
  tool daemon

  # Assert
  [[ "${status}" -eq 0 ]]
  holds out_used "55G"
  holds ticker_pid someone-else
}

@test "plan - a published mount name has its hash and its percent sign doubled" {
  # Arrange
  df_says "-Pk /" "${GNU_USAGE}"
  df_says "-h" 'Filesystem Size Used Avail Use% Mounted on
/dev/sda1 1G 1G 1G 55% /mnt/#1'
  option published all
  other_owner

  # Act
  tool daemon

  # Assert
  holds out_all '/mnt/##1 55%%'
}

@test "plan - the detail popup runs the card in a popup of its own and waits for Enter" {
  # Arrange
  local tool
  tool=$(tool_path)

  # Act
  lib_run disk 'disk_revamped_popup'

  # Assert
  [[ "${status}" -eq 0 ]]
  logged "display-popup -E -w 80% -h 80% ${tool} card; read -r disk_revamped_wait"
}

@test "plan - the eat popup runs the scan" {
  # Arrange
  local tool
  tool=$(tool_path)

  # Act
  lib_run disk 'disk_revamped_eat'

  # Assert
  logged "display-popup -E -w 80% -h 80% ${tool} scan; read -r disk_revamped_wait"
}

@test "plan - a setting from the environment rides on the popup command, and a hash in the path leaves the command with none" {
  # Arrange
  local dir="${BATS_TEST_TMPDIR}/it's#1"
  mkdir -p "${dir}/lib" "${dir}/bin"
  cp -R "${REVAMPED_TESTS_DIR}/../lib/." "${dir}/lib/"

  # Act
  run env DISK_REVAMPED_MOUNT=/home sh -c '[ -n "${ZSH_VERSION:-}" ] && emulate sh; REVAMPED_LIB="$1"; . "${REVAMPED_LIB}/disk.sh"; disk_revamped_popup' sh "${dir}/lib"

  # Assert
  [[ "${status}" -eq 0 ]]
  logged "display-popup -E -w 80% -h 80% '${BATS_TEST_TMPDIR}/it'\\''s'\"\$(printf '%b' '\\0043')\"'1/bin/disk-revamped' --mount '/home' card; read -r disk_revamped_wait"
}

@test "plan - a tmux older than 3.2 says so and opens nothing" {
  # Arrange
  tmux_is 3.1

  # Act
  lib_run disk 'disk_revamped_popup'

  # Assert
  [[ "${status}" -eq 0 ]]
  logged "display-message disk-revamped: tmux 3.2+ is required for the disk popups"
  run sent '^display-popup'
  [[ "${output}" == "0" ]]
}

@test "plan - a popup or a message tmux refuses to open leaves the key quiet" {
  # Arrange
  printf '%s\n' "display-message disk-revamped: tmux 3.2+ is required for the disk popups" >"${FAKE}/refused"
  tmux_is 3.1
  lib_run disk 'disk_revamped_popup'
  [[ "${status}" -eq 0 ]]
  [[ -z "${output}" ]]
  tmux_is 3.6
  local tool
  tool=$(tool_path)
  printf '%s\n' "display-popup -E -w 80% -h 80% ${tool} card; read -r disk_revamped_wait" >"${FAKE}/refused"

  # Act
  lib_run disk 'disk_revamped_popup'

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ -z "${output}" ]]
}

@test "plan - a path is quoted for a job with each hash and each percent sign doubled, and for a key with no hash left" {
  # Arrange
  local script='disk_revamped_job_quote "/a b/it'"'"'s#1 50%"; disk_revamped_literal "/a b/it'"'"'s#1 50%"'

  # Act
  lib_run disk "${script}"

  # Assert
  [[ "${lines[0]}" == "'/a b/it'\\''s##1 50%%'" ]]
  [[ "${lines[1]}" == "'/a b/it'\\''s'\"\$(printf '%b' '\\0043')\"'1 50%'" ]]
}

@test "plan - a format given in the environment rides on the job with its percent signs doubled, since tmux reads the status line as a time format" {
  # Arrange
  option popup_key off
  var status-right '#{disk_percentage}'

  # Act
  planned 'export DISK_REVAMPED_PERCENTAGE_FORMAT="%s%% used"; '

  # Assert
  [[ "${lines[0]}" == *"disk-revamped' --percentage-format '%%s%%%% used' status percentage)" ]]
}

@test "plan - the same placeholder twice is replaced twice and recorded once" {
  # Arrange
  option popup_key off
  var status-left '#{disk_free} #{disk_free}'

  # Act
  planned

  # Assert
  [[ "${lines[0]}" == "set-option -gq status-left #("*" status free) #("*" status free)" ]]
  [[ "${lines[1]}" == "set-option -gq @disk_revamped_published free" ]]
}
