#!/usr/bin/env bash

# Ghostty Terminal Emulator - Enhanced Installation & Theme Manager
# Version: 3.0.0
# Description: Installs Ghostty and applies beautiful themes (optimized for sudo execution)
# License: MIT

set -euo pipefail

# Script configuration
readonly SCRIPT_NAME="ghostty-installer"
readonly SCRIPT_VERSION="3.0.0"
readonly LOG_FILE="/tmp/ghostty-install.log"
readonly GITHUB_REPO="https://raw.githubusercontent.com/dacrab/ghostty-config/main"

# Enhanced color palette
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly BOLD='\033[1m'
readonly DIM='\033[2m'
readonly NC='\033[0m'

# Enhanced styling
readonly CHECKMARK="✓"
readonly CROSS="✗"
readonly ARROW="→"
readonly STAR="★"
readonly WARNING="⚠"

# Global variables
TARGET_USER=""
TARGET_HOME=""
VERBOSE=false
SKIP_THEME=false
SKIP_INSTALL=false
NON_INTERACTIVE=false

# ============================================================================
# Enhanced Utility Functions
# ============================================================================

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "ERROR")   echo -e "${RED}${CROSS}${NC} ${BOLD}ERROR:${NC} $message" >&2 ;;
        "WARN")    echo -e "${YELLOW}${WARNING}${NC}  ${BOLD}WARNING:${NC} $message" ;;
        "INFO")    echo -e "${BLUE}${BOLD}ℹ${NC}  ${message}" ;;
        "SUCCESS") echo -e "${GREEN}${CHECKMARK}${NC} ${BOLD}$message${NC}" ;;
        "DEBUG")   [[ "$VERBOSE" == true ]] && echo -e "${DIM}${CYAN}DEBUG:${NC} $message" ;;
        "STEP")    echo -e "${PURPLE}${ARROW}${NC} ${BOLD}$message${NC}" ;;
    esac
    
    # Safe logging
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE" 2>/dev/null || true
}

print_banner() {
    echo
    echo -e "${PURPLE}${BOLD}"
    cat << 'EOF'
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
    ║                          Version 3.0.0                        ║
    ╚════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo -e "  ${CYAN}${BOLD}Professional Installation Script with Beautiful Themes${NC}"
    echo -e "  ${DIM}Optimized for one-line installation with sudo${NC}"
    echo
}

print_separator() {
    echo -e "${DIM}────────────────────────────────────────────────────────────${NC}"
}

spinner() {
    local pid=$1
    local message="$2"
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    
    # Show message immediately
    echo -ne "  ${message}..."
    
    # Only show spinner if we have a TTY
    if [[ -t 1 ]]; then
        local temp
        while kill -0 "$pid" 2>/dev/null; do
            temp=${spinstr#?}
            printf " ${CYAN}%c${NC}" "$spinstr"
            spinstr=$temp${spinstr%"$temp"}
            sleep $delay
            printf "\b\b"
        done
        printf "  "
    else
        # Non-interactive mode - just wait
        wait "$pid" 2>/dev/null || true
    fi
    
    echo
}

# ============================================================================
# User Detection and Setup
# ============================================================================

detect_target_user() {
    # When running with sudo, detect the original user
    if [[ -n "${SUDO_USER:-}" ]]; then
        TARGET_USER="$SUDO_USER"
        log "DEBUG" "Detected sudo user: $TARGET_USER"
    else
        log "WARN" "No SUDO_USER detected, running as root"
        
        # Try to find a suitable user
        local users
        users=$(getent passwd | awk -F: '$3 >= 1000 && $3 < 65534 { print $1 }' | head -5)
        
        if [[ -z "$users" ]]; then
            TARGET_USER="root"
            log "WARN" "No regular users found, using root"
        else
            local user_count
            user_count=$(echo "$users" | wc -l)
            
            if [[ "$user_count" -eq 1 ]]; then
                TARGET_USER="$users"
                log "INFO" "Auto-selected user: $TARGET_USER"
            else
                echo -e "${YELLOW}Multiple users found:${NC}"
                echo "$users" | nl -w2 -s') '
                
                if [[ "$NON_INTERACTIVE" == true ]]; then
                    TARGET_USER=$(echo "$users" | head -1)
                    log "INFO" "Non-interactive mode: auto-selected $TARGET_USER"
                else
                    read -p "Select user number (1-$user_count): " selection
                    TARGET_USER=$(echo "$users" | sed -n "${selection}p")
                    
                    if [[ -z "$TARGET_USER" ]]; then
                        log "ERROR" "Invalid selection"
                        exit 1
                    fi
                fi
            fi
        fi
    fi
    
    # Get user's home directory
    TARGET_HOME=$(getent passwd "$TARGET_USER" 2>/dev/null | cut -d: -f6)
    
    if [[ -z "$TARGET_HOME" || ! -d "$TARGET_HOME" ]]; then
        if [[ "$TARGET_USER" == "root" ]]; then
            TARGET_HOME="/root"
        else
            TARGET_HOME="/home/$TARGET_USER"
        fi
    fi
    
    if [[ ! -d "$TARGET_HOME" ]]; then
        log "ERROR" "Home directory not found: $TARGET_HOME"
        exit 1
    fi
    
    log "SUCCESS" "Target user: $TARGET_USER ($TARGET_HOME)"
}

# ============================================================================
# Distribution Detection and Package Management
# ============================================================================

detect_distribution() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        echo "${ID,,}"
    else
        log "ERROR" "Cannot determine distribution"
        exit 1
    fi
}

run_with_progress() {
    local cmd="$1"
    local description="$2"
    local hide_output="${3:-true}"
    
    log "STEP" "$description"
    
    if [[ "$hide_output" == "true" && "$VERBOSE" != "true" ]]; then
        # Run in background with progress indicator
        eval "$cmd" >/dev/null 2>&1 &
        local pid=$!
        spinner "$pid" "$description"
        wait "$pid"
        local exit_code=$?
    else
        # Show output directly
        log "DEBUG" "Executing: $cmd"
        eval "$cmd"
        local exit_code=$?
    fi
    
    if [[ $exit_code -eq 0 ]]; then
        log "SUCCESS" "$description completed"
    else
        log "ERROR" "$description failed (exit code: $exit_code)"
        return $exit_code
    fi
}

# ============================================================================
# Installation Functions
# ============================================================================

install_arch() {
    log "INFO" "Installing on Arch Linux..."
    
    run_with_progress "pacman -Sy --noconfirm --needed ghostty" \
        "Installing Ghostty from official repositories"
}

install_debian() {
    log "INFO" "Installing on Debian/Ubuntu..."
    
    run_with_progress "apt-get update" \
        "Updating package repositories"
    
    run_with_progress "apt-get install -y curl gpg ca-certificates" \
        "Installing dependencies"
    
    if [[ ! -f /etc/apt/sources.list.d/ghostty.list ]]; then
        log "STEP" "Adding Ghostty APT repository"
        
        # Create keyring directory
        mkdir -p /etc/apt/keyrings
        
        run_with_progress "curl -fsSL https://apt.ghostty.org/ghostty.asc | gpg --dearmor -o /etc/apt/keyrings/ghostty.gpg" \
            "Adding GPG key"
        
        echo 'deb [signed-by=/etc/apt/keyrings/ghostty.gpg] https://apt.ghostty.org/debian/ stable main' > /etc/apt/sources.list.d/ghostty.list
        
        run_with_progress "apt-get update" \
            "Updating with new repository"
    fi
    
    run_with_progress "apt-get install -y ghostty" \
        "Installing Ghostty"
}

install_fedora() {
    log "INFO" "Installing on Fedora/RHEL..."
    
    if ! dnf repolist enabled 2>/dev/null | grep -q "copr.*ghostty"; then
        run_with_progress "dnf copr enable -y ghostty/ghostty" \
            "Enabling Ghostty COPR repository"
    fi
    
    run_with_progress "dnf install -y ghostty" \
        "Installing Ghostty"
}

install_opensuse() {
    log "INFO" "Installing on openSUSE..."
    
    run_with_progress "zypper refresh" \
        "Refreshing repositories"
    
    run_with_progress "zypper install -y ghostty" \
        "Installing Ghostty"
}

install_ghostty() {
    [[ "$SKIP_INSTALL" == true ]] && return 0
    
    if command -v ghostty >/dev/null 2>&1; then
        log "INFO" "Ghostty is already installed"
        return 0
    fi
    
    local distro
    distro=$(detect_distribution)
    
    case "$distro" in
        "arch"|"manjaro"|"endeavouros"|"artix")
            install_arch ;;
        "debian"|"ubuntu"|"pop"|"elementary"|"linuxmint"|"zorin")
            install_debian ;;
        "fedora"|"centos"|"rhel"|"rocky"|"almalinux")
            install_fedora ;;
        "opensuse"|"opensuse-tumbleweed"|"opensuse-leap")
            install_opensuse ;;
        "nixos")
            log "WARN" "NixOS requires manual installation"
            log "INFO" "Add to configuration.nix: environment.systemPackages = [ pkgs.ghostty ];"
            ;;
        *)
            log "ERROR" "Unsupported distribution: $distro"
            log "INFO" "Install manually from: https://ghostty.org"
            exit 1 ;;
    esac
    
    # Verify installation
    if command -v ghostty >/dev/null 2>&1; then
        local version
        version=$(ghostty --version 2>/dev/null | head -1)
        log "SUCCESS" "Ghostty installed successfully! ${version:-}"
    else
        log "ERROR" "Installation verification failed"
        exit 1
    fi
}

# ============================================================================
# Theme Management
# ============================================================================

get_themes() {
    cat << 'EOF'
1|Ash|ash|Neutral gray theme for balanced contrast
2|Catppuccin Latte|catpuccin-latte|Light, warm theme with pastel colors
3|Catppuccin Mocha|catpuccin-mocha|Dark theme with rich, cozy colors
4|Dracula|dracula|Popular dark theme with purple accents
5|Everforest|everforest|Green-based theme comfortable for eyes
6|Kanagawa|kanagawa|Japanese-inspired dark theme
7|Matte Black|matte-black|Pure black theme for OLED displays
8|Midnight|midnight|Deep dark theme for late-night coding
9|Nord|nord|Arctic, north-bluish clean theme
10|Retro PC|retro-pc|Nostalgic green-on-black terminal
11|Rose Pine|rose-pine|Natural pine, faux fur and a bit of soho vibes
12|Rose Pine Dark|rose-pine-dark|Darker variant of Rose Pine theme
13|Snow|snow|Clean, minimal light theme
14|Solarized|solarized|Precision colors for machines and people
15|Solarized Light|solarized-light|Light variant of Solarized theme
16|Solarized Osaka|solarized-osaka|Modern take on Solarized
17|Synthwave '84|synthwave-84|Retro synthwave neon theme
18|Tokyo Night|tokyo-night|Dark blue theme inspired by Tokyo's skyline
EOF
}

show_theme_menu() {
    echo
    echo -e "${CYAN}${BOLD}Available Themes:${NC}"
    echo
    
    get_themes | while IFS='|' read -r num name file desc; do
        printf "  ${PURPLE}%2s)${NC} ${BOLD}%-20s${NC} ${DIM}%s${NC}\n" "$num" "$name" "$desc"
    done
    
    echo
    echo -e "  ${CYAN}${BOLD} 0)${NC}  ${BOLD}Skip theme configuration${NC}"
    echo
}

download_and_apply_theme() {
    local theme_name="$1"
    local theme_file="$2"
    local config_path="$3"
    
    local theme_url="${GITHUB_REPO}/config/${theme_file}"
    
    log "STEP" "Downloading theme: $theme_name"
    
    local temp_file
    temp_file=$(mktemp)
    
    if curl -fsSL -o "$temp_file" "$theme_url"; then
        if [[ -s "$temp_file" ]]; then
            mv "$temp_file" "$config_path"
            
            # Set proper ownership
            local target_group
            target_group=$(id -gn "$TARGET_USER" 2>/dev/null || echo "$TARGET_USER")
            chown "$TARGET_USER:$target_group" "$config_path"
            chmod 644 "$config_path"
            
            log "SUCCESS" "Theme '$theme_name' applied successfully"
            return 0
        fi
    fi
    
    rm -f "$temp_file"
    log "ERROR" "Failed to download theme"
    return 1
}

configure_theme() {
    [[ "$SKIP_THEME" == true ]] && return 0
    
    local config_dir="$TARGET_HOME/.config/ghostty"
    local config_path="$config_dir/config"
    
    # Create config directory
    log "STEP" "Setting up configuration directory"
    mkdir -p "$config_dir"
    
    local target_group
    target_group=$(id -gn "$TARGET_USER" 2>/dev/null || echo "$TARGET_USER")
    chown "$TARGET_USER:$target_group" "$config_dir"
    chmod 755 "$config_dir"
    
    # Handle theme selection
    local choice
    if [[ "$NON_INTERACTIVE" == true ]]; then
        # Auto-select Tokyo Night for non-interactive
        choice="18"
        log "INFO" "Auto-selecting Tokyo Night theme (non-interactive mode)"
    else
        show_theme_menu
        
        while true; do
            read -p "$(echo -e "${BLUE}${BOLD}Select theme (0-18):${NC} ")" choice
            
            [[ "$choice" == "0" ]] && { log "INFO" "Skipping theme configuration"; return 0; }
            [[ "$choice" =~ ^[1-9]$|^1[0-8]$ ]] && break
            
            log "WARN" "Invalid selection. Please choose 0-18."
        done
    fi
    
    # Get theme data
    local theme_data
    theme_data=$(get_themes | grep "^$choice|")
    
    if [[ -z "$theme_data" ]]; then
        log "ERROR" "Invalid theme selection"
        return 1
    fi
    
    local theme_name theme_file
    IFS='|' read -r _ theme_name theme_file _ <<< "$theme_data"
    
    # Backup existing config
    if [[ -f "$config_path" ]]; then
        log "INFO" "Backing up existing configuration"
        cp "$config_path" "${config_dir}/config.bak"
    fi
    
    # Download and apply theme
    if download_and_apply_theme "$theme_name" "$theme_file" "$config_path"; then
        echo
        print_separator
        echo -e "  ${GREEN}${BOLD}${CHECKMARK} Theme Configuration Complete!${NC}"
        echo -e "  ${DIM}Config: ${config_path}${NC}"
        echo -e "  ${DIM}Theme: ${theme_name}${NC}"
        print_separator
    else
        return 1
    fi
}

# ============================================================================
# Main Function
# ============================================================================

show_help() {
    cat << EOF
${BOLD}Ghostty Enhanced Installer${NC}

${BOLD}USAGE:${NC}
    curl -fsSL https://raw.githubusercontent.com/dacrab/ghostty-config/main/setup.sh | sudo bash

${BOLD}OPTIONS:${NC}
    Environment variables can be set before the command:
    
    VERBOSE=1           Enable verbose output
    SKIP_THEME=1        Skip theme configuration
    SKIP_INSTALL=1      Skip Ghostty installation
    NON_INTERACTIVE=1   Auto-select default theme

${BOLD}EXAMPLES:${NC}
    # Standard installation
    curl -fsSL <url> | sudo bash
    
    # Verbose installation
    curl -fsSL <url> | sudo VERBOSE=1 bash
    
    # Install only (no theme)
    curl -fsSL <url> | sudo SKIP_THEME=1 bash
    
    # Theme only (Ghostty already installed)
    curl -fsSL <url> | sudo SKIP_INSTALL=1 bash

${BOLD}SUPPORTED DISTRIBUTIONS:${NC}
    • Arch Linux, Manjaro, EndeavourOS
    • Debian, Ubuntu, Pop!_OS, Linux Mint
    • Fedora, RHEL, Rocky Linux, AlmaLinux
    • openSUSE Leap/Tumbleweed
    • NixOS (manual configuration required)

Repository: https://github.com/dacrab/ghostty-config
EOF
}

main() {
    # Initialize logging
    echo "=== Ghostty Installer Log - $(date) ===" > "$LOG_FILE" 2>/dev/null || true
    
    # Handle environment variables
    [[ "${VERBOSE:-}" == "1" ]] && VERBOSE=true
    [[ "${SKIP_THEME:-}" == "1" ]] && SKIP_THEME=true
    [[ "${SKIP_INSTALL:-}" == "1" ]] && SKIP_INSTALL=true
    [[ "${NON_INTERACTIVE:-}" == "1" ]] && NON_INTERACTIVE=true
    
    # Detect if running non-interactively (from pipe)
    [[ ! -t 0 ]] && NON_INTERACTIVE=true
    
    # Show banner
    print_banner
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        log "ERROR" "This script must be run with sudo privileges"
        log "INFO" "Use: curl -fsSL <url> | sudo bash"
        exit 1
    fi
    
    # Environment info
    if [[ "$NON_INTERACTIVE" == true ]]; then
        echo -e "  ${BLUE}${BOLD}Mode:${NC} Non-interactive installation"
    fi
    if [[ "$VERBOSE" == true ]]; then
        echo -e "  ${BLUE}${BOLD}Verbose:${NC} Enabled"
    fi
    echo
    
    # Detect target user
    detect_target_user
    
    # Install Ghostty
    install_ghostty
    
    # Configure theme
    configure_theme
    
    # Final message
    echo
    log "SUCCESS" "Installation completed successfully!"
    
    if [[ "$SKIP_THEME" != true ]]; then
        echo -e "  ${CYAN}${BOLD}Next steps:${NC}"
        echo -e "  ${ARROW} Launch Ghostty: ${CYAN}ghostty${NC}"
        echo -e "  ${ARROW} Edit config: ${CYAN}${TARGET_HOME}/.config/ghostty/config${NC}"
        echo -e "  ${ARROW} Browse themes: ${CYAN}https://github.com/dacrab/ghostty-config${NC}"
    fi
    
    echo
}

# Error handling
trap 'log "ERROR" "Script interrupted"; exit 1' INT TERM

# Execute main function
main "$@"
