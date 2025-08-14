#!/bin/bash
# install_scalyr.sh
# Automates Scalyr agent installation + config deployment

set -e  # exit if any command fails

# ---- USER VARIABLES ----
CONFIG_URL="https://raw.githubusercontent.com/charleshewish/Scalyr/tree/Linux/agent.json"

# ---- INSTALL SCALYR AGENT ----
echo "[INFO] Updating package list..."
sudo apt-get update -y

echo "[INFO] Installing Scalyr agent..."
sudo apt-get install -y scalyr-agent-2

# ---- DOWNLOAD CONFIG ----
echo "[INFO] Downloading Scalyr config from GitHub..."
curl -sL -o scalyr_agent.json "$CONFIG_URL"

# ---- APPLY CONFIG ----
echo "[INFO] Applying config to /etc/scalyr-agent-2/agent.json..."
sudo mv agent.json /etc/scalyr-agent-2/agent.json
sudo chown root:root /etc/scalyr-agent-2/agent.json
sudo chmod 644 /etc/scalyr-agent-2/agent.json

# ---- RESTART AGENT ----
echo "[INFO] Restarting Scalyr agent..."
sudo scalyr-agent-2 restart

echo "[SUCCESS] Scalyr agent installed and configured!"
