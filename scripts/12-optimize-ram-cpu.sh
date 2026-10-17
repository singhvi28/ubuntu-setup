#!/usr/bin/env bash
# ==============================================================================
# 12-optimize-ram-cpu.sh (MAX-CPU / AGGRESSIVE EDITION - SANDBOX SAFE)
#
# Trades background CPU cycles (AMD Ryzen 7 5800U 16-thread) for maximum RAM
# savings using:
#   1. Ultra-aggressive zswap (zstd, 60% pool, swappiness=180, page-cluster=0)
#   2. Turbo KSM (Kernel Samepage Merging: 90% max CPU advisor, 15ms scan, zero-pages)
#   3. Sandbox-Safe Universal KSM activation:
#      - Uses Linux 6.7+ prctl(PR_SET_MEMORY_MERGE, 1) inherited from parent
#        processes (systemd --user, gnome-shell, login shells) instead of
#        global LD_PRELOAD or attaching gdb to seccomp-sandboxed Chromium/Brave
#        renderer/extension child processes.
#   4. Active Cgroup v2 Cold-Page Compressor Daemon (cpu-ram-reclaimer.service):
#      - Continuously ages and zstd-compresses idle anonymous pages from
#        user.slice and system.slice into zswap BEFORE memory pressure hits.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME="$(getent passwd "$REAL_USER" | cut -d: -f6)"

echo "==> [12/12] Optimizing RAM with CPU (zswap zstd 60%, KSM deduplication & Cgroup Reclaimer)"
echo "============================================================"
echo " BEFORE OPTIMIZATION: Memory & Compression Status"
echo "============================================================"
free -h
grep -E "Zswap:|Zswapped:" /proc/meminfo || true
echo "KSM pages_sharing (4K pages deduplicated): $(cat /sys/kernel/mm/ksm/pages_sharing 2>/dev/null || echo 0)"
echo ""

# ------------------------------------------------------------------------------
# 1. Aggressive Kernel VM Sysctls (/etc/sysctl.d/99-zswap-tradeoff.conf)
# ------------------------------------------------------------------------------
echo "[1/6] Applying aggressive VM sysctl parameters (swappiness=180, compaction=80)..."
sudo cp "$REPO_DIR/configs/sysctl/99-swappiness.conf" /etc/sysctl.d/99-zswap-tradeoff.conf
sudo rm -f /etc/sysctl.d/99-swappiness.conf
sudo sysctl --system >/dev/null

# ------------------------------------------------------------------------------
# 2. Turbo zswap + KSM + MGLRU (/etc/tmpfiles.d/memory-cpu-tradeoff.conf)
# ------------------------------------------------------------------------------
echo "[2/6] Configuring Turbo zswap (60% pool, zstd) & KSM (90% max CPU, 15ms scan)..."
sudo modprobe zstd 2>/dev/null || true
sudo mkdir -p /etc/tmpfiles.d /etc/modules-load.d /etc/default/grub.d
sudo cp "$REPO_DIR/configs/modules/zswap.conf" /etc/modules-load.d/zswap.conf
sudo cp "$REPO_DIR/configs/grub/99-zswap.cfg" /etc/default/grub.d/99-zswap.cfg
sudo cp "$REPO_DIR/configs/tmpfiles.d/memory-cpu-tradeoff.conf" /etc/tmpfiles.d/memory-cpu-tradeoff.conf
sudo systemd-tmpfiles --create /etc/tmpfiles.d/memory-cpu-tradeoff.conf

# ------------------------------------------------------------------------------
# 3. Sandbox-Safe KSM Inheritance (PR_SET_MEMORY_MERGE = 67)
# ------------------------------------------------------------------------------
echo "[3/6] Configuring sandbox-safe KSM inheritance (no LD_PRELOAD seccomp conflicts)..."
rm -f "$REAL_HOME/.config/environment.d/99-ksm-auto.conf"
dbus-update-activation-environment --systemd LD_PRELOAD="" 2>/dev/null || true

sudo tee /etc/profile.d/ksm-auto-merge.sh >/dev/null << 'EOF'
# Enable Linux 6.7+ process-wide KSM memory deduplication (inherited by all child processes)
python3 -c "import ctypes; ctypes.CDLL(None).prctl(67, 1, 0, 0, 0)" 2>/dev/null || true
EOF
sudo chmod 644 /etc/profile.d/ksm-auto-merge.sh

if [[ -f "$REAL_HOME/.bashrc" ]] && ! grep -q "PR_SET_MEMORY_MERGE" "$REAL_HOME/.bashrc"; then
    cat << 'EOF' >> "$REAL_HOME/.bashrc"

# Enable KSM memory deduplication for this shell and all child processes (PR_SET_MEMORY_MERGE=67)
python3 -c "import ctypes; ctypes.CDLL(None).prctl(67, 1, 0, 0, 0)" 2>/dev/null || true
EOF
    chown "$REAL_USER:$REAL_USER" "$REAL_HOME/.bashrc"
fi

# ------------------------------------------------------------------------------
# 4. Sandbox-Safe Live KSM Enrollment for Running Processes
#    Skips any process with Seccomp != 0 or Chromium/Electron --type= flags
# ------------------------------------------------------------------------------
echo "[4/6] Safely enrolling non-seccomp parent processes into KSM deduplication..."
ENROLLED=0
SKIPPED_SECCOMP=0
if command -v gdb >/dev/null 2>&1; then
    for pid in $(pgrep -u "$REAL_USER" -f "systemd|gnome-shell|brave|antigravity|language_server|agy|node|python|evince|nautilus|bash" || true); do
        if [[ "$pid" == "$$" || "$pid" == "$PPID" ]]; then
            continue
        fi
        SECCOMP_MODE=$(awk '/^Seccomp:/ {print $2}' "/proc/$pid/status" 2>/dev/null || echo "2")
        if [[ "$SECCOMP_MODE" != "0" ]]; then
            ((SKIPPED_SECCOMP+=1))
            continue
        fi
        CMDLINE=$(tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null || true)
        if [[ "$CMDLINE" == *"--type="* ]]; then
            ((SKIPPED_SECCOMP+=1))
            continue
        fi
        MERGING_PAGES=$(sudo cat "/proc/$pid/ksm_merging_pages" 2>/dev/null || echo 0)
        if [[ "$MERGING_PAGES" -gt 0 ]]; then
            ((ENROLLED+=1))
            continue
        fi
        sudo gdb -n -q -batch \
            -ex "attach $pid" \
            -ex "call (int)prctl(67, 1, 0, 0, 0)" \
            -ex "detach" \
            -ex "quit" >/dev/null 2>&1 && ((ENROLLED+=1)) || true
    done
fi
echo "      Safely enrolled $ENROLLED parent/app processes (skipped $SKIPPED_SECCOMP seccomp-sandboxed child processes)."

# ------------------------------------------------------------------------------
# 5. Create & Start Active Cgroup v2 Cold-Page Compressor Daemon
# ------------------------------------------------------------------------------
echo "[5/6] Installing & starting cpu-ram-reclaimer.service background daemon..."
sudo tee /usr/local/bin/cpu-ram-reclaimer.sh >/dev/null << 'EOF'
#!/usr/bin/env bash
# Continuously trades idle CPU cycles to compress cold anonymous memory into zswap
# using Linux cgroup v2 memory.reclaim (swappiness=200 hints anonymous-first reclaim).

while true; do
    if [[ -w /sys/fs/cgroup/user.slice/memory.reclaim ]]; then
        echo "32M swappiness=200" > /sys/fs/cgroup/user.slice/memory.reclaim 2>/dev/null || \
        echo "32M" > /sys/fs/cgroup/user.slice/memory.reclaim 2>/dev/null || true
    fi
    if [[ -w /sys/fs/cgroup/system.slice/memory.reclaim ]]; then
        echo "8M swappiness=200" > /sys/fs/cgroup/system.slice/memory.reclaim 2>/dev/null || \
        echo "8M" > /sys/fs/cgroup/system.slice/memory.reclaim 2>/dev/null || true
    fi
    sleep 12
done
EOF
sudo chmod 755 /usr/local/bin/cpu-ram-reclaimer.sh

sudo cp "$REPO_DIR/configs/systemd/cpu-ram-reclaimer.service" /etc/systemd/system/cpu-ram-reclaimer.service
sudo systemctl daemon-reload
sudo systemctl enable --now cpu-ram-reclaimer.service

# ------------------------------------------------------------------------------
# 6. Summary & Live Verification
# ------------------------------------------------------------------------------
echo "[6/6] Verifying active configuration..."
echo ""
echo "============================================================"
echo " AFTER OPTIMIZATION: Memory & Compression Status"
echo "============================================================"
free -h
echo ""
echo "--- Active zswap Status ---"
grep -E "Zswap:|Zswapped:|SwapCached:" /proc/meminfo || true
awk '
  /Zswap:/ { zswap=$2 }
  /Zswapped:/ { zswapped=$2 }
  END {
    if (zswap > 0) {
      printf "zswap Ratio: %.2fx (%.1f MiB compressed into %.1f MiB RAM -> SAVED %.1f MiB)\n",
             zswapped/zswap, zswapped/1024, zswap/1024, (zswapped-zswap)/1024
    }
  }
' /proc/meminfo

echo ""
echo "--- Active KSM (Kernel Samepage Merging) Status ---"
SHARED=$(cat /sys/kernel/mm/ksm/pages_shared)
SHARING=$(cat /sys/kernel/mm/ksm/pages_sharing)
ZERO_PAGES=$(cat /sys/kernel/mm/ksm/ksm_zero_pages)
SAVED_KSM_MIB=$(( (SHARING + ZERO_PAGES) * 4 / 1024 ))
echo "KSM pages_shared     : $SHARED"
echo "KSM pages_sharing    : $SHARING (duplicate 4K pages merged)"
echo "KSM ksm_zero_pages   : $ZERO_PAGES (zero 4K pages merged)"
echo "KSM RAM Saved so far : ~${SAVED_KSM_MIB} MiB"
echo "============================================================"
echo "Done! Sandbox-safe KSM + zswap compression active."
