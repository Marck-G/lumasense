# LumaSense

Automatic screen brightness adjustment based on ambient light conditions detected through your camera.

## Overview

LumaSense is a Rust application that uses your device's camera to detect ambient light conditions and automatically adjusts your screen brightness accordingly. This helps reduce eye strain and provides optimal viewing comfort in different lighting environments.

## Features

- **Automatic Brightness Control**: Adjusts screen brightness based on ambient light detected by camera
- **Smooth Transitions**: Animated brightness changes for comfortable viewing
- **Configurable Settings**: Customizable brightness thresholds and multipliers
- **Fallback Methods**: Multiple brightness control methods for compatibility
- **Professional Logging**: Detailed logging for debugging and monitoring

## Prerequisites

- Rust 1.70+ 
- Linux system with backlight control
- Camera device (webcam)
- Root privileges for backlight control (via udev rules)

## Installation

### 1. Clone the Repository

```bash
git clone <repository-url>
cd lumasense
```

### 2. Build the Application

```bash
cargo build --release
```

The binary will be created at `target/release/lumasense`.

### 3. Install the Binary

```bash
# Copy to system binary directory
sudo cp target/release/lumasense /usr/local/bin/

# Make executable
sudo chmod +x /usr/local/bin/lumasense
```

## Configuration

### Configuration File

Create a configuration file at `~/.config/lumasense/config.toml` or use the provided `config.toml`:

```toml
[brightness]
min_ambient = 0.0
max_ambient = 100.0
min_brightness = 6.0
max_brightness = 100.0
low_ambient_multiplier = 0.5
high_ambient_multiplier = 1.5
animation_duration_ms = 500
animation_steps = 30
backlight_path = "/sys/class/backlight/intel_backlight"
brightness_threshold = 5.0

[camera]
capture_delay_ms = 100
device_index = 0
```

### Configuration Options

#### Brightness Settings
- `min_ambient` / `max_ambient`: Ambient light range (0.0-100.0)
- `min_brightness` / `max_brightness`: Screen brightness range (0.0-100.0%)
- `low_ambient_multiplier`: Multiplier for low light conditions
- `high_ambient_multiplier`: Multiplier for bright conditions
- `animation_duration_ms`: Duration of brightness transitions
- `animation_steps`: Number of steps in animation
- `backlight_path`: Path to backlight control files
- `brightness_threshold`: Minimum change required to update brightness

#### Camera Settings
- `capture_delay_ms`: Delay between camera captures
- `device_index`: Camera device index (0, 1, 2, etc.)

## Udev Rules

To allow non-root users to control screen brightness, you need to create udev rules:

### 1. Create Udev Rule File

```bash
sudo nano /etc/udev/rules.d/99-backlight.rules
```

### 2. Add the Following Rules

```udev
# Allow users in video group to control backlight
SUBSYSTEM=="backlight", ACTION=="add", RUN+="/bin/chgrp video /sys/class/backlight/%k/brightness"
SUBSYSTEM=="backlight", ACTION=="add", RUN+="/bin/chmod g+w /sys/class/backlight/%k/brightness"

# Also set permissions for max_brightness
SUBSYSTEM=="backlight", ACTION=="add", RUN+="/bin/chgrp video /sys/class/backlight/%k/max_brightness"
SUBSYSTEM=="backlight", ACTION=="add", RUN+="/bin/chmod g+r /sys/class/backlight/%k/max_brightness"
```

### 3. Reload Udev Rules

```bash
sudo udevadm control --reload-rules
sudo udevadm trigger
```

### 4. Add User to Video Group

```bash
sudo usermod -a -G video $USER
```

**Note**: You may need to log out and log back in for group changes to take effect.

## Usage

### Basic Usage

```bash
# Run with default configuration
LumaSense

```

### Running as a Service

Create a systemd service file:

```bash
sudo nano /etc/systemd/system/LumaSense.service
```

Add the following content:

```ini
[Unit]
Description=LumaSense - Automatic brightness control
After=graphical-session.target

[Service]
Type=simple
User=$USER
ExecStart=/usr/local/bin/LumaSense
Restart=always
RestartSec=3

[Install]
WantedBy=graphical-session.target
```

Enable and start the service:

```bash
# Enable the service
sudo systemctl enable LumaSense.service

# Start the service
sudo systemctl start LumaSense.service

# Check status
sudo systemctl status LumaSense.service
```

## Troubleshooting

### Permission Issues

If you get permission errors when trying to control brightness:

1. Ensure udev rules are properly installed
2. Verify your user is in the `video` group
3. Check that the backlight path in config matches your system

### Camera Issues

If the camera fails to open:

1. Check camera permissions
2. Verify camera device index in config
3. Ensure no other applications are using the camera

### Finding Backlight Path

To find your system's backlight path:

```bash
ls /sys/class/backlight/
```

Common paths:
- `/sys/class/backlight/intel_backlight` (Intel integrated graphics)
- `/sys/class/backlight/amdgpu_bl0` (AMD graphics)
- `/sys/class/backlight/nv_backlight` (NVIDIA graphics)

### Finding Camera Device

To list available camera devices:

```bash
ls /dev/video*
```

## Development

### Building for Development

```bash
cargo build
```

### Running Tests

```bash
cargo test
```

### Code Formatting

```bash
cargo fmt
```

### Code Analysis

```bash
cargo clippy
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Issues

If you encounter any problems, please file an issue along with a detailed description.