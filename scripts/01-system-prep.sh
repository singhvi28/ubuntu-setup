#!/usr/bin/env bash
set -euo pipefail

echo "==> [1/9] System Preparation, Kernel/Sysctl Tuning & Power Optimization"

# 1. Update package database
sudo apt update

# 2. Install base essentials
sudo apt install -y curl wget git gpg ca-certificates software-properties-common apt-transport-https build-essential iw dmidecode

# 3. Memory Compression (zswap + zstd) & Sysctl Optimizations
echo "==> Configuring zswap RAM compression (zstd) & sysctl optimizations..."
sudo modprobe zstd || true
sudo mkdir -p /etc/modules-load.d
sudo cp "$(dirname "$0")/../configs/modules/zswap.conf" /etc/modules-load.d/zswap.conf

# Enable live zswap parameters if supported
if [ -d /sys/module/zswap/parameters ]; then
    echo zstd | sudo tee /sys/module/zswap/parameters/compressor 2>/dev/null || echo lzo | sudo tee /sys/module/zswap/parameters/compressor
    echo 60 | sudo tee /sys/module/zswap/parameters/max_pool_percent >/dev/null
    echo 1 | sudo tee /sys/module/zswap/parameters/enabled >/dev/null
fi

# Make zswap persistent via GRUB
sudo mkdir -p /etc/default/grub.d
sudo cp "$(dirname "$0")/../configs/grub/99-zswap.cfg" /etc/default/grub.d/99-zswap.cfg
if command -v update-grub >/dev/null 2>&1; then
    sudo update-grub
fi

# Apply sysctl optimizations (swappiness=80, page-cluster=0, vfs_cache_pressure=100, TTL=65)
sudo cp "$(dirname "$0")/../configs/sysctl/99-swappiness.conf" /etc/sysctl.d/99-swappiness.conf
sudo cp "$(dirname "$0")/../configs/sysctl/99-network-ttl.conf" /etc/sysctl.d/99-network-ttl.conf
sudo sysctl --system

# 4. Optional: auto-cpufreq (Battery & Thermal Optimization for Laptops)
read -p "Do you want to install auto-cpufreq for automatic CPU frequency/battery optimization? [y/N]: " -r INSTALL_AUTOCPU
if [[ "$INSTALL_AUTOCPU" =~ ^[Yy]$ ]]; then
    echo "==> Installing auto-cpufreq..."
    TEMP_DIR=$(mktemp -d)
    git clone https://github.com/AdnanHodzic/auto-cpufreq.git "$TEMP_DIR/auto-cpufreq"
    (cd "$TEMP_DIR/auto-cpufreq" && sudo ./auto-cpufreq-installer --install)
    rm -rf "$TEMP_DIR"
fi

# 5. Optional: Remove Snapd and install Flatpak
read -p "Do you want to completely remove snapd and configure Flatpak + Flathub? [y/N]: " -r REMOVE_SNAP
if [[ "$REMOVE_SNAP" =~ ^[Yy]$ ]]; then
    echo "==> Removing Snapd..."
    sudo snap list 2>/dev/null | awk 'NR>1 {print $1}' | while read -r snap_name; do
        sudo snap remove --purge "$snap_name" || true
    done
    sudo apt purge -y snapd gnome-software-plugin-snap || true
    sudo rm -rf /snap /var/snap /var/lib/snapd /var/cache/snapd /run/snapd ~/snap

    # Prevent snapd from re-installing
    sudo tee /etc/apt/preferences.d/nosnap.pref << 'PREF'
Package: snapd
Pin: release *
Pin-Priority: -10
PREF

    echo "==> Installing Flatpak and enabling Flathub..."
    sudo apt update
    sudo apt install -y flatpak gnome-software-plugin-flatpak
    sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
fi

echo "==> System preparation complete!"
