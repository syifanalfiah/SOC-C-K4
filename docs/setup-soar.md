# Setup SOAR — Automated DDoS Detection & Mitigation

> **Group Task #1:** Incorporate SOAR capabilities to enable the automated detection and mitigation of DDoS attack vectors.

---

## Apa Itu SOAR?

**SOAR = Security Orchestration, Automation, and Response**

| | SIEM (Sebelumnya) | SOAR (Yang Ditambahkan) |
|--|---|---|
| **Deteksi** | ✅ Ya | ✅ Ya |
| **Alert** | ✅ Ya | ✅ Ya |
| **Respons Otomatis** | ❌ Tidak | ✅ Ya! |
| **Contoh** | "Ada DDoS!" | "Ada DDoS → IP diblokir otomatis + notifikasi Telegram" |

### Komponen SOAR yang Diimplementasikan:

```
┌─────────────────────────────────────────────────────────────┐
│                    SOAR WORKFLOW                             │
│                                                             │
│  ┌──────────┐    ┌──────────────┐    ┌──────────────────┐  │
│  │ DETECTION │───▶│ ORCHESTRATION│───▶│ AUTOMATED        │  │
│  │           │    │              │    │ RESPONSE          │  │
│  │ Custom    │    │ Wazuh Active │    │                   │  │
│  │ Rules     │    │ Response     │    │ • Block IP        │  │
│  │ 100050-   │    │ Engine       │    │ • Rate Limiting   │  │
│  │ 100055    │    │              │    │ • SYN Cookies     │  │
│  │           │    │              │    │ • Telegram Alert  │  │
│  └──────────┘    └──────────────┘    └──────────────────┘  │
│                                                             │
│  Detection ──▶ Orchestration ──▶ Response                   │
│  (D)            (O)               (R) + Automation (A)      │
│                                    = S.O.A.R                │
└─────────────────────────────────────────────────────────────┘
```

---

## Arsitektur SOAR DDoS

```
                    SERANGAN DDoS
                         │
                         ▼
              ┌─────────────────────┐
              │   Wazuh Agent       │
              │   (di laptop)       │
              │                     │
              │   Kirim log ke      │
              │   Manager           │
              └──────────┬──────────┘
                         │ TCP 1514
                         ▼
              ┌─────────────────────┐
              │   Wazuh Manager     │
              │   (Azure Server)    │
              │                     │
              │   ┌───────────────┐ │
              │   │ Rule Matching │ │
              │   │ ID: 100050-55 │ │  ◄── DETECTION
              │   └───────┬───────┘ │
              │           │         │
              │   ┌───────▼───────┐ │
              │   │ Active        │ │
              │   │ Response      │ │  ◄── ORCHESTRATION
              │   │ Engine        │ │
              │   └───────┬───────┘ │
              │           │         │
              │   ┌───────▼───────┐ │
              │   │ ddos-response │ │
              │   │ .sh           │ │  ◄── AUTOMATION + RESPONSE
              │   │               │ │
              │   │ • iptables    │ │
              │   │   block IP    │ │
              │   │ • rate-limit  │ │
              │   │ • SYN cookies │ │
              │   │ • Telegram    │ │
              │   │   notif       │ │
              │   └───────────────┘ │
              └─────────────────────┘
                         │
              ┌──────────┼──────────┐
              ▼          ▼          ▼
         IP Diblokir  Rate-limit  Notifikasi
         (iptables)   Diterapkan  Telegram
```

---

## Step-by-Step Setup di Server Azure

### Step 1: Upload Custom Rules

```bash
# SSH ke server
ssh wazuh-manager@70.153.19.42
sudo su

# Backup rules lama
cp /var/ossec/etc/rules/custom-rules.xml /var/ossec/etc/rules/custom-rules.xml.backup

# Upload rules baru (dari repo, file rules/custom-rules.xml)
# Copy-paste isi file rules/custom-rules.xml ke:
nano /var/ossec/etc/rules/custom-rules.xml
```

**Rules DDoS yang ditambahkan:**

| Rule ID | Level | Deteksi Apa | Threshold |
|---------|-------|-------------|-----------|
| 100050 | 10 | SYN Flood | 8 events / 60 detik |
| 100051 | 10 | HTTP Flood | 15 events / 30 detik |
| 100052 | 10 | UDP Flood | 8 events / 60 detik |
| 100053 | 10 | Connection Exhaustion / DDoS Pattern | 10 events / 60 detik |
| 100054 | 10 | ICMP Flood (Ping) | 8 events / 60 detik |
| 100055 | 14 | **CRITICAL: Massive DDoS** (multi-vector) | 5 DDoS events / 120 detik |

---

### Step 2: Upload Script Active Response

```bash
# Buat script di lokasi Active Response Wazuh
nano /var/ossec/active-response/bin/ddos-response.sh

# Copy-paste isi file scripts/active-response-ddos.sh

# Set permissions (WAJIB!)
chmod 750 /var/ossec/active-response/bin/ddos-response.sh
chown root:wazuh /var/ossec/active-response/bin/ddos-response.sh
```

---

### Step 3: Update ossec.conf (Tambah Active Response DDoS)

```bash
nano /var/ossec/etc/ossec.conf
```

Tambahkan **sebelum** tag `</ossec_config>`:

```xml
  <!-- ============================================================ -->
  <!-- SOAR - DDoS Automated Response                               -->
  <!-- Ini adalah "otak" SOAR: menghubungkan rules DDoS ke script   -->
  <!-- ============================================================ -->

  <!-- Command: definisi script yang akan dijalankan -->
  <command>
    <name>ddos-response</name>
    <executable>ddos-response.sh</executable>
    <timeout_allowed>yes</timeout_allowed>
  </command>

  <!-- Active Response: SYN Flood (Rule 100050) -->
  <active-response>
    <disabled>no</disabled>
    <command>ddos-response</command>
    <location>local</location>
    <rules_id>100050</rules_id>
    <timeout>600</timeout>
  </active-response>

  <!-- Active Response: HTTP Flood (Rule 100051) -->
  <active-response>
    <disabled>no</disabled>
    <command>ddos-response</command>
    <location>local</location>
    <rules_id>100051</rules_id>
    <timeout>600</timeout>
  </active-response>

  <!-- Active Response: UDP Flood (Rule 100052) -->
  <active-response>
    <disabled>no</disabled>
    <command>ddos-response</command>
    <location>local</location>
    <rules_id>100052</rules_id>
    <timeout>600</timeout>
  </active-response>

  <!-- Active Response: Connection Exhaustion (Rule 100053) -->
  <active-response>
    <disabled>no</disabled>
    <command>ddos-response</command>
    <location>local</location>
    <rules_id>100053</rules_id>
    <timeout>600</timeout>
  </active-response>

  <!-- Active Response: ICMP Flood (Rule 100054) -->
  <active-response>
    <disabled>no</disabled>
    <command>ddos-response</command>
    <location>local</location>
    <rules_id>100054</rules_id>
    <timeout>600</timeout>
  </active-response>

  <!-- Active Response: CRITICAL Massive DDoS (Rule 100055) -->
  <active-response>
    <disabled>no</disabled>
    <command>ddos-response</command>
    <location>local</location>
    <rules_id>100055</rules_id>
    <timeout>1800</timeout>
  </active-response>
```

---

### Step 4: (Opsional) Setup Notifikasi Telegram

Jika ingin SOAR kirim notifikasi ke Telegram saat DDoS terdeteksi:

```bash
# Edit script active response
nano /var/ossec/active-response/bin/ddos-response.sh

# Cari baris ini dan isi:
TELEGRAM_BOT_TOKEN="ISI_TOKEN_BOT_DISINI"
TELEGRAM_CHAT_ID="ISI_CHAT_ID_DISINI"
```

Cara mendapatkan token dan chat ID:
1. Buka Telegram → cari `@BotFather`
2. Kirim `/newbot` → ikuti instruksi → dapat token
3. Kirim pesan ke bot → buka `https://api.telegram.org/bot<TOKEN>/getUpdates` → dapat chat_id

---

### Step 5: Restart Wazuh Manager

```bash
# Test konfigurasi dulu (pastikan tidak ada error)
/var/ossec/bin/wazuh-analysisd -t

# Jika OK, restart
systemctl restart wazuh-manager

# Cek status
systemctl status wazuh-manager
```

---

### Step 6: Validasi — Jalankan Simulasi DDoS

```bash
# Di laptop agent (BUKAN di server), jalankan:
sudo bash scripts/attack-ddos.sh
```

**Yang seharusnya terjadi (alur SOAR):**
1. ✅ Script kirim flood ke server
2. ✅ Agent mengirim log ke Manager
3. ✅ Manager cocokkan dengan Rule 100050-100055
4. ✅ Rule terpicu → Active Response dijalankan
5. ✅ Script `ddos-response.sh` otomatis:
   - Blokir IP penyerang via iptables
   - Terapkan rate-limiting
   - Aktifkan SYN cookies
   - Kirim notifikasi Telegram
6. ✅ Alert muncul di Dashboard

---

### Step 7: Verifikasi SOAR Bekerja

```bash
# Di server, cek log active response
sudo tail -f /var/ossec/logs/active-responses.log

# Cek IP yang diblokir
sudo iptables -L INPUT -n | grep DROP

# Cek file tracking
cat /etc/ddos-blocked-ips.txt

# Cek SYN cookies aktif
cat /proc/sys/net/ipv4/tcp_syncookies
```

**Di Dashboard:**
```
Security Events → filter:
rule.groups: ddos AND rule.groups: soar
```

Atau filter spesifik:
```
rule.id: 100050 OR rule.id: 100051 OR rule.id: 100052 OR rule.id: 100053 OR rule.id: 100054 OR rule.id: 100055
```

---

## Troubleshooting

### Rules tidak terpicu?
```bash
# Cek apakah rules ter-load
/var/ossec/bin/wazuh-analysisd -t
# Lihat output — pastikan tidak ada error di custom-rules.xml

# Cek log real-time
tail -f /var/ossec/logs/ossec.log | grep -i "ddos\|100050\|100051\|100052\|100053\|100054\|100055"
```

### Active Response tidak jalan?
```bash
# Cek apakah script executable
ls -la /var/ossec/active-response/bin/ddos-response.sh

# Test manual
echo '{"command":"add","parameters":{"alert":{"data":{"srcip":"192.168.1.100"},"rule":{"id":"100050","level":"10"}}}}' | /var/ossec/active-response/bin/ddos-response.sh

# Cek log
tail -f /var/ossec/logs/active-responses.log
```

### IP tidak ke-block?
```bash
# Pastikan iptables tersedia
which iptables

# Cek rules iptables
iptables -L -n -v
```

---

## Catatan Penting

> **Wazuh adalah Host-Based IDS (HIDS)**, bukan Network-Based IDS.
> Artinya, DDoS detection bergantung pada **log yang dihasilkan** oleh sistem/aplikasi,
> bukan langsung dari network traffic.
>
> Dalam implementasi ini, kita menggunakan:
> - Log injection via `logger` (untuk simulasi)
> - Log dari aplikasi (Apache, kernel) yang mendeteksi anomali
>
> Untuk production-grade DDoS detection, idealnya diintegrasikan dengan
> network-based IDS seperti **Suricata** atau **Snort**.
