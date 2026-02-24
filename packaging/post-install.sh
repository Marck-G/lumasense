#!/bin/bash

# Post-installation script for lumasense
echo "Setting up lumasense..."

# Determine the user to run the service as
# Try to find a suitable user (first non-system user)
SYSTEM_USER=""
if [ -f /etc/passwd ]; then
    # Look for the first user with UID >= 1000 (typically non-system users)
    SYSTEM_USER=$(awk -F: '$3 >= 1000 && $3 < 65534 {print $1; exit}' /etc/passwd)
fi

# Fallback to root if no suitable user found
if [ -z "$SYSTEM_USER" ]; then
    SYSTEM_USER="root"
fi

echo "Using user '$SYSTEM_USER' for lumasense service"

# Create a user-specific service file by replacing %i with the actual username
if [ -f "/usr/lib/systemd/system/lumasense.service" ]; then
    echo "Customizing systemd service for user '$SYSTEM_USER'..."
    
    # Create a backup of the original service file
    cp "/usr/lib/systemd/system/lumasense.service" "/usr/lib/systemd/system/lumasense.service.bak"
    
    # Replace %i with the actual username
    sed -i "s/%i/$SYSTEM_USER/g" "/usr/lib/systemd/system/lumasense.service"
    
    # Update XAUTHORITY path for the specific user
    if [ "$SYSTEM_USER" != "root" ]; then
        USER_HOME=$(getent passwd "$SYSTEM_USER" | cut -d: -f6)
        if [ -n "$USER_HOME" ]; then
            sed -i "s|Environment=XAUTHORITY=/home/%i/.Xauthority|Environment=XAUTHORITY=$USER_HOME/.Xauthority|g" "/usr/lib/systemd/system/lumasense.service"
        fi
    fi
    
    # Reload systemd to recognize the changes
    systemctl daemon-reload
fi

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
