#!/bin/bash
# ================================================================
# DEPLOY SOAR DDoS ke Wazuh Manager
# ================================================================
# Cara pakai:
#   1. SSH ke server:  ssh wazuh-manager@70.153.19.42
#   2. sudo su
#   3. Copy-paste SEMUA isi file ini ke terminal
#   4. Selesai! Tinggal test dari agent
# ================================================================

echo "================================================="
echo "  DEPLOY SOAR DDoS - Wazuh Manager"
echo "  $(date)"
echo "================================================="
echo ""

# ============================================================
# STEP 1: Backup file lama
# ============================================================
echo "[1/5] Backup file lama..."
cp /var/ossec/etc/rules/custom-rules.xml /var/ossec/etc/rules/custom-rules.xml.backup.$(date +%Y%m%d) 2>/dev/null
cp /var/ossec/etc/ossec.conf /var/ossec/etc/ossec.conf.backup.$(date +%Y%m%d) 2>/dev/null
echo "  [DONE] Backup disimpan dengan suffix .backup.$(date +%Y%m%d)"
echo ""

# ============================================================
# STEP 2: Upload Custom Rules (DDoS SOAR)
# ============================================================
echo "[2/5] Upload custom-rules.xml..."

cat > /var/ossec/etc/rules/custom-rules.xml << 'RULES_EOF'
<!--
  Custom Wazuh Rules
  UPDATE: Ditambahkan rules SOAR DDoS (100050-100055)
-->

<group name="custom,attack_demo,">

  <!-- ========== BRUTE FORCE CUSTOM ========== -->

  <rule id="100001" level="10" frequency="5" timeframe="120">
    <if_matched_sid>5710</if_matched_sid>
    <description>[DEMO] SSH Brute Force terdeteksi - 5+ failed login dalam 2 menit</description>
    <group>authentication_failures,brute_force,</group>
  </rule>

  <rule id="100002" level="13" frequency="10" timeframe="120">
    <if_matched_sid>5710</if_matched_sid>
    <description>[DEMO] CRITICAL: Massive SSH Brute Force - 10+ failed login attempts</description>
    <group>authentication_failures,brute_force,</group>
  </rule>

  <!-- ========== WEB ATTACK CUSTOM ========== -->

  <rule id="100010" level="10">
    <if_group>web|accesslog</if_group>
    <url>select|union|insert|update|delete|drop|concat|char|0x</url>
    <description>[DEMO] SQL Injection terdeteksi di web request</description>
    <group>web,attack,sql_injection,</group>
  </rule>

  <rule id="100011" level="10">
    <if_group>web|accesslog</if_group>
    <url>script|alert|onerror|onload|javascript</url>
    <description>[DEMO] XSS (Cross-Site Scripting) terdeteksi di web request</description>
    <group>web,attack,xss,</group>
  </rule>

  <rule id="100012" level="10">
    <if_group>web|accesslog</if_group>
    <url>../|..\|/etc/passwd|/etc/shadow</url>
    <description>[DEMO] Directory Traversal terdeteksi - percobaan akses file sistem</description>
    <group>web,attack,path_traversal,</group>
  </rule>

  <!-- ========== FILE INTEGRITY CUSTOM ========== -->

  <rule id="100020" level="10">
    <if_sid>550</if_sid>
    <match>/etc/</match>
    <description>[DEMO] File konfigurasi penting diubah di /etc/</description>
    <group>syscheck,config_change,</group>
  </rule>

  <rule id="100021" level="12">
    <if_sid>550</if_sid>
    <match>/usr/bin/|/usr/sbin/|/bin/|/sbin/</match>
    <description>[DEMO] CRITICAL: File executable sistem dimodifikasi!</description>
    <group>syscheck,binary_change,</group>
  </rule>

  <!-- ========== PRIVILEGE ESCALATION CUSTOM ========== -->

  <rule id="100030" level="10" frequency="3" timeframe="120">
    <if_matched_sid>5401</if_matched_sid>
    <description>[DEMO] Privilege Escalation attempt - multiple sudo failures</description>
    <group>authentication_failures,privilege_escalation,</group>
  </rule>

  <rule id="100031" level="14">
    <if_sid>5901</if_sid>
    <match>uid=0</match>
    <description>[DEMO] CRITICAL: User baru dibuat dengan root privileges (UID 0)!</description>
    <group>adduser,privilege_escalation,</group>
  </rule>

  <!-- ========== SUSPICIOUS ACTIVITY ========== -->

  <rule id="100040" level="12">
    <if_group>syslog</if_group>
    <match>nc -l|ncat -l|netcat -l</match>
    <description>[DEMO] Suspicious: Netcat listener detected (potential backdoor)</description>
    <group>suspicious_activity,backdoor,</group>
  </rule>

  <rule id="100041" level="14">
    <if_group>syslog</if_group>
    <match>bash -i >& /dev/tcp|nc -e /bin|python -c 'import socket</match>
    <description>[DEMO] CRITICAL: Reverse shell attempt detected!</description>
    <group>suspicious_activity,reverse_shell,</group>
  </rule>

  <!-- ================================================================ -->
  <!--          SOAR - DDoS DETECTION & AUTOMATED RESPONSE              -->
  <!--  Group Task #1: Incorporate SOAR capabilities for DDoS           -->
  <!--  Rule ID: 100050 - 100055                                        -->
  <!-- ================================================================ -->

  <rule id="100050" level="10" frequency="8" timeframe="60">
    <if_group>syslog</if_group>
    <match>SYN flood|syn_flood|SYN_RECV</match>
    <description>[SOAR-DDoS] SYN Flood terdeteksi - 8+ events dalam 60 detik</description>
    <group>ddos,attack,soar,synflood,</group>
  </rule>

  <rule id="100051" level="10" frequency="15" timeframe="30">
    <if_group>web|accesslog|syslog</if_group>
    <match>flood|FLOOD|HTTP flood|connection flood</match>
    <description>[SOAR-DDoS] HTTP Flood terdeteksi - 15+ requests dalam 30 detik</description>
    <group>ddos,attack,soar,httpflood,</group>
  </rule>

  <rule id="100052" level="10" frequency="8" timeframe="60">
    <if_group>syslog</if_group>
    <match>UDP flood|udp_flood|UDP_FLOOD</match>
    <description>[SOAR-DDoS] UDP Flood terdeteksi - 8+ events dalam 60 detik</description>
    <group>ddos,attack,soar,udpflood,</group>
  </rule>

  <rule id="100053" level="10" frequency="10" timeframe="60">
    <if_group>syslog</if_group>
    <match>POSSIBLE DDoS|possible ddos|DDoS ATTACK|HIGH TRAFFIC ANOMALY</match>
    <description>[SOAR-DDoS] Connection Exhaustion / DDoS Pattern terdeteksi</description>
    <group>ddos,attack,soar,connection_exhaustion,</group>
  </rule>

  <rule id="100054" level="10" frequency="8" timeframe="60">
    <if_group>syslog</if_group>
    <match>ICMP flood|icmp_flood|ping flood|PING_FLOOD</match>
    <description>[SOAR-DDoS] ICMP Flood (Ping Flood) terdeteksi</description>
    <group>ddos,attack,soar,icmpflood,</group>
  </rule>

  <rule id="100055" level="14" frequency="5" timeframe="120">
    <if_matched_group>ddos</if_matched_group>
    <description>[SOAR-DDoS] CRITICAL: Massive DDoS Attack - multiple vectors detected! Auto-mitigation triggered.</description>
    <group>ddos,attack,soar,critical,</group>
  </rule>

</group>
RULES_EOF

echo "  [DONE] custom-rules.xml updated (17 rules total)"
echo ""

# ============================================================
# STEP 3: Upload Script Active Response DDoS
# ============================================================
echo "[3/5] Upload ddos-response.sh..."

cat > /var/ossec/active-response/bin/ddos-response.sh << 'SCRIPT_EOF'
#!/bin/bash
# SOAR - Active Response Script untuk DDoS Mitigation
# Otomatis dijalankan oleh Wazuh saat rule DDoS terpicu

LOCAL=$(dirname $0)
LOG_FILE="/var/ossec/logs/active-responses.log"
RULES_FILE="/etc/ddos-blocked-ips.txt"

# Telegram config (opsional)
TELEGRAM_BOT_TOKEN=""
TELEGRAM_CHAT_ID=""

log_action() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') | SOAR-DDoS | Action: ${1} | IP: ${2} | ${3}" >> ${LOG_FILE}
}

send_telegram() {
    if [ -n "${TELEGRAM_BOT_TOKEN}" ] && [ -n "${TELEGRAM_CHAT_ID}" ]; then
        curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
            -d chat_id="${TELEGRAM_CHAT_ID}" \
            -d text="🚨 SOAR-DDoS Alert
${1}
⏰ $(date '+%Y-%m-%d %H:%M:%S')
🖥️ Server: $(hostname)" \
            -d parse_mode="Markdown" > /dev/null 2>&1
    fi
}

block_ip() {
    local ip="$1"
    local timeout="$2"

    if iptables -L INPUT -n | grep -q "${ip}"; then
        log_action "SKIP" "${ip}" "IP sudah diblokir sebelumnya"
        return 0
    fi

    iptables -I INPUT -s "${ip}" -j DROP
    iptables -I FORWARD -s "${ip}" -j DROP
    echo "${ip} | blocked_at: $(date '+%Y-%m-%d %H:%M:%S') | timeout: ${timeout}s" >> ${RULES_FILE}
    log_action "BLOCK" "${ip}" "IP diblokir selama ${timeout} detik via iptables"

    send_telegram "🔒 *IP DIBLOKIR*
IP: \`${ip}\`
Alasan: DDoS Attack Detected
Durasi: ${timeout} detik"

    (
        sleep "${timeout}"
        iptables -D INPUT -s "${ip}" -j DROP 2>/dev/null
        iptables -D FORWARD -s "${ip}" -j DROP 2>/dev/null
        sed -i "/${ip}/d" ${RULES_FILE} 2>/dev/null
        log_action "UNBLOCK" "${ip}" "IP di-unblock setelah timeout ${timeout} detik"
        send_telegram "🔓 *IP DI-UNBLOCK*
IP: \`${ip}\`
Status: Timeout selesai"
    ) &
}

apply_rate_limit() {
    local ip="$1"
    iptables -I INPUT -s "${ip}" -p tcp --syn -m connlimit --connlimit-above 25 -j DROP 2>/dev/null
    iptables -I INPUT -s "${ip}" -m limit --limit 50/minute --limit-burst 100 -j ACCEPT 2>/dev/null
    log_action "RATE-LIMIT" "${ip}" "Rate limiting diterapkan: max 25 conn/min, 50 pkt/min"
}

global_mitigation() {
    echo 1 > /proc/sys/net/ipv4/tcp_syncookies 2>/dev/null
    echo 2 > /proc/sys/net/ipv4/tcp_synack_retries 2>/dev/null
    echo 30 > /proc/sys/net/ipv4/tcp_fin_timeout 2>/dev/null
    echo 65535 > /proc/sys/net/core/somaxconn 2>/dev/null
    echo 65535 > /proc/sys/net/ipv4/tcp_max_syn_backlog 2>/dev/null
    echo 1 > /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts 2>/dev/null
    echo 1 > /proc/sys/net/ipv4/conf/all/rp_filter 2>/dev/null
    log_action "GLOBAL" "ALL" "Global DDoS mitigation aktif (SYN cookies, rate limit, backlog tuning)"
    send_telegram "🛡️ *GLOBAL MITIGATION AKTIF*
SYN Cookies: ON
Backlog: 65535
Status: Mode pertahanan DDoS"
}

# MAIN — dipanggil oleh Wazuh Active Response
read INPUT_JSON

ACTION=$(echo "${INPUT_JSON}" | python3 -c "import sys,json; data=json.load(sys.stdin); print(data.get('command','add'))" 2>/dev/null || echo "add")
SRCIP=$(echo "${INPUT_JSON}" | python3 -c "import sys,json; data=json.load(sys.stdin); print(data.get('parameters',{}).get('alert',{}).get('data',{}).get('srcip','unknown'))" 2>/dev/null || echo "unknown")
RULE_ID=$(echo "${INPUT_JSON}" | python3 -c "import sys,json; data=json.load(sys.stdin); print(data.get('parameters',{}).get('alert',{}).get('rule',{}).get('id','0'))" 2>/dev/null || echo "0")
ALERT_LEVEL=$(echo "${INPUT_JSON}" | python3 -c "import sys,json; data=json.load(sys.stdin); print(data.get('parameters',{}).get('alert',{}).get('rule',{}).get('level','0'))" 2>/dev/null || echo "0")

if [ "${ACTION}" = "" ]; then ACTION=$1; SRCIP=$3; fi

TIMEOUT=600
log_action "TRIGGER" "${SRCIP}" "SOAR dipicu oleh Rule ID: ${RULE_ID}, Level: ${ALERT_LEVEL}, Action: ${ACTION}"

case "${ACTION}" in
    add)
        case "${RULE_ID}" in
            100055)
                TIMEOUT=1800
                block_ip "${SRCIP}" "${TIMEOUT}"
                apply_rate_limit "${SRCIP}"
                global_mitigation
                log_action "RESPONSE" "${SRCIP}" "CRITICAL: Block 30min + Rate Limit + Global Mitigation"
                ;;
            100050|100051|100052|100053|100054)
                TIMEOUT=600
                if [ "${SRCIP}" != "unknown" ] && [ "${SRCIP}" != "" ]; then
                    block_ip "${SRCIP}" "${TIMEOUT}"
                    apply_rate_limit "${SRCIP}"
                fi
                global_mitigation
                log_action "RESPONSE" "${SRCIP}" "MEDIUM: Block 10min + Rate Limit + Global Mitigation"
                ;;
            *)
                TIMEOUT=300
                if [ "${SRCIP}" != "unknown" ] && [ "${SRCIP}" != "" ]; then
                    block_ip "${SRCIP}" "${TIMEOUT}"
                fi
                log_action "RESPONSE" "${SRCIP}" "DEFAULT: Block 5min"
                ;;
        esac
        ;;
    delete)
        if [ "${SRCIP}" != "unknown" ] && [ "${SRCIP}" != "" ]; then
            iptables -D INPUT -s "${SRCIP}" -j DROP 2>/dev/null
            iptables -D FORWARD -s "${SRCIP}" -j DROP 2>/dev/null
            sed -i "/${SRCIP}/d" ${RULES_FILE} 2>/dev/null
            log_action "UNBLOCK" "${SRCIP}" "IP di-unblock via delete"
        fi
        ;;
esac

exit 0
SCRIPT_EOF

chmod 750 /var/ossec/active-response/bin/ddos-response.sh
chown root:wazuh /var/ossec/active-response/bin/ddos-response.sh

echo "  [DONE] ddos-response.sh uploaded + permissions set"
echo ""

# ============================================================
# STEP 4: Tambahkan SOAR config ke ossec.conf
# ============================================================
echo "[4/5] Tambahkan SOAR DDoS config ke ossec.conf..."

# Cek apakah sudah ada ddos-response di ossec.conf
if grep -q "ddos-response" /var/ossec/etc/ossec.conf; then
    echo "  [SKIP] SOAR DDoS config sudah ada di ossec.conf"
else
    # Tambahkan blok SOAR DDoS sebagai ossec_config baru di akhir file secara aman
    cat >> /var/ossec/etc/ossec.conf << 'SOAR_EOF'

<ossec_config>
  <command>
    <name>ddos-response</name>
    <executable>ddos-response.sh</executable>
    <timeout_allowed>yes</timeout_allowed>
  </command>

  <active-response>
    <disabled>no</disabled>
    <command>ddos-response</command>
    <location>local</location>
    <rules_id>100050</rules_id>
    <timeout>600</timeout>
  </active-response>

  <active-response>
    <disabled>no</disabled>
    <command>ddos-response</command>
    <location>local</location>
    <rules_id>100051</rules_id>
    <timeout>600</timeout>
  </active-response>

  <active-response>
    <disabled>no</disabled>
    <command>ddos-response</command>
    <location>local</location>
    <rules_id>100052</rules_id>
    <timeout>600</timeout>
  </active-response>

  <active-response>
    <disabled>no</disabled>
    <command>ddos-response</command>
    <location>local</location>
    <rules_id>100053</rules_id>
    <timeout>600</timeout>
  </active-response>

  <active-response>
    <disabled>no</disabled>
    <command>ddos-response</command>
    <location>local</location>
    <rules_id>100054</rules_id>
    <timeout>600</timeout>
  </active-response>

  <active-response>
    <disabled>no</disabled>
    <command>ddos-response</command>
    <location>local</location>
    <rules_id>100055</rules_id>
    <timeout>1800</timeout>
  </active-response>
</ossec_config>
SOAR_EOF
    echo "  [DONE] SOAR DDoS config ditambahkan ke ossec.conf"
fi

# ============================================================
# STEP 5: Test konfigurasi & restart Wazuh
# ============================================================
echo "[5/5] Test konfigurasi & restart Wazuh..."

echo "  Testing configuration..."
/var/ossec/bin/wazuh-analysisd -t
if [ $? -eq 0 ]; then
    echo "  Configuration OK. Restarting wazuh-manager..."
    systemctl restart wazuh-manager
    sleep 3
    if systemctl is-active --quiet wazuh-manager; then
        echo "  [DONE] Wazuh Manager successfully restarted and running!"
    else
        echo "  [ERROR] Wazuh Manager failed to start after restart!"
        systemctl status wazuh-manager
    fi
else
    echo "  [ERROR] Ada error di konfigurasi! Rollback ke backup..."
    cp /var/ossec/etc/ossec.conf.backup.$(date +%Y%m%d) /var/ossec/etc/ossec.conf
    cp /var/ossec/etc/rules/custom-rules.xml.backup.$(date +%Y%m%d) /var/ossec/etc/rules/custom-rules.xml
    /var/ossec/bin/wazuh-analysisd -t
fi

echo "================================================="
echo "  DEPLOY SELESAI!"
echo "================================================="