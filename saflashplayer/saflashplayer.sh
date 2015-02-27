#!/bin/sh

LD_LIBRARY_PATH="/usr/lib/seamonkey:${LD_LIBRARY_PATH}" \
/usr/bin/saflashplayer.bin "$@"
