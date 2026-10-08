#!/usr/bin/env bash
set -euo pipefail

echo "==> [4/9] Installing Flatpak Applications"

if ! command -v flatpak &>/dev/null; then
    echo "==> Flatpak is not installed. Installing Flatpak..."
    sudo apt update && sudo apt install -y flatpak
fi

sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

FLATPAK_LIST="$(dirname "$0")/../packages/flatpak-packages.list"

if [ -f "$FLATPAK_LIST" ]; then
    while IFS= read -r app || [ -n "$app" ]; do
        [[ "$app" =~ ^#.*$ || -z "$app" ]] && continue
        echo "==> Installing Flatpak: $app..."
        flatpak install -y --noninteractive flathub "$app" || true
    done < "$FLATPAK_LIST"
fi

echo "==> Flatpak installation complete!"
