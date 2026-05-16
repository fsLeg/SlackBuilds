#!/bin/sh

set -e

CWD="$(pwd)"
TMP="${TMP:-$(mktemp -d)}"
. "$CWD/buf.info"
OUTPUT="${OUTPUT:-$CWD}"
export GOPATH="$TMP/cache"
export GOCACHE="$TMP/cache"
unset XZ_DEFAULTS XZ_OPT

tar xf "$CWD/$PRGNAM-$VERSION.tar.gz" -C "$TMP"
cd "$TMP/$PRGNAM-$VERSION"

go mod vendor

if [ -f "$OUTPUT/$PRGNAM-$VERSION-vendored-sources.tar.xz" ]; then
    rm -v "$OUTPUT/$PRGNAM-$VERSION-vendored-sources.tar.xz"
fi

# the archive is not reproducible due to different vendor/modules.txt on
# different systems; blame go.
tar --sort=name \
    --mtime="@$(date --date="$(tar tvf "$CWD/$PRGNAM-$VERSION.tar.gz" | head -1 | awk '{print $4" "$5}')" +"%s")" \
    --owner=0 --group=0 --numeric-owner \
    --pax-option=exthdr.name=%d/PaxHeaders/%f,delete=atime,delete=ctime \
    --create vendor/ | xz -6e --threads=1 > "$OUTPUT/$PRGNAM-$VERSION-vendored-sources.tar.xz"

go clean -cache -modcache
cd "$CWD"
rm -r "$TMP"
