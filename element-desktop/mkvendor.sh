#!/bin/bash

source element-desktop.info

CWD=$(pwd)
TMP=$(mktemp -d)
RUST_PLATFORM=$(rustc -Vv | awk '/host/ {print $2}')
export npm_config_nodedir="/usr"

cd $TMP
tar xf $CWD/element-desktop-$VERSION.tar.gz
tar xf $CWD/element-web-$VERSION.tar.gz

# element-web
cd element-web-$VERSION
mkdir -p vendor
YARN_YARN_OFFLINE_MIRROR=$(pwd)/vendor \
YARN_CACHE_FOLDER=$(pwd)/cache \
yarn install --frozen-lockfile \
             --ignore-engines \
             --no-fund \
             --update-checksums

# element-desktop
cd ../element-desktop-$VERSION

## pre-built electron
EVERSION=$(jq --raw-output '.devDependencies.electron' < package.json)
mkdir -p cache/electron{,-builder/fpm@2.0.1/fpm@2.0.1-fpm-1.16.0-ruby-3.4.3-linux-amd64}
wget -P cache/electron https://github.com/electron/electron/releases/download/v$EVERSION/electron-v$EVERSION-linux-x64.zip

## pre-built ruby for electron-builder
wget -P cache/electron-builder https://github.com/electron-userland/electron-builder-binaries/releases/download/fpm@2.0.1/fpm-1.16.0-ruby-3.4.3-linux-amd64.7z
7z x -ocache/electron-builder/fpm@2.0.1/fpm@2.0.1-fpm-1.16.0-ruby-3.4.3-linux-amd64 cache/electron-builder/fpm-1.16.0-ruby-3.4.3-linux-amd64.7z
rm cache/electron-builder/fpm-1.16.0-ruby-3.4.3-linux-amd64.7z

## element-desktop itself
mkdir -p vendor
YARN_YARN_OFFLINE_MIRROR=$(pwd)/vendor \
YARN_CACHE_FOLDER=$(pwd)/cache \
npm_config_cache="$(pwd)/cache" \
XDG_CACHE_HOME=$YARN_CACHE_FOLDER \
yarn install --frozen-lockfile \
             --ignore-engines \
             --no-fund \
             --update-checksums

## matrix-seshat
SESHATVERSION=$(jq --raw-output '.hakDependencies."matrix-seshat"' < package.json | tr -d '^')
wget -P .hak https://github.com/matrix-org/seshat/archive/$SESHATVERSION/seshat-$SESHATVERSION.tar.gz
tar xf .hak/seshat-$SESHATVERSION.tar.gz -C .hak seshat-$SESHATVERSION/seshat-node
mkdir -p .hak/hakModules .hak/matrix-seshat/$RUST_PLATFORM
mv .hak/seshat-$SESHATVERSION/seshat-node .hak/matrix-seshat/$RUST_PLATFORM/build
cp -R .hak/matrix-seshat/$RUST_PLATFORM/build .hak/hakModules/matrix-seshat
rm .hak/seshat-$SESHATVERSION.tar.gz
cd .hak/matrix-seshat/$RUST_PLATFORM/build
mkdir -p yarn-vendor
YARN_YARN_OFFLINE_MIRROR=$(pwd)/yarn-vendor \
YARN_CACHE_FOLDER=$(pwd)/cache \
CARGO_HOME=$(pwd)/cargo \
yarn install --frozen-lockfile \
             --ignore-engines \
             --no-fund \
             --update-checksums

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
rm -rf cache cargo
cd ../../../..

# vendor everything
cd ..
tar cf $CWD/element-desktop-$VERSION-vendored-sources.tar \
           element-{desktop,web}-$VERSION/vendor \
           element-desktop-$VERSION/.hak/hakModules \
           element-desktop-$VERSION/.hak/matrix-seshat/$RUST_PLATFORM/build \
           element-desktop-$VERSION/cache/electron{,-builder}
rm -rf $TMP
cd $CWD
