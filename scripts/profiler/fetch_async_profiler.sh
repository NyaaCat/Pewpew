#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ASYNC_PROFILER_VERSION="${ASYNC_PROFILER_VERSION:-4.2.1}"
ASYNC_PROFILER_ARCH="${ASYNC_PROFILER_ARCH:-linux-x64}"
ASYNC_PROFILER_DIR="${ASYNC_PROFILER_DIR:-$ROOT_DIR/tmp/async-profiler}"
TARBALL="async-profiler-${ASYNC_PROFILER_VERSION}-${ASYNC_PROFILER_ARCH}.tar.gz"
URL="https://github.com/async-profiler/async-profiler/releases/download/v${ASYNC_PROFILER_VERSION}/${TARBALL}"

if [ -x "$ASYNC_PROFILER_DIR/bin/asprof" ] || [ -x "$ASYNC_PROFILER_DIR/profiler.sh" ]; then
  echo "async-profiler already present at $ASYNC_PROFILER_DIR"
  exit 0
fi

mkdir -p "$ASYNC_PROFILER_DIR"

TMP_TARBALL="$ASYNC_PROFILER_DIR/$TARBALL"

echo "Downloading async-profiler v${ASYNC_PROFILER_VERSION} to $TMP_TARBALL"
curl -L -o "$TMP_TARBALL" "$URL"

echo "Extracting async-profiler to $ASYNC_PROFILER_DIR"
tar -xzf "$TMP_TARBALL" -C "$ASYNC_PROFILER_DIR" --strip-components=1
rm -f "$TMP_TARBALL"

if [ -x "$ASYNC_PROFILER_DIR/bin/asprof" ] && [ ! -x "$ASYNC_PROFILER_DIR/profiler.sh" ]; then
  cat > "$ASYNC_PROFILER_DIR/profiler.sh" <<'EOF'
#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/bin/asprof" "$@"
EOF
  chmod +x "$ASYNC_PROFILER_DIR/profiler.sh"
fi

if [ ! -x "$ASYNC_PROFILER_DIR/bin/asprof" ] && [ ! -x "$ASYNC_PROFILER_DIR/profiler.sh" ]; then
  echo "async-profiler setup failed: no profiler launcher found"
  exit 1
fi
