#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

echo "Building Zigumi OS..."
if ! command -v zig >/dev/null 2>&1; then
  echo "zig not found in PATH"
  exit 1
fi

# Clean previous outputs (optional)
rm -rf build
mkdir -p build

# Build with Makefile (uses Makefile at project root)
make all

echo "Build finished. Kernel binary: build/zigumi-os"
echo "To create and install Limine on the ISO run:"
echo "  make iso"