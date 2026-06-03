# Arsitektur & Alur Sistem Wazuh SIEM

## 1. Apa Itu Wazuh?

Wazuh adalah platform keamanan open-source yang menyediakan:
- **Intrusion Detection (IDS)** — Deteksi serangan dan aktivitas mencurigakan
- **Log Analysis** — Analisis log sistem secara real-time
- **File Integrity Monitoring (FIM)** — Deteksi perubahan file penting
- **Vulnerability Detection** — Identifikasi kerentanan sistem
- **Security Configuration Assessment (SCA)** — Audit konfigurasi keamanan

---

## 2. Arsitektur Sistem

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
│  │  │              │  │  Menyimpan   │  │  Monitoring Alert    │ │  │
│  │  │ Menerima log │  │  & indexing  │  │                      │ │  │
│  │  │ dari agent   │  │  alert data  │  │                      │ │  │
│  │  └──────┬───────┘  └──────┬───────┘  └──────────────────────┘ │  │
│  │         │                 │                                    │  │
│  └─────────┼─────────────────┼────────────────────────────────────┘  │
│            │                 │                                       │
└────────────┼─────────────────┼───────────────────────────────────────┘
             │                 │
    Port 1514/1515 (TCP)       │
             │                 │
    ┌────────┼─────────────────┼────────────────────┐
    │        │                 │                    │
    ▼        ▼                 ▼                    ▼
┌────────┐ ┌────────┐ ┌────────┐
│ AGENT 1│ │ AGENT 2│ │ AGENT 3│
│        │ │        │ │        │
│Laptop 1│ │Laptop 2│ │Laptop 3│
│(Linux/ │ │(Linux/ │ │(Linux/ │
│Windows)│ │Windows)│ │Windows)│
│        │ │        │ │        │
│Simulasi│ │Simulasi│ │Simulasi│
│Brute   │ │Web     │ │File    │
│Force   │ │Attack  │ │Integr. │
└────────┘ └────────┘ └────────┘
```

### Penjelasan Komponen:

| Komponen | Fungsi | Port |
|----------|--------|------|
| **Wazuh Manager** | Otak sistem: menerima, menganalisis, dan memproses log dari semua agent | 1514 (event), 1515 (enrollment) |
| **Wazuh Indexer** | Database (OpenSearch) untuk menyimpan alert & log yang sudah diproses | 9200 |
| **Wazuh Dashboard** | Web UI untuk visualisasi, monitoring, dan manajemen alert | 443 (HTTPS) |
| **Wazuh Agent** | Software di setiap laptop yang mengumpulkan log & mengirim ke manager | - |

---

## 3. Alur Kerja Sistem (Data Flow)

```
STEP 1: Agent Mengumpulkan Data
   │
   │  Agent membaca:
   │  - System logs (/var/log/syslog, /var/log/auth.log)
   │  - Application logs (Apache, Nginx, dll)
   │  - File changes (FIM)
   │  - Running processes
   │  - Network connections
   │
   ▼
STEP 2: Agent Mengirim ke Manager
   │
   │  Data dikirim via TCP port 1514
   │  (terenkripsi AES)
   │
   ▼
STEP 3: Manager Menganalisis
   │
   │  Manager melakukan:
   │  - Rule matching (cocokkan dengan ruleset)
   │  - Correlation (hubungkan event terkait)
   │  - Decoding (parsing format log)
   │  - Alert generation (buat alert jika match)
   │
   ▼
STEP 4: Alert Disimpan ke Indexer
   │
   │  Alert dikirim ke Wazuh Indexer (OpenSearch)
   │  untuk di-index dan disimpan
   │
   ▼
STEP 5: Dashboard Menampilkan
   │
   │  Wazuh Dashboard menampilkan:
   │  - Real-time alerts
   │  - Security events timeline
   │  - Agent status
   │  - Threat intelligence
   │  - Compliance reports
   │
   ▼
STEP 6: SOC/Admin Merespon
      Admin melihat alert di dashboard,
      melakukan investigasi & response
```

---

## 4. Pembagian Peran Tim (4 Orang)

| Anggota | Peran | Tugas |
|---------|-------|-------|
| **Syifa Nurul Alfiah** | Manager / SOC Analyst | Setup cloud (Azure for Students), install Manager, config rules, TheHive integration |
| **Putri Joselina Silitonga** | Agent 1 / Attacker (macOS) | Install agent di laptop, simulasi **Brute Force SSH** & **Privilege Escalation** |
| **Salsa Bil Ulla** | Agent 2 / Attacker (Windows) | Install agent di laptop, simulasi **Web Attack (SQL Injection, XSS)** & **Windows Service** |
| **Revalina Erica Permatasari** | Agent 3 / Attacker (Kali Linux) | Install agent di laptop, simulasi **File Integrity Monitoring**, **Rootkit**, & **DDoS Attack (SOAR)** |

> **Catatan**: Semua 4 laptop tetap bisa dipakai flexible. Manager di cloud, jadi siapapun bisa akses dashboard dari browser.

---

## 5. Topologi Jaringan

```
                    ┌─────────────────────┐
                    │   INTERNET / CLOUD   │
                    │                     │
                    │  ┌───────────────┐  │
                    │  │  VPS Server   │  │
                    │  │               │  │
                    │  │ Wazuh Manager │  │
                    │  │ IP: x.x.x.x  │  │
                    │  └───────┬───────┘  │
                    │          │          │
                    └──────────┼──────────┘
                               │
                    ┌──────────┼──────────┐
                    │          │          │
              ┌─────┴────┐ ┌──┴──────┐ ┌─┴────────┐
              │ Laptop A  │ │Laptop B │ │ Laptop C │
              │ Agent 001 │ │Agent 002│ │ Agent 003│
              │ WiFi/LAN  │ │WiFi/LAN │ │ WiFi/LAN │
              └───────────┘ └─────────┘ └──────────┘
```

### Requirement Jaringan:
- Azure Virtual Machine harus bisa diakses dari internet (public IP)
- Laptop agent harus bisa akses internet untuk connect ke VPS Azure
- Network Security Group (NSG) Azure harus buka port: **1514, 1515, 443, 9200**
- Bisa pakai WiFi kampus / hotspot HP
