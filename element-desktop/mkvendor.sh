#!/bin/bash

set -e

if [ ! -x "$(which jq)" -o ! -x "$(which 7z)" ]; then
  echo Please install jq and p7zip.
  exit 1
fi

source element-desktop.info

CWD=$(pwd)
TMP=$(mktemp -d)

export PATH="/opt/rust/bin:$PATH"
if [ -z "$LD_LIBRARY_PATH" ]; then
  export LD_LIBRARY_PATH="/opt/rust/lib64"
else
  export LD_LIBRARY_PATH="/opt/rust/lib64:$LD_LIBRARY_PATH"
fi

cd $TMP
tar xf $CWD/element-desktop-$VERSION.tar.gz
tar xf $CWD/element-web-$VERSION.tar.gz

BASE_TMP_DIR=$TMP/element-desktop-$VERSION
export YARN_YARN_OFFLINE_MIRROR=$BASE_TMP_DIR/vendor
export YARN_CACHE_FOLDER=$BASE_TMP_DIR/cache
export npm_config_cache=$YARN_CACHE_FOLDER
export npm_config_nodedir=/usr
export XDG_CACHE_HOME=$BASE_TMP_DIR/electron-cache
export CARGO_HOME=$BASE_TMP_DIR/cargo

mkdir -p $YARN_YARN_OFFLINE_MIRROR

# element-web
cd element-web-$VERSION
yarn install --frozen-lockfile \
             --ignore-engines \
             --no-fund \
             --update-checksums
yarn cache clean

# element-desktop
cd ../element-desktop-$VERSION

## pre-built electron
EVERSION=$(jq --raw-output '.devDependencies.electron' < package.json)
mkdir -p $XDG_CACHE_HOME/electron{,-builder/fpm@2.0.1/fpm@2.0.1-fpm-1.16.0-ruby-3.4.3-linux-amd64}
if [ -e $CWD/electron-v$EVERSION-linux-x64.zip ]; then
  cp $CWD/electron-v$EVERSION-linux-x64.zip $XDG_CACHE_HOME/electron/
else
  wget --directory-prefix=$XDG_CACHE_HOME/electron --tries=0 --retry-on-http-error=503 https://github.com/electron/electron/releases/download/v$EVERSION/electron-v$EVERSION-linux-x64.zip
fi

## pre-built ruby for electron-builder
if [ -e $CWD/fpm-1.16.0-ruby-3.4.3-linux-amd64.7z ]; then
  cp $CWD/fpm-1.16.0-ruby-3.4.3-linux-amd64.7z $XDG_CACHE_HOME/electron-builder/
else
  wget --directory-prefix=$XDG_CACHE_HOME/electron-builder --tries=0 --retry-on-http-error=503 https://github.com/electron-userland/electron-builder-binaries/releases/download/fpm@2.0.1/fpm-1.16.0-ruby-3.4.3-linux-amd64.7z
fi
7z x -o$XDG_CACHE_HOME/electron-builder/fpm@2.0.1/fpm@2.0.1-fpm-1.16.0-ruby-3.4.3-linux-amd64 $XDG_CACHE_HOME/electron-builder/fpm-1.16.0-ruby-3.4.3-linux-amd64.7z
rm $XDG_CACHE_HOME/electron-builder/fpm-1.16.0-ruby-3.4.3-linux-amd64.7z

## element-desktop itself
yarn install --frozen-lockfile \
             --ignore-engines \
             --no-fund \
             --update-checksums
yarn cache clean
EDIR=$(find $XDG_CACHE_HOME/electron -type d -mindepth 1 -maxdepth 1)
rm $EDIR/electron-v$EVERSION-linux-x64.zip
ln -s ../electron-v$EVERSION-linux-x64.zip $EDIR/

## matrix-seshat
RUST_PLATFORM=$(rustc -Vv | awk '/host/ {print $2}')
SESHATVERSION=$(jq --raw-output '.hakDependencies."matrix-seshat"' < package.json | tr -d '^')
mkdir -p .hak/hakModules .hak/matrix-seshat/$RUST_PLATFORM
if [ -e $CWD/seshat-$SESHATVERSION.tar.gz ]; then
  cp $CWD/seshat-$SESHATVERSION.tar.gz .hak/
else
  wget --directory-prefix=.hak --tries=0 --retry-on-http-error=503 https://github.com/matrix-org/seshat/archive/$SESHATVERSION/seshat-$SESHATVERSION.tar.gz
fi
tar xf .hak/seshat-$SESHATVERSION.tar.gz -C .hak seshat-$SESHATVERSION/seshat-node
mv .hak/seshat-$SESHATVERSION/seshat-node .hak/matrix-seshat/$RUST_PLATFORM/build
cp -R .hak/matrix-seshat/$RUST_PLATFORM/build .hak/hakModules/matrix-seshat
rm .hak/seshat-$SESHATVERSION.tar.gz

cd .hak/matrix-seshat/$RUST_PLATFORM/build
yarn install --frozen-lockfile \
             --ignore-engines \
             --no-fund \
             --update-checksums
yarn cache clean

## native extensions
cat << EOF >> Cargo.toml
[package.metadata.vendor-filter]
platforms = ["x86_64-unknown-linux-gnu", "aarch64-unknown-linux-gnu"]
all-features = true
exclude-crate-paths = [
  { name = "openssl-src", exclude = "openssl" },
]
EOF
cargo-vendor-filterer || cargo vendor --locked
mkdir -p .cargo
cat << EOF > .cargo/config.toml
[source.crates-io]
replace-with = 'vendored-sources'

[source.vendored-sources]
directory = 'vendor'
EOF
cd ../../../..

# vendor everything
cd ..
tar cfJ $CWD/element-desktop-$VERSION-vendored-sources.tar.xz \
           element-desktop-$VERSION/vendor \
           element-desktop-$VERSION/.hak/hakModules \
           element-desktop-$VERSION/.hak/matrix-seshat/$RUST_PLATFORM/build \
           element-desktop-$VERSION/electron-cache/electron{,-builder}
rm -rf $TMP
cd $CWD
