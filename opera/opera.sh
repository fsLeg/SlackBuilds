#!/bin/bash

# Allow users to override command-line options
# Based on Gentoo's chromium package (and by extension, Debian's)
if [[ -f /etc/default/opera_FLAVOR_ ]]; then
	. /etc/default/opera_FLAVOR_
fi

# Prefer user defined OPERA_USER_FLAGS (from env) over system
# default OPERA_FLAGS (from /etc/default/opera_FLAVOR_)
OPERA_FLAGS=${OPERA_USER_FLAGS:-$OPERA_FLAGS}

export CHROME_WRAPPER=$(readlink -f "$0")
export CHROME_DESKTOP=opera_FLAVOR_.desktop

# Use ffmpeg libs
export LD_LIBRARY_PATH="PATH_TO_FFMPEG:${LD_LIBRARY_PATH}"

exec /usr/lib_LIBDIRSUFFIX_/opera_FLAVOR_/opera_FLAVOR_ $OPERA_FLAGS "$@"

