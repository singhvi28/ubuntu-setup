#!/usr/bin/env bash
set -euo pipefail

echo "==> [7/9] Setting up rTorrent Systemd Service and Daemon"

# 1. Ensure directories exist
mkdir -p "$HOME/.rtorrent/session"
mkdir -p "$HOME/.rtorrent/watch"
mkdir -p "$HOME/.config/systemd/user"

# 2. Setup download directory
if [ ! -d "/data" ]; then
    echo "Note: /data directory does not exist. Creating ~/data as fallback..."
    mkdir -p "$HOME/data"
fi

# 3. Copy configuration file
echo "==> Copying .rtorrent.rc to ~/"
cp "$(dirname "$0")/../dotfiles/.rtorrent.rc" "$HOME/.rtorrent.rc"

# 4. Copy systemd user unit
echo "==> Installing systemd user unit: rtorrent.service"
cp "$(dirname "$0")/../dotfiles/.config/systemd/user/rtorrent.service" "$HOME/.config/systemd/user/rtorrent.service"

# 5. Reload and enable systemd user service
systemctl --user daemon-reload
systemctl --user enable rtorrent.service
systemctl --user restart rtorrent.service || true

echo "==> rTorrent background service is configured and enabled!"
