#!/usr/bin/env bash
set -euo pipefail

REPO="https://raw.githubusercontent.com/dacrab/ghostty-config/main/config"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}/ghostty"
GHOSTTY_SOURCE="deb [signed-by=/usr/share/keyrings/ghostty.gpg] https://debian.griffo.io bookworm main"

GREEN='\033[0;32m' BLUE='\033[0;34m' RED='\033[0;31m' NC='\033[0m'
msg() { printf '%b\n' "$1$2${NC}"; }
die() { msg "$RED" "✗ $1"; exit 1; }

get_distro() {
    if [[ -f /etc/os-release ]]; then
        # shellcheck source=/dev/null
        source /etc/os-release
        echo "${ID,,}"
    else
        die "Unknown distro"
    fi
}

install_ghostty() {
    if command -v ghostty &>/dev/null; then
        msg "$BLUE" "Ghostty already installed"
        return
    fi
    
    msg "$BLUE" "→ Installing Ghostty..."
    case "$(get_distro)" in
        arch|manjaro|endeavouros)
            sudo pacman -Syu ghostty --noconfirm --needed ;;
        debian)
            sudo apt-get update -qq && sudo apt-get install -y -qq curl gpg
            if [[ ! -f /usr/share/keyrings/ghostty.gpg ]]; then
                curl -fsSL https://debian.griffo.io/KEY.gpg | sudo gpg --dearmor -o /usr/share/keyrings/ghostty.gpg
            fi
            if ! grep -qF "$GHOSTTY_SOURCE" /etc/apt/sources.list.d/ghostty.list 2>/dev/null; then
                echo "$GHOSTTY_SOURCE" | sudo tee /etc/apt/sources.list.d/ghostty.list
            fi
            sudo apt-get update -qq && sudo apt-get install -y -qq ghostty ;;
        ubuntu|pop|linuxmint)
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/mkasberg/ghostty-ubuntu/HEAD/install.sh)" ;;
        fedora)
            sudo dnf copr enable -y scottames/ghostty
            sudo dnf install -y ghostty ;;
        opensuse*|suse*)
            sudo zypper install -y ghostty ;;
        alpine)
            sudo apk add ghostty ;;
        gentoo)
            sudo emerge -av ghostty ;;
        void)
            sudo xbps-install -y ghostty ;;
        solus)
            sudo eopkg install -y ghostty ;;
        *)
            if command -v snap &>/dev/null; then
                sudo snap install ghostty --classic
                return
            fi
            die "Unsupported distro. Install Ghostty manually: https://ghostty.org/docs/install/binary" ;;
    esac
    
    if command -v ghostty &>/dev/null; then
        msg "$GREEN" "✓ Ghostty installed"
    else
        die "Installation failed"
    fi
}

THEMES=(
    "Ash|ash" "Catppuccin Latte|catpuccin-latte" "Catppuccin Mocha|catpuccin-mocha"
    "Dracula|dracula" "Everforest|everforest" "Kanagawa|kanagawa" "Matte Black|matte-black"
    "Midnight|midnight" "Nord|nord" "Retro PC|retro-pc" "Rose Pine|rose-pine"
    "Rose Pine Dawn|rose-pine-dark" "Snow|snow" "Solarized|solarized"
    "Solarized Light|solarized-light" "Solarized Osaka|solarized-osaka"
    "Synthwave '84|synthwave-84" "Tokyo Night|tokyo-night"
)

select_theme() {
    echo -e "\n${BLUE}Select a theme:${NC}\n"
    for i in "${!THEMES[@]}"; do printf "  %2d) %s\n" $((i+1)) "${THEMES[$i]%%|*}"; done
    echo -e "   0) Skip\n"
    
    while true; do
        read -rp "Choice [0-${#THEMES[@]}]: " n
        [[ "$n" == "0" || -z "$n" ]] && return
        if ((n >= 1 && n <= ${#THEMES[@]})); then
            break
        fi
        msg "$RED" "Invalid"
    done
    
    file="${THEMES[$((n-1))]##*|}"
    mkdir -p "$CFG"
    [[ -f "$CFG/config" ]] && cp "$CFG/config" "$CFG/config.bak"
    curl -fsSL "$REPO/$file" -o "$CFG/config"
    msg "$GREEN" "✓ Theme applied"
}

echo -e "\n${BLUE}👻 Ghostty Setup${NC}"
install_ghostty
select_theme
echo -e "\n${GREEN}✓ Done!${NC} Run 'ghostty' to launch.\n"
