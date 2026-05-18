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

### ⏳ TAHAP 3: Simulasi Serangan (Praktek Keamanan)
*Status: Belum Dikerjakan*
- **Tujuan:** Membuktikan Wazuh bisa mendeteksi serangan secara real-time.
- **File panduan:** `docs/attack-simulation.md`
- **Script yang tersedia di folder `scripts/`:**
  - `attack-bruteforce.sh` — Simulasi SSH Brute Force (Agent 1)
  - `attack-web.sh` — Simulasi Web Attack SQLi/XSS (Agent 2)
  - `attack-fim.sh` — Simulasi File Integrity Monitoring (Agent 3)
  - `attack-rootkit.sh` — Simulasi Rootkit Detection (Agent 3)
  - `attack-malware.sh` — Simulasi Malware Detection 🆕 (semua agent)
- **Cara Jalankan:** Copy salah satu script ke laptop agent, lalu `bash nama-script.sh`

---

### ⏳ TAHAP 4: Integrasi Malware Detection Module ⭐ WAJIB (Group Task #1)
*Status: Config siap, tinggal diaktifkan*
- **Requirement:** *"Integrate the malware module into the SIEM system and conduct operational validation"*
- **File panduan lengkap:** `docs/setup-malware.md` ← **BACA INI**
- **Config yang sudah disiapkan:** `configs/manager/ossec.conf` (ada blok `<integration>` VirusTotal)
- **Script validasi:** `scripts/attack-malware.sh`

**Rangkuman singkat langkahnya:**

**Di Azure Server (SSH ke 70.153.19.42):**
```bash
ssh wazuh-manager@70.153.19.42
sudo su

# Tambahkan API key VirusTotal ke ossec.conf
nano /var/ossec/etc/ossec.conf
# -> Tambahkan blok <integration>...</integration> (lihat configs/manager/ossec.conf)
# -> Isi api_key dengan key dari https://www.virustotal.com

systemctl restart wazuh-manager
```

**Di Laptop Agent (untuk validasi):**
```bash
# Buat EICAR test file — ini yang akan terdeteksi sebagai malware
echo 'X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*' > /tmp/eicar-test.txt

# Atau jalankan script lengkap:
bash attack-malware.sh
```

**Cek hasilnya di Dashboard:**
- `https://70.153.19.42` -> **Modules** -> **Malware Detection**
- Filter: `rule.id: 87105` (alert VirusTotal)

---

### ⏳ TAHAP 5: Custom Rules & Finalisasi
*Status: Opsional / Nilai Plus*
- **Tujuan:** Memasang rule buatan sendiri agar alert tampil dengan label `[DEMO]`.
- **File yang dipakai:** `rules/custom-rules.xml`
- **Cara pasang (di Azure):**
```bash
sudo cp custom-rules.xml /var/ossec/etc/rules/
sudo systemctl restart wazuh-manager
```

---

### 📝 PANDUAN FILE:
| File | Fungsi |
|------|--------|
| `docs/setup-manager.md` | Setup Azure server (sudah selesai) |
| `docs/setup-agent.md` | Install agent di laptop |
| `docs/setup-malware.md` | 🆕 Setup Malware Detection Module |
| `docs/attack-simulation.md` | Panduan semua simulasi serangan |
| `docs/architecture.md` | Arsitektur sistem untuk presentasi |
| `configs/manager/ossec.conf` | Config server (sudah ada blok VirusTotal) |
| `configs/agent/ossec.conf` | Config laptop agent |
| `rules/custom-rules.xml` | Custom detection rules |
| `scripts/attack-malware.sh` | 🆕 Script simulasi malware |
