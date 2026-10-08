#!/usr/bin/env bash
set -euo pipefail

echo "==> [5/9] Setting up Development Runtimes (Node, UV/Python, Go, Neovim, IDE Extensions)"

mkdir -p "$HOME/.local/bin"

# 1. NPM Global Prefix & Tools
echo "==> Configuring NPM global prefix at ~/.npm-global..."
mkdir -p "$HOME/.npm-global/bin" "$HOME/.npm-global/lib"
npm config set prefix "$HOME/.npm-global"
if command -v npm &>/dev/null; then
    echo "==> Installing global NPM packages (mudslide)..."
    npm install -g mudslide || true
fi

# 2. UV (Extremely fast Python package manager)
echo "==> Installing astral uv..."
if ! command -v uv &>/dev/null; then
    curl -LsSf https://astral.sh/uv/install.sh | sh || true
fi

# 3. Pipx & yt-dlp
echo "==> Installing pipx & yt-dlp..."
sudo apt install -y pipx || true
pipx ensurepath || true
pipx install yt-dlp || true

# 4. Official Neovim Binary (/opt/nvim-linux-x86_64)
if [ ! -d "/opt/nvim-linux-x86_64" ]; then
    echo "==> Installing Neovim latest release to /opt/nvim-linux-x86_64..."
    NVIM_URL="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz"
    TEMP_DIR=$(mktemp -d)
    curl -fsSL "$NVIM_URL" -o "$TEMP_DIR/nvim.tar.gz"
    sudo tar -C /opt -xzf "$TEMP_DIR/nvim.tar.gz"
    rm -rf "$TEMP_DIR"
fi

# 5. Go Runtime
if [ ! -d "$HOME/.local/go" ] && ! command -v go &>/dev/null; then
    echo "==> Installing Go 1.23.6 to ~/.local/go..."
    GO_VERSION="1.23.6"
    GO_TAR="go${GO_VERSION}.linux-amd64.tar.gz"
    TEMP_DIR=$(mktemp -d)
    curl -fsSL "https://go.dev/dl/${GO_TAR}" -o "$TEMP_DIR/${GO_TAR}"
    mkdir -p "$HOME/.local"
    tar -C "$HOME/.local" -xzf "$TEMP_DIR/${GO_TAR}"
    rm -rf "$TEMP_DIR"
    mkdir -p "$HOME/go/bin" "$HOME/go/src" "$HOME/go/pkg"
fi

# 6. VS Code Extensions
if command -v code &>/dev/null; then
    VSCODE_LIST="$(dirname "$0")/../packages/vscode-extensions.list"
    if [ -f "$VSCODE_LIST" ]; then
        echo "==> Installing VS Code extensions..."
        while IFS= read -r ext || [ -n "$ext" ]; do
            [[ "$ext" =~ ^#.*$ || -z "$ext" ]] && continue
            code --install-extension "$ext" --force || true
        done < "$VSCODE_LIST"
    fi
fi

# 7. Cursor Extensions
if command -v cursor &>/dev/null; then
    CURSOR_LIST="$(dirname "$0")/../packages/cursor-extensions.list"
    if [ -f "$CURSOR_LIST" ]; then
        echo "==> Installing Cursor extensions..."
        while IFS= read -r ext || [ -n "$ext" ]; do
            [[ "$ext" =~ ^#.*$ || -z "$ext" ]] && continue
            cursor --install-extension "$ext" --force || true
        done < "$CURSOR_LIST"
    fi
fi

echo "==> Development runtimes setup complete!"
