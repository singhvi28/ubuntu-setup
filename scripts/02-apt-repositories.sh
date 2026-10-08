#!/usr/bin/env bash
set -euo pipefail

echo "==> [2/9] Configuring External APT Repositories & GPG Keys"

sudo mkdir -p /etc/apt/keyrings /usr/share/keyrings

# 1. Google Chrome
if [ ! -f /usr/share/keyrings/google-chrome.gpg ]; then
    echo "==> Adding Google Chrome repository..."
    curl -fSsL https://dl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] https://dl.google.com/linux/chrome-stable/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list
fi

# 2. Brave Browser
if [ ! -f /usr/share/keyrings/brave-browser-archive-keyring.gpg ]; then
    echo "==> Adding Brave Browser repository..."
    sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list
fi

# 3. Microsoft Edge & VS Code
if [ ! -f /etc/apt/keyrings/microsoft.asc ]; then
    echo "==> Adding Microsoft repository..."
    curl -sSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /etc/apt/keyrings/microsoft.asc
    echo "deb [signed-by=/etc/apt/keyrings/microsoft.asc] https://packages.microsoft.com/repos/edge stable main" | sudo tee /etc/apt/sources.list.d/microsoft-edge.list
    echo "deb [arch=amd64,arm64 signed-by=/etc/apt/keyrings/microsoft.asc] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list
fi

# 4. NodeSource (Node.js 20.x LTS)
if [ ! -f /usr/share/keyrings/nodesource.gpg ]; then
    echo "==> Adding NodeSource repository..."
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/nodesource.gpg
    echo "deb [signed-by=/usr/share/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
    echo -e "Package: nodejs\nPin: origin deb.nodesource.com\nPin-Priority: 600" | sudo tee /etc/apt/preferences.d/nodejs
fi

# 5. Docker CE
if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
    echo "==> Adding Docker CE repository..."
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list
fi

# 6. MongoDB 7.0
if [ ! -f /usr/share/keyrings/mongodb-server-7.0.gpg ]; then
    echo "==> Adding MongoDB repository..."
    curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | sudo gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg
    echo "deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
fi

# 7. WineHQ
if [ ! -f /etc/apt/keyrings/winehq-archive.key ]; then
    echo "==> Adding WineHQ repository..."
    sudo dpkg --add-architecture i386 || true
    sudo wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key
    sudo wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/ubuntu/dists/noble/winehq-noble.sources || true
fi

# 8. OBS Studio & Howdy PPAs
echo "==> Adding PPAs (OBS Studio, Howdy)..."
sudo add-apt-repository -y ppa:obsproject/obs-studio
sudo add-apt-repository -y ppa:ubuntuhandbook1/howdy

# 9. Librewolf (via extrepo)
echo "==> Enabling Librewolf via extrepo..."
sudo apt install -y extrepo
sudo extrepo enable librewolf

echo "==> Updating APT cache with all new repositories..."
sudo apt update

echo "==> Repositories setup complete!"
