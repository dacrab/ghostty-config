```
╔════════════════════════════════════════════════════════════════╗
║                                                                ║
║   ██████╗ ██╗  ██╗ ██████╗ ███████╗████████╗████████╗██╗   ██╗ ║
║  ██╔════╝ ██║  ██║██╔═══██╗██╔════╝╚══██╔══╝╚══██╔══╝╚██╗ ██╔╝ ║
║  ██║  ███╗███████║██║   ██║███████╗   ██║      ██║    ╚████╔╝  ║
║  ██║   ██║██╔══██║██║   ██║╚════██║   ██║      ██║     ╚██╔╝   ║
║  ╚██████╔╝██║  ██║╚██████╔╝███████║   ██║      ██║      ██║    ║
║   ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝   ╚═╝      ╚═╝      ╚═╝    ║
║                                                                ║
║                Enhanced Installer & Theme Manager              ║
╚════════════════════════════════════════════════════════════════╝
```

# 🚀 Ghostty Enhanced Installer

**One-command installer for Ghostty terminal with 18+ beautiful themes**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Themes](https://img.shields.io/badge/Themes-18+-blue.svg)](#available-themes)
[![Distributions](https://img.shields.io/badge/Linux-8+-red.svg)](#supported-systems)

</div>

## ⚡ Quick Install

<div align="center">

```bash
curl -fsSL https://raw.githubusercontent.com/dacrab/ghostty-config/main/setup.sh | sudo bash
```

</div>

### 🎯 What happens:
1. **🔍 Checks** if Ghostty is installed
2. **🔐 If not** → prompts for password and installs automatically  
3. **🎨 Shows** theme menu with 18+ beautiful options
4. **✨ Pick** a theme or skip (0)
5. **🎉 Done!** Launch Ghostty with your new theme

## 🐧 Supported Systems

<div align="center">

| Distribution | Package Manager | Status |
|:------------:|:---------------:|:------:|
| **Arch Linux** | `pacman` | ✅ |
| **Debian/Ubuntu** | `apt` | ✅ |
| **Fedora/RHEL** | `dnf` | ✅ |
| **openSUSE** | `zypper` | ✅ |
| **NixOS** | `nix` | ✅ |
| **Alpine** | `apk` | ✅ |
| **Gentoo** | `emerge` | ✅ |
| **Void** | `xbps` | ✅ |

</div>

## 🎨 Available Themes

<div align="center">

### 18+ Carefully Curated Themes

</div>

<table align="center">
<tr>
<td align="center">

**🌙 Popular Dark**
- Catppuccin Mocha
- Dracula  
- Tokyo Night
- Nord
- Rose Pine
- Everforest

</td>
<td align="center">

**☀️ Light Themes**
- Catppuccin Latte
- Snow
- Solarized Light
- Rose Pine Dawn

</td>
<td align="center">

**🎮 Retro/Special**
- Synthwave '84
- Retro PC
- Matte Black
- Kanagawa
- Midnight

</td>
</tr>
</table>

<div align="center">

[**🔍 View all theme files →**](config/)

</div>

## 🛠️ Manual Installation

<div align="center">

**Want to install a specific theme manually?**

</div>

```bash
# Create config directory
mkdir -p ~/.config/ghostty

# Download any theme (replace 'dracula' with your choice)
curl -o ~/.config/ghostty/config \
  https://raw.githubusercontent.com/dacrab/ghostty-config/main/config/dracula
```

## ⚙️ Advanced Options

```bash
# Skip themes (install Ghostty only)
curl -fsSL https://raw.githubusercontent.com/dacrab/ghostty-config/main/setup.sh | bash -s -- --skip-theme

# Preview changes without installing
curl -fsSL https://raw.githubusercontent.com/dacrab/ghostty-config/main/setup.sh | bash -s -- --dry-run

# Verbose output for debugging
curl -fsSL https://raw.githubusercontent.com/dacrab/ghostty-config/main/setup.sh | bash -s -- --verbose
```

## 🚀 Features

<div align="center">

| Feature | Description |
|:-------:|:------------|
| 🎯 **One-Command** | Install Ghostty + themes instantly |
| 🔍 **Auto-Detection** | Detects your Linux distribution |
| 🎨 **18+ Themes** | Beautiful, professionally configured |
| 🛡️ **Safe** | Automatic backups, dry-run mode |
| ⚡ **Fast** | Optimized installation process |
| 🔧 **Smart** | Handles repositories and dependencies |

</div>

---

<div align="center">

**Made with ❤️ for terminal enthusiasts**

⭐ **Star this repo if you found it helpful!** ⭐

</div>
