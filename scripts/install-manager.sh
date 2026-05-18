#!/bin/bash
# ===================================================
# Wazuh Manager All-in-One Installer
# Disesuaikan untuk Microsoft Azure for Students (Standard_B2s)
# ===================================================
# Usage: sudo bash install-manager.sh
# ===================================================

set -e

# Warna output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=================================================${NC}"
echo -e "${BLUE}   WAZUH MANAGER - AZURE INSTALLER               ${NC}"
echo -e "${BLUE}=================================================${NC}"
echo ""

# Cek root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[ERROR] Script ini harus dijalankan sebagai root (sudo)${NC}"
    exit 1
fi

# Dapatkan IP VPS
VPS_IP=$(hostname -I | awk '{print $1}')
PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || echo "$VPS_IP")

echo -e "${GREEN}[INFO] Detected IP:${NC}"
echo -e "  Private IP: ${VPS_IP}"
echo -e "  Public IP:  ${PUBLIC_IP}"
echo ""

# ====== Cek RAM ======
TOTAL_RAM=$(free -m | awk '/^Mem:/{print $2}')
echo -e "${YELLOW}[INFO] Total Physical RAM: ${TOTAL_RAM} MB${NC}"
if [ "$TOTAL_RAM" -lt 3000 ]; then
    echo -e "${RED}[WARNING] RAM terdeteksi kurang dari 4GB! Script ini direkomendasikan untuk Azure Standard_B2s (4GB RAM).${NC}"
    echo -e "${YELLOW}Melanjutkan instalasi, tapi resiko crash tinggi jika RAM terlalu kecil.${NC}"
else
    echo -e "${GREEN}[INFO] Spesifikasi RAM memadai (Standard_B2s Azure).${NC}"
fi
echo ""

# ====== STEP 1: Update System ======
echo -e "${YELLOW}[STEP 1/5] Updating system packages...${NC}"
apt update && DEBIAN_FRONTEND=noninteractive apt upgrade -y
apt install -y curl apt-transport-https unzip wget
echo -e "${GREEN}[DONE] System updated${NC}"
echo ""

# ====== STEP 2: Configure Firewall ======
echo -e "${YELLOW}[STEP 2/5] Configuring firewall (Internal OS)...${NC}"
echo -e "${YELLOW}Pastikan juga kamu sudah allow port di Azure Portal (Network Security Group)!${NC}"
apt install -y ufw
ufw allow 22/tcp    # SSH
ufw allow 443/tcp   # Dashboard
ufw allow 1514/tcp  # Agent events
ufw allow 1515/tcp  # Agent enrollment
ufw allow 9200/tcp  # Indexer API
echo "y" | ufw enable
ufw status
echo -e "${GREEN}[DONE] Firewall configured${NC}"
echo ""

# ====== STEP 3: Download Wazuh Installer ======
echo -e "${YELLOW}[STEP 3/5] Downloading Wazuh installer...${NC}"
cd /root
curl -sO https://packages.wazuh.com/4.9/wazuh-install.sh
curl -sO https://packages.wazuh.com/4.9/config.yml
echo -e "${GREEN}[DONE] Installer downloaded${NC}"
echo ""

# ====== STEP 4: Configure config.yml ======
echo -e "${YELLOW}[STEP 4/5] Configuring Wazuh (using IP: ${PUBLIC_IP})...${NC}"

cat > config.yml << EOF
nodes:
  # Wazuh indexer nodes
  indexer:
    - name: node-1
      ip: "${PUBLIC_IP}"

  # Wazuh server nodes
  server:
    - name: wazuh-1
      ip: "${PUBLIC_IP}"

  # Wazuh dashboard nodes
  dashboard:
    - name: dashboard
      ip: "${PUBLIC_IP}"
EOF

echo -e "${GREEN}[DONE] Configuration created${NC}"
cat config.yml
echo ""

# ====== STEP 5: Install Wazuh All-in-One ======
echo -e "${YELLOW}[STEP 5/5] Installing Wazuh (Ini butuh waktu sekitar 10-15 menit)...${NC}"
echo -e "${YELLOW}          Please be patient...${NC}"

# Generate config files
bash wazuh-install.sh --generate-config-files

# Install all components
bash wazuh-install.sh --all-in-one 2>&1 | tee /root/wazuh-install.log

echo ""
echo -e "${BLUE}=================================================${NC}"
echo -e "${GREEN}   INSTALASI SELESAI!${NC}"
echo -e "${BLUE}=================================================${NC}"
echo ""
echo -e "${GREEN}Dashboard URL: https://${PUBLIC_IP}:443${NC}"
echo ""
echo -e "${YELLOW}Credential ada di output 'INFO:' di atas, atau jalankan perintah ini:${NC}"
echo -e "  sudo tar -axf wazuh-install-files.tar wazuh-install-files/wazuh-passwords.txt -O"
echo ""
echo -e "${YELLOW}Cek status service:${NC}"
echo -e "  sudo systemctl status wazuh-manager"
echo -e "  sudo systemctl status wazuh-indexer"
echo -e "  sudo systemctl status wazuh-dashboard"
echo ""
echo -e "${YELLOW}Log instalasi disimpan di: /root/wazuh-install.log${NC}"
