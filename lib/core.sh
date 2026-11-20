#!/bin/sh
# shellcheck disable=SC2034

[ -n "${DISK_REVAMPED_CORE_LOADED:-}" ] && return 0
DISK_REVAMPED_CORE_LOADED=1

readonly DISK_REVAMPED_VERSION="3.0.0"
