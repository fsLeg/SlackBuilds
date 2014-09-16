#!/bin/bash

# Allow users to override command-line options
# Based on Gentoo's chromium package (and by extension, Debian's)
if [[ -f /etc/default/opera-developer ]]; then
	. /etc/default/opera-developer
fi

# Prefer user defined OPERA_USER_FLAGS (from env) over system
# default OPERA_FLAGS (from /etc/default/opera-developer)
OPERA_FLAGS=${OPERA_USER_FLAGS:-$OPERA_FLAGS}

export CHROME_WRAPPER=$(readlink -f "$0")
export CHROME_DESKTOP=opera-developer.desktop

exec /usr/lib64/opera-developer/opera-developer $OPERA_FLAGS "$@"

