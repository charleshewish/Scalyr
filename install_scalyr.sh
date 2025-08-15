#!/usr/bin/env bash
# install_scalyr.sh — Install scalyr-agent-2-aio with config from GitHub (avoids install-time API key validation)

set -euo pipefail

# ===== PREP =====
echo "[INFO] Updating apt cache and ensuring curl is available..."
sudo apt-get update -y
sudo apt-get install -y curl ca-certificates scalyr-agent-2-aio

# ===== CONFIG =====
CONFIG_URL="https://raw.githubusercontent.com/charleshewish/Scalyr/Linux/agent.json"
CONFIG_PATH="/etc/scalyr-agent-2/agent.json"

echo "[INFO] Downloading agent.json from GitHub..."
sudo curl -fsSL "$CONFIG_URL" -o "$CONFIG_PATH"

# Detect the non-root user running the script
RUN_USER=$(logname 2>/dev/null || echo "$USER")

echo "[INFO] Setting ownership of agent.json for $RUN_USER..."
sudo chown "$RUN_USER":"$RUN_USER" "$CONFIG_PATH"

# ===== RESTART AGENT =====
echo "[INFO] Restarting Scalyr Agent..."
sudo scalyr-agent-2 stop || true
sudo scalyr-agent-2 start

echo "[INFO] Installation complete!"
