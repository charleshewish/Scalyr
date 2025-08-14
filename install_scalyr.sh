#!/bin/bash
# install_scalyr.sh
# Automates Scalyr agent installation + config deployment

set -e  # exit if any command fails

# ---- USER VARIABLES ----
CONFIG_URL="https://raw.githubusercontent.com/charleshewish/Scalyr/tree/Linux/agent.json"

# ---- CREATE TEMP CONFIG BEFORE INSTALL ----
echo "[INFO] Creating temporary config so install doesn't fail..."
sudo mkdir -p /etc/scalyr-agent-2
echo '{}' | sudo tee /etc/scalyr-agent-2/agent.json >/dev/null
sudo chown root:root /etc/scalyr-agent-2/agent.json
sudo chmod 644 /etc/scalyr-agent-2/agent.json

# ---- UPDATE & INSTALL SCALYR AGENT ----
echo "[INFO] Updating package list..."
sudo apt-get update -y

echo "[INFO] Installing Scalyr agent (aio version)..."
sudo apt-get install -y scalyr-agent-2-aio

# ---- DOWNLOAD REAL CONFIG ----
echo "[INFO] Downloading Scalyr config from GitHub..."
curl -sL -o scalyr_agent.json "$CONFIG_URL"

# ---- APPLY REAL CONFIG ----
echo "[INFO] Applying config to /etc/scalyr-agent-2/agent.json..."
sudo mv scalyr_agent.json /etc/scalyr-agent-2/agent.json
sudo chown root:root /etc/scalyr-agent-2/agent.json
sudo chmod 644 /etc/scalyr-agent-2/agent.json

# ---- RESTART AGENT ----
echo "[INFO] Restarting Scalyr agent..."
sudo systemctl restart scalyr-agent-2

echo "[SUCCESS] Scalyr agent installed and configured!"
