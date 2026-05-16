#!/bin/sh

set -e

if [ ! -x "$(which cargo-vendor-filterer)" ]; then
  echo Please install cargo-vendor-filterer.
  exit 1
fi

CWD=$(pwd)
TMP=$(mktemp -d)
. "$CWD/helix.info"
OUTPUT="${OUTPUT:-$CWD}"
export CARGO_HOME="$TMP"
unset XZ_DEFAULTS XZ_OPT

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

cargo-vendor-filterer

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

tar --sort=name \
    --mtime="@$(date --date="$(tar tvf "$CWD/$PRGNAM-$VERSION-source.tar.xz" | head -1 | awk '{print $4" "$5}')" +"%s")" \
    --owner=0 --group=0 --numeric-owner \
    --pax-option=exthdr.name=%d/PaxHeaders/%f,delete=atime,delete=ctime \
    --create .cargo/ vendor/ | xz -6e --threads=1 > "$OUTPUT/$PRGNAM-$VERSION-vendored-sources.tar.xz"

cd "$CWD"
rm -r "$TMP"
