#!/bin/bash

[ -n "$1" ] && FILENAME="$1" || { echo "Filename is required"; exit 1; }

# Extract part before '#'
NAME="${FILENAME%%#*}"

# Extract part after '#' + 3 bytes
START="${FILENAME#*#}"
START="${START:2}"

bintomon -l 0x$START -r- $FILENAME >$NAME.mon

