#!/bin/sh

set -e

CWD="$(pwd)"
TMP="${TMP:-$(mktemp -d)}"
. "$CWD/dart-sass.info"
OUTPUT="${OUTPUT:-$CWD}"
export PUB_CACHE="$TMP/vendor/pub-cache"
unset XZ_DEFAULTS XZ_OPT

tar xf "$CWD/$PRGNAM-$VERSION.tar.gz" -C "$TMP"
cd "$TMP/$PRGNAM-$VERSION"

dart --disable-analytics
dart pub get

if [ -f "$OUTPUT/$PRGNAM-$VERSION-vendored-sources.tar.xz" ]; then
    rm -v "$OUTPUT/$PRGNAM-$VERSION-vendored-sources.tar.xz"
fi

tar --sort=name \
    --mtime="@$(date --date="$(tar tvf "$CWD/$PRGNAM-$VERSION.tar.gz" | head -1 | awk '{print $4" "$5}')" +"%s")" \
    --owner=0 --group=0 --numeric-owner \
    --pax-option=exthdr.name=%d/PaxHeaders/%f,delete=atime,delete=ctime \
    --create --directory="$TMP" vendor/ | xz -6e --threads=1 > "$OUTPUT/$PRGNAM-$VERSION-vendored-sources.tar.xz"

cd "$CWD"
rm -r "$TMP"
