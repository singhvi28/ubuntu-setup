#!/usr/bin/env bash
# ==============================================================================
# Script: 10-nsfw-restrictions.sh
# Repository: https://github.com/singhvi28/ubuntu-setup
# Description: Interactive manager for NSFW restrictions & anti-bypass defenses.
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NSFW_DIR="$SCRIPT_DIR/nsfw-restriction"

# ANSI Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo "==> [10/10] NSFW Website Restrictions & Anti-Bypass Defenses"

run_apply() {
    echo -e "\n${BLUE}==> Applying NSFW content restrictions...${NC}"
    if [ "$EUID" -ne 0 ]; then
        sudo bash "$NSFW_DIR/apply.sh"
    else
        bash "$NSFW_DIR/apply.sh"
    fi
}

run_verify() {
    echo -e "\n${BLUE}==> Running verification probe...${NC}"
    bash "$NSFW_DIR/verify.sh"
}

# Handle command-line arguments if provided
if [ "$#" -gt 0 ]; then
    case "$1" in
        --apply|-a)
            run_apply
            exit 0
            ;;
        --verify|-v)
            run_verify
            exit 0
            ;;
        --help|-h)
            echo "Usage: ./10-nsfw-restrictions.sh [--apply | --verify]"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown argument: $1${NC}"
            exit 1
            ;;
    esac
fi

# Interactive menu
echo -e "${CYAN}-------------------------------------------------------------"
echo " Manage NSFW Filtering, SafeSearch & Firewall Anti-Bypass"
echo -e "-------------------------------------------------------------${NC}"
echo "  [1] Apply / Update Restrictions (DNS, 140k+ Hosts, Browser Policies, Firewall)"
echo "  [2] Verify Current Restriction Status & Run Probes"
echo "  [q] Return / Exit"
echo ""

read -p "Select option [1-2, q]: " -r choice
case "$choice" in
    1) run_apply ;;
    2) run_verify ;;
    q|Q) echo "Skipping...";;
    *) echo -e "${RED}Invalid choice!${NC}" ;;
esac
