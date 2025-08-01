#!/usr/bin/env bash

# Ghostty Terminal Emulator - Universal Installation & Theme Manager
# Version: 3.4.0
# Description: Installs Ghostty and themes with a universal, compatible interface
# that works on any system, with or without special fonts.
# License: MIT

set -euo pipefail

# Script configuration
readonly SCRIPT_NAME="ghostty-installer"
readonly SCRIPT_VERSION="3.4.0"
readonly GITHUB_REPO="https://raw.githubusercontent.com/dacrab/ghostty-config/main"

# Enhanced color palette
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'
readonly DIM='\033[2m'
readonly NC='\033[0m'

# Enhanced styling
readonly CHECKMARK="✓"
readonly CROSS="✗"
readonly ARROW="→"

# Global variables
LOG_FILE=""
TARGET_USER=""
TARGET_HOME=""
VERBOSE=false
SKIP_THEME=false
SKIP_INSTALL=false

# ============================================================================
# Utility Functions
# ============================================================================

log() {
    local level="$1"; shift; local message="$*"; local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    case "$level" in
        "ERROR")   echo -e "${RED}${CROSS}${NC} ${BOLD}ERROR:${NC} $message" >&2 ;;
        "INFO")    echo -e "${BLUE}${BOLD}ℹ${NC}  ${message}" ;;
        "SUCCESS") echo -e "${GREEN}${CHECKMARK}${NC} ${BOLD}$message${NC}" ;;
        "DEBUG")   [[ "$VERBOSE" == true ]] && echo -e "${DIM}DEBUG: $message${NC}" ;;
        "STEP")    echo -e "${PURPLE}${ARROW}${NC} ${BOLD}$message${NC}" ;;
    esac
    if [[ -n "$LOG_FILE" && -w "$LOG_FILE" ]]; then
        echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    fi
}

cleanup() {
    if [[ -n "$LOG_FILE" && -f "$LOG_FILE" ]]; then
        # On successful exit, offer to remove the log. On error, keep it.
        if [ $? -eq 0 ]; then
             rm -f "$LOG_FILE"
        else
            log "INFO" "An error occurred. Log file kept for review at: $LOG_FILE"
        fi
    fi
}

print_banner() {
    echo -e "${PURPLE}${BOLD}"
    cat << 'EOF'
    ╔════════════════════════════════════════════════════════════════╗
    ║   ██████╗ ██╗  ██╗ ██████╗ ███████╗████████╗████████╗██╗   ██╗ ║
    ║  ██╔════╝ ██║  ██║██╔═══██╗██╔════╝╚══██╔══╝╚══██╔══╝╚██╗ ██╔╝ ║
    ║  ██║  ███╗███████║██║   ██║███████╗   ██║      ██║    ╚████╔╝  ║
    ║  ██║   ██║██╔══██║██║   ██║╚════██║   ██║      ██║     ╚██╔╝   ║
    ║  ╚██████╔╝██║  ██║╚██████╔╝███████║   ██║      ██║      ██║    ║
    ║   ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝   ╚═╝      ╚═╝      ╚═╝    ║
    ║              Universal Installer (v3.4.0)                      ║
    ╚════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    sleep 0.5
}

spinner() {
    local pid=$1; local message="$2"; local delay=0.1
    # FIX: Use a universal ASCII spinner that works on all terminals.
    local spinstr='|/-\'
    local i=0
    
    echo -ne "  ${message}... "
    if [[ -t 1 ]]; then
        while ps -p "$pid" > /dev/null; do
            i=$(( (i+1) %4 ))
            printf "${CYAN}%c${NC}" "${spinstr:$i:1}"
            sleep $delay
            printf "\b"
        done
        printf " " # Clear the spinner character
    else
        wait "$pid" 2>/dev/null || true
    fi
    echo
}

run_with_progress() {
    local cmd="$1"; local description="$2"
    log "STEP" "$description"
    if [[ "$VERBOSE" == true ]]; then
        eval "$cmd"; local exit_code=$?
    else
        eval "$cmd" &> "$LOG_FILE.cmd" &
        local pid=$!; spinner "$pid" "$description"; wait "$pid"; local exit_code=$?
        # Append command output to main log and clean up
        cat "$LOG_FILE.cmd" >> "$LOG_FILE"; rm -f "$LOG_FILE.cmd"
    fi
    if [[ $exit_code -eq 0 ]]; then
        log "SUCCESS" "$description completed"
    else
        log "ERROR" "$description failed (exit code: $exit_code)"; return 1
    fi
}

# ============================================================================
# User and OS Detection
# ============================================================================

detect_target_user() {
    log "STEP" "Detecting user for installation"
    if [[ -n "${SUDO_USER:-}" ]]; then
        TARGET_USER="$SUDO_USER"
    else
        TARGET_USER=$(logname 2>/dev/null || who am i | awk '{print $1}')
    fi
    TARGET_HOME=$(getent passwd "$TARGET_USER" 2>/dev/null | cut -d: -f6)
    if [[ -z "$TARGET_HOME" || ! -d "$TARGET_HOME" ]]; then
        log "ERROR" "Could not determine home directory for user '$TARGET_USER'"; exit 1
    fi
    log "SUCCESS" "Target user: $TARGET_USER ($TARGET_HOME)"
    echo
}

detect_distribution() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release; echo "${ID,,}"
    else
        log "ERROR" "Cannot determine operating system"; exit 1
    fi
}

# ============================================================================
# Installation
# ============================================================================

install_ghostty() {
    [[ "$SKIP_INSTALL" == true ]] && return 0
    if command -v ghostty >/dev/null 2>&1; then
        log "INFO" "Ghostty is already installed. Skipping installation."; return 0
    fi
    
    # Dependencies no longer include 'unzip'
    case "$(detect_distribution)" in
        arch|manjaro|endeavouros)
            run_with_progress "pacman -Sy --noconfirm --needed ghostty" "Installing Ghostty" ;;
        debian|ubuntu|pop|linuxmint)
            run_with_progress "apt-get update" "Updating package lists"
            run_with_progress "apt-get install -y curl gpg" "Installing dependencies"
            mkdir -p /etc/apt/keyrings
            run_with_progress "curl -fsSL https://apt.ghostty.org/ghostty.asc | gpg --dearmor -o /etc/apt/keyrings/ghostty.gpg" "Adding GPG key"
            echo 'deb [signed-by=/etc/apt/keyrings/ghostty.gpg] https://apt.ghostty.org/debian/ stable main' > /etc/apt/sources.list.d/ghostty.list
            run_with_progress "apt-get update" "Updating with new repository"
            run_with_progress "apt-get install -y ghostty" "Installing Ghostty package"
            ;;
        fedora|rhel|rocky|almalinux)
            run_with_progress "dnf install -y dnf-plugins-core" "Installing DNF plugins"
            run_with_progress "dnf copr enable -y dacrab/ghostty" "Enabling Ghostty COPR repository"
            run_with_progress "dnf install -y ghostty" "Installing Ghostty package"
            ;;
        *)
            log "ERROR" "Unsupported distribution. Please install Ghostty manually and re-run with SKIP_INSTALL=1"; exit 1 ;;
    esac
    
    if command -v ghostty >/dev/null 2>&1; then
        log "SUCCESS" "Ghostty installed successfully! ($(ghostty --version 2>/dev/null | head -1))"
    else
        log "ERROR" "Installation failed."; exit 1
    fi
    echo
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
    echo -e "  ${CYAN}${BOLD}Select a Theme to Install${NC}\n"
    get_themes | while IFS='|' read -r num name file desc; do
        printf "  ${PURPLE}%2s)${NC} ${BOLD}%-20s${NC} ${DIM}%s${NC}\n" "$num" "$name" "$desc"
    done
    echo; echo -e "  ${CYAN}${BOLD} 0)${NC}  ${BOLD}Skip theme configuration${NC}\n"
}

apply_theme() {
    local theme_name="$1"; local theme_file_name="$2"; local config_path="$3"
    local theme_url="${GITHUB_REPO}/config/${theme_file_name}"
    local temp_file; temp_file=$(mktemp)

    if run_with_progress "curl --silent --fail -L -o \"$temp_file\" \"$theme_url\"" "Downloading theme: $theme_name"; then
        mv "$temp_file" "$config_path"
        # Ensure the final config file has the correct ownership
        local target_group; target_group=$(id -gn "$TARGET_USER" 2>/dev/null || echo "$TARGET_USER")
        chown "$TARGET_USER:$target_group" "$config_path"; chmod 644 "$config_path"
        return 0
    else
        rm -f "$temp_file"; log "ERROR" "Failed to download theme '$theme_name'"; return 1
    fi
}

configure_theme() {
    [[ "$SKIP_THEME" == true ]] && return 0
    
    local config_dir="$TARGET_HOME/.config/ghostty"; local config_path="$config_dir/config"
    log "STEP" "Setting up configuration directory at $config_dir"
    # Run directory creation and permission changes as the target user to avoid root ownership issues.
    sudo -u "$TARGET_USER" mkdir -p "$config_dir"
    
    show_theme_menu
    local choice; local theme_count; theme_count=$(get_themes | wc -l)
    while true; do
        # Read from /dev/tty to ensure prompts work even when piped from curl.
        read -p "$(echo -e "${BLUE}${BOLD}Select theme (0-$theme_count):${NC} ")" choice < /dev/tty
        if [[ "$choice" == "0" ]]; then log "INFO" "Skipping theme configuration."; return 0; fi
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "$theme_count" ]; then break; fi
        log "ERROR" "Invalid selection. Please enter a number between 0 and $theme_count." >&2
    done
    
    local theme_data; theme_data=$(get_themes | sed -n "${choice}p")
    local theme_name theme_file_name; IFS='|' read -r _ theme_name theme_file_name _ <<< "$theme_data"
    
    if [[ -f "$config_path" ]]; then
        log "STEP" "Backing up existing configuration to $config_path.bak"
        # Perform the backup as the user to respect permissions
        sudo -u "$TARGET_USER" cp "$config_path" "$config_path.bak"
    fi
    
    if apply_theme "$theme_name" "$theme_file_name" "$config_path"; then
        echo; log "SUCCESS" "Theme '$theme_name' applied successfully!"
    fi
}

# ============================================================================
# Main Function
# ============================================================================

main() {
    # Create a temporary log file that will be cleaned up on exit.
    LOG_FILE=$(mktemp /tmp/ghostty-installer-XXXXXX.log); chmod 644 "$LOG_FILE"
    trap cleanup EXIT INT TERM
    
    [[ "${VERBOSE:-}" == "1" ]] && VERBOSE=true
    [[ "${SKIP_THEME:-}" == "1" ]] && SKIP_THEME=true
    [[ "${SKIP_INSTALL:-}" == "1" ]] && SKIP_INSTALL=true
    
    print_banner
    if [[ $EUID -ne 0 ]]; then
        log "ERROR" "This script requires sudo privileges."; exit 1
    fi
    
    detect_target_user
    install_ghostty
    configure_theme
    
    echo; log "SUCCESS" "Installation completed!"
    echo -e "\n  ${ARROW} Launch Ghostty with the command: ${CYAN}ghostty${NC}"
    echo -e "  ${DIM}For the best experience with icons, consider setting a Nerd Font in your terminal.${NC}\n"
}

# Ensure the script starts execution here
main "$@"
