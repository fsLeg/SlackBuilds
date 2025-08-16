#!/bin/bash

set -e

CWD="$(pwd)"
TMP="${TMP:-$(mktemp -d)}"
source "$CWD/popcorntime.info"
TARNAM=popcorn-desktop
OUTPUT="${OUTPUT:-$CWD}"
export YARN_CACHE_FOLDER="$TMP/cache"
export npm_config_cache="$YARN_CACHE_FOLDER"
export YARN_YARN_OFFLINE_MIRROR="$TMP/vendor"

tar xf "$CWD/$TARNAM-$VERSION.tar.gz" -C "$TMP"
cd "$TMP/$TARNAM-$VERSION"

# fix links for some dependencies
# https://aur.archlinux.org/cgit/aur.git/tree/yarn_lock-fixes.patch?h=popcorntime
cat << EOF > yarn_lock-fixes.patch
diff --git a/yarn.lock b/yarn.lock
index 9764d06ef..d7e51c545 100644
--- a/yarn.lock
+++ b/yarn.lock
@@ -7227,7 +7227,7 @@ teex@^1.0.1:
 
 "temp@github:adam-lynch/node-temp#remove_tmpdir_dep":
   version "0.8.3"
-  resolved "git+ssh://git@github.com/adam-lynch/node-temp.git#279c1350cb7e4f02515d91da9e35d39a40774016"
+  resolved "git+https://github.com/adam-lynch/node-temp.git#279c1350cb7e4f02515d91da9e35d39a40774016"
   dependencies:
     rimraf "~2.2.6"
 
@@ -7994,7 +7994,7 @@ vinyl@^3.0.0:
 
 "vtt.js@git+https://github.com/gkatsev/vtt.js.git#vjs-v0.12.1":
   version "0.12.1"
-  resolved "git+ssh://git@github.com/gkatsev/vtt.js.git#8ea664e257ec7b5c092f58ac989e3134ff536a7a"
+  resolved "git+https://github.com/gkatsev/vtt.js.git#8ea664e257ec7b5c092f58ac989e3134ff536a7a"
 
 w-json@^1.3.10:
   version "1.3.10"
EOF
patch -p1 < yarn_lock-fixes.patch

mkdir -p "$YARN_YARN_OFFLINE_MIRROR"
yarn install --frozen-lockfile \
             --ignore-engines \
             --ignore-scripts \
             --no-fund \
             --production

if [ -f "$OUTPUT/$PRGNAM-$VERSION-vendored-sources.tar" ]; then
    rm "$OUTPUT/$PRGNAM-$VERSION-vendored-sources.tar"
fi

tar cf "$OUTPUT/$PRGNAM-$VERSION-vendored-sources.tar" -C "$TMP" vendor/

cd "$CWD"
rm -rf "$TMP"
