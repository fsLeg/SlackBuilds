#!/bin/sh

set -e

if [ ! -x "$(which jq)" ] || [ ! -x "$(which 7z)" ]; then
  echo Please install jq and p7zip.
  exit 1
fi

CWD="$(pwd)"
TMP="${TMP:-$(mktemp -d)}"
. "$CWD/element-desktop.info"
OUTPUT="${OUTPUT:-$CWD}"
WEBNAM="${PRGNAM%-desktop}-web"

export PATH="/opt/rust/bin:$PATH"
if [ -z "$LD_LIBRARY_PATH" ]; then
  export LD_LIBRARY_PATH="/opt/rust/lib64"
else
  export LD_LIBRARY_PATH="/opt/rust/lib64:$LD_LIBRARY_PATH"
fi

cd "$TMP"
tar xf "$CWD/$WEBNAM-$VERSION.tar.gz"

BASE_TMP_DIR="$TMP/$WEBNAM-$VERSION"
export YARN_YARN_OFFLINE_MIRROR="$BASE_TMP_DIR/vendor"
export YARN_CACHE_FOLDER="$BASE_TMP_DIR/cache"
export npm_config_cache="$YARN_CACHE_FOLDER"
export npm_config_nodedir=/usr
export XDG_CACHE_HOME="$BASE_TMP_DIR/electron-cache"
export XDG_CONFIG_HOME="$BASE_TMP_DIR"
export CARGO_HOME="$BASE_TMP_DIR/cargo"
export COREPACK_HOME="$BASE_TMP_DIR/corepack"

# set up package managers
mkdir -p "$COREPACK_HOME/bin" "$YARN_YARN_OFFLINE_MIRROR"
corepack pack -o "$COREPACK_HOME/pm.tgz" \
  "$(jq -r .packageManager "$WEBNAM-$VERSION/package.json" | cut -d'+' -f1)" \
  "$(jq -r .packageManager "$WEBNAM-$VERSION/apps/desktop/package.json" | cut -d'+' -f1)" \
  "yarn@^1"
corepack enable --install-directory "$COREPACK_HOME/bin"
export PATH="$COREPACK_HOME/bin:$PATH"
pnpm config set store-dir "$XDG_CONFIG_HOME/pnpm-store"

# element-web
cd "$TMP/$WEBNAM-$VERSION"
pnpm install --frozen-lockfile

# element-desktop
cd "apps/desktop"

## pre-built electron
EVERSION=$(jq --raw-output '.devDependencies.electron' < package.json)
mkdir -p "$XDG_CACHE_HOME/electron" "$XDG_CACHE_HOME/electron-builder"
if [ -e "$CWD/electron-v$EVERSION-linux-x64.zip" ]; then
  cp "$CWD/electron-v$EVERSION-linux-x64.zip" "$XDG_CACHE_HOME/electron/"
else
  wget --directory-prefix="$XDG_CACHE_HOME/electron" --tries=0 --retry-on-http-error=503 "https://github.com/electron/electron/releases/download/v$EVERSION/electron-v$EVERSION-linux-x64.zip"
fi

## element-desktop itself
pnpm install --frozen-lockfile
pnpm store add $(python3 -c "
import yaml
d = yaml.safe_load(open('../../pnpm-lock.yaml'))
print('\n'.join(d['importers']['apps/desktop']['dependencies'].keys()))
print('\n'.join(d['importers']['apps/desktop']['devDependencies'].keys()))
print('\n'.join(d['packages'].keys()))
") || true
pnpm add '@esbuild/linux-x64'

EDIR="$(find "$XDG_CACHE_HOME/electron" -type d -mindepth 1 -maxdepth 1)"
rm "$EDIR/electron-v$EVERSION-linux-x64.zip"
ln -s "../electron-v$EVERSION-linux-x64.zip" "$EDIR/"

## pre-built ruby for electron-builder
FPM_RUBY=$(grep linux-amd64 ../../node_modules/app-builder-lib/out/toolsets/linux.js | head -1 | cut -d'"' -f2)
FPM_RUBY_TAG=$(grep 'const fpmPath' ../../node_modules/app-builder-lib/out/toolsets/linux.js | head -1 | cut -d'"' -f2)
mkdir -p "$XDG_CACHE_HOME/electron-builder/$FPM_RUBY_TAG/$FPM_RUBY_TAG-${FPM_RUBY%.7z}"
if [ -e "$CWD/$FPM_RUBY" ]; then
  cp "$CWD/$FPM_RUBY" "$XDG_CACHE_HOME/electron-builder/"
else
  wget --directory-prefix="$XDG_CACHE_HOME/electron-builder/" --tries=0 --retry-on-http-error=503 "https://github.com/electron-userland/electron-builder-binaries/releases/download/$FPM_RUBY_TAG/$FPM_RUBY"
fi
7z x -o"$XDG_CACHE_HOME/electron-builder/$FPM_RUBY_TAG/$FPM_RUBY_TAG-${FPM_RUBY%.7z}" "$XDG_CACHE_HOME/electron-builder/$FPM_RUBY"
rm "$XDG_CACHE_HOME/electron-builder/$FPM_RUBY"

## matrix-seshat
RUST_PLATFORM=$(rustc -Vv | awk '/host/ {print $2}')
SESHATVERSION=$(jq --raw-output '.hakDependencies."matrix-seshat"' < package.json | tr -d '^')
mkdir -p .hak/hakModules ".hak/matrix-seshat/$RUST_PLATFORM"
if [ -e "$CWD/seshat-$SESHATVERSION.tar.gz" ]; then
  cp "$CWD/seshat-$SESHATVERSION.tar.gz" .hak/
else
  wget --directory-prefix=.hak --tries=0 --retry-on-http-error=503 "https://github.com/matrix-org/seshat/archive/$SESHATVERSION/seshat-$SESHATVERSION.tar.gz"
fi
tar xf ".hak/seshat-$SESHATVERSION.tar.gz" -C .hak "seshat-$SESHATVERSION/seshat-node"
mv ".hak/seshat-$SESHATVERSION/seshat-node" .hak/hakModules/matrix-seshat
ln -s ../../hakModules/matrix-seshat ".hak/matrix-seshat/$RUST_PLATFORM/build"
rm -r ".hak/seshat-$SESHATVERSION.tar.gz" ".hak/seshat-$SESHATVERSION"

pushd ".hak/matrix-seshat/$RUST_PLATFORM/build"
jq '.packageManager = "yarn@1.22.22"' package.json > tmp.json && mv tmp.json package.json
yarn install --frozen-lockfile
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
popd

rm -rf pnpm .hak/hakModules/matrix-seshat/{node_modules,target}

# vendor everything
cd "$TMP"

if [ -f "$OUTPUT/$PRGNAM-$VERSION-vendored-sources.tar.xz" ]; then
    rm -v "$OUTPUT/$PRGNAM-$VERSION-vendored-sources.tar.xz"
fi

tar cfJ "$OUTPUT/$PRGNAM-$VERSION-vendored-sources.tar.xz" \
        "$WEBNAM-$VERSION/pnpm-store" \
        "$WEBNAM-$VERSION/vendor" \
        "$WEBNAM-$VERSION/apps/desktop/.hak" \
        "$WEBNAM-$VERSION/electron-cache" \
        "$WEBNAM-$VERSION/corepack/pm.tgz"
cd "$CWD"
echo "Removing directory $TMP..."
rm -r "$TMP"
echo "Done."
