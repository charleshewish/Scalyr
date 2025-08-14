#!/usr/bin/env bash
# install_scalyr.sh — pre-seed agent.json, then install scalyr-agent-2-aio

set -euo pipefail

CONFIG_URL="https://raw.githubusercontent.com/charleshewish/Scalyr/tree/Linux/agent.json"

PKG="scalyr-agent-2-aio"
SERVICE="scalyr-agent-2"
CONF_DIR="/etc/scalyr-agent-2"
CONF_FILE="${CONF_DIR}/agent.json"

echo "[INFO] Updating apt cache and ensuring curl is available..."
sudo apt-get update -y
sudo apt-get install -y curl ca-certificates

echo "[INFO] Downloading agent config from GitHub FIRST..."
TMP_CONF="$(mktemp)"
curl -fsSL "$CONFIG_URL" -o "$TMP_CONF"

# (Optional) very light sanity check that we didn't fetch an HTML error page
if ! head -c 1 "$TMP_CONF" | grep -q '{'; then
  echo "[ERROR] Downloaded file doesn't look like JSON. Check CONFIG_URL." >&2
  exit 1
fi

echo "[INFO] Pre-creating ${CONF_DIR} and placing config before package install..."
sudo mkdir -p "$CONF_DIR"
# install sets owner+mode atomically
sudo install -o root -g root -m 600 "$TMP_CONF" "$CONF_FILE"
rm -f "$TMP_CONF"

echo "[INFO] Installing ${PKG}..."
sudo apt-get install -y "$PKG"

echo "[INFO] Enabling/restarting service..."
# In case enable fails because it's already enabled, try restart
if ! sudo systemctl enable --now "$SERVICE"; then
  sudo systemctl restart "$SERVICE"
fi

echo "[SUCCESS] Scalyr agent installed and using ${CONF_FILE}"
