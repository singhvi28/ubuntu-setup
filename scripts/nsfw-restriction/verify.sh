#!/usr/bin/env bash
# ==============================================================================
# Script: verify.sh (NSFW Restrictions Status & Probe)
# Repository: https://github.com/singhvi28/ubuntu-setup
# Description: Verifies whether NSFW restrictions and anti-bypass protections
#              are active on this system. Can be run without root.
# ==============================================================================

echo "=========================================================="
echo " Checking NSFW Restriction Status & Anti-Bypass Defenses"
echo "=========================================================="

# 1. Check DNS configuration
echo -n "[1] Checking systemd-resolved DNS servers: "
if [ -f /etc/systemd/resolved.conf.d/nsfw-filter.conf ]; then
    echo "ACTIVE (Filter config present)"
    resolvectl status 2>/dev/null | grep -E 'DNS Servers|Current DNS Server' | head -n 4 || true
else
    echo "NOT CONFIGURED (Filter config missing)"
fi
echo ""

# 2. Check /etc/hosts entries
echo -n "[2] Checking /etc/hosts blocklist: "
if grep -q "BEGIN NSFW BLOCKLIST" /etc/hosts 2>/dev/null; then
    COUNT=$(grep -c '^0\.0\.0\.0 ' /etc/hosts 2>/dev/null || echo 0)
    echo "ACTIVE ($COUNT domains blocked locally)"
else
    echo "NOT PRESENT"
fi
echo ""

# 3. Check browser policies
echo "[3] Checking enterprise browser policies:"
check_file() {
    local path="$1"
    local name="$2"
    if [ -f "$path" ]; then
        echo "    - $name: ACTIVE ($path)"
    else
        echo "    - $name: NOT DEPLOYED"
    fi
}
check_file "/etc/opt/chrome/policies/managed/nsfw_restrictions.json" "Google Chrome"
check_file "/etc/chromium/policies/managed/nsfw_restrictions.json" "Chromium Base"
check_file "/etc/brave/policies/managed/nsfw_restrictions.json" "Brave Browser"
check_file "/etc/opt/edge/policies/managed/nsfw_restrictions.json" "Microsoft Edge"
check_file "/etc/vivaldi/policies/managed/nsfw_restrictions.json" "Vivaldi"
check_file "/etc/opera/policies/managed/nsfw_restrictions.json" "Opera"
check_file "/etc/firefox/policies/policies.json" "Firefox (System)"
check_file "/opt/firefox/distribution/policies.json" "Firefox (/opt)"
check_file "/etc/librewolf/policies/policies.json" "LibreWolf"
echo ""

# 4. Check firewall anti-bypass rules
echo -n "[4] Checking firewall anti-bypass chain (iptables): "
if iptables -L NSFW_RESTRICT -n &>/dev/null; then
    echo "ACTIVE (NSFW_RESTRICT chain is filtering)"
    RULE_COUNT=$(iptables -L NSFW_RESTRICT -n 2>/dev/null | wc -l || echo 0)
    echo "    $RULE_COUNT filtering rules loaded in kernel."
else
    echo "NOT ACTIVE (Run apply.sh with sudo to enable)"
fi
echo ""

# 5. Test resolution of sample adult domains
echo "[5] Testing domain resolution (local probe):"
TEST_DOMAINS=("pornhub.com" "xvideos.com" "redtube.com")
for d in "${TEST_DOMAINS[@]}"; do
    IP=$(getent ahosts "$d" 2>/dev/null | head -n 1 | awk '{print $1}')
    if [ "$IP" = "0.0.0.0" ] || [ -z "$IP" ]; then
        echo "    - $d -> BLOCKED ($IP)"
    else
        echo "    - $d -> RESOLVED to $IP (Filter not active or bypassed)"
    fi
done

echo "=========================================================="
