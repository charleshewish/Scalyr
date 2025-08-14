#!/usr/bin/env bash
# install_scalyr.sh — Install scalyr-agent-2-aio with config from GitHub (avoids install-time API key validation)

set -euo pipefail

# ===== USER VARIABLES =====
CONFIG_URL="https://raw.githubusercontent.com/charleshewish/Scalyr/tree/Linux/agent.json"
PKG="scalyr-agent-2-aio"
SERVICE="scalyr-agent-2"
CONF_DIR="/etc/scalyr-agent-2"
CONF_FILE="${CONF_DIR}/agent.json"

# ===== PREP =====
echo "[INFO] Updating apt cache and ensuring curl is available..."
sudo apt-get update -y
sudo apt-get install -y curl ca-certificates

# ===== PREVENT SERVICE AUTO-START =====
echo "[INFO] Temporarily disabling $SERVICE so it doesn't start during package install..."
sudo systemctl mask "$SERVICE" || true

# ===== INSTALL PACKAGE =====
echo "[INFO] Installing $PKG..."
sudo apt-get install -y "$PKG"

# ===== FETCH CONFIG FROM GITHUB =====
echo "[INFO] Downloading agent config from GitHub..."
TMP_CONF="$(mktemp)"
curl -fsSL "$CONFIG_URL" -o "$TMP_CONF"

# Basic sanity check
if ! head -c 1 "$TMP_CONF" | grep -q '{'; then
  echo "[ERROR] Downloaded file doesn't look like JSON. Check CONFIG_URL." >&2
  rm -f "$TMP_CONF"
  exit 1
fi

# ===== PLACE CONFIG =====
echo "[INFO] Applying config to $CONF_FILE..."
sudo mkdir -p "$CONF_DIR"
sudo install -o root -g root -m 640 "$TMP_CONF" "$CONF_FILE"
rm -f "$TMP_CONF"

# ===== ENABLE & START SERVICE =====
echo "[INFO] Re-enabling and starting $SERVICE..."
sudo systemctl unmask "$SERVICE"
sudo systemctl enable --now "$SERVICE"

echo "[SUCCESS] $PKG installed and configured using $CONF_FILE"
