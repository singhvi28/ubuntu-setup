#!/usr/bin/env bash
set -euo pipefail

echo "==> [8/9] Deploying Dotfiles, Neovim Config & Custom Binaries"

DOTFILES_DIR="$(cd "$(dirname "$0")/../dotfiles" && pwd)"

# 1. Neovim configuration
echo "==> Installing Neovim configuration..."
mkdir -p "$HOME/.config/nvim"
cp -r "$DOTFILES_DIR/.config/nvim/"* "$HOME/.config/nvim/"

# 2. MangoHud configuration
echo "==> Installing MangoHud configuration..."
mkdir -p "$HOME/.config/MangoHud"
cp -r "$DOTFILES_DIR/.config/MangoHud/"* "$HOME/.config/MangoHud/"

# 3. VS Code / Code Insiders / Cursor / Qoder settings
echo "==> Deploying IDE settings..."
mkdir -p "$HOME/.config/Code/User" "$HOME/.config/Code - Insiders/User" "$HOME/.config/Cursor/User" "$HOME/.config/Qoder/User"
cp "$DOTFILES_DIR/.config/Code/User/"* "$HOME/.config/Code/User/" 2>/dev/null || true
cp "$DOTFILES_DIR/.config/Code - Insiders/User/"* "$HOME/.config/Code - Insiders/User/" 2>/dev/null || true
cp "$DOTFILES_DIR/.config/Cursor/User/"* "$HOME/.config/Cursor/User/" 2>/dev/null || true
cp "$DOTFILES_DIR/.config/Qoder/User/"* "$HOME/.config/Qoder/User/" 2>/dev/null || true

# 4. NPM & Conda configs
cp "$DOTFILES_DIR/.npmrc" "$HOME/.npmrc" 2>/dev/null || true
cp "$DOTFILES_DIR/.condarc" "$HOME/.condarc" 2>/dev/null || true

# 5. Local custom scripts (~/.local/bin)
echo "==> Installing custom CLI scripts to ~/.local/bin..."
mkdir -p "$HOME/.local/bin"
cp "$DOTFILES_DIR/.local/bin/"* "$HOME/.local/bin/"
chmod +x "$HOME/.local/bin/"*

# 6. Deploy ~/.bashrc_custom and source it from ~/.bashrc (single source of truth)
echo "==> Deploying ~/.bashrc_custom and linking in ~/.bashrc..."
sed "s|/home/singhvi28|$HOME|g" "$DOTFILES_DIR/.bashrc_custom" > "$HOME/.bashrc_custom"

BASHRC="$HOME/.bashrc"
if ! grep -q "\.bashrc_custom" "$BASHRC" 2>/dev/null; then
    cat << 'BASH_EOF' >> "$BASHRC"

# Load ubuntu-setup custom aliases, PATHs, and CPU-for-RAM tunables
if [ -f "$HOME/.bashrc_custom" ]; then
    . "$HOME/.bashrc_custom"
fi
BASH_EOF
fi

echo "==> Dotfiles deployed successfully!"
