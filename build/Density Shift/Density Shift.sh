#!/bin/sh
printf '\033c\033]0;%s\a' Density Shift
base_path="$(dirname "$(realpath "$0")")"
"$base_path/Density Shift" "$@"
