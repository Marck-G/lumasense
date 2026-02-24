#!/bin/bash

# Pre-uninstallation script for lumasense
echo "Cleaning up lumasense..."

# Stop and disable systemd service
if [ -x "$(command -v systemctl)" ]; then
    echo "Stopping lumasense service..."
    systemctl stop lumasense.service 2>/dev/null || true
    echo "Disabling lumasense service..."
    systemctl disable lumasense.service 2>/dev/null || true
fi

echo "lumasense cleanup complete!"