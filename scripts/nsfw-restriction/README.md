# NSFW Restrictions & Anti-Bypass Defenses

Comprehensive system-wide NSFW content filtering and tamper-resistant anti-bypass protection for Ubuntu 24.04 LTS.

---

## Features

1. **CleanBrowsing & Cloudflare Family DNS (`systemd-resolved`):**
   - Routes all system DNS requests through CleanBrowsing Family (`185.228.168.168`) and Cloudflare Family (`1.1.1.3`).
   - Automatically forces SafeSearch on Google, Bing, DuckDuckGo, and YouTube at the resolver level.
   - Wildcard routing (`Domains=~.`) prevents interface-level DHCP override.

2. **Enterprise Browser Policies:**
   - Pre-staged for **Chrome, Chromium, Brave, Microsoft Edge, Vivaldi, Opera, Firefox, LibreWolf, and Waterfox**.
   - Locks DNS-over-HTTPS (DoH) to **OFF** so browsers cannot bypass local/system DNS.
   - Forces Google SafeSearch and YouTube Restricted Mode ON.

3. **StevenBlack Curated Blocklist (`/etc/hosts`):**
   - 140,000+ adult domains redirected locally to `0.0.0.0`.
   - Works offline with zero latency across all local processes.
   - Retains system hostname and Docker mappings intact.

4. **Kernel Firewall Anti-Bypass (`iptables`):**
   - Blocks rogue outbound Port 53 queries to unapproved DNS servers.
   - Rejects public unfiltered DoH IPs (`1.1.1.1`, `8.8.8.8`, `9.9.9.9`, etc.) so portable browsers (like AppImages) fail over immediately to the filtered system DNS.
   - Persistent across reboots via `nsfw-restriction-firewall.service`.

---

## Usage

### Apply Restrictions
```bash
sudo ./apply.sh
```

### Verify Status
```bash
./verify.sh
```

### Remove / Restore Defaults
```bash
sudo ./remove.sh
```
