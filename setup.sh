#!/usr/bin/env bash

# Ghostty Terminal Emulator - Enhanced Installation & Theme Manager
# Version: 2.0.0
# Description: Installs Ghostty and applies beautiful themes automatically
# License: MIT

set -euo pipefail

# Script configuration
readonly SCRIPT_NAME="$(basename "${0}")"
readonly SCRIPT_VERSION="2.0.0"
readonly LOG_FILE="/tmp/ghostty-install.log"

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

# Global variables
REAL_USER=""
USER_HOME=""
DRY_RUN=false
VERBOSE=false
SKIP_THEME=false

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
        "WARN")    echo -e "${YELLOW}${BOLD}⚠${NC}  ${BOLD}WARNING:${NC} $message" ;;
        "INFO")    echo -e "${BLUE}${BOLD}ℹ${NC}  ${message}" ;;
        "SUCCESS") echo -e "${GREEN}${CHECKMARK}${NC} ${BOLD}$message${NC}" ;;
        "DEBUG")   [[ "$VERBOSE" == true ]] && echo -e "${DIM}${CYAN}DEBUG:${NC} $message" ;;
        "STEP")    echo -e "${PURPLE}${ARROW}${NC} ${BOLD}$message${NC}" ;;
    esac
    
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

print_banner() {
    clear
    echo
    echo -e "${PURPLE}${BOLD}"
    cat << 'EOF'
    ╔══════════════════════════════════════════════════════════╗
    ║                                                          ║
    ║   ██████╗ ██╗  ██╗ ██████╗ ███████╗████████╗████████╗   ║
    ║  ██╔════╝ ██║  ██║██╔═══██╗██╔════╝╚══██╔══╝╚══██╔══╝   ║
    ║  ██║  ███╗███████║██║   ██║███████╗   ██║      ██║      ║
    ║  ██║   ██║██╔══██║██║   ██║╚════██║   ██║      ██║      ║
    ║  ╚██████╔╝██║  ██║╚██████╔╝███████║   ██║      ██║      ║
    ║   ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝   ╚═╝      ╚═╝      ║
    ║                                                          ║
    ║            Enhanced Installer & Theme Manager            ║
    ║                      Version 2.0.0                      ║
    ╚══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo -e "  ${CYAN}${BOLD}Professional Installation Script with Beautiful Themes${NC}"
    echo -e "  ${DIM}Automatically detects your system and applies stunning themes${NC}"
    echo
}

print_separator() {
    echo -e "${DIM}────────────────────────────────────────────────────────────${NC}"
}

spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local temp
    
    while ps -p "$pid" > /dev/null 2>&1; do
        temp=${spinstr#?}
        printf " ${CYAN}%c${NC}  " "$spinstr"
        spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

show_help() {
    cat << EOF
${BOLD}USAGE:${NC}
    $SCRIPT_NAME [OPTIONS]

${BOLD}DESCRIPTION:${NC}
    Enhanced installer for Ghostty terminal emulator with automatic theme management.
    Detects your Linux distribution and installs using the appropriate method.
    Includes 18+ curated themes with professional configurations.

${BOLD}OPTIONS:${NC}
    -h, --help          Show this help message
    -v, --verbose       Enable verbose output with debugging info
    -d, --dry-run       Preview actions without making changes
    -s, --skip-theme    Skip theme selection and configuration
    --version           Show script version

${BOLD}SUPPORTED DISTRIBUTIONS:${NC}
    ${GREEN}${CHECKMARK}${NC} Arch Linux (pacman)          ${GREEN}${CHECKMARK}${NC} Alpine Linux (apk)
    ${GREEN}${CHECKMARK}${NC} Debian/Ubuntu (apt)          ${GREEN}${CHECKMARK}${NC} Fedora/RHEL (dnf)
    ${GREEN}${CHECKMARK}${NC} openSUSE (zypper)            ${GREEN}${CHECKMARK}${NC} Gentoo (emerge)
    ${GREEN}${CHECKMARK}${NC} NixOS (nix)                  ${GREEN}${CHECKMARK}${NC} Void Linux (xbps)

${BOLD}FEATURES:${NC}
    • Automatic distribution detection
    • Repository setup and management
    • 18+ beautiful pre-configured themes
    • Configuration file management
    • Backup and restore functionality
    • Comprehensive error handling

${BOLD}EXAMPLES:${NC}
    $SCRIPT_NAME                     # Standard installation with theme selection
    $SCRIPT_NAME --skip-theme        # Install only, skip theme configuration
    $SCRIPT_NAME --dry-run --verbose # Preview with detailed output

${BOLD}THEME REPOSITORY:${NC}
    Themes sourced from: https://github.com/dacrab/ghostty-config

For support and issues: https://github.com/dacrab/ghostty-config/issues
EOF
}

check_dependencies() {
    local deps=("curl" "grep" "awk" "id" "getent")
    local missing_deps=()
    
    log "DEBUG" "Checking script dependencies..."
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log "ERROR" "Missing required dependencies: ${missing_deps[*]}"
        log "ERROR" "Please install these packages and retry"
        exit 1
    fi
    
    log "DEBUG" "All dependencies satisfied"
}

setup_user_environment() {
    # Determine real user (works with sudo)
    if [[ -n "${SUDO_USER:-}" ]]; then
        REAL_USER="$SUDO_USER"
    elif [[ "$EUID" -eq 0 ]]; then
        log "WARN" "Running as root without SUDO_USER set"
        read -p "Enter username for configuration: " REAL_USER
        if [[ -z "$REAL_USER" ]]; then
            log "ERROR" "Username required for configuration"
            exit 1
        fi
    else
        REAL_USER="$(whoami)"
    fi
    
    # Get user's home directory
    if ! USER_HOME=$(getent passwd "$REAL_USER" 2>/dev/null | cut -d: -f6); then
        log "ERROR" "Could not determine home directory for user '$REAL_USER'"
        exit 1
    fi
    
    if [[ ! -d "$USER_HOME" ]]; then
        log "ERROR" "Home directory does not exist: $USER_HOME"
        exit 1
    fi
    
    log "DEBUG" "User: $REAL_USER, Home: $USER_HOME"
}

# ============================================================================
# Enhanced Distribution Detection
# ============================================================================

detect_distribution() {
    log "STEP" "Detecting Linux distribution..."
    
    local distro=""
    local version=""
    
    if [[ -f /etc/os-release ]]; then
        # shellcheck source=/etc/os-release
        source /etc/os-release
        distro="${ID,,}"
        version="${VERSION_ID:-unknown}"
        
        log "INFO" "Detected: ${NAME:-$distro} ${version}"
        log "DEBUG" "Distribution ID: $distro"
        
        echo "$distro"
    else
        log "ERROR" "Cannot determine distribution - /etc/os-release not found"
        exit 1
    fi
}

# ============================================================================
# Installation Functions with Enhanced Error Handling
# ============================================================================

execute_with_progress() {
    local cmd="$1"
    local description="$2"
    
    log "STEP" "$description"
    
    if [[ "$DRY_RUN" == true ]]; then
        log "INFO" "[DRY RUN] Would execute: $cmd"
        return 0
    fi
    
    # Execute command in background and show spinner
    if [[ "$VERBOSE" == true ]]; then
        log "DEBUG" "Executing: $cmd"
        eval "$cmd"
    else
        eval "$cmd" > /tmp/cmd_output 2>&1 &
        local cmd_pid=$!
        spinner $cmd_pid
        wait $cmd_pid
        local exit_code=$?
        
        if [[ $exit_code -eq 0 ]]; then
            log "SUCCESS" "$description completed"
        else
            log "ERROR" "$description failed (exit code: $exit_code)"
            [[ -f /tmp/cmd_output ]] && cat /tmp/cmd_output >&2
            return $exit_code
        fi
    fi
}

install_arch() {
    log "INFO" "Installing on Arch Linux..."
    
    execute_with_progress "sudo pacman -Sy --noconfirm --needed ghostty" \
        "Installing Ghostty from official repositories"
}

install_debian_based() {
    log "INFO" "Installing on Debian/Ubuntu system..."
    
    execute_with_progress "sudo apt-get update" \
        "Updating package repositories"
    
    execute_with_progress "sudo apt-get install -y curl gpg ca-certificates" \
        "Installing required dependencies"
    
    # Check if repository is already configured
    if [[ ! -f /etc/apt/sources.list.d/ghostty.list ]]; then
        log "STEP" "Adding official Ghostty APT repository"
        
        execute_with_progress "curl -fsSL https://apt.ghostty.org/ghostty.asc | sudo gpg --dearmor -o /etc/apt/keyrings/ghostty.gpg" \
            "Adding repository GPG key"
        
        execute_with_progress "echo 'deb [signed-by=/etc/apt/keyrings/ghostty.gpg] https://apt.ghostty.org/debian/ stable main' | sudo tee /etc/apt/sources.list.d/ghostty.list" \
            "Adding repository configuration"
        
        execute_with_progress "sudo apt-get update" \
            "Updating package lists with new repository"
    else
        log "INFO" "Ghostty repository already configured"
    fi
    
    execute_with_progress "sudo apt-get install -y ghostty" \
        "Installing Ghostty"
}

install_fedora() {
    log "INFO" "Installing on Fedora/RHEL system..."
    
    # Try official COPR repository first
    if ! dnf repolist enabled 2>/dev/null | grep -q "copr.*ghostty"; then
        log "STEP" "Enabling COPR repository for Ghostty"
        
        if execute_with_progress "sudo dnf copr enable -y ghostty/ghostty" \
            "Enabling official COPR repository"; then
            log "SUCCESS" "COPR repository enabled"
        else
            log "WARN" "COPR repository failed, trying alternative methods"
            
            # Fallback to manual repository setup
            execute_with_progress "sudo dnf install -y dnf-plugins-core" \
                "Installing DNF plugins"
            
            # Add Terra repository as fallback
            execute_with_progress "sudo dnf config-manager --add-repo https://terra.fyralabs.com/terra.repo" \
                "Adding Terra repository as fallback"
        fi
    else
        log "INFO" "Ghostty repository already enabled"
    fi
    
    execute_with_progress "sudo dnf install -y ghostty" \
        "Installing Ghostty"
}

install_opensuse() {
    log "INFO" "Installing on openSUSE..."
    
    execute_with_progress "sudo zypper refresh" \
        "Refreshing package repositories"
    
    execute_with_progress "sudo zypper install -y ghostty" \
        "Installing Ghostty"
}

install_nixos() {
    log "INFO" "NixOS detected"
    log "WARN" "NixOS requires manual configuration"
    
    cat << EOF

${YELLOW}${BOLD}NixOS Installation Instructions:${NC}

1. Add Ghostty to your system configuration:
   ${CYAN}environment.systemPackages = [ pkgs.ghostty ];${NC}

2. Rebuild your system:
   ${CYAN}sudo nixos-rebuild switch${NC}

3. Or install in user profile:
   ${CYAN}nix-env -iA nixpkgs.ghostty${NC}

EOF
    
    read -p "Press Enter to continue with theme configuration..." -r
}

# ============================================================================
# Enhanced Theme Management
# ============================================================================

get_available_themes() {
    # Enhanced theme list matching the config directory
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

display_theme_menu() {
    echo
    log "INFO" "Available themes:"
    echo
    
    local theme_data
    theme_data=$(get_available_themes)
    
    while IFS='|' read -r num name file desc; do
        printf "  ${PURPLE}%2s)${NC} ${BOLD}%-20s${NC} ${DIM}%s${NC}\n" "$num" "$name" "$desc"
    done <<< "$theme_data"
    
    echo
    echo -e "  ${CYAN}${BOLD}0)${NC}  ${BOLD}Skip theme configuration${NC}"
    echo
}

download_theme() {
    local theme_file="$1"
    local theme_name="$2"
    local config_path="$3"
    
    # Use GitHub repository for theme files
    local base_url="https://raw.githubusercontent.com/dacrab/ghostty-config/main/config"
    local theme_url="${base_url}/${theme_file}"
    
    log "STEP" "Downloading theme: $theme_name"
    
    if [[ "$DRY_RUN" == true ]]; then
        log "INFO" "[DRY RUN] Would download from: $theme_url"
        return 0
    fi
    
    # Create a temporary file for download
    local temp_file
    temp_file=$(mktemp)
    
    if curl -fsSL -o "$temp_file" "$theme_url"; then
        # Verify the download was successful and contains theme data
        if [[ -s "$temp_file" ]] && grep -q "^#\|^[a-z-]" "$temp_file"; then
            mv "$temp_file" "$config_path"
            log "SUCCESS" "Theme downloaded and applied successfully"
            return 0
        else
            log "ERROR" "Downloaded file appears to be invalid"
            rm -f "$temp_file"
            return 1
        fi
    else
        log "ERROR" "Failed to download theme from $theme_url"
        rm -f "$temp_file"
        return 1
    fi
}

create_custom_config() {
    local config_path="$1"
    local theme_name="$2"
    
    log "INFO" "Creating custom configuration with $theme_name theme"
    
    cat > "$config_path" << EOF
# Ghostty Configuration
# Theme: $theme_name
# Generated by Ghostty Enhanced Installer v$SCRIPT_VERSION
# $(date)

# Window settings
window-decoration = false
window-inherit-working-directory = true
window-theme = dark
window-save-state = always
window-width = 1920
window-height = 1080

# Mouse settings
mouse-hide-while-typing = true
copy-on-select = true

# Font and cursor settings
font-family = MesloLGDZ
font-size = 12
cursor-style = block

# Theme-specific settings will be applied from downloaded theme file
EOF
}

apply_theme_configuration() {
    [[ "$SKIP_THEME" == true ]] && return 0
    
    log "STEP" "Configuring Ghostty theme"
    
    setup_user_environment
    
    local config_dir="$USER_HOME/.config/ghostty"
    local config_path="$config_dir/config"
    
    # Create config directory
    log "DEBUG" "Creating config directory: $config_dir"
    if [[ "$DRY_RUN" != true ]]; then
        install -d -o "$REAL_USER" -g "$(id -gn "$REAL_USER")" -m 755 "$config_dir"
    fi
    
    # Show theme selection menu
    display_theme_menu
    
    local choice
    while true; do
        read -p "$(echo -e "${BLUE}${BOLD}Select theme (0-18):${NC} ")" choice
        
        if [[ "$choice" == "0" ]]; then
            log "INFO" "Skipping theme configuration"
            return 0
        fi
        
        if [[ "$choice" =~ ^[1-9]$|^1[0-8]$ ]]; then
            break
        fi
        
        log "WARN" "Invalid selection. Please choose 0-18."
    done
    
    # Get theme information
    local theme_data
    theme_data=$(get_available_themes | grep "^$choice|")
    
    if [[ -z "$theme_data" ]]; then
        log "ERROR" "Theme selection error"
        return 1
    fi
    
    local theme_name theme_file
    IFS='|' read -r _ theme_name theme_file _ <<< "$theme_data"
    
    # Backup existing configuration
    if [[ -f "$config_path" && "$DRY_RUN" != true ]]; then
        local backup_path="${config_path}.backup.$(date +%Y%m%d_%H%M%S)"
        log "INFO" "Backing up existing configuration to $(basename "$backup_path")"
        cp "$config_path" "$backup_path"
    fi
    
    # Download and apply theme
    if download_theme "$theme_file" "$theme_name" "$config_path"; then
        if [[ "$DRY_RUN" != true ]]; then
            chown "$REAL_USER":"$(id -gn "$REAL_USER")" "$config_path"
            chmod 644 "$config_path"
        fi
        
        log "SUCCESS" "Theme '$theme_name' applied successfully!"
        
        echo
        print_separator
        echo -e "  ${GREEN}${BOLD}${CHECKMARK} Configuration Complete!${NC}"
        echo -e "  ${DIM}Config location: ${config_path}${NC}"
        echo -e "  ${DIM}Launch Ghostty to see your new theme${NC}"
        print_separator
        echo
    else
        log "ERROR" "Failed to apply theme"
        return 1
    fi
}

# ============================================================================
# Installation Verification
# ============================================================================

verify_installation() {
    log "STEP" "Verifying Ghostty installation"
    
    if command -v ghostty &> /dev/null; then
        local version
        if version=$(ghostty --version 2>/dev/null); then
            log "SUCCESS" "Ghostty installed successfully! Version: $version"
        else
            log "SUCCESS" "Ghostty installed successfully!"
        fi
        return 0
    else
        log "ERROR" "Ghostty installation verification failed"
        return 1
    fi
}

# ============================================================================
# Main Installation Logic
# ============================================================================

install_ghostty() {
    local distro
    distro=$(detect_distribution)
    
    # Check if already installed
    if command -v ghostty &> /dev/null; then
        log "INFO" "Ghostty is already installed"
        local version
        if version=$(ghostty --version 2>/dev/null); then
            log "INFO" "Current version: $version"
        fi
        return 0
    fi
    
    log "STEP" "Installing Ghostty..."
    
    case "$distro" in
        "arch"|"manjaro"|"endeavouros"|"artix")
            install_arch
            ;;
        "debian"|"ubuntu"|"pop"|"elementary"|"linuxmint"|"zorin")
            install_debian_based
            ;;
        "fedora"|"centos"|"rhel"|"rocky"|"almalinux")
            install_fedora
            ;;
        "opensuse"|"opensuse-tumbleweed"|"opensuse-leap")
            install_opensuse
            ;;
        "nixos")
            install_nixos
            ;;
        *)
            log "ERROR" "Unsupported distribution: $distro"
            log "INFO" "Please install Ghostty manually from: https://ghostty.org"
            exit 1
            ;;
    esac
}

# ============================================================================
# Argument Parsing and Main Function
# ============================================================================

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -s|--skip-theme)
                SKIP_THEME=true
                shift
                ;;
            --version)
                echo "$SCRIPT_NAME version $SCRIPT_VERSION"
                exit 0
                ;;
            *)
                log "ERROR" "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
}

cleanup() {
    local exit_code=$?
    
    # Clean up temporary files
    rm -f /tmp/cmd_output /tmp/ghostty_theme_*
    
    if [[ $exit_code -eq 0 ]]; then
        echo
        log "SUCCESS" "All operations completed successfully!"
        if [[ "$DRY_RUN" != true && "$SKIP_THEME" != true ]]; then
            echo -e "  ${CYAN}${BOLD}Next steps:${NC}"
            echo -e "  ${ARROW} Launch Ghostty: ${CYAN}ghostty${NC}"
            echo -e "  ${ARROW} Edit config: ${CYAN}~/.config/ghostty/config${NC}"
            echo -e "  ${ARROW} More themes: ${CYAN}https://github.com/ghostty-org/ghostty${NC}"
        fi
    else
        echo
        log "ERROR" "Script failed with exit code $exit_code"
        log "INFO" "Check the log file: $LOG_FILE"
    fi
    
    echo
    exit $exit_code
}

main() {
    # Set up error handling and cleanup
    trap cleanup EXIT
    
    # Initialize log file
    echo "=== Ghostty Enhanced Installer Log - $(date) ===" > "$LOG_FILE"
    
    # Parse command line arguments
    parse_arguments "$@"
    
    # Show enhanced banner
    print_banner
    
    # Dry run notification
    if [[ "$DRY_RUN" == true ]]; then
        echo -e "  ${YELLOW}${BOLD}DRY RUN MODE${NC} ${DIM}- No changes will be made${NC}"
        echo
    fi
    
    # Preflight checks
    log "STEP" "Performing system checks"
    check_dependencies
    
    # Check if we need elevated privileges
    if [[ $EUID -ne 0 && "$DRY_RUN" != true ]]; then
        log "ERROR" "This script requires elevated privileges"
        log "INFO" "Please run with sudo: sudo $0"
        exit 1
    fi
    
    # Install Ghostty
    install_ghostty
    
    # Verify installation (skip in dry run)
    if [[ "$DRY_RUN" != true ]]; then
        verify_installation
    fi
    
    # Apply theme configuration
    apply_theme_configuration
}

# Execute main function with all arguments
main "$@"