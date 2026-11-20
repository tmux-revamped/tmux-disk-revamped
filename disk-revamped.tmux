#!/bin/sh

disk_revamped_dir=$(cd "$(dirname "$0")" && pwd)
"${disk_revamped_dir}/bin/disk-revamped" apply
