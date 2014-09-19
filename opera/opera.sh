#!/bin/bash

# Allow users to override command-line options
# Based on Gentoo's chromium package (and by extension, Debian's)
if [[ -f /etc/default/opera-beta ]]; then
	. /etc/default/opera-beta
fi

# Prefer user defined OPERA_USER_FLAGS (from env) over system
# default OPERA_FLAGS (from /etc/default/opera-beta)
OPERA_FLAGS=${OPERA_USER_FLAGS:-$OPERA_FLAGS}

export CHROME_WRAPPER=$(readlink -f "$0")
export CHROME_DESKTOP=opera-beta.desktop

# Use ffmpeg libs
export LD_LIBRARY_PATH="PATH_TO_FFMPEG:${LD_LIBRARY_PATH}"

exec /usr/lib_LIBDIRSUFFIX_/opera-beta/opera-beta $OPERA_FLAGS "$@"

