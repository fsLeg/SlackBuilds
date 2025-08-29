#!/bin/sh

set -e

CWD="$(pwd)"
TMP="${TMP:-$(mktemp -d)}"
. "$CWD/hugo.info"
OUTPUT="${OUTPUT:-$CWD}"
export GOPATH="$TMP/cache"
export GOCACHE="$TMP/cache"

tar xf "$CWD/$PRGNAM-$VERSION.tar.gz" -C "$TMP"
cd "$TMP/$PRGNAM-$VERSION"

go mod vendor

# libwebp-1.3.2 is the one in Slackware 15, newer ones don't compile
if [ -e "$CWD/libwebp-1.3.2.tar.gz" ]; then
  cp "$CWD/libwebp-1.3.2.tar.gz" "$TMP/"
else
  wget --directory-prefix="$TMP" --tries=0 --retry-on-http-error=503 "https://github.com/webmproject/libwebp/archive/v1.3.2/libwebp-v1.3.2.tar.gz"
fi
tar xf "$TMP/libwebp-1.3.2.tar.gz" -C ..
mv "$TMP/libwebp-1.3.2" vendor/github.com/bep/gowebp/libwebp_src

# libsass is deprecated, 3.6.6 is the last release
if [ -e "$CWD/libsass-3.6.6.tar.gz" ]; then
  cp "$CWD/libsass-3.6.6.tar.gz" "$TMP/"
else
  wget --directory-prefix="$TMP" --tries=0 --retry-on-http-error=503 "https://github.com/sass/libsass/archive/3.6.6/libsass-3.6.6.tar.gz"
fi
tar xf "$TMP/libsass-3.6.6.tar.gz" -C ..
mv "$TMP/libsass-3.6.6" vendor/github.com/bep/golibsass/libsass_src

if [ -f "$OUTPUT/$PRGNAM-$VERSION-vendored-sources.tar" ]; then
    rm "$OUTPUT/$PRGNAM-$VERSION-vendored-sources.tar"
fi

tar cfJ "$OUTPUT/$PRGNAM-$VERSION-vendored-sources.tar.xz" vendor/

go clean -cache -modcache
cd "$CWD"
rm -rf "$TMP"
