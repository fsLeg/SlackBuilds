#!/bin/sh

set -e

CWD="$(pwd)"
TMP="${TMP:-$(mktemp -d)}"
. "$CWD/shadowsocks-rust.info"
OUTPUT="${OUTPUT:-$CWD}"
export CARGO_HOME="$TMP"

export PATH="/opt/rust/bin:$PATH"
if [ -z "$LD_LIBRARY_PATH" ]; then
  export LD_LIBRARY_PATH="/opt/rust/lib64"
else
  export LD_LIBRARY_PATH="/opt/rust/lib64:$LD_LIBRARY_PATH"
fi

tar xf "$CWD/$PRGNAM-$VERSION.tar.gz" -C "$TMP"
cd "$TMP/$PRGNAM-$VERSION"

# configure cargo-vendor-filterer
cat << EOF >> Cargo.toml
[package.metadata.vendor-filter]
platforms = ["x86_64-unknown-linux-gnu", "i686-unknown-linux-gnu", "aarch64-unknown-linux-gnu", "arm-unknown-linux-gnueabihf"]
all-features = true
exclude-crate-paths = [
  { name = "openssl-src", exclude = "openssl" },
]
EOF

cargo-vendor-filterer || cargo vendor --locked

mkdir -p .cargo
cat << EOF > .cargo/config.toml
[source.crates-io]
replace-with = "vendored-sources"

[source.vendored-sources]
directory = "vendor"
EOF

if [ -f "$OUTPUT/$PRGNAM-$VERSION-vendored-sources.tar.xz" ]; then
    rm -v "$OUTPUT/$PRGNAM-$VERSION-vendored-sources.tar.xz"
fi

tar cfJ "$OUTPUT/$PRGNAM-$VERSION-vendored-sources.tar.xz" .cargo/ vendor/

cd "$CWD"
rm -rf "$TMP"
