#!/bin/bash

set -e

# Script to build all package formats using fpm
# Usage: ./build-all.sh [version]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Default version
VERSION="${1:-0.1.0}"

echo "Building all packages for lumasense version $VERSION"

# Check if fpm is installed
if ! command -v fpm &> /dev/null; then
    echo "Error: fpm is not installed. Please install it with:"
    echo "  gem install fpm"
    exit 1
fi

# Build the release binary
echo "Building release binary..."
cd "$PROJECT_ROOT"
cargo build --release

# Build all packages
echo "Building Debian package..."
bash "$SCRIPT_DIR/build-deb.sh" "$VERSION"

echo "Building RPM package..."
bash "$SCRIPT_DIR/build-rpm.sh" "$VERSION"

echo "Building Arch package..."
bash "$SCRIPT_DIR/build-arch.sh" "$VERSION"

echo "All packages built successfully!"
echo "Generated packages:"
ls -la *.deb *.rpm *.pkg.tar.zst 2>/dev/null || echo "No packages found in current directory"