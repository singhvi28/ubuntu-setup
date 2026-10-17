#!/usr/bin/env bash
set -euo pipefail

echo "==> [5/9] Setting up Development Runtimes (Node, UV/Python, Ollama, Go, Neovim, IDE Extensions)"

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

# 4. Ollama (Local LLM Inference Engine) + KV-Cache Quantization & Auto-Unload Override
if ! command -v ollama &>/dev/null; then
    echo "==> Installing Ollama for local LLM inference..."
    curl -fsSL https://ollama.com/install.sh | sh || true
fi
if [ -f "$(dirname "$0")/../configs/systemd/ollama-memory-override.conf" ]; then
    echo "==> Applying Ollama memory optimization override (Flash Attention, q8_0 KV-cache, 3m keep-alive)..."
    sudo mkdir -p /etc/systemd/system/ollama.service.d
    sudo cp "$(dirname "$0")/../configs/systemd/ollama-memory-override.conf" /etc/systemd/system/ollama.service.d/override.conf
    sudo systemctl daemon-reload || true
    sudo systemctl try-restart ollama.service 2>/dev/null || true
fi

# 5. Official Neovim Binary (/opt/nvim-linux-x86_64)
if [ ! -d "/opt/nvim-linux-x86_64" ]; then
    echo "==> Installing Neovim latest release to /opt/nvim-linux-x86_64..."
    NVIM_URL="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz"
    TEMP_DIR=$(mktemp -d)
    curl -fsSL "$NVIM_URL" -o "$TEMP_DIR/nvim.tar.gz"
    sudo tar -C /opt -xzf "$TEMP_DIR/nvim.tar.gz"
    rm -rf "$TEMP_DIR"
fi

# 6. Go Runtime (Dynamically resolves latest stable release with fallback)
if [ ! -d "$HOME/.local/go" ] && ! command -v go &>/dev/null; then
    GO_TAR=$(curl -fsSL "https://go.dev/VERSION?m=text" 2>/dev/null | head -n1 || echo "go1.23.6").linux-amd64.tar.gz
    echo "==> Installing ${GO_TAR} to ~/.local/go..."
    TEMP_DIR=$(mktemp -d)
    curl -fsSL "https://go.dev/dl/${GO_TAR}" -o "$TEMP_DIR/${GO_TAR}"
    mkdir -p "$HOME/.local"
    tar -C "$HOME/.local" -xzf "$TEMP_DIR/${GO_TAR}"
    rm -rf "$TEMP_DIR"
    mkdir -p "$HOME/go/bin" "$HOME/go/src" "$HOME/go/pkg"
fi

# 7. Parallel IDE Extension Installer (VS Code, Code Insiders & Cursor)
install_ide_extensions() {
    local bin_name="$1"
    local list_file="$2"
    if command -v "$bin_name" &>/dev/null && [ -f "$list_file" ]; then
        echo "==> Installing $bin_name extensions in parallel (4 workers)..."
        grep -vE '^\s*#|^\s*$' "$list_file" | xargs -r -n 1 -P 4 -I {} "$bin_name" --install-extension "{}" --force || true
    fi
}

install_ide_extensions "code" "$(dirname "$0")/../packages/vscode-extensions.list"
install_ide_extensions "code-insiders" "$(dirname "$0")/../packages/code-insiders-extensions.list"
install_ide_extensions "cursor" "$(dirname "$0")/../packages/cursor-extensions.list"

echo "==> Development runtimes setup complete!"
