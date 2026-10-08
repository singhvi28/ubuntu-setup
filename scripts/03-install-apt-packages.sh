#!/usr/bin/env bash
set -euo pipefail

echo "==> [3/9] Installing Curated APT Packages"

sudo apt update

echo "==> Installing Development Tools & Build Chain..."
sudo apt install -y \
    build-essential \
    g++ \
    gcc \
    gdb \
    clangd \
    cmake \
    ninja-build \
    git \
    gh \
    git-filter-repo \
    fzf \
    cloc \
    jq \
    ncdu \
    htop \
    screen \
    traceroute \
    libfuse2t64 \
    exfatprogs \
    gparted \
    efibootmgr \
    fdupes

echo "==> Installing Editors & IDEs..."
sudo apt install -y \
    code \
    code-insiders \
    dbeaver-ce || true

echo "==> Installing Web Browsers & Media Tools..."
sudo apt install -y \
    google-chrome-stable \
    brave-browser \
    librewolf \
    obs-studio \
    vlc \
    mpv \
    cheese \
    ffmpeg \
    winehq-stable || true

echo "==> Installing Databases & Services..."
sudo apt install -y \
    postgresql \
    postgresql-client \
    postgresql-contrib \
    mysql-server \
    redis-server \
    rabbitmq-server \
    mongodb-org || true

echo "==> Installing Docker Engine..."
sudo apt install -y docker-ce docker-ce-cli containerd.io
sudo usermod -aG docker "$USER" || true

echo "==> Installing Python Toolchains..."
sudo apt install -y \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    python3-numpy \
    python3-opencv \
    python3-requests \
    python3-bs4 \
    python3-openpyxl \
    python3-setuptools \
    python3-wheel

echo "==> Installing Node.js & Pandoc / TeX..."
sudo apt install -y \
    nodejs \
    pandoc \
    texlive-fonts-recommended \
    texlive-plain-generic \
    texlive-xetex || true

echo "==> Installing GNOME Utilities & Hardware Integrations..."
sudo apt install -y \
    gnome-tweaks \
    gnome-shell-extension-manager \
    gnome-browser-connector \
    ddcutil \
    touchegg \
    howdy \
    v4l-utils \
    rtorrent || true

echo "==> APT package installation complete!"
