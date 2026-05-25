#!/bin/bash
# ================================================================
# SOAR - Active Response Script untuk DDoS Mitigation
# ================================================================
#
# Script ini OTOMATIS dijalankan oleh Wazuh Manager ketika
# rule DDoS (100050-100055) terpicu.
#
# Apa yang dilakukan script ini (SOAR = automated response):
# 1. Blokir IP penyerang menggunakan iptables
# 2. Terapkan rate-limiting untuk mencegah flood
# 3. Log semua aksi ke file untuk audit trail
# 4. Kirim notifikasi ke Telegram (opsional)
#
# Lokasi di server: /var/ossec/active-response/bin/ddos-response.sh
# Permissions: chmod 750, chown root:wazuh
# ================================================================

LOCAL=$(dirname $0)
LOCK_FILE="/tmp/ddos-response-lock"
LOG_FILE="/var/ossec/logs/active-responses.log"
RULES_FILE="/etc/ddos-blocked-ips.txt"

# Telegram config (opsional — isi jika mau notifikasi)
TELEGRAM_BOT_TOKEN=""
TELEGRAM_CHAT_ID=""

# ============================================================
# Fungsi: Log aksi ke file
# ============================================================
log_action() {
    local action="$1"
    local ip="$2"
    local detail="$3"
    echo "$(date '+%Y-%m-%d %H:%M:%S') | SOAR-DDoS | Action: ${action} | IP: ${ip} | ${detail}" >> ${LOG_FILE}
}

# ============================================================
# Fungsi: Kirim notifikasi Telegram
# ============================================================
send_telegram() {
    local message="$1"
    if [ -n "${TELEGRAM_BOT_TOKEN}" ] && [ -n "${TELEGRAM_CHAT_ID}" ]; then
        curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
            -d chat_id="${TELEGRAM_CHAT_ID}" \
            -d text="🚨 SOAR-DDoS Alert

${message}

⏰ $(date '+%Y-%m-%d %H:%M:%S')
🖥️ Server: $(hostname)" \
            -d parse_mode="Markdown" > /dev/null 2>&1
    fi
}

# ============================================================
# Fungsi: Blokir IP menggunakan iptables
# ============================================================
block_ip() {
    local ip="$1"
    local timeout="$2"

    # Cek apakah IP sudah diblokir sebelumnya
    if iptables -L INPUT -n | grep -q "${ip}"; then
        log_action "SKIP" "${ip}" "IP sudah diblokir sebelumnya"
        return 0
    fi

    # Blokir IP — DROP semua paket dari IP ini
    iptables -I INPUT -s "${ip}" -j DROP
    iptables -I FORWARD -s "${ip}" -j DROP

    # Simpan IP ke file (untuk tracking)
    echo "${ip} | blocked_at: $(date '+%Y-%m-%d %H:%M:%S') | timeout: ${timeout}s" >> ${RULES_FILE}

    log_action "BLOCK" "${ip}" "IP diblokir selama ${timeout} detik via iptables"

    # Kirim notifikasi Telegram
    send_telegram "🔒 *IP DIBLOKIR*
IP: \`${ip}\`
Alasan: DDoS Attack Detected
Durasi: ${timeout} detik
Rule: SOAR Auto-Response"

    # Schedule unblock setelah timeout
    (
        sleep "${timeout}"
        iptables -D INPUT -s "${ip}" -j DROP 2>/dev/null
        iptables -D FORWARD -s "${ip}" -j DROP 2>/dev/null
        sed -i "/${ip}/d" ${RULES_FILE} 2>/dev/null
        log_action "UNBLOCK" "${ip}" "IP di-unblock setelah timeout ${timeout} detik"
        send_telegram "🔓 *IP DI-UNBLOCK*
IP: \`${ip}\`
Status: Timeout ${timeout} detik selesai"
    ) &
}

# ============================================================
# Fungsi: Terapkan rate-limiting
# ============================================================
apply_rate_limit() {
    local ip="$1"

    # Rate limit: maksimal 25 koneksi baru per menit dari 1 IP
    iptables -I INPUT -s "${ip}" -p tcp --syn -m connlimit --connlimit-above 25 -j DROP 2>/dev/null

    # Rate limit: maksimal 50 paket per menit (anti-flood)
    iptables -I INPUT -s "${ip}" -m limit --limit 50/minute --limit-burst 100 -j ACCEPT 2>/dev/null

    log_action "RATE-LIMIT" "${ip}" "Rate limiting diterapkan: max 25 conn/min, 50 pkt/min"
}

# ============================================================
# Fungsi: DDoS global mitigation (tanpa IP spesifik)
# ============================================================
global_mitigation() {
    # Anti SYN Flood — aktifkan SYN cookies
    echo 1 > /proc/sys/net/ipv4/tcp_syncookies 2>/dev/null

    # Kurangi SYN-ACK retries (default 5, turunkan ke 2)
    echo 2 > /proc/sys/net/ipv4/tcp_synack_retries 2>/dev/null

    # Kurangi timeout SYN_RECV
    echo 30 > /proc/sys/net/ipv4/tcp_fin_timeout 2>/dev/null

    # Naikkan backlog queue
    echo 65535 > /proc/sys/net/core/somaxconn 2>/dev/null
    echo 65535 > /proc/sys/net/ipv4/tcp_max_syn_backlog 2>/dev/null

    # Drop ICMP broadcast (anti Smurf attack)
    echo 1 > /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts 2>/dev/null

    # Aktifkan reverse path filtering
    echo 1 > /proc/sys/net/ipv4/conf/all/rp_filter 2>/dev/null

    log_action "GLOBAL" "ALL" "Global DDoS mitigation diterapkan (SYN cookies, rate limit, backlog tuning)"

    send_telegram "🛡️ *GLOBAL MITIGATION AKTIF*
SYN Cookies: ON
SYN-ACK Retries: 2
Backlog: 65535
ICMP Broadcast: Blocked
Status: Server dalam mode pertahanan DDoS"
}

# ============================================================
# MAIN — Entry point (dipanggil oleh Wazuh Active Response)
# ============================================================
# Wazuh Active Response memanggil script dengan format:
# $1 = action (add/delete)
# $2 = user (-)
# $3 = srcip (IP penyerang)
# $4 = alert ID
# (Wazuh 4.x format menggunakan stdin JSON)

# Baca input dari Wazuh (format JSON via stdin)
read INPUT_JSON

ACTION=$(echo "${INPUT_JSON}" | python3 -c "import sys,json; data=json.load(sys.stdin); print(data.get('command','add'))" 2>/dev/null || echo "add")
SRCIP=$(echo "${INPUT_JSON}" | python3 -c "import sys,json; data=json.load(sys.stdin); print(data.get('parameters',{}).get('alert',{}).get('data',{}).get('srcip','unknown'))" 2>/dev/null || echo "unknown")
RULE_ID=$(echo "${INPUT_JSON}" | python3 -c "import sys,json; data=json.load(sys.stdin); print(data.get('parameters',{}).get('alert',{}).get('rule',{}).get('id','0'))" 2>/dev/null || echo "0")
ALERT_LEVEL=$(echo "${INPUT_JSON}" | python3 -c "import sys,json; data=json.load(sys.stdin); print(data.get('parameters',{}).get('alert',{}).get('rule',{}).get('level','0'))" 2>/dev/null || echo "0")

# Fallback: jika tidak bisa parse JSON, gunakan argumen posisi
if [ "${ACTION}" = "" ]; then
    ACTION=$1
    SRCIP=$3
fi

TIMEOUT=600  # Default: blokir 10 menit

log_action "TRIGGER" "${SRCIP}" "SOAR dipicu oleh Rule ID: ${RULE_ID}, Level: ${ALERT_LEVEL}, Action: ${ACTION}"

case "${ACTION}" in
    add)
        # Tentukan severity berdasarkan rule
        case "${RULE_ID}" in
            100055)
                # CRITICAL: Massive DDoS — blokir 30 menit + global mitigation
                TIMEOUT=1800
                block_ip "${SRCIP}" "${TIMEOUT}"
                apply_rate_limit "${SRCIP}"
                global_mitigation
                log_action "RESPONSE" "${SRCIP}" "CRITICAL response: Block 30min + Rate Limit + Global Mitigation"
                ;;
            100050|100051|100052|100053|100054)
                # MEDIUM: Single-vector DDoS — blokir 10 menit + rate limit
                TIMEOUT=600
                if [ "${SRCIP}" != "unknown" ] && [ "${SRCIP}" != "" ]; then
                    block_ip "${SRCIP}" "${TIMEOUT}"
                    apply_rate_limit "${SRCIP}"
                fi
                global_mitigation
                log_action "RESPONSE" "${SRCIP}" "MEDIUM response: Block 10min + Rate Limit + Global Mitigation"
                ;;
            *)
                # DEFAULT: rule lain — blokir 5 menit saja
                TIMEOUT=300
                if [ "${SRCIP}" != "unknown" ] && [ "${SRCIP}" != "" ]; then
                    block_ip "${SRCIP}" "${TIMEOUT}"
                fi
                log_action "RESPONSE" "${SRCIP}" "DEFAULT response: Block 5min"
                ;;
        esac
        ;;
    delete)
        # Unblock IP (dipanggil saat timeout Active Response Wazuh habis)
        if [ "${SRCIP}" != "unknown" ] && [ "${SRCIP}" != "" ]; then
            iptables -D INPUT -s "${SRCIP}" -j DROP 2>/dev/null
            iptables -D FORWARD -s "${SRCIP}" -j DROP 2>/dev/null
            sed -i "/${SRCIP}/d" ${RULES_FILE} 2>/dev/null
            log_action "UNBLOCK" "${SRCIP}" "IP di-unblock via Wazuh Active Response delete"
        fi
        ;;
esac

exit 0
