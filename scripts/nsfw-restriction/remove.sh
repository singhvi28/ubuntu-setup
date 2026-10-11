#!/usr/bin/env bash
# ==============================================================================
# Script: remove.sh (NSFW Restrictions Uninstaller)
# Repository: https://github.com/singhvi28/ubuntu-setup
# Description: Restores system settings, removes browser restrictions, tears down
#              firewall rules, and reverts /etc/hosts to its original state.
# ==============================================================================

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "[-] Error: This script must be run as root. Please run with sudo:"
    echo "    sudo bash $0"
    exit 1
fi

echo "=========================================================="
echo " Removing NSFW Restrictions and Restoring Defaults"
echo "=========================================================="

BACKUP_DIR="/etc/nsfw-restriction-backup"

# 1. Restore /etc/hosts
if [ -f "$BACKUP_DIR/hosts.orig" ]; then
    echo "[*] Step 1/4: Restoring original /etc/hosts..."
    cp -f "$BACKUP_DIR/hosts.orig" /etc/hosts
    chmod 644 /etc/hosts
    echo "    Restored /etc/hosts from backup."
else
    echo "[*] Step 1/4: Cleaning blocklist entries from /etc/hosts..."
    sed -i '/# BEGIN NSFW BLOCKLIST/,/# END NSFW BLOCKLIST/d' /etc/hosts || true
fi

# 2. Remove systemd-resolved drop-in configuration
RESOLVED_CONF="/etc/systemd/resolved.conf.d/nsfw-filter.conf"
echo "[*] Step 2/4: Removing systemd-resolved NSFW filter configuration..."
if [ -f "$RESOLVED_CONF" ]; then
    rm -f "$RESOLVED_CONF"
    if systemctl is-active --quiet systemd-resolved; then
        systemctl restart systemd-resolved
        echo "    systemd-resolved restarted to defaults."
    fi
fi

# 3. Remove browser policies across all browser families
echo "[*] Step 3/4: Removing browser enterprise policies..."
CHROMIUM_POLICY_FILES=(
    "/etc/opt/chrome/policies/managed/nsfw_restrictions.json"
    "/etc/chromium/policies/managed/nsfw_restrictions.json"
    "/etc/chromium-browser/policies/managed/nsfw_restrictions.json"
    "/etc/brave/policies/managed/nsfw_restrictions.json"
    "/etc/opt/edge/policies/managed/nsfw_restrictions.json"
    "/etc/vivaldi/policies/managed/nsfw_restrictions.json"
    "/etc/opera/policies/managed/nsfw_restrictions.json"
)
for file in "${CHROMIUM_POLICY_FILES[@]}"; do
    rm -f "$file"
done

FIREFOX_POLICY_FILES=(
    "/etc/firefox/policies/policies.json"
    "/opt/firefox/distribution/policies.json"
    "/usr/lib/firefox/distribution/policies.json"
    "/etc/librewolf/policies/policies.json"
    "/etc/waterfox/policies/policies.json"
)
for file in "${FIREFOX_POLICY_FILES[@]}"; do
    rm -f "$file"
done

# 4. Remove Firewall Rules and Service
echo "[*] Step 4/4: Disabling firewall anti-bypass rules..."
if systemctl is-enabled nsfw-restriction-firewall.service &>/dev/null; then
    systemctl stop nsfw-restriction-firewall.service || true
    systemctl disable nsfw-restriction-firewall.service || true
fi
rm -f /etc/systemd/system/nsfw-restriction-firewall.service
systemctl daemon-reload || true

# Explicit chain cleanup
iptables -D OUTPUT -j NSFW_RESTRICT 2>/dev/null || true
iptables -F NSFW_RESTRICT 2>/dev/null || true
iptables -X NSFW_RESTRICT 2>/dev/null || true

if command -v ip6tables &>/dev/null; then
    ip6tables -D OUTPUT -j NSFW_RESTRICT 2>/dev/null || true
    ip6tables -F NSFW_RESTRICT 2>/dev/null || true
    ip6tables -X NSFW_RESTRICT 2>/dev/null || true
fi

# 5. Flush caches
if command -v resolvectl &>/dev/null; then
    resolvectl flush-caches || true
fi

echo "=========================================================="
echo " [✓] NSFW restrictions successfully removed!"
echo " Restart your browsers for default behavior to resume."
echo "=========================================================="
