# 🚀 Ghostty Enhanced Installer & Theme Collection

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell Script](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)
[![Themes](https://img.shields.io/badge/Themes-18+-blue.svg)](#-available-themes)
[![Distributions](https://img.shields.io/badge/Distributions-8+-red.svg)](#-supported-distributions)

A comprehensive installation script and curated theme collection for the Ghostty terminal emulator. Features automatic distribution detection, professional installation, and 18+ beautiful pre-configured themes.

## 🎯 Quick Start

```bash
# One command to install Ghostty + themes
curl -fsSL https://raw.githubusercontent.com/dacrab/ghostty-config/main/setup.sh | bash
```

**What this does:**
- ✅ Detects your Linux distribution automatically
- ✅ Installs Ghostty using the appropriate package manager
- ✅ Lets you choose from 18+ beautiful themes
- ✅ Configures everything with sensible defaults
- ✅ Creates backups of existing configurations

## 📋 Table of Contents

- [✨ Features](#-features)
- [🚀 One-Command Installation](#-one-command-installation)
- [🎨 Available Themes](#-available-themes)
- [🛠️ Script Options](#️-script-options)
- [🐧 Supported Distributions](#-supported-distributions)
- [🔄 Manual Theme Installation](#-manual-theme-installation)
- [🛡️ Safety Features](#️-safety-features)
- [🔧 Configuration Details](#-configuration-details)
- [🚨 Troubleshooting](#-troubleshooting)
- [🤝 Contributing](#-contributing)

## ✨ Features

- 🎯 **One-Command Installation** - Install Ghostty and apply themes instantly
- 🐧 **Multi-Distribution Support** - Works on Arch, Debian/Ubuntu, Fedora, openSUSE, NixOS, and more
- 🎨 **18+ Beautiful Themes** - Carefully curated collection including Dracula, Catppuccin, Tokyo Night, Nord, and more
- 🔧 **Smart Configuration** - Automatic backup, user detection, and error handling
- 📦 **Repository Management** - Handles official repositories and package sources
- 🛡️ **Safe & Reliable** - Comprehensive error handling with dry-run mode

## 🚀 One-Command Installation

### ⚡ Quick Install (Recommended)

Install Ghostty with your favorite theme in a single command:

```bash
curl -fsSL https://raw.githubusercontent.com/dacrab/ghostty-config/main/setup.sh | bash
```

> **Note**: The script will prompt for sudo privileges when needed for system package installation.

### 🔧 Alternative Installation Methods

**Download and inspect first (recommended for security):**
```bash
curl -O https://raw.githubusercontent.com/dacrab/ghostty-config/main/setup.sh
chmod +x setup.sh
# Review the script content
less setup.sh
# Run with sudo for system installation
sudo ./setup.sh
```

**With custom options:**
```bash
# Verbose output for debugging
curl -fsSL https://raw.githubusercontent.com/dacrab/ghostty-config/main/setup.sh | bash -s -- --verbose

# Preview changes without installing (dry run)
curl -fsSL https://raw.githubusercontent.com/dacrab/ghostty-config/main/setup.sh | bash -s -- --dry-run

# Install Ghostty only, skip theme selection
curl -fsSL https://raw.githubusercontent.com/dacrab/ghostty-config/main/setup.sh | bash -s -- --skip-theme
```

### 🛡️ Security Note

Always review scripts before running them with elevated privileges. You can inspect the installer at:
https://raw.githubusercontent.com/dacrab/ghostty-config/main/setup.sh

## 🎨 Available Themes

Choose from our carefully curated collection of 18+ professional themes:

| Theme | Description | Preview |
|-------|-------------|---------|
| **Catppuccin Latte** | Light, warm theme with pastel colors | `#eff1f5` |
| **Catppuccin Mocha** | Dark theme with rich, cozy colors | `#1e1e2e` |
| **Dracula** | Popular dark theme with purple accents | `#282a36` |
| **Tokyo Night** | Dark blue theme inspired by Tokyo's skyline | `#1a1b26` |
| **Nord** | Arctic, north-bluish clean theme | `#2e3440` |
| **Rose Pine** | Natural pine, faux fur and a bit of soho vibes | `#191724` |
| **Rose Pine Dawn** | Light variant of Rose Pine theme | `#faf4ed` |
| **Everforest** | Green-based theme comfortable for eyes | `#2d353b` |
| **Solarized Dark** | Precision colors for machines and people | `#002b36` |
| **Solarized Light** | Light variant of Solarized theme | `#fdf6e3` |
| **Synthwave '84** | Retro synthwave neon theme | `#2a2139` |
| **Midnight** | Deep dark theme for late-night coding | `#0f0f23` |
| **Snow** | Clean, minimal light theme | `#ffffff` |
| **Matte Black** | Pure black theme for OLED displays | `#000000` |
| **Ash** | Neutral gray theme | `#3c3c3c` |
| **Kanagawa** | Japanese-inspired dark theme | `#1f1f28` |
| **Retro PC** | Nostalgic green-on-black terminal | `#000000` |
| **Solarized Osaka** | Modern take on Solarized | `#1a1a2e` |

## 🛠️ Script Options

The installer supports various options for different use cases:

```bash
./setup.sh [OPTIONS]

Options:
  -h, --help          Show help message
  -v, --verbose       Enable verbose output with debugging
  -d, --dry-run       Preview actions without making changes
  -s, --skip-theme    Skip theme selection and configuration
  --version           Show script version
```

### Examples

```bash
# Standard installation with theme selection
./setup.sh

# Install only, skip theme configuration
./setup.sh --skip-theme

# Preview what would be installed
./setup.sh --dry-run --verbose

# One-command with options
curl -fsSL https://raw.githubusercontent.com/dacrab/ghostty-config/main/setup.sh | bash -s -- --verbose
```

## 🐧 Supported Distributions

The installer automatically detects and supports:

| Distribution | Package Manager | Status |
|-------------|----------------|--------|
| **Arch Linux** | pacman | ✅ Official repos |
| **Debian/Ubuntu** | apt | ✅ Official PPA |
| **Fedora/RHEL** | dnf | ✅ COPR repository |
| **openSUSE** | zypper | ✅ Official repos |
| **NixOS** | nix | ✅ Manual instructions |
| **Alpine Linux** | apk | ✅ Community repos |
| **Gentoo** | emerge | ✅ Portage tree |
| **Void Linux** | xbps | ✅ Official repos |

## 🔄 Manual Theme Installation

If you prefer to manually install a specific theme:

### Quick Theme Download
```bash
# Create config directory
mkdir -p ~/.config/ghostty

# Download a specific theme (example: dracula)
curl -o ~/.config/ghostty/config \
  https://raw.githubusercontent.com/dacrab/ghostty-config/main/config/dracula
```

### Available Theme Files
All theme configurations are available in the `config/` directory:

```bash
# List all available themes
curl -s https://api.github.com/repos/dacrab/ghostty-config/contents/config | \
  grep '"name"' | cut -d'"' -f4
```

### Manual Configuration
1. Create the config directory:
   ```bash
   mkdir -p ~/.config/ghostty
   ```

2. Choose and download your preferred theme:
   ```bash
   # Replace 'theme-name' with your choice (e.g., 'tokyo-night', 'catpuccin-mocha')
   curl -o ~/.config/ghostty/config \
     https://raw.githubusercontent.com/dacrab/ghostty-config/main/config/theme-name
   ```

## 🛡️ Safety Features

- **Automatic Backup** - Existing configurations are backed up before changes
- **User Detection** - Works correctly with sudo and different user contexts  
- **Dry Run Mode** - Preview all changes before applying them
- **Error Handling** - Comprehensive error checking and recovery
- **Logging** - Detailed logs saved to `/tmp/ghostty-install.log`

## 🔧 Configuration Details

All themes include these optimized settings:

### Window Settings
- Borderless design for modern aesthetics
- Inherits working directory from parent
- Dark theme with state persistence
- Full HD resolution (1920x1080)

### Font & Display
- **Font**: MesloLGDZ at 12pt (install with your package manager)
- **Cursor**: Block style for better visibility
- **Transparency**: Optimized opacity per theme

### Mouse Behavior
- Auto-hide cursor while typing
- Copy-on-select for productivity
- Smart selection handling

## 🚨 Troubleshooting

### Common Issues

**Permission denied:**
```bash
# Make sure to run with sudo for system installation
sudo ./setup.sh
```

**Font not found:**
```bash
# Install MesloLGDZ font (example for Ubuntu/Debian)
sudo apt install fonts-meslo-lg
```

**Theme not applying:**
```bash
# Check config location and permissions
ls -la ~/.config/ghostty/config
```

**Repository errors:**
```bash
# Try with verbose mode to see detailed errors
./setup.sh --verbose
```

## 🤝 Contributing

We welcome contributions! Here's how you can help:

1. **Add New Themes** - Submit theme configurations in the `config/` directory
2. **Improve Installation** - Enhance distribution support or error handling
3. **Documentation** - Help improve this README or add screenshots
4. **Bug Reports** - Report issues with specific distributions or themes

### Adding a New Theme

1. Create a new theme file in `config/your-theme-name`
2. Follow the existing format and include all required settings
3. Test the theme thoroughly
4. Submit a pull request with a description

## 📜 License

This project is released under the MIT License. Feel free to use, modify, and distribute as you wish.

## 🙏 Acknowledgments

- **Ghostty Team** - For creating an amazing terminal emulator
- **Theme Authors** - Original creators of the color schemes
- **Community** - Contributors and users who make this project better

## 🎯 Quick Theme Preview

Want to see a theme before installing? Check out individual theme files:

```bash
# Preview a theme configuration
curl -s https://raw.githubusercontent.com/dacrab/ghostty-config/main/config/dracula

# List all available themes
curl -s https://api.github.com/repos/dacrab/ghostty-config/contents/config | grep '"name"' | cut -d'"' -f4
```

## ✅ Verification

After installation, verify everything works:

```bash
# Check Ghostty is installed
ghostty --version

# Check your configuration
cat ~/.config/ghostty/config

# Launch Ghostty
ghostty
```

---

**Made with ❤️ for the terminal enthusiast community**

*Star ⭐ this repo if you found it helpful!*
