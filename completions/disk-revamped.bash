# shellcheck shell=bash
# shellcheck disable=SC2207

_disk_revamped() {
  local cur prev
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD - 1]}"

  case "${prev}" in
  --theme)
    COMPREPLY=($(compgen -W "kodougu catppuccin-mocha catppuccin-latte dracula nord gruvbox tokyo-night mono" -- "${cur}"))
    return
    ;;
  status)
    COMPREPLY=($(compgen -W "percentage icon fg_color bg_color used total read write all free inodes purgeable graph fill_rate full_eta mounts" -- "${cur}"))
    return
    ;;
  --render)
    COMPREPLY=($(compgen -W "jobs options" -- "${cur}"))
    return
    ;;
  --notify)
    COMPREPLY=($(compgen -W "0 1" -- "${cur}"))
    return
    ;;
  --icons)
    COMPREPLY=($(compgen -W "ascii nerd" -- "${cur}"))
    return
    ;;
  --fixed-width)
    COMPREPLY=($(compgen -W "on off" -- "${cur}"))
    return
    ;;
  --popup-key | --eat-key | --mount | --mounts | --interval | --detail-interval | --history-length | --medium-thresh | --high-thresh | --low-icon | --medium-icon | --high-icon | --low-fg-color | --medium-fg-color | --high-fg-color | --low-bg-color | --medium-bg-color | --high-bg-color | --percentage-format | --size-format | --inodes-format | --separator | --percentage-label | --used-label | --total-label | --free-label | --read-label | --write-label | --inodes-label | --purgeable-label | --graph-label | --fill-rate-label | --full-eta-label | --mounts-label | --all-label | --percentage-width | --used-width | --total-width | --free-width | --read-width | --write-width | --inodes-width | --purgeable-width | --graph-width | --fill-rate-width | --full-eta-width | --mounts-width | --all-width | --eat-path | --eat-count | --eat-interval)
    return
    ;;
  *) ;;
  esac

  COMPREPLY=($(compgen -W "apply list status refresh card scan popup eat daemon doctor version help --json --theme --popup-key --eat-key --mount --mounts --interval --detail-interval --render --history-length --notify --medium-thresh --high-thresh --low-icon --medium-icon --high-icon --low-fg-color --medium-fg-color --high-fg-color --low-bg-color --medium-bg-color --high-bg-color --percentage-format --size-format --inodes-format --separator --icons --fixed-width --percentage-label --used-label --total-label --free-label --read-label --write-label --inodes-label --purgeable-label --graph-label --fill-rate-label --full-eta-label --mounts-label --all-label --percentage-width --used-width --total-width --free-width --read-width --write-width --inodes-width --purgeable-width --graph-width --fill-rate-width --full-eta-width --mounts-width --all-width --eat-path --eat-count --eat-interval" -- "${cur}"))
}

complete -F _disk_revamped disk-revamped
