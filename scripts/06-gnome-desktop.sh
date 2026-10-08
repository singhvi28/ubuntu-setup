#!/usr/bin/env bash
set -euo pipefail

echo "==> [6/9] Configuring GNOME Desktop, Keybindings & Extensions"

# 1. Install Pop Shell Tiling Window Manager
echo "==> Installing Pop Shell Tiling Extension (Pop OS Shell for GNOME)..."
sudo apt install -y git node-typescript make gir1.2-gtk-3.0 python3-gi || true
TEMP_DIR=$(mktemp -d)
if git clone https://github.com/pop-os/shell.git "$TEMP_DIR/pop-shell"; then
    (cd "$TEMP_DIR/pop-shell" && make local-install) || true
fi
rm -rf "$TEMP_DIR"

# 2. Apply Dconf settings
DCONF_DIR="$(dirname "$0")/../configs/dconf"
if [ -f "$DCONF_DIR/gnome-all.dconf" ]; then
    echo "==> Restoring full GNOME dconf settings..."
    dconf load /org/gnome/ < "$DCONF_DIR/gnome-all.dconf"
fi

# 3. Ensure specific critical settings are enforced
echo "==> Enforcing key desktop shortcuts and behavior..."

# Enable fractional scaling support in Wayland/Mutter
gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer']"

# Window controls & shortcuts
gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close'
gsettings set org.gnome.desktop.wm.keybindings show-desktop "['<Super>m']"
gsettings set org.gnome.shell.keybindings show-screenshot-ui "['<Shift><Super>s']"

# Hibernate custom media key (<Shift><Super>h)
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name 'Hibernate'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command 'sudo systemctl hibernate'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding '<Shift><Super>h'

# Dock: Autohide, bottom position, compact
gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM'
gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed false
gsettings set org.gnome.shell.extensions.dash-to-dock extend-height false
gsettings set org.gnome.shell.extensions.dash-to-dock isolate-workspaces true

# Power & screen saver
gsettings set org.gnome.desktop.session idle-delay 0
gsettings set org.gnome.settings-daemon.plugins.power idle-dim false
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'nothing'

# 4. Enable GNOME extensions
echo "==> Enabling configured GNOME extensions..."
EXTENSIONS=(
    "ding@rastersoft.com"
    "ubuntu-dock@ubuntu.com"
    "tiling-assistant@ubuntu.com"
    "clipboard-indicator@tudmotu.com"
    "CoverflowAltTab@palatis.blogspot.com"
    "Vitals@CoreCoding.com"
    "just-another-search-bar@xelad0m"
    "caffeine@patapon.info"
    "display-brightness-ddcutil@themightydeity.github.com"
    "pop-shell@system76.com"
)

for ext in "${EXTENSIONS[@]}"; do
    gnome-extensions enable "$ext" 2>/dev/null || echo "Note: Extension $ext not yet active"
done

echo "==> GNOME desktop configuration complete!"
