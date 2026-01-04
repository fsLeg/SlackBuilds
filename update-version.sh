#!/bin/sh

# Update the version of SlackBuilds. Useful for incremental updates.
# Intended to be run from the root of the repo.
# It updates the version in the .SlackBuild and .info files, generates
# vendored-sources tarball and updates MD5 checksums in the .info file.

set -e

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: $0 PRGNAM NEWVER"
  exit 1
fi

PRGNAM="${1%/}"
NEWVER="$2"
CWD="$(pwd)"

cd "$PRGNAM"

. "./$PRGNAM.info"
sed -i "s|$(echo "$VERSION" | sed 's/\./\\./g')|$NEWVER|g" "$PRGNAM.SlackBuild" "$PRGNAM.info"
unset VERSION DOWNLOAD DOWNLOAD_x86_64
. "./$PRGNAM.info"

for URL in $(test "$DOWNLOAD" != "UNSUPPORTED" && echo "$DOWNLOAD" || echo "") \
           $(test -n "$DOWNLOAD_x86_64" && echo "$DOWNLOAD_x86_64" || echo "")
do
  if [ ! -f "$(basename "$URL")" ]; then
    wget --tries=inf --retry-on-http-error=503 "$URL" || true
  fi
done

if [ -f mkvendor.sh ]; then
  sh mkvendor.sh
  # send a notification before entering password
  tput bel  || true
  echo put $PRGNAM-$VERSION-vendored-sources.tar* | sftp sawako:/media/slab1/sbo
fi

if [ "$DOWNLOAD" != "UNSUPPORTED" ]; then
  for TARBALL in $(basename -a $DOWNLOAD); do
    CHECKSUMS="$CHECKSUMS$(md5sum "$TARBALL" | cut -d' ' -f1) "
  done
  perl -0777 -pi -e 's|MD5SUM="[0-9a-f\s\\]*"|MD5SUM="'"${CHECKSUMS% }"'"|' "$PRGNAM.info"
fi
if [ -n "$DOWNLOAD_x86_64" ] && [ "$DOWNLOAD_x86_64" != "UNSUPPORTED" ]; then
  for TARBALL in $(basename -a $DOWNLOAD_x86_64); do
    CHECKSUMS64="$CHECKSUMS64$(md5sum "$TARBALL" | cut -d' ' -f1) "
  done
  perl -0777 -pi -e 's|MD5SUM_x86_64="[0-9a-f\s\\]*"|MD5SUM_x86_64="'"${CHECKSUMS64% }"'"|' "$PRGNAM.info"
fi

sbofixinfo
rm -f "$PRGNAM.info.bak"

if [ -z "$NOBUILD" ]; then
  time fakeroot bash "$PRGNAM.SlackBuild"
fi

cd "$CWD"
