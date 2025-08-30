#!/bin/sh

set -e

CWD="$(pwd)"
TMP="${TMP:-$(mktemp -d)}"
. "$CWD/buf.info"
OUTPUT="${OUTPUT:-$CWD}"
export GOPATH="$TMP/cache"
export GOCACHE="$TMP/cache"

tar xf "$CWD/$PRGNAM-$VERSION.tar.gz" -C "$TMP"
cd "$TMP/$PRGNAM-$VERSION"

go mod vendor

if [ -f "$OUTPUT/$PRGNAM-$VERSION-vendored-sources.tar.xz" ]; then
    rm -v "$OUTPUT/$PRGNAM-$VERSION-vendored-sources.tar.xz"
fi

tar cfJ "$OUTPUT/$PRGNAM-$VERSION-vendored-sources.tar.xz" vendor/

go clean -cache -modcache
cd "$CWD"
rm -rv "$TMP"
