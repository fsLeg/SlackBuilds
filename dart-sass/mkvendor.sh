#!/bin/bash

set -e

CWD="$(pwd)"
TMP="${TMP:-$(mktemp -d)}"
source "$CWD/dart-sass.info"
OUTPUT="${OUTPUT:-$CWD}"
export PUB_CACHE="$TMP/vendor/pub-cache"

tar xf "$CWD/$PRGNAM-$VERSION.tar.gz" -C "$TMP"
cd "$TMP/$PRGNAM-$VERSION"

dart --disable-analytics
dart pub get

if [ -f "$OUTPUT/$PRGNAM-$VERSION-vendored-sources.tar" ]; then
    rm "$OUTPUT/$PRGNAM-$VERSION-vendored-sources.tar"
fi

tar cfJ "$OUTPUT/$PRGNAM-$VERSION-vendored-sources.tar.xz" -C "$TMP" vendor/

cd "$CWD"
rm -rf "$TMP"
