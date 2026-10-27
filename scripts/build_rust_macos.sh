#!/bin/sh
# Xcode "Build Rust Bridge" phase for the macOS Runner target: builds the
# bridge for every active architecture and embeds it in the app's Frameworks.
set -eu

if [ -z "${TARGET_BUILD_DIR:-}" ] || [ -z "${FRAMEWORKS_FOLDER_PATH:-}" ]; then
  echo "error: build_rust_macos.sh must run as an Xcode build phase" >&2
  exit 1
fi

# Xcode does not load the login shell, so add rustup's default location.
PATH="${CARGO_HOME:-$HOME/.cargo}/bin:$PATH"
export PATH
if ! command -v cargo >/dev/null 2>&1; then
  echo "error: Rust stable is required: install cargo and the macOS targets with rustup" >&2
  exit 1
fi

WORKSPACE="$(cd "$(dirname "$0")/.." && pwd)"
LIBRARY_NAME="libskyport_flutter_bridge.dylib"
RUST_TARGET_DIR="${PROJECT_TEMP_DIR:-$WORKSPACE/target}/rust"
# Cargo reads the deployment target that Xcode exports for this build.
export MACOSX_DEPLOYMENT_TARGET

built=""
for arch in ${ARCHS:-$(uname -m)}; do
  case "$arch" in
    arm64) target="aarch64-apple-darwin" ;;
    x86_64) target="x86_64-apple-darwin" ;;
    *) echo "error: unsupported macOS architecture: $arch" >&2; exit 1 ;;
  esac
  # Cargo performs its own dependency tracking; invoking it also catches added Rust files.
  cargo build --manifest-path "$WORKSPACE/Cargo.toml" \
    --package skyport_flutter_bridge --release --locked \
    --target "$target" --target-dir "$RUST_TARGET_DIR"
  built="$built $RUST_TARGET_DIR/$target/release/$LIBRARY_NAME"
done

destination_dir="$TARGET_BUILD_DIR/$FRAMEWORKS_FOLDER_PATH"
destination="$destination_dir/$LIBRARY_NAME"
mkdir -p "$destination_dir"
rm -f "$destination"
# shellcheck disable=SC2086 # One path per architecture.
lipo -create $built -output "$destination"
install_name_tool -id "@rpath/$LIBRARY_NAME" "$destination"

# Xcode signs the app last; nested code must already carry its own signature.
if [ "${CODE_SIGNING_ALLOWED:-YES}" != "NO" ]; then
  identity="${EXPANDED_CODE_SIGN_IDENTITY:-}"
  [ -n "$identity" ] || identity="-"
  if [ "${ENABLE_HARDENED_RUNTIME:-NO}" = "YES" ]; then
    codesign --force --timestamp=none --options runtime --sign "$identity" "$destination"
  else
    codesign --force --timestamp=none --sign "$identity" "$destination"
  fi
fi
