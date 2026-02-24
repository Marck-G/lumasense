#!/bin/bash

# Post-installation script for lumasense
echo "Setting up lumasense..."

# Reload udev rules
if [ -x "$(command -v udevadm)" ]; then
    echo "Reloading udev rules..."
    udevadm control --reload-rules
    udevadm trigger
fi

# Enable and start systemd service
if [ -x "$(command -v systemctl)" ]; then
    echo "Enabling lumasense service..."
    systemctl enable lumasense.service
    echo "Starting lumasense service..."
    systemctl start lumasense.service
fi

echo "lumasense setup complete!"