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
