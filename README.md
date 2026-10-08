# 🐧 Ubuntu 24.04 LTS (Noble Numbat) Custom Setup & Dotfiles

> Fully automated, modular, and reproducible setup suite for an Ubuntu 24.04 LTS workstation. Recreates packages, PPAs, kernel optimizations, GNOME customizations, dev runtimes, databases, background services, and dotfiles.

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
  - [5. Databases & Backend Services](#5-databases--backend-services)
  - [6. GNOME Desktop & Shell Extensions](#6-gnome-desktop--shell-extensions)
  - [7. Biometric Facial Authentication (Howdy)](#7-biometric-facial-authentication-howdy)
  - [8. rTorrent Daemon & CLI (`rt`)](#8-rtorrent-daemon--cli-rt)
  - [9. Custom Scripts & Binaries](#9-custom-scripts--binaries)
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
- **Swappiness Reduction** (`/etc/sysctl.d/99-swappiness.conf`):
  - `vm.swappiness = 20` (prevents early aggressive swapping and keeps RAM responsive).
- **Network TTL Modification** (`/etc/sysctl.d/99-network-ttl.conf`):
  - `net.ipv4.ip_default_ttl = 65` and `net.ipv6.conf.all.hop_limit = 65` (optimizes packet forwarding and hotspot/tethering throughput).
- **Wayland Fractional Scaling**:
  - `scale-monitor-framebuffer` enabled in Mutter for crisp HiDPI fractional display scaling.

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
- **C/C++**: `gcc`, `g++`, `gdb`, `clangd`, `cmake`, `ninja-build`
- **Python**:
  - [Astral `uv`](https://github.com/astral-sh/uv) (ultra-fast pip/venv replacement in `~/.local/bin/uv`)
  - `pipx` for isolated CLI tools (`yt-dlp`)
  - Full scientific/ML stack: NumPy, Pandas, Scikit-learn, Matplotlib, Seaborn, PyTorch, LiteLLM, OpenCV
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

### 5. Databases & Backend Services
Native local services installed and ready:
- **PostgreSQL 16** (`postgresql`, `postgresql-contrib`)
- **MySQL Server** (`mysql-server`)
- **Redis Server** (`redis-server`)
- **RabbitMQ Message Broker** (`rabbitmq-server`)
- **MongoDB 7.0** (`mongodb-org`)
- **Docker Engine & Docker Compose** (User added to `docker` group)

### 6. GNOME Desktop & Shell Extensions
- **Keybindings**:
  - `Shift + Super + H`: Triggers system **Hibernate** (`sudo systemctl hibernate`).
  - `Super + M`: **Show Desktop**.
  - `Shift + Super + S`: **Interactive Screenshot UI**.
  - `Ctrl + F86MonBrightnessDown / Up`: External monitor DDC hardware brightness control.
- **Dock Configuration**:
  - Positioned at **Bottom**
  - **Autohide enabled** (`dock-fixed=false`)
  - Compact height (`extend-height=false`)
  - Workspace isolation enabled
- **Active Extensions**:
  - `blur-my-shell@aunetx`: Glassmorphism styling for shell and dock
  - `caffeine@patapon.info`: Prevents system sleeping/locking during presentations or builds
  - `clipboard-indicator@tudmotu.com`: Clipboard history with paste-on-select
  - `CoverflowAltTab@palatis.blogspot.com`: 3D coverflow task switcher
  - `display-brightness-ddcutil@themightydeity.github.com`: Controls external monitor backlight via DDC/CI
  - `just-another-search-bar@xelad0m`
  - `just-perfection-desktop@just-perfection`: Fine-grained GNOME Shell customization
  - `Vitals@CoreCoding.com`: Top bar hardware monitoring (CPU, RAM, GPU, temps, fan speed)

### 7. Biometric Facial Authentication (Howdy)
- Infrared camera facial recognition matching Windows Hello functionality.
- Configured with PAM module `/usr/lib/security/howdy/pam_howdy.so` for instant `sudo` and lockscreen authentication.
- Emitter control tool `linux-enable-ir-emitter` enabled in `~/.local/bin`.

### 8. rTorrent Daemon & CLI (`rt`)
- Headless background service managed via systemd user unit (`rtorrent.service`).
- SCGI Unix domain socket communication at `~/.rtorrent/session/rpc.sock`.
- Custom CLI controller `rt` (`~/.local/bin/rt`):
  - Checks/auto-starts background service
  - Lists downloads, progress, peers, seeds, up/down speeds, and storage stats.

### 9. Custom Scripts & Binaries (`~/.local/bin/`)
- `rt`: rTorrent client CLI with XML-RPC socket queries.
- `playlist` & `playlist-length`: Universal Playlist Duration Calculator for local directories and YouTube playlists.
- `motrix`: Flatpak runner wrapper.
- `whisper-transcribe`: Launcher for local Whisper AI transcription virtual environment.
- `mangohud` & `mangoplot`: Gaming / GPU performance overlay and benchmark plotter.

---

## 📂 Repository Structure

```
ubuntu-setup/
├── README.md                          # Main documentation (this file)
├── LICENSE                            # MIT License
├── bootstrap.sh                       # Master interactive setup runner
├── scripts/
│   ├── 01-system-prep.sh              # Sysctl tuning, snap removal, flatpak setup
│   ├── 02-apt-repositories.sh         # All GPG keys and external APT sources
│   ├── 03-install-apt-packages.sh     # Manually curated APT packages
│   ├── 04-install-flatpaks.sh         # Flatpak applications
│   ├── 05-dev-runtimes.sh             # Node 20, uv, Python, Go, Neovim, IDE extensions
│   ├── 06-gnome-desktop.sh            # GNOME Dconf dump restore & extensions
│   ├── 07-services-rtorrent.sh        # rTorrent systemd user service setup
│   ├── 08-symlink-dotfiles.sh         # Dotfile deployment & bash configuration
│   └── 09-face-unlock-howdy.sh        # Howdy IR facial recognition setup
├── packages/
│   ├── apt-packages.list              # Raw list of manually installed packages
│   ├── flatpak-packages.list          # Flatpak applications list
│   ├── npm-globals.list               # NPM global packages
│   ├── vscode-extensions.list         # VS Code extensions list
│   ├── cursor-extensions.list         # Cursor extensions list
│   └── python-requirements.txt        # Key Python libraries
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
│   │   └── systemd/user/              # User systemd service units
│   └── .local/bin/                    # Custom executables (rt, playlist, etc.)
└── configs/
    ├── dconf/                         # Dconf dumps for GNOME, mutter, shell
    ├── sysctl/                        # Kernel & network tuning .conf files
    └── pam/                           # PAM configuration examples
```

---

## 🛠 Step-by-Step Manual Guide

If you prefer running individual components manually:

### 1. Apply System Tuning
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

### 3. Deploy Dotfiles & Neovim
```bash
bash scripts/05-dev-runtimes.sh
bash scripts/08-symlink-dotfiles.sh
```

### 4. Restore GNOME Desktop & Shortcuts
```bash
bash scripts/06-gnome-desktop.sh
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
3. **Hibernate Swapfile Setup** (if needed):
   - Ensure `/data/swap.img` or root swap size >= RAM size (16GB).
4. **Mount `/data` Partition**:
   - Add your data partition UUID to `/etc/fstab` if migrating to a new machine.

---

## 📜 License
Distributed under the [MIT License](LICENSE).
