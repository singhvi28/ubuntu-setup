#!/usr/bin/env bash
set -euo pipefail

echo "==> [11] Configuring Automated Browser Extensions (Brave & Chrome)"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_DIR="$SCRIPT_DIR/../packages"

UPDATE_URL="https://clients2.google.com/service/update2/crx"
JSON_CONTENT="{\"external_update_url\": \"$UPDATE_URL\"}"

# 1. Setup Brave Browser External Extensions (User & System-wide)
BRAVE_USER_EXT_DIR="$HOME/.config/BraveSoftware/Brave-Browser/External Extensions"
mkdir -p "$BRAVE_USER_EXT_DIR"

if [ -f "$PACKAGES_DIR/brave-extensions.json" ]; then
    echo "==> Provisioning 33 Brave Browser extensions..."
    python3 - << PYEOF
import json, os

ext_dir = "$BRAVE_USER_EXT_DIR"
json_content = '$JSON_CONTENT'

with open("$PACKAGES_DIR/brave-extensions.json") as f:
    extensions = json.load(f)

for ext in extensions:
    ext_id = ext["id"]
    file_path = os.path.join(ext_dir, f"{ext_id}.json")
    with open(file_path, "w") as out:
        out.write(json_content + "\n")

print(f"Created {len(extensions)} external extension manifests in {ext_dir}")
PYEOF
fi

# 2. Setup Google Chrome External Extensions
CHROME_USER_EXT_DIR="$HOME/.config/google-chrome/External Extensions"
mkdir -p "$CHROME_USER_EXT_DIR"

if [ -f "$PACKAGES_DIR/chrome-extensions.json" ]; then
    echo "==> Provisioning Chrome extensions..."
    python3 - << PYEOF
import json, os

ext_dir = "$CHROME_USER_EXT_DIR"
json_content = '$JSON_CONTENT'

with open("$PACKAGES_DIR/chrome-extensions.json") as f:
    extensions = json.load(f)

for ext in extensions:
    ext_id = ext["id"]
    file_path = os.path.join(ext_dir, f"{ext_id}.json")
    with open(file_path, "w") as out:
        out.write(json_content + "\n")

print(f"Created {len(extensions)} external extension manifests in {ext_dir}")
PYEOF
fi

echo ""
echo "==> Browser extensions provisioned successfully!"
echo "When you launch Brave or Chrome, the browser will automatically fetch and prompt to enable each extension."
