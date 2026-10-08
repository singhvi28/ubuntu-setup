#!/usr/bin/env bash
# ==============================================================================
# Master Setup & Bootstrap Script for Ubuntu 24.04 (Noble Numbat)
# Created for: singhvi28
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"

# ANSI Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_banner() {
    echo -e "${CYAN}"
    echo "=================================================================="
    echo "       🚀 Ubuntu 24.04 LTS Custom Setup & Dotfiles Bootstrap      "
    echo "                 Automated Environment Installer                  "
    echo "=================================================================="
    echo -e "${NC}"
}

run_step() {
    local script_name="$1"
    local desc="$2"
    echo -e "\n${BLUE}==> Executing: ${desc} (${script_name})${NC}"
    if [ -f "$SCRIPTS_DIR/$script_name" ]; then
        bash "$SCRIPTS_DIR/$script_name"
        echo -e "${GREEN}✓ Completed: ${desc}${NC}"
    else
        echo -e "${RED}✗ Error: Script $script_name not found!${NC}"
        return 1
    fi
}

run_all() {
    echo -e "${YELLOW}Starting full installation...${NC}"
    run_step "01-system-prep.sh" "System prep, sysctl tuning & Flatpak setup"
    run_step "02-apt-repositories.sh" "External APT PPAs & GPG keyrings"
    run_step "03-install-apt-packages.sh" "Curated APT packages & development tools"
    run_step "04-install-flatpaks.sh" "Flatpak desktop applications"
    run_step "05-dev-runtimes.sh" "Node.js, UV/Python, Go, Neovim & IDE extensions"
    run_step "06-gnome-desktop.sh" "GNOME desktop, keybindings & extensions"
    run_step "07-services-rtorrent.sh" "rTorrent systemd daemon & directory structure"
    run_step "08-symlink-dotfiles.sh" "Dotfiles, Neovim config & CLI scripts"
    run_step "09-face-unlock-howdy.sh" "Howdy face unlock setup guide"
    
    echo -e "\n${GREEN}=================================================================="
    echo "🎉 Complete system setup finished successfully!"
    echo "Please restart your shell or run: source ~/.bashrc"
    echo "==================================================================${NC}"
}

print_menu() {
    print_banner
    echo "Choose an option to execute:"
    echo "  [0] Run ALL Steps (Full System Bootstrap)"
    echo "  [1] System Preparation & Sysctl Tuning (swappiness, TTL)"
    echo "  [2] External APT Repositories & Keyrings (Chrome, Brave, Docker, etc.)"
    echo "  [3] Install APT Packages (Compilers, DBs, IDEs, Tools)"
    echo "  [4] Install Flatpak Apps (Firefox, Motrix, LocalSend, Bottles)"
    echo "  [5] Development Runtimes (Node 20, uv, Go, Neovim, Extensions)"
    echo "  [6] GNOME Desktop & Extensions (Dock, Keybindings, Fractional Scaling)"
    echo "  [7] rTorrent Service & Configuration"
    echo "  [8] Dotfiles & CLI Scripts (~/.local/bin, Neovim, MangoHud)"
    echo "  [9] Facial Recognition / Howdy Guide"
    echo "  [q] Quit"
    echo ""
}

if [ "$#" -gt 0 ]; then
    case "$1" in
        --all|-a)
            run_all
            exit 0
            ;;
        --help|-h)
            echo "Usage: ./bootstrap.sh [--all|-a]"
            exit 0
            ;;
        *)
            echo "Unknown argument: $1"
            exit 1
            ;;
    esac
fi

while true; do
    print_menu
    read -p "Select option [0-9, q]: " choice
    case "$choice" in
        0) run_all; break ;;
        1) run_step "01-system-prep.sh" "System prep & sysctl";;
        2) run_step "02-apt-repositories.sh" "External APT Repositories";;
        3) run_step "03-install-apt-packages.sh" "APT Packages";;
        4) run_step "04-install-flatpaks.sh" "Flatpak Applications";;
        5) run_step "05-dev-runtimes.sh" "Development Runtimes";;
        6) run_step "06-gnome-desktop.sh" "GNOME Desktop & Extensions";;
        7) run_step "07-services-rtorrent.sh" "rTorrent Systemd Service";;
        8) run_step "08-symlink-dotfiles.sh" "Dotfiles & Scripts";;
        9) run_step "09-face-unlock-howdy.sh" "Howdy Facial Recognition";;
        q|Q) echo "Exiting..."; exit 0;;
        *) echo -e "${RED}Invalid choice!${NC}\n";;
    esac
    echo ""
    read -p "Press Enter to continue..."
done
