#!/bin/bash
# ===================================================
# Simulasi SSH Brute Force Attack
# Jalankan di Agent 1 (atau dari komputer lain ke Agent 1)
# ===================================================
# Usage: bash attack-bruteforce.sh <TARGET_IP>
# ===================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${RED}=================================================${NC}"
echo -e "${RED}   SIMULASI: SSH BRUTE FORCE ATTACK              ${NC}"
echo -e "${RED}=================================================${NC}"
echo ""
echo -e "${YELLOW}[WARNING] Ini hanya simulasi untuk tujuan edukasi!${NC}"
echo ""

TARGET_IP="${1:-localhost}"

echo -e "${GREEN}[INFO] Target: ${TARGET_IP}${NC}"
echo -e "${GREEN}[INFO] Memulai simulasi...${NC}"
echo ""

# ====== Metode 1: Failed SSH Login Attempts ======
echo -e "${YELLOW}[1/3] Simulasi failed SSH login (15 attempts)...${NC}"

# Cek apakah sshpass tersedia
if command -v sshpass &> /dev/null; then
    for i in $(seq 1 15); do
        echo "  Attempt $i/15 - user: hacker_${i}"
        sshpass -p "wrongpassword${i}" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 "hacker_${i}@${TARGET_IP}" 2>/dev/null
        sleep 0.5
    done
else
    echo -e "${YELLOW}  sshpass tidak tersedia, menggunakan logger...${NC}"
    for i in $(seq 1 15); do
        echo "  Attempt $i/15"
        logger -p auth.warning "sshd[$$]: Failed password for invalid user hacker_${i} from 10.10.10.${i} port $((2000+i)) ssh2"
        sleep 0.3
    done
fi

echo -e "${GREEN}  [DONE]${NC}"
echo ""

# ====== Metode 2: Multiple users brute force ======
echo -e "${YELLOW}[2/3] Simulasi brute force multiple users...${NC}"

USERS=("admin" "root" "test" "user" "ubuntu" "mysql" "postgres" "oracle" "ftp" "www-data")
for user in "${USERS[@]}"; do
    echo "  Trying user: $user"
    logger -p auth.warning "sshd[$$]: Failed password for ${user} from 192.168.1.100 port 22 ssh2"
    sleep 0.3
done

echo -e "${GREEN}  [DONE]${NC}"
echo ""

# ====== Metode 3: Rapid fire (trigger high-level alert) ======
echo -e "${YELLOW}[3/3] Simulasi rapid-fire brute force (trigger alert level 13)...${NC}"

for i in $(seq 1 30); do
    logger -p auth.crit "sshd[$$]: Failed password for invalid user attacker from 10.0.0.66 port $((3000+i)) ssh2"
    sleep 0.1
done

echo -e "${GREEN}  [DONE]${NC}"
echo ""

echo -e "${RED}=================================================${NC}"
echo -e "${GREEN}SIMULASI SELESAI!${NC}"
echo ""
echo -e "${YELLOW}Cek Wazuh Dashboard:${NC}"
echo "  1. Login ke Dashboard"
echo "  2. Buka Security Events"
echo "  3. Filter: rule.id: 5710 OR rule.id: 5712 OR rule.id: 5763"
echo "  4. Lihat alert brute force yang muncul"
echo -e "${RED}=================================================${NC}"
