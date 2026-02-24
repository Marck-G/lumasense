#!/bin/bash

set -e

# Script to build .rpm package using fpm
# Usage: ./build-rpm.sh [version]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Default version
VERSION="${1:-0.1.0}"
PACKAGE_NAME="lumasense"
ARCH="x86_64"

echo "Building RPM package for $PACKAGE_NAME version $VERSION"

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

# Create temporary directory for packaging
TEMP_DIR="./tmp/${PACKAGE_NAME}-pkg"
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"

# Copy binary
mkdir -p "$TEMP_DIR/usr/bin"
cp "$PROJECT_ROOT/target/release/lumasense" "$TEMP_DIR/usr/bin/"

# Copy configuration file
mkdir -p "$TEMP_DIR/etc/lumasense"
cp "$PROJECT_ROOT/config.toml" "$TEMP_DIR/etc/lumasense/config.toml"

# Copy systemd service
mkdir -p "$TEMP_DIR/usr/lib/systemd/system"
cp "$SCRIPT_DIR/lumasense.service" "$TEMP_DIR/usr/lib/systemd/system/"

# Copy udev rules
mkdir -p "$TEMP_DIR/usr/lib/udev/rules.d"
cp "$SCRIPT_DIR/99-lumasense-backlight.rules" "$TEMP_DIR/usr/lib/udev/rules.d/"

# Build the package
echo "Creating .rpm package..."
fpm -s dir \
    -t rpm \
    -n "$PACKAGE_NAME" \
    -v "$VERSION" \
    -a "$ARCH" \
    --description "Automatic screen brightness adjustment based on ambient light conditions detected through your camera" \
    --url "https://github.com/Marck-G/lumen-sense" \
    --license "MIT" \
    --maintainer "Marck D. Carrión<marckcarrion@gmail.com>" \
    --after-install "$SCRIPT_DIR/post-install.sh" \
    --before-remove "$SCRIPT_DIR/pre-uninstall.sh" \
    --prefix "/" \
    -C "$TEMP_DIR" \
    .

# Cleanup
rm -rf "$TEMP_DIR"

echo "RPM package created successfully!"
echo "Package: ${PACKAGE_NAME}-${VERSION}-${ARCH}.rpm"