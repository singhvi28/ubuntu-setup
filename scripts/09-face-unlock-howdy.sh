#!/usr/bin/env bash
set -euo pipefail

echo "==> [9/9] Facial Recognition (Howdy + IR Emitter) Setup Guide"

echo "-------------------------------------------------------------"
echo "Howdy provides Windows Hello-style facial authentication for"
echo "sudo, polkit, and lockscreen login on Ubuntu 24.04."
echo "-------------------------------------------------------------"

# 1. Install Howdy and v4l-utils
if ! command -v howdy &>/dev/null; then
    echo "==> Installing Howdy..."
    sudo add-apt-repository -y ppa:ubuntuhandbook1/howdy
    sudo apt update
    sudo apt install -y howdy v4l-utils
fi

# 2. Camera detection helper
echo ""
echo "==> Scanning for available video devices and IR cameras:"
v4l2-ctl --list-devices || true

echo ""
echo "==> Next Steps for Facial Authentication Setup:"
echo "1. Run: sudo howdy config"
echo "   Locate 'device_path' and set it to your IR camera (e.g., /dev/video2)."
echo "2. If your IR camera requires an emitter trigger (common on Lenovo laptops):"
echo "   Run: linux-enable-ir-emitter configure"
echo "3. Add your face model:"
echo "   Run: sudo howdy add"
echo "4. Test face detection:"
echo "   Run: sudo howdy test"
echo "-------------------------------------------------------------"
