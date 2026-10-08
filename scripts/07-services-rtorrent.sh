#!/usr/bin/env bash
set -euo pipefail

echo "==> [7/9] Setting up Background Daemons, User Units & Service Optimizations"

# 1. Enable User Lingering (keeps user systemd services running without active graphical login)
echo "==> Enabling user lingering for $USER..."
sudo loginctl enable-linger "$USER" || true

# 2. Disable heavy database autostart on boot (saving ~2GB RAM, start on-demand)
echo "==> Disabling automatic boot startup for database services (start on-demand)..."
sudo systemctl disable postgresql mysql redis-server rabbitmq-server mongod 2>/dev/null || true

# 3. Setup rTorrent Directories & Config
echo "==> Configuring rTorrent directories and configuration..."
mkdir -p "$HOME/.rtorrent/session"
mkdir -p "$HOME/.rtorrent/watch"
mkdir -p "$HOME/.config/systemd/user"

if [ ! -d "/data" ]; then
    echo "Note: /data directory does not exist. Creating ~/data as fallback..."
    mkdir -p "$HOME/data"
fi

cp "$(dirname "$0")/../dotfiles/.rtorrent.rc" "$HOME/.rtorrent.rc"
cp "$(dirname "$0")/../dotfiles/.config/systemd/user/rtorrent.service" "$HOME/.config/systemd/user/rtorrent.service"

# 4. Setup Solve-Diff Streamlit Systemd Service
echo "==> Installing solve-diff.service (Competitive Programming Streamlit UI)..."
cp "$(dirname "$0")/../dotfiles/.config/systemd/user/solve-diff.service" "$HOME/.config/systemd/user/solve-diff.service"

# 5. Reload and Enable Systemd User Services
echo "==> Enabling and starting systemd user units..."
systemctl --user daemon-reload
systemctl --user enable rtorrent.service solve-diff.service
systemctl --user restart rtorrent.service solve-diff.service || true

echo "==> Background services and daemons successfully configured!"
