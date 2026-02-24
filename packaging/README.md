# LumaSense Packaging

This directory contains scripts and configuration files for building LumaSense packages using fpm (Effing Package Management).

## Required Packages

Before building packages, you need to install the following dependencies:

### Core Dependencies

- **fpm** (Effing Package Management) - Main packaging tool
- **ruby** - Ruby interpreter for fpm
- **ruby-ffi** - Ruby FFI library for fpm
- **rubygems** - Ruby package manager
- **erb** - Ruby templating engine for fpm

### System Dependencies

- **v4l-utils** - Video4Linux utilities for camera access
- **build-essential** (Debian/Ubuntu) or equivalent - Build tools
- **rpm-tools** (for RPM packaging) - RPM build tools

### Installation Commands

#### Arch Linux
```bash
# Install core dependencies
sudo pacman -S ruby ruby-ffi v4l-utils

# Install fpm and dependencies via gem
gem install fpm erb
```

#### Debian/Ubuntu
```bash
# Install system dependencies
sudo apt update
sudo apt install ruby ruby-dev gem build-essential v4l-utils

# Install fpm and dependencies via gem
gem install fpm erb
```

#### For RPM Packaging (Additional)
```bash
# Arch Linux
sudo pacman -S rpm-tools

# Debian/Ubuntu
sudo apt install rpm

# Fedora/CentOS/RHEL
sudo dnf install rpm-build
```

## Prerequisites

### Install fpm

fpm is required to build packages. Install it using Ruby:

```bash
# On Arch Linux
sudo pacman -S ruby ruby-ffi

# On Debian/Ubuntu
sudo apt install ruby ruby-dev gem build-essential

# Install fpm
gem install fpm
```

## Package Contents

Each package includes the following files:

- **Binary**: `/usr/bin/lumasense` - The main application executable
- **Configuration**: `/etc/lumasense/config.toml` - Default configuration file
- **Systemd Service**: `/usr/lib/systemd/system/lumasense.service` - Systemd service for automatic startup
- **Udev Rules**: `/usr/lib/udev/rules.d/99-lumasense-backlight.rules` - Permissions for backlight control

## Build Scripts

### Build All Packages

```bash
# Build all package formats (Debian, RPM, Arch)
./build-all.sh [version]

# Example: Build version 0.1.0
./build-all.sh 0.1.0
```

### Build Individual Packages

```bash
# Build Debian package (.deb)
./build-deb.sh [version]

# Build RPM package (.rpm)
./build-rpm.sh [version]

# Build Arch package (.pkg.tar.zst)
./build-arch.sh [version]
```

## Installation

### Debian/Ubuntu

```bash
sudo dpkg -i lumasense_0.1.0_amd64.deb
sudo apt-get install -f  # Fix any missing dependencies
```

### Red Hat/CentOS/Fedora

```bash
sudo rpm -ivh lumasense-0.1.0-x86_64.rpm
# or
sudo dnf install lumasense-0.1.0-x86_64.rpm
```

### Arch Linux

```bash
sudo pacman -U lumasense-0.1.0-x86_64.pkg.tar.zst
```

## Post-Installation Setup

### Enable Systemd Service

```bash
# Enable the service for your user
systemctl --user enable lumasense.service
systemctl --user start lumasense.service

# Or enable for all users (requires root)
sudo systemctl enable lumasense.service
sudo systemctl start lumasense.service
```

### Configure User Permissions

To allow non-root users to control screen brightness, you need to add your user to the `video` group and reload udev rules:

```bash
# Add user to video group
sudo usermod -a -G video $USER

# Reload udev rules
sudo udevadm control --reload-rules
sudo udevadm trigger

# Log out and log back in for group changes to take effect
```

### Configuration

The application will look for configuration files in the following locations (in order):

1. `~/.config/lumasense/config.toml` (user-specific)
2. `/etc/lumasense/config.toml` (system-wide)
3. Default values (if no config file found)

You can copy the default configuration and customize it:

```bash
# Create user config directory
mkdir -p ~/.config/lumasense

# Copy default config
cp /etc/lumasense/config.toml ~/.config/lumasense/config.toml

# Edit the configuration
nano ~/.config/lumasense/config.toml
```

## Package Structure

```
packaging/
├── build-all.sh              # Build all package formats
├── build-deb.sh              # Build .deb package
├── build-rpm.sh              # Build .rpm package
├── build-arch.sh             # Build Arch package
├── lumasense.service         # Systemd service file
└── 99-lumasense-backlight.rules  # Udev rules for backlight control
```

## Troubleshooting

### Permission Issues

If you get permission errors when trying to control brightness:

1. Ensure udev rules are properly installed
2. Verify your user is in the `video` group
3. Check that the backlight path in config matches your system

### Finding Backlight Path

To find your system's backlight path:

```bash
ls /sys/class/backlight/
```

Common paths:
- `/sys/class/backlight/intel_backlight` (Intel integrated graphics)
- `/sys/class/backlight/amdgpu_bl0` (AMD graphics)
- `/sys/class/backlight/nv_backlight` (NVIDIA graphics)

### Camera Issues

If the camera fails to open:

1. Check camera permissions
2. Verify camera device index in config
3. Ensure no other applications are using the camera

## Development

When making changes to the packaging:

1. Update the version in build scripts if needed
2. Test package building with `./build-all.sh`
3. Verify package contents and installation
4. Test the installed application

## License

The packaging scripts and configuration are licensed under the MIT License.