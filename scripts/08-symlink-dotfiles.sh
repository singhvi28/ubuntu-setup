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

# 3. VS Code / Cursor / Qoder settings
echo "==> Deploying IDE settings..."
mkdir -p "$HOME/.config/Code/User" "$HOME/.config/Cursor/User" "$HOME/.config/Qoder/User"
cp "$DOTFILES_DIR/.config/Code/User/"* "$HOME/.config/Code/User/" 2>/dev/null || true
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

# 6. Append custom bash configuration if not already present
BASHRC="$HOME/.bashrc"
if ! grep -q "ubuntu-setup / custom aliases" "$BASHRC" 2>/dev/null; then
    echo "==> Appending custom aliases and PATHs to ~/.bashrc..."
    cat << 'BASH_EOF' >> "$BASHRC"

# === ubuntu-setup / custom aliases & PATHs ===
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.npm-global/bin:$PATH"
export PATH="/opt/nvim-linux-x86_64/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"

alias cf-check='cd /home/singhvi28/solve-diff && streamlit run app.py'
alias solve-diff='cd /home/singhvi28/solve-diff && streamlit run app.py'
alias cheese="GDK_BACKEND=x11 cheese"
alias brave2='brave-browser --user-agent="Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Mobile Safari/537.36"'
alias updateall='sudo apt update && sudo apt full-upgrade -y && sudo apt autoremove -y && sudo apt autoclean'
# ============================================
BASH_EOF
fi

echo "==> Dotfiles deployed successfully!"
