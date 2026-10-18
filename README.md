# 🐧 Ubuntu 24.04 LTS (Noble Numbat) Custom Setup & Dotfiles

> Fully automated, modular, and reproducible setup suite for an Ubuntu 24.04 LTS workstation. Recreates packages, PPAs, kernel optimizations, GNOME customizations, dev runtimes, local AI engines, databases, background services, and dotfiles.

[![OS](https://img.shields.io/badge/OS-Ubuntu%2024.04%20LTS-E95420?logo=ubuntu&logoColor=white)](https://ubuntu.com/)
[![Shell](https://img.shields.io/badge/Shell-Bash-4EAA25?logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Editor](https://img.shields.io/badge/Neovim-0.10+-57A143?logo=neovim&logoColor=white)](https://neovim.io/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## ⚡ Quickstart

On a fresh Ubuntu 24.04 installation, run:

```bash
# 1. Clone this repository
git clone https://github.com/singhvi28/ubuntu-setup.git ~/ubuntu-setup
cd ~/ubuntu-setup

# 2. Run the interactive bootstrap installer
./bootstrap.sh

# Or run non-interactively for full installation:
./bootstrap.sh --all
```

---

## 📋 Table of Contents
- [System Architecture & Profile](#-system-architecture--profile)
- [Key Customizations Overview](#-key-customizations-overview)
  - [1. System & Kernel Optimizations](#1-system--kernel-optimizations)
  - [2. Snap Removal & Flatpak Setup](#2-snap-removal--flatpak-setup)
  - [3. External Repositories & GPG Keys](#3-external-repositories--gpg-keys)
  - [4. Development Stacks & Toolchains](#4-development-stacks--toolchains)
  - [5. Local AI & LLM Inference (Ollama)](#5-local-ai--llm-inference-ollama)
  - [6. Databases & Memory Footprint Optimization](#6-databases--memory-footprint-optimization)
  - [7. GNOME Desktop, Pop Shell Tiling & Extensions](#7-gnome-desktop-pop-shell-tiling--extensions)
  - [8. Biometric Facial Authentication (Howdy)](#8-biometric-facial-authentication-howdy)
  - [9. Background Daemons & Services (`rtorrent`, `solve-diff`)](#9-background-daemons--services-rtorrent-solve-diff)
  - [10. Custom Scripts & Binaries](#10-custom-scripts--binaries)
  - [11. NSFW Website Restrictions & Anti-Bypass Defenses](#11-nsfw-website-restrictions--anti-bypass-defenses)
  - [12. Browser Extensions & Custom Settings](#12-browser-extensions--custom-settings)
- [Repository Structure](#-repository-structure)
- [Step-by-Step Manual Guide](#-step-by-step-manual-guide)
- [Post-Install Checklist](#-post-install-checklist)

---

## 🖥 System Architecture & Profile

- **Base OS**: Ubuntu 24.04.5 LTS (Noble Numbat, 64-bit)
- **Primary Hardware**: Lenovo IdeaPad (AMD Ryzen 7 5800U, Radeon Vega Graphics, 16GB RAM)
- **Partitioning / Storage Setup**:
  - `/` (Root Ext4 on NVMe)
  - `/data` (Dedicated user storage partition mounted at `/data`)
  - Swap file located at `/data/swap.img`
  - GTK Bookmarks configured with direct link to `file:///data`

---

## 🎯 Key Customizations Overview

### 1. System & Kernel Optimizations
- **Memory-CPU Tradeoff & Zswap In-RAM Compression** (`/etc/sysctl.d/99-swappiness.conf`, `/etc/default/grub.d/99-zswap.cfg`):
  - **Zswap + Zstd (60% Pool, 95% Threshold)**: In-kernel memory compression intercepts swap pages and compresses them into a 60% in-RAM pool using the 16-thread Ryzen CPU (~3.5:1 ratio), effectively expanding working memory while avoiding slow disk paging.
  - `vm.swappiness = 80`: Proactively moves idle anonymous memory pages into the compressed RAM pool using CPU rather than dropping filesystem caches.
  - `vm.page-cluster = 0`: Decompresses single 4KB pages on fault for sub-millisecond RAM response times without read-ahead stalls.
  - `vm.vfs_cache_pressure = 100`: Reclaims filesystem directory and inode caches at a healthy rate.
- **Network TTL Modification** (`/etc/sysctl.d/99-network-ttl.conf`):
  - `net.ipv4.ip_default_ttl = 65` and `net.ipv6.conf.all.hop_limit = 65` (optimizes packet forwarding and hotspot/tethering throughput).
- **Wayland Fractional Scaling**:
  - `scale-monitor-framebuffer` enabled in Mutter for crisp HiDPI fractional display scaling.
- **Power & Thermal Management**:
  - `auto-cpufreq` installer integrated for optimizing CPU frequency and battery efficiency on AMD Ryzen laptops.

### 2. Snap Removal & Flatpak Setup
Canonical's `snapd` is completely removed for reduced overhead, faster app launch times, and native deb/flatpak consistency:
- APT pinning (`/etc/apt/preferences.d/nosnap.pref`) locks out `snapd`.
- Flatpak + Flathub configured as the primary sandbox app provider:
  - **Firefox**: `org.mozilla.firefox`
  - **Motrix**: `net.agalwood.Motrix` (Full-featured download manager)
  - **LocalSend**: `org.localsend.localsend_app` (AirDrop alternative for local network sharing)
  - **Bottles**: `com.usebottles.bottles` (Wine environment manager)

### 3. External Repositories & GPG Keys
The following official upstream repositories and PPAs are configured with modern GPG keyrings:
- **Google Chrome**: Official Google Linux repository
- **Brave Browser**: Official Brave Release repository
- **Microsoft Edge & VS Code**: Official Microsoft Linux repository
- **NodeSource**: Node.js 20.x LTS repository
- **Docker CE**: Official Docker engine repository
- **MongoDB 7.0**: Official MongoDB Ubuntu repository
- **WineHQ**: Official WineHQ Noble repository (with `i386` multiarch support)
- **OBS Studio PPA**: `ppa:obsproject/obs-studio`
- **Howdy PPA**: `ppa:ubuntuhandbook1/howdy`
- **Librewolf**: Managed cleanly via `extrepo`

### 4. Development Stacks & Toolchains
- **C/C++**: `gcc`, `g++`, `gdb`, `clangd`, `cmake`, `ninja-build`, `make`
- **Python**:
  - [Astral `uv`](https://github.com/astral-sh/uv) (ultra-fast pip/venv replacement in `~/.local/bin/uv`)
  - `pipx` for isolated CLI tools (`yt-dlp`)
  - Full scientific/ML & Agentic stack: NumPy, Pandas, Scikit-learn, Matplotlib, Seaborn, PyTorch, LiteLLM, Langfuse, OpenCV
  - Web & API stack: FastAPI, Uvicorn, Streamlit, Playwright, Selenium, BeautifulSoup4
- **Node.js & JavaScript**:
  - Node 20 LTS via NodeSource
  - User-level NPM global prefix configured at `~/.npm-global` (prevents needing `sudo` for npm global installs)
  - Global CLI tools: `mudslide` (WhatsApp CLI)
- **Go**:
  - Go runtime configured in `~/.local/go` and GOPATH at `~/go`
  - `whatscli` installed in `~/go/bin`
- **Editors & IDEs**:
  - **Neovim** (in `/opt/nvim-linux-x86_64`): Configured with `lazy.nvim`, `mason.nvim`, `mason-lspconfig` (auto-managing `basedpyright`), and high-performance `blink.cmp` autocompletion.
  - **VS Code & Cursor**: Configured with custom `settings.json`, `keybindings.json` (`Ctrl+F5` debug run), and full extension suite.
  - **Qoder** & **DBeaver CE** database management.

### 5. Local AI & LLM Inference (Ollama)
- **Ollama Engine**: Local LLM runner installed as an active systemd service (`ollama.service`).
- Enables CPU + Vulkan GPU acceleration for fast local code assistance and small parameter models (e.g. `qwen2.5-coder:7b`, `deepseek-r1:8b`).

### 6. Databases & Memory Footprint Optimization
Native local database engines are installed:
- **PostgreSQL 16**, **MySQL Server**, **Redis Server**, **RabbitMQ**, **MongoDB 7.0**, **Docker Engine**.
- **On-Demand Daemons**: Automatic boot startup for all database services is disabled (`systemctl disable`). Databases run **on-demand**, freeing up ~2GB of RAM on startup.
- **Node.js Heap Optimization**: `export NODE_OPTIONS="--max-old-space-size=2048"` in `.bashrc_custom` forces V8/Node runtimes to run compacting garbage collection earlier instead of ballooning up to 4+ GB of RAM.
- **IDE RAM Capping (VS Code / Insiders / Cursor)**: `typescript.tsserver.maxTsServerMemory` capped at 1024MB, symlink following disabled during search, and heavy build directories (`node_modules`, `build`, `dist`, `.venv`, `.git/objects`) excluded from the file-system watcher daemon.
- **Browser Memory Saver**: Brave configured with aggressive tab discarding and hardware rasterization offloading.

### 7. GNOME Desktop, Pop Shell Tiling & Extensions
- **Pop Shell Tiling Window Manager** (`pop-shell@system76.com`):
  - i3/sway-style automatic tiling directly in Ubuntu GNOME for multi-window developer productivity.
- **Keybindings**:
  - `Shift + Super + H`: Triggers system **Hibernate** (`sudo systemctl hibernate`).
  - `Super + M`: **Show Desktop**.
  - `Shift + Super + S`: **Interactive Screenshot UI**.
  - `Ctrl + F86MonBrightnessDown / Up`: External monitor DDC hardware brightness control.
- **Dock Configuration**:
  - Positioned at **Bottom**, **Autohide enabled** (`dock-fixed=false`), compact height, workspace isolation.
- **Active Extensions**:
  - `pop-shell@system76.com`: Auto-tiling window management
  - `blur-my-shell@aunetx`: Glassmorphism styling for shell and dock
  - `caffeine@patapon.info`: Sleep prevention toggle
  - `clipboard-indicator@tudmotu.com`: Clipboard history with paste-on-select
  - `CoverflowAltTab@palatis.blogspot.com`: 3D coverflow task switcher
  - `display-brightness-ddcutil@themightydeity.github.com`: External monitor backlight DDC control
  - `just-another-search-bar@xelad0m`
  - `just-perfection-desktop@just-perfection`: GNOME Shell customization
  - `Vitals@CoreCoding.com`: Top bar telemetry (CPU, RAM, GPU, temps, fan speed)

### 8. Biometric Facial Authentication (Howdy)
- Infrared camera facial recognition matching Windows Hello functionality.
- Configured with PAM module `/usr/lib/security/howdy/pam_howdy.so` for instant `sudo` and lockscreen authentication.
- Emitter control tool `linux-enable-ir-emitter` enabled in `~/.local/bin`.

### 9. Background Daemons & Services (`rtorrent`, `solve-diff`)
- **Systemd User Lingering** enabled (`loginctl enable-linger`) so user services continue running without active graphical sessions.
- **`rtorrent.service`**: Headless BitTorrent client in detached screen session with SCGI socket at `~/.rtorrent/session/rpc.sock`.
- **`solve-diff.service`**: Background Streamlit service for Competitive Programming problem diff solver, accessible on `http://localhost:8501`.

### 10. Custom Scripts & Binaries (`~/.local/bin/`)
- `rt`: rTorrent client CLI with XML-RPC socket queries.
- `playlist` & `playlist-length`: Universal Playlist Duration Calculator for local directories and YouTube playlists.
- `motrix`: Flatpak runner wrapper.
- `whisper-transcribe`: Launcher for local Whisper AI transcription virtual environment.
- `mangohud` & `mangoplot`: Gaming / GPU performance overlay and benchmark plotter.

### 11. NSFW Website Restrictions & Anti-Bypass Defenses
Multi-layered, tamper-resistant restriction suite ensuring adult content is blocked and SafeSearch is enforced across all browsers and connections:
- **System-Wide Family DNS (`systemd-resolved`)**: Unconditionally routes all queries through CleanBrowsing Family (`185.228.168.168`) and Cloudflare Family (`1.1.1.3`), locking SafeSearch on Google, Bing, DuckDuckGo, and YouTube at the resolver level.
- **Enterprise Browser Policies**: Pre-staged for all Chromium (Chrome, Chromium, Brave, Edge, Vivaldi, Opera) and Firefox (Firefox, LibreWolf, Waterfox) families, locking DNS-over-HTTPS (DoH) OFF and locking Google SafeSearch ON.
- **Offline Blocklist (`/etc/hosts`)**: Integrates StevenBlack's curated repository with 140,000+ adult domains mapped locally to `0.0.0.0`.
- **Kernel Firewall Anti-Bypass (`iptables`)**: Prevents DNS leakage on port 53 and blocks unmanaged DoH endpoints (`1.1.1.1`, `8.8.8.8`, `9.9.9.9`), forcing newly downloaded or portable browsers (AppImages) to fail over to the filtered system resolver.
- **Usage**:
  - Apply: `sudo ./scripts/nsfw-restriction/apply.sh` (or `./scripts/10-nsfw-restrictions.sh --apply`)
  - Verify: `./scripts/nsfw-restriction/verify.sh` (or `./scripts/10-nsfw-restrictions.sh --verify`)

### 12. Browser Extensions & Custom Settings
Comprehensive extension catalog documented in [`packages/browser-extensions.md`](packages/browser-extensions.md):
- **Brave Browser (33 Extensions)**:
  - *Competitive Programming / LeetCode*: Competitive Companion, CPH Submit, Codeforces Practice Tracker, Codeforces++, Carrot, CF Analytics, xodeforces, BetterLC, Clip LeetCode, Leetcode Analyzer, Leetcode Difficulty Rating.
  - *Privacy & Security*: uBlock Origin, Proton Pass, Proton VPN.
  - *AI & Development*: React Developer Tools, AI Exporter (ChatGPT/Claude/Gemini chats), Wider Gemini, Tampermonkey.
  - *Media & Productivity*: Dark Reader, Enhancer for YouTube, Really Hide YouTube Shorts, OneTab, Tab Auto Refresh, Blank Dark New Tab, Volume Booster.
- **Google Chrome (8 Extensions)**:
  - GRAYtist, Competitive Companion, Dark Reader, Carrot, CF Analytics, HirePro Assessment.
- **Automated Provisioning (`scripts/11-browser-extensions.sh`)**:
  - Automatically generates Chromium `External Extensions` JSON descriptors for all 33 Brave and Chrome extensions.
  - When the browser is launched on a fresh PC, it immediately downloads and prompts to activate all extensions.
- **Settings & Profile Synchronization**:
  - **Brave**: Use **Brave Sync** (24-word sync chain phrase) to safely restore bookmarks, history, and passwords without exposing credentials to Git.
  - **Chrome**: Use Google Account Sync.
  - **Mobile Emulation**: Custom alias `brave2` in `.bashrc_custom` provides instant Android Pixel User-Agent emulation.

---

## 📂 Repository Structure

```
ubuntu-setup/
├── README.md                          # Main documentation (this file)
├── LICENSE                            # MIT License
├── bootstrap.sh                       # Master interactive setup runner
├── scripts/
│   ├── 01-system-prep.sh              # Sysctl tuning, auto-cpufreq, snap removal, flatpak setup
│   ├── 02-apt-repositories.sh         # All GPG keys and external APT sources
│   ├── 03-install-apt-packages.sh     # Manually curated APT packages
│   ├── 04-install-flatpaks.sh         # Flatpak applications
│   ├── 05-dev-runtimes.sh             # Node 20, uv, Ollama, Go, Neovim, IDE extensions
│   ├── 06-gnome-desktop.sh            # Pop Shell tiling, GNOME Dconf dump restore & extensions
│   ├── 07-services-rtorrent.sh        # Background services (rtorrent, solve-diff), lingering, DB tuning
│   ├── 08-symlink-dotfiles.sh         # Dotfile deployment & bash configuration
│   ├── 09-face-unlock-howdy.sh        # Howdy IR facial recognition setup
│   ├── 10-nsfw-restrictions.sh        # Interactive NSFW restriction manager
│   ├── 11-browser-extensions.sh       # Automated Brave & Chrome extension provisioning
│   └── nsfw-restriction/              # Modular restriction scripts
│       ├── apply.sh                   # Hardened installer (DNS, hosts, policies, firewall)
│       ├── verify.sh                  # Non-root verification probe
│       └── README.md                  # Component documentation
├── packages/
│   ├── apt-packages.list              # Raw list of manually installed packages
│   ├── flatpak-packages.list          # Flatpak applications list
│   ├── brave-extensions.json          # Machine-readable Brave extension descriptors (33 extensions)
│   ├── chrome-extensions.json         # Machine-readable Chrome extension descriptors (8 extensions)
│   ├── browser-extensions.md          # Comprehensive catalog with Chrome Web Store links
│   ├── npm-globals.list               # NPM global packages
│   ├── vscode-extensions.list         # VS Code extensions list
│   ├── cursor-extensions.list         # Cursor extensions list
│   ├── gnome-extensions-all.list      # All GNOME extensions
│   └── python-requirements.txt        # Key Python libraries (ML, FastAPI, Streamlit, Langfuse)
├── dotfiles/
│   ├── .bashrc_custom                 # Custom PATHs, exports, and aliases
│   ├── .npmrc                         # User NPM prefix configuration
│   ├── .condarc                       # Conda auto-activation config
│   ├── .gitconfig.example             # Git configuration template
│   ├── .rtorrent.rc                   # Complete rTorrent configuration
│   ├── .config/
│   │   ├── nvim/                      # Neovim init.lua & lazy-lock
│   │   ├── MangoHud/                  # MangoHud gaming overlay config
│   │   ├── Code/User/                 # VS Code settings & keybindings
│   │   ├── Cursor/User/               # Cursor settings
│   │   ├── Qoder/User/                # Qoder settings
│   │   └── systemd/user/              # User systemd service units (rtorrent, solve-diff)
│   └── .local/bin/                    # Custom executables (rt, playlist, etc.)
└── configs/
    ├── dconf/                         # Dconf dumps for GNOME, mutter, shell, pop-shell
    ├── sysctl/                        # Kernel & network tuning .conf files
    ├── pam/                           # PAM configuration examples
    └── nsfw-restriction/              # DNS drop-in and browser policy JSON templates
```

---

## 🛠 Step-by-Step Manual Guide

If you prefer running individual components manually:

### 1. Apply System Tuning & Power Optimization
```bash
sudo cp configs/sysctl/99-swappiness.conf /etc/sysctl.d/
sudo cp configs/sysctl/99-network-ttl.conf /etc/sysctl.d/
sudo sysctl --system
```

### 2. Add Repositories & Install Packages
```bash
bash scripts/02-apt-repositories.sh
bash scripts/03-install-apt-packages.sh
bash scripts/04-install-flatpaks.sh
```

### 3. Deploy Development Runtimes & Local AI
```bash
bash scripts/05-dev-runtimes.sh
bash scripts/08-symlink-dotfiles.sh
```

### 4. Setup Pop Shell & GNOME Desktop
```bash
bash scripts/06-gnome-desktop.sh
```

### 5. Setup Background Services & Lingering
```bash
bash scripts/07-services-rtorrent.sh
```

---

## 🔒 Post-Install Checklist

After the automated installer finishes, complete these remaining manual steps:

1. **GitHub / SSH Authentication**:
   ```bash
   gh auth login
   ssh-keygen -t ed25519 -C "akkisinghvi28@gmail.com"
   gh ssh-key add ~/.ssh/id_ed25519.pub --title "$(hostname)"
   ```
2. **Facial Authentication Setup**:
   ```bash
   sudo howdy config # Set camera path (e.g. /dev/video2)
   sudo howdy add    # Enroll face model
   sudo howdy test   # Verify face detection
   ```
3. **Pull Ollama Local Models**:
   ```bash
   ollama pull qwen2.5-coder:7b
   ```
4. **Mount `/data` Partition**:
   - Add your data partition UUID to `/etc/fstab` if migrating to a new machine.

---

## 📜 License
Distributed under the [MIT License](LICENSE).
