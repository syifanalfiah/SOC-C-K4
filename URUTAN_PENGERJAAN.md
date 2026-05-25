# 🗺️ ROADMAP / URUTAN PENGERJAAN TUGAS WAZUH

Jangan bingung dengan banyaknya file! Ikuti urutan langkah di bawah ini. Centang secara mental jika sudah kamu selesaikan.

---

### ✅ TAHAP 1: Setup Server Utama (Wazuh Manager)
*Status: **SUDAH SELESAI!*** 🎉
- **Yang sudah dilakukan:** Bikin server di Azure, buka port, dan install Wazuh Manager.
- **File panduan:** `docs/setup-manager.md`
- **Hasil:** Dashboard Wazuh bisa diakses 24 jam di `https://70.153.19.42`

---

### ✅ TAHAP 2: Menghubungkan Laptop ke Server (Setup Agent)
*Status: **SEDANG BERJALAN** (1 agent Mac sudah terhubung)*
- **Tujuan:** Install Wazuh Agent di laptop masing-masing anggota tim.
- **File panduan:** `docs/setup-agent.md`
- **Cara cek agent aktif di Dashboard:**
  1. Buka `https://70.153.19.42` -> login `admin`
  2. Klik menu **☰ (garis tiga)** -> **Wazuh** -> **Agents**
  3. Atau klik angka **Active** di halaman Home Overview

---

### ✅ TAHAP 3: Simulasi Serangan (Praktek Keamanan)
*Status: **SUDAH SELESAI!*** 🎉
- **Tujuan:** Membuktikan Wazuh bisa mendeteksi serangan secara real-time.
- **File panduan:** `docs/attack-simulation.md`
- **Script yang tersedia di folder `scripts/`:**
  - `attack-bruteforce.sh` — Simulasi SSH Brute Force (Agent 1)
  - `attack-web.sh` — Simulasi Web Attack SQLi/XSS (Agent 2)
  - `attack-fim.sh` — Simulasi File Integrity Monitoring (Agent 3)
  - `attack-rootkit.sh` — Simulasi Rootkit Detection (Agent 3)
  - `attack-malware.sh` — Simulasi Malware Detection (semua agent)
  - `attack-ddos.sh` — Simulasi DDoS Attack (Agent 3)
- **Cara Jalankan:** Copy salah satu script ke laptop agent, lalu `bash nama-script.sh`

---

### ✅ TAHAP 4: Integrasi Malware Detection Module ⭐ (Group Task sebelumnya)
*Status: **SUDAH SELESAI!*** 🎉
- **File panduan lengkap:** `docs/setup-malware.md`
- **Config:** `configs/manager/ossec.conf` (ada blok `<integration>` VirusTotal)
- **Script validasi:** `scripts/attack-malware.sh`

---

### ⏳ TAHAP 5: SOAR — Automated DDoS Response ⭐⭐ WAJIB (Group Task #1 BARU)
*Status: **FILE SUDAH SIAP, TINGGAL DEPLOY KE SERVER***

> **Requirement:** *"Incorporate SOAR capabilities to enable the automated detection and mitigation of DDoS attack vectors"*

**Apa yang sudah disiapkan:**
- ✅ Custom Rules DDoS (ID 100050-100055) → `rules/custom-rules.xml`
- ✅ Active Response config → `configs/manager/ossec.conf`
- ✅ Script auto-response → `scripts/active-response-ddos.sh`
- ✅ Script simulasi DDoS (update) → `scripts/attack-ddos.sh`
- ✅ Panduan lengkap → `docs/setup-soar.md` ← **BACA INI**

**Rangkuman langkah deploy ke server:**

**Di Azure Server (SSH ke 70.153.19.42):**
```bash
ssh wazuh-manager@70.153.19.42
sudo su

# 1. Upload custom rules baru
nano /var/ossec/etc/rules/custom-rules.xml
# → Copy-paste isi file rules/custom-rules.xml

# 2. Upload script active response
nano /var/ossec/active-response/bin/ddos-response.sh
# → Copy-paste isi file scripts/active-response-ddos.sh
chmod 750 /var/ossec/active-response/bin/ddos-response.sh
chown root:wazuh /var/ossec/active-response/bin/ddos-response.sh

# 3. Update ossec.conf
nano /var/ossec/etc/ossec.conf
# → Tambahkan blok SOAR DDoS (lihat configs/manager/ossec.conf)

# 4. Test & restart
/var/ossec/bin/wazuh-analysisd -t
systemctl restart wazuh-manager
```

**Di Laptop Agent (untuk validasi SOAR):**
```bash
# Jalankan simulasi DDoS yang sudah di-update
sudo bash attack-ddos.sh
```

**Verifikasi SOAR bekerja:**
```bash
# Di server — cek apakah IP otomatis diblokir
sudo iptables -L INPUT -n | grep DROP
sudo tail -20 /var/ossec/logs/active-responses.log
```

**Cek di Dashboard:**
- `https://70.153.19.42` -> **Security Events**
- Filter: `rule.groups: soar` atau `rule.id: 100050 OR rule.id: 100055`

---

### ⏳ TAHAP 5.5: Integrasi TheHive — Incident Response ⭐⭐ (Tambahan SOAR)
*Status: **FILE SUDAH SIAP, TINGGAL DEPLOY KE SERVER***

> **Tujuan:** Menghubungkan Wazuh dengan TheHive agar setiap alert DDoS (dan alert lainnya) otomatis menjadi Alert/Case di TheHive untuk diinvestigasi.

**Apa yang sudah disiapkan:**
- ✅ Script integrasi Python → `scripts/custom-w2thive.py`
- ✅ Wrapper script → `scripts/custom-w2thive`
- ✅ Config integrasi di ossec.conf → `configs/manager/ossec.conf`
- ✅ Script deploy otomatis → `scripts/deploy-thehive-manager.sh`
- ✅ Panduan lengkap → `docs/setup-thehive.md` ← **BACA INI**
- ✅ Landing page HTML (updated) → `index.html`

**Rangkuman langkah deploy TheHive ke server:**

**Di Azure Server (SSH ke 70.153.19.42):**
```bash
ssh wazuh-manager@70.153.19.42
sudo su

# Jalankan script deploy (atau copy-paste isi deploy-thehive-manager.sh)
# Script otomatis:
# 1. Install Docker
# 2. Install TheHive via Docker Compose
# 3. Install thehive4py
# 4. Upload script integrasi
# 5. Update ossec.conf
# 6. Restart Wazuh Manager
```

**Verifikasi:**
- TheHive Dashboard: `http://70.153.19.42:9000`
- Login: `admin@thehive.local` / `secret` (ganti segera!)
- Jalankan simulasi DDoS → cek alert muncul di TheHive

---

### ✅ TAHAP 6: Custom Rules & Finalisasi
*Status: **SUDAH SELESAI!*** 🎉
- **File yang dipakai:** `rules/custom-rules.xml`
- **Total custom rules:** 17 rules (11 lama + 6 rules DDoS SOAR baru)

---

### 📝 PANDUAN FILE:
| File | Fungsi |
|------|--------|
| `docs/setup-manager.md` | Setup Azure server (sudah selesai) |
| `docs/setup-agent.md` | Install agent di laptop |
| `docs/setup-malware.md` | Setup Malware Detection Module |
| `docs/setup-soar.md` | 🆕 **Setup SOAR DDoS (Group Task #1)** |
| `docs/setup-thehive.md` | 🆕 **Setup TheHive Incident Response** |
| `docs/attack-simulation.md` | Panduan semua simulasi serangan |
| `docs/architecture.md` | Arsitektur sistem untuk presentasi |
| `configs/manager/ossec.conf` | Config server (VirusTotal + SOAR DDoS + TheHive) |
| `configs/agent/ossec.conf` | Config laptop agent |
| `rules/custom-rules.xml` | Custom detection rules (17 rules) |
| `index.html` | 🔄 Landing page HTML (Wazuh + SOAR + TheHive) |
| `scripts/attack-ddos.sh` | 🔄 Script simulasi DDoS (updated + SOAR validation) |
| `scripts/active-response-ddos.sh` | 🆕 **Script auto-response SOAR DDoS** |
| `scripts/custom-w2thive.py` | 🆕 **Script integrasi Wazuh → TheHive** |
| `scripts/custom-w2thive` | 🆕 **Wrapper script integrasi TheHive** |
| `scripts/deploy-thehive-manager.sh` | 🆕 **Script deploy TheHive di server** |
| `scripts/attack-malware.sh` | Script simulasi malware |

