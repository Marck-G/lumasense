# Lumasense Makefile
# Automated build system for the lumasense ambient light-controlled backlight application

# Configuration
PROJECT_NAME := lumasense
VERSION := 0.1.0
BINARY_NAME := lumasense
CONFIG_FILE := config.toml
TARGET_DIR := target
RELEASE_TARGET := $(TARGET_DIR)/release/$(BINARY_NAME)
DEBUG_TARGET := $(TARGET_DIR)/debug/$(BINARY_NAME)

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
NC := \033[0m # No Color

# Default target
.PHONY: all
all: build

# Build the project
.PHONY: build
build:
	@echo -e "$(BLUE)Building $(PROJECT_NAME) v$(VERSION)...$(NC)"
	cargo build --release
	@echo -e "$(GREEN)✓ Build completed successfully$(NC)"
	@echo -e "$(BLUE)Release binary: $(RELEASE_TARGET)$(NC)"

# Build debug version
.PHONY: build-debug
build-debug:
	@echo -e "$(BLUE)Building debug version of $(PROJECT_NAME)...$(NC)"
	cargo build
	@echo -e "$(GREEN)✓ Debug build completed successfully$(NC)"
	@echo -e "$(BLUE)Debug binary: $(DEBUG_TARGET)$(NC)"

# Clean build artifacts
.PHONY: clean
clean:
	@echo -e "$(YELLOW)Cleaning build artifacts...$(NC)"
	cargo clean
	@echo -e "$(GREEN)✓ Clean completed$(NC)"

# Run tests
.PHONY: test
test:
	@echo -e "$(BLUE)Running tests...$(NC)"
	cargo test
	@echo -e "$(GREEN)✓ All tests passed$(NC)"

# Run with debug build
.PHONY: run
run: build-debug
	@echo -e "$(BLUE)Running $(PROJECT_NAME) in debug mode...$(NC)"
	$(DEBUG_TARGET)

# Run with release build
.PHONY: run-release
run-release: build
	@echo -e "$(BLUE)Running $(PROJECT_NAME) in release mode...$(NC)"
	$(RELEASE_TARGET)

# Check code formatting
.PHONY: fmt-check
fmt-check:
	@echo -e "$(BLUE)Checking code formatting...$(NC)"
	cargo fmt -- --check
	@echo -e "$(GREEN)✓ Code formatting is correct$(NC)"

# Format code
.PHONY: fmt
fmt:
	@echo -e "$(BLUE)Formatting code...$(NC)"
	cargo fmt
	@echo -e "$(GREEN)✓ Code formatting completed$(NC)"

# Check for linting issues
.PHONY: lint
lint:
	@echo -e "$(BLUE)Running linting checks...$(NC)"
	cargo clippy -- -D warnings
	@echo -e "$(GREEN)✓ No linting issues found$(NC)"

# Check for security vulnerabilities
.PHONY: audit
audit:
	@echo -e "$(BLUE)Checking for security vulnerabilities...$(NC)"
	cargo audit
	@echo -e "$(GREEN)✓ No security vulnerabilities found$(NC)"

# Generate documentation
.PHONY: docs
docs:
	@echo -e "$(BLUE)Generating documentation...$(NC)"
	cargo doc --no-deps --open
	@echo -e "$(GREEN)✓ Documentation generated$(NC)"

# Install system dependencies (Linux)
.PHONY: install-deps
install-deps:
	@echo -e "$(BLUE)Installing system dependencies...$(NC)"
	@echo "Note: This requires manual installation based on your distribution."
	@echo "For Arch Linux: sudo pacman -S v4l-utils"
	@echo "For Ubuntu/Debian: sudo apt install v4l-utils"
	@echo "For Fedora/RHEL: sudo dnf install v4l-utils"
	@echo -e "$(YELLOW)Please install the appropriate packages for your system$(NC)"

# Install the application system-wide
.PHONY: install
install: build
	@echo -e "$(BLUE)Installing $(PROJECT_NAME) system-wide...$(NC)"
	sudo install -Dm755 $(RELEASE_TARGET) /usr/local/bin/$(BINARY_NAME)
	sudo install -Dm644 $(CONFIG_FILE) /etc/$(PROJECT_NAME)/config.toml
	@echo -e "$(GREEN)✓ Installation completed$(NC)"
	@echo "Binary installed to: /usr/local/bin/$(BINARY_NAME)"
	@echo "Config file installed to: /etc/$(PROJECT_NAME)/config.toml"

# Uninstall the application
.PHONY: uninstall
uninstall:
	@echo -e "$(YELLOW)Uninstalling $(PROJECT_NAME)...$(NC)"
	sudo rm -f /usr/local/bin/$(BINARY_NAME)
	sudo rm -rf /etc/$(PROJECT_NAME)
	@echo -e "$(GREEN)✓ Uninstallation completed$(NC)"

# Setup systemd service
.PHONY: setup-service
setup-service:
	@echo -e "$(BLUE)Setting up systemd service...$(NC)"
	sudo cp packaging/lumasense.service /etc/systemd/system/
	sudo systemctl daemon-reload
	sudo systemctl enable lumasense.service
	@echo -e "$(GREEN)✓ Systemd service configured$(NC)"
	@echo "To start the service: sudo systemctl start lumasense"
	@echo "To check status: sudo systemctl status lumasense"

# Setup udev rules for backlight permissions
.PHONY: setup-udev
setup-udev:
	@echo -e "$(BLUE)Setting up udev rules...$(NC)"
	sudo cp packaging/99-lumasense-backlight.rules /etc/udev/rules.d/
	sudo udevadm control --reload-rules
	sudo udevadm trigger
	@echo -e "$(GREEN)✓ Udev rules installed$(NC)"
	@echo "You may need to reboot for the rules to take effect"

# Build packages for distribution
.PHONY: package
package:
	@echo -e "$(BLUE)Building packages for distribution...$(NC)"
	@echo "Building all package formats..."
	@cd packaging && ./build-all.sh $(VERSION)
	@echo -e "$(GREEN)✓ Package build completed$(NC)"
	@echo "Check packaging/ directory for generated packages"

# Build specific package format
.PHONY: package-arch
package-arch:
	@echo -e "$(BLUE)Building Arch Linux package...$(NC)"
	@cd packaging && ./build-arch.sh $(VERSION)
	@echo -e "$(GREEN)✓ Arch package built$(NC)"

.PHONY: package-deb
package-deb:
	@echo -e "$(BLUE)Building Debian package...$(NC)"
	@cd packaging && ./build-deb.sh $(VERSION)
	@echo -e "$(GREEN)✓ Debian package built$(NC)"

.PHONY: package-rpm
package-rpm:
	@echo -e "$(BLUE)Building RPM package...$(NC)"
	@cd packaging && ./build-rpm.sh $(VERSION)
	@echo -e "$(GREEN)✓ RPM package built$(NC)"

# Development targets
.PHONY: dev-setup
dev-setup:
	@echo -e "$(BLUE)Setting up development environment...$(NC)"
	cargo install cargo-audit
	cargo install cargo-audit
	cargo install cargo-audit
	@echo -e "$(GREEN)✓ Development tools installed$(NC)"

.PHONY: dev-clean
dev-clean: clean
	@echo -e "$(BLUE)Cleaning development environment...$(NC)"
	rm -rf packaging/*.deb packaging/*.rpm packaging/*.pkg.tar.zst packaging/*.tar.gz
	@echo -e "$(GREEN)✓ Development cleanup completed$(NC)"

# Release preparation
.PHONY: prepare-release
prepare-release: fmt lint test build
	@echo -e "$(BLUE)Preparing release v$(VERSION)...$(NC)"
	@echo "1. Code formatting: ✓"
	@echo "2. Linting: ✓"
	@echo "3. Tests: ✓"
	@echo "4. Build: ✓"
	@echo -e "$(GREEN)✓ Release preparation completed$(NC)"

# Help target
.PHONY: help
help:
	@echo -e "$(BLUE)$(PROJECT_NAME) v$(VERSION) - Build System$(NC)"
	@echo ""
	@echo "Available targets:"
	@echo ""
	@echo "Build targets:"
	@echo "  build           - Build release version"
	@echo "  build-debug     - Build debug version"
	@echo "  clean           - Clean build artifacts"
	@echo ""
	@echo "Development targets:"
	@echo "  test            - Run tests"
	@echo "  run             - Run debug build"
	@echo "  run-release     - Run release build"
	@echo "  fmt             - Format code"
	@echo "  fmt-check       - Check code formatting"
	@echo "  lint            - Run linting checks"
	@echo "  audit           - Check for security vulnerabilities"
	@echo "  docs            - Generate documentation"
	@echo ""
	@echo "Installation targets:"
	@echo "  install-deps    - Install system dependencies"
	@echo "  install         - Install system-wide"
	@echo "  uninstall       - Uninstall application"
	@echo "  setup-service   - Setup systemd service"
	@echo "  setup-udev      - Setup udev rules"
	@echo ""
	@echo "Packaging targets:"
	@echo "  package         - Build all packages"
	@echo "  package-arch    - Build Arch Linux package"
	@echo "  package-deb     - Build Debian package"
	@echo "  package-rpm     - Build RPM package"
	@echo ""
	@echo "Release targets:"
	@echo "  prepare-release - Prepare for release"
	@echo "  dev-setup       - Setup development environment"
	@echo "  dev-clean       - Clean development environment"
	@echo ""
	@echo "Utility targets:"
	@echo "  help            - Show this help message"
	@echo "  all             - Default target (build)"
	@echo ""

# Default target alias
.PHONY: default
default: build

# Phony targets
.PHONY: all build build-debug clean test run run-release fmt-check fmt lint audit docs \
	install-deps install uninstall setup-service setup-udev package package-arch \
	package-deb package-rpm dev-setup dev-clean prepare-release help default