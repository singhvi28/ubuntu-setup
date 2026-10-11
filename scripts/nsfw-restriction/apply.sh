#!/usr/bin/env bash
# ==============================================================================
# Script: apply.sh (NSFW Restrictions Installer)
# Repository: https://github.com/singhvi28/ubuntu-setup
# Description: Configures system-wide NSFW restrictions and anti-bypass defenses.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIGS_DIR="$(cd "$SCRIPT_DIR/../../configs/nsfw-restriction" && pwd)"

if [ "$EUID" -ne 0 ]; then
    echo "[-] Error: This script must be run as root. Please run with sudo:"
    echo "    sudo bash $0"
    exit 1
fi

echo "=========================================================="
echo " Starting Hardened NSFW Website Restriction Setup"
echo "=========================================================="

BACKUP_DIR="/etc/nsfw-restriction-backup"
mkdir -p "$BACKUP_DIR"

# ------------------------------------------------------------------------------
# 1. Back up original files
# ------------------------------------------------------------------------------
echo "[*] Step 1/5: Backing up current configuration..."
if [ ! -f "$BACKUP_DIR/hosts.orig" ]; then
    cp -p /etc/hosts "$BACKUP_DIR/hosts.orig"
    echo "    Saved /etc/hosts backup to $BACKUP_DIR/hosts.orig"
fi

# ------------------------------------------------------------------------------
# 2. Configure System-Wide Family Filtering DNS (systemd-resolved)
# ------------------------------------------------------------------------------
echo "[*] Step 2/5: Configuring system-wide Family DNS filter..."
RESOLVED_CONF_DIR="/etc/systemd/resolved.conf.d"
mkdir -p "$RESOLVED_CONF_DIR"

if [ -f "$CONFIGS_DIR/nsfw-filter.conf" ]; then
    cp "$CONFIGS_DIR/nsfw-filter.conf" "$RESOLVED_CONF_DIR/nsfw-filter.conf"
else
    cat << 'EOF' > "$RESOLVED_CONF_DIR/nsfw-filter.conf"
[Resolve]
DNS=185.228.168.168#family-filter-dns.cleanbrowsing.org 185.228.169.168#family-filter-dns.cleanbrowsing.org 1.1.1.3#family.cloudflare-dns.com 1.0.0.3#family.cloudflare-dns.com 2a0d:5600:33:4::#family-filter-dns.cleanbrowsing.org 2a0d:5600:54:4::#family-filter-dns.cleanbrowsing.org 2606:4700:4700::1113#family.cloudflare-dns.com 2606:4700:4700::1003#family.cloudflare-dns.com
FallbackDNS=185.228.168.168 1.1.1.3
Domains=~.
DNSOverTLS=opportunistic
EOF
fi

if systemctl is-active --quiet systemd-resolved; then
    systemctl restart systemd-resolved
    echo "    systemd-resolved restarted with Family DNS."
else
    echo "    systemd-resolved is not active; skipping service restart."
fi

# ------------------------------------------------------------------------------
# 3. Configure Enterprise Policies for ALL Browsers
# ------------------------------------------------------------------------------
echo "[*] Step 3/5: Deploying enterprise policies across all browser families..."

CHROMIUM_POLICY_SOURCE="$CONFIGS_DIR/chromium-policy.json"
CHROMIUM_POLICY_DIRS=(
    "/etc/opt/chrome/policies/managed"
    "/etc/chromium/policies/managed"
    "/etc/chromium-browser/policies/managed"
    "/etc/brave/policies/managed"
    "/etc/opt/edge/policies/managed"
    "/etc/vivaldi/policies/managed"
    "/etc/opera/policies/managed"
)

for dir in "${CHROMIUM_POLICY_DIRS[@]}"; do
    mkdir -p "$dir"
    cp "$CHROMIUM_POLICY_SOURCE" "$dir/nsfw_restrictions.json"
done
echo "    Applied policies to Chromium family: Chrome, Chromium, Brave, Edge, Vivaldi, Opera."

FIREFOX_POLICY_SOURCE="$CONFIGS_DIR/firefox-policy.json"
FIREFOX_POLICY_DIRS=(
    "/etc/firefox/policies"
    "/opt/firefox/distribution"
    "/usr/lib/firefox/distribution"
    "/etc/librewolf/policies"
    "/etc/waterfox/policies"
)

for dir in "${FIREFOX_POLICY_DIRS[@]}"; do
    mkdir -p "$dir"
    cp "$FIREFOX_POLICY_SOURCE" "$dir/policies.json"
done
echo "    Applied policies to Firefox family: Firefox, LibreWolf, Waterfox."

# ------------------------------------------------------------------------------
# 4. Install /etc/hosts Adult Blocklist (StevenBlack Porn Extension)
# ------------------------------------------------------------------------------
echo "[*] Step 4/5: Downloading and installing offline domain blocklist..."
TEMP_HOSTS=$(mktemp)

echo "    Downloading StevenBlack adult domains list..."
if curl -fsSL --connect-timeout 15 "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/porn/hosts" -o "$TEMP_HOSTS"; then
    TEMP_MERGED=$(mktemp)

    # Copy the clean original base hosts first (preserving local hostname & docker)
    cat "$BACKUP_DIR/hosts.orig" > "$TEMP_MERGED"
    echo "" >> "$TEMP_MERGED"
    echo "# ==============================================================" >> "$TEMP_MERGED"
    echo "# BEGIN NSFW BLOCKLIST - Managed by nsfw-restriction script" >> "$TEMP_MERGED"
    echo "# Updated on: $(date -u)" >> "$TEMP_MERGED"
    echo "# ==============================================================" >> "$TEMP_MERGED"

    # Append only domain entries starting with 0.0.0.0 (skipping 0.0.0.0 0.0.0.0)
    grep -E '^0\.0\.0\.0[[:space:]]+[^0]' "$TEMP_HOSTS" >> "$TEMP_MERGED"

    echo "# ==============================================================" >> "$TEMP_MERGED"
    echo "# END NSFW BLOCKLIST" >> "$TEMP_MERGED"
    echo "# ==============================================================" >> "$TEMP_MERGED"

    # Atomically replace /etc/hosts
    chmod 644 "$TEMP_MERGED"
    cp -f "$TEMP_MERGED" /etc/hosts
    rm -f "$TEMP_HOSTS" "$TEMP_MERGED"

    BLOCK_COUNT=$(grep -c '^0\.0\.0\.0 ' /etc/hosts || true)
    echo "    Successfully loaded $BLOCK_COUNT adult domains into /etc/hosts."
else
    echo "    [!] Warning: Failed to download hosts list. DNS filtering, firewall, and policies are active."
    rm -f "$TEMP_HOSTS"
fi

# ------------------------------------------------------------------------------
# 5. Configure Kernel Firewall (iptables) to prevent DoH bypass & DNS leakage
# ------------------------------------------------------------------------------
echo "[*] Step 5/5: Installing kernel firewall anti-bypass rules..."

FW_SCRIPT="/etc/nsfw-restriction-backup/apply_firewall.sh"
cat << 'EOF' > "$FW_SCRIPT"
#!/usr/bin/env bash
set -euo pipefail

# 1. Setup IPv4 chain
iptables -N NSFW_RESTRICT 2>/dev/null || iptables -F NSFW_RESTRICT

# Allow port 53 to trusted family DNS and local resolver
iptables -A NSFW_RESTRICT -p udp --dport 53 -d 185.228.168.168 -j ACCEPT
iptables -A NSFW_RESTRICT -p udp --dport 53 -d 185.228.169.168 -j ACCEPT
iptables -A NSFW_RESTRICT -p udp --dport 53 -d 1.1.1.3 -j ACCEPT
iptables -A NSFW_RESTRICT -p udp --dport 53 -d 1.0.0.3 -j ACCEPT
iptables -A NSFW_RESTRICT -p udp --dport 53 -d 127.0.0.1 -j ACCEPT
iptables -A NSFW_RESTRICT -p udp --dport 53 -d 127.0.0.53 -j ACCEPT
iptables -A NSFW_RESTRICT -p tcp --dport 53 -d 185.228.168.168 -j ACCEPT
iptables -A NSFW_RESTRICT -p tcp --dport 53 -d 185.228.169.168 -j ACCEPT
iptables -A NSFW_RESTRICT -p tcp --dport 53 -d 1.1.1.3 -j ACCEPT
iptables -A NSFW_RESTRICT -p tcp --dport 53 -d 1.0.0.3 -j ACCEPT
iptables -A NSFW_RESTRICT -p tcp --dport 53 -d 127.0.0.1 -j ACCEPT
iptables -A NSFW_RESTRICT -p tcp --dport 53 -d 127.0.0.53 -j ACCEPT

# Block arbitrary outbound DNS queries (stops rogue DNS bypasses)
iptables -A NSFW_RESTRICT -p udp --dport 53 -j REJECT --reject-with icmp-port-unreachable
iptables -A NSFW_RESTRICT -p tcp --dport 53 -j REJECT --reject-with tcp-reset

# Block well-known public unfiltered DoH/DoT endpoints
# (Forces any unmanaged browser attempting DoH to fail over immediately to system DNS)
UNMANAGED_DOH_IPS=(
    "1.1.1.1" "1.0.0.1"
    "8.8.8.8" "8.8.4.4"
    "9.9.9.9" "149.112.112.112"
    "208.67.222.222" "208.67.220.220"
)
for ip in "${UNMANAGED_DOH_IPS[@]}"; do
    iptables -A NSFW_RESTRICT -d "$ip" -j REJECT --reject-with icmp-port-unreachable
done

# Jump to chain if not already hooked
iptables -C OUTPUT -j NSFW_RESTRICT 2>/dev/null || iptables -I OUTPUT 1 -j NSFW_RESTRICT

# 2. Setup IPv6 chain (if supported)
if command -v ip6tables &>/dev/null; then
    ip6tables -N NSFW_RESTRICT 2>/dev/null || ip6tables -F NSFW_RESTRICT
    ip6tables -A NSFW_RESTRICT -p udp --dport 53 -d 2a0d:5600:33:4:: -j ACCEPT
    ip6tables -A NSFW_RESTRICT -p udp --dport 53 -d 2a0d:5600:54:4:: -j ACCEPT
    ip6tables -A NSFW_RESTRICT -p udp --dport 53 -d 2606:4700:4700::1113 -j ACCEPT
    ip6tables -A NSFW_RESTRICT -p udp --dport 53 -d 2606:4700:4700::1003 -j ACCEPT
    ip6tables -A NSFW_RESTRICT -p udp --dport 53 -d ::1 -j ACCEPT
    ip6tables -A NSFW_RESTRICT -p tcp --dport 53 -d 2a0d:5600:33:4:: -j ACCEPT
    ip6tables -A NSFW_RESTRICT -p tcp --dport 53 -d 2a0d:5600:54:4:: -j ACCEPT
    ip6tables -A NSFW_RESTRICT -p tcp --dport 53 -d 2606:4700:4700::1113 -j ACCEPT
    ip6tables -A NSFW_RESTRICT -p tcp --dport 53 -d 2606:4700:4700::1003 -j ACCEPT
    ip6tables -A NSFW_RESTRICT -p tcp --dport 53 -d ::1 -j ACCEPT
    ip6tables -A NSFW_RESTRICT -p udp --dport 53 -j REJECT
    ip6tables -A NSFW_RESTRICT -p tcp --dport 53 -j REJECT

    UNMANAGED_DOH_IPV6=(
        "2606:4700:4700::1111" "2606:4700:4700::1001"
        "2001:4860:4860::8888" "2001:4860:4860::8844"
    )
    for ip6 in "${UNMANAGED_DOH_IPV6[@]}"; do
        ip6tables -A NSFW_RESTRICT -d "$ip6" -j REJECT 2>/dev/null || true
    done
    ip6tables -C OUTPUT -j NSFW_RESTRICT 2>/dev/null || ip6tables -I OUTPUT 1 -j NSFW_RESTRICT
fi
EOF

chmod +x "$FW_SCRIPT"
bash "$FW_SCRIPT"

# Install systemd service for persistent firewall rules across reboots
SERVICE_FILE="/etc/systemd/system/nsfw-restriction-firewall.service"
cat << EOF > "$SERVICE_FILE"
[Unit]
Description=NSFW Restriction Firewall Anti-Bypass Rules
After=network.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=$FW_SCRIPT
ExecStop=/bin/bash -c "iptables -D OUTPUT -j NSFW_RESTRICT 2>/dev/null || true; iptables -F NSFW_RESTRICT 2>/dev/null || true; iptables -X NSFW_RESTRICT 2>/dev/null || true; ip6tables -D OUTPUT -j NSFW_RESTRICT 2>/dev/null || true; ip6tables -F NSFW_RESTRICT 2>/dev/null || true; ip6tables -X NSFW_RESTRICT 2>/dev/null || true"

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable nsfw-restriction-firewall.service
echo "    Firewall rules active and enabled across reboots."

# Flush DNS caches
if command -v resolvectl &>/dev/null; then
    resolvectl flush-caches || true
fi

echo "=========================================================="
echo " [✓] Hardened restriction setup complete!"
echo " Any existing or newly downloaded browser is now restricted."
echo " Restart your browser(s) for policies to apply immediately."
echo "=========================================================="
