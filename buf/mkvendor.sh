#!/bin/bash

set -e

CWD="$(pwd)"
TMP="${TMP:-$(mktemp -d)}"
source "$CWD/buf.info"
OUTPUT="${OUTPUT:-$CWD}"
export GOPATH="$TMP/cache"
export GOCACHE="$TMP/cache"

tar xf "$CWD/$PRGNAM-$VERSION.tar.gz" -C "$TMP"
cd "$TMP/$PRGNAM-$VERSION"

go mod vendor

if [ -f "$OUTPUT/$PRGNAM-$VERSION-vendored-sources.tar" ]; then
    rm "$OUTPUT/$PRGNAM-$VERSION-vendored-sources.tar"
fi

tar cfJ "$OUTPUT/$PRGNAM-$VERSION-vendored-sources.tar.xz" vendor/

cd "$CWD"
su -c "rm -rf \"$TMP\""
