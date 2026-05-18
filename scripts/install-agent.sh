#!/bin/bash
# ===================================================
# Wazuh Agent Installer
# Jalankan di laptop agent (Ubuntu/Debian)
# ===================================================
# Usage: sudo bash install-agent.sh <MANAGER_IP>
# Contoh: sudo bash install-agent.sh 167.71.198.100
# ===================================================

set -e

# Warna
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=================================================${NC}"
echo -e "${BLUE}   WAZUH AGENT INSTALLER                         ${NC}"
echo -e "${BLUE}=================================================${NC}"
echo ""

# Cek root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[ERROR] Jalankan dengan sudo!${NC}"
    exit 1
fi

# Cek argument
if [ -z "$1" ]; then
    echo -e "${RED}[ERROR] Manager IP belum diisi!${NC}"
    echo -e "Usage: sudo bash install-agent.sh <MANAGER_IP>"
    echo -e "Contoh: sudo bash install-agent.sh 167.71.198.100"
    exit 1
fi

MANAGER_IP="$1"
AGENT_NAME=$(hostname)

echo -e "${GREEN}[INFO] Manager IP: ${MANAGER_IP}${NC}"
echo -e "${GREEN}[INFO] Agent Name: ${AGENT_NAME}${NC}"
echo ""

# ====== STEP 1: Import GPG Key ======
echo -e "${YELLOW}[STEP 1/4] Importing Wazuh GPG key...${NC}"
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import && chmod 644 /usr/share/keyrings/wazuh.gpg
echo -e "${GREEN}[DONE]${NC}"

# ====== STEP 2: Add Repository ======
echo -e "${YELLOW}[STEP 2/4] Adding Wazuh repository...${NC}"
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | tee -a /etc/apt/sources.list.d/wazuh.list
apt update
echo -e "${GREEN}[DONE]${NC}"

# ====== STEP 3: Install Agent ======
echo -e "${YELLOW}[STEP 3/4] Installing Wazuh Agent...${NC}"
WAZUH_MANAGER="${MANAGER_IP}" WAZUH_AGENT_NAME="${AGENT_NAME}" apt install -y wazuh-agent
echo -e "${GREEN}[DONE]${NC}"

# ====== STEP 4: Start Agent ======
echo -e "${YELLOW}[STEP 4/4] Starting Wazuh Agent...${NC}"
systemctl daemon-reload
systemctl enable wazuh-agent
systemctl start wazuh-agent
echo -e "${GREEN}[DONE]${NC}"

echo ""
echo -e "${BLUE}=================================================${NC}"
echo -e "${GREEN}   AGENT INSTALLED SUCCESSFULLY!${NC}"
echo -e "${BLUE}=================================================${NC}"
echo ""
echo -e "${GREEN}Agent Name: ${AGENT_NAME}${NC}"
echo -e "${GREEN}Manager IP: ${MANAGER_IP}${NC}"
echo ""
echo -e "${YELLOW}Cek status:${NC}"
echo "  sudo systemctl status wazuh-agent"
echo ""
echo -e "${YELLOW}Cek koneksi ke manager:${NC}"
echo "  sudo cat /var/ossec/logs/ossec.log | grep -i 'connected'"
echo ""
echo -e "${YELLOW}Cek enrollment:${NC}"
echo "  sudo cat /var/ossec/etc/client.keys"
