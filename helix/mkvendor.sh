#!/bin/sh

set -e

CWD=$(pwd)
TMP=$(mktemp -d)
. "$CWD/helix.info"
OUTPUT="${OUTPUT:-$CWD}"
export CARGO_HOME="$TMP"

export PATH="/opt/rust/bin:$PATH"
if [ -z "$LD_LIBRARY_PATH" ]; then
  export LD_LIBRARY_PATH="/opt/rust/lib64"
else
  export LD_LIBRARY_PATH="/opt/rust/lib64:$LD_LIBRARY_PATH"
fi

mkdir -p "$TMP/$PRGNAM-$VERSION"
tar xf "$CWD/$PRGNAM-$VERSION-source.tar.xz" -C "$TMP/$PRGNAM-$VERSION"
cd "$TMP/$PRGNAM-$VERSION"

# configure cargo-vendor-filterer
# the [package] definition and existing src/main.rs file are required for vendoring to work
mkdir -p src
touch src/main.rs
cat << EOF >> Cargo.toml
[package.metadata.vendor-filter]
platforms = ["x86_64-unknown-linux-gnu", "i686-unknown-linux-gnu", "aarch64-unknown-linux-gnu", "arm-unknown-linux-gnueabihf"]
all-features = true
exclude-crate-paths = [
  { name = "openssl-src", exclude = "openssl" },
]
[package]
name = "$PRGNAM"
EOF

cargo-vendor-filterer || cargo vendor --locked

mkdir -p .cargo
cat << EOF > .cargo/config.toml
[source.crates-io]
replace-with = "vendored-sources"

[source.vendored-sources]
directory = "vendor"
EOF

tar cfJ "$OUTPUT/$PRGNAM-$VERSION-vendored-sources.tar.xz" .cargo/ vendor/

cd "$CWD"
rm -rf "$TMP"
