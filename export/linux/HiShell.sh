#!/bin/sh
printf '\033c\033]0;%s\a' HiShell
base_path="$(dirname "$(realpath "$0")")"
"$base_path/HiShell.x86_64" "$@"
