# Setup Wazuh Agent (Laptop)

## Agent Support

Wazuh Agent bisa diinstall di berbagai OS:
- **Linux** (Ubuntu, Debian, CentOS, Fedora)
- **Windows** (10, 11, Server)
- **macOS**

---

## Metode 1: Install via Dashboard (PALING MUDAH)

### Step 1: Login ke Wazuh Dashboard
1. Buka browser → `https://70.153.19.42:443`
2. Login dengan admin credentials

### Step 2: Deploy New Agent
1. Klik menu **Agents** (sidebar kiri)
2. Klik tombol **Deploy new agent**
3. Pilih OS laptop kamu
4. Masukkan IP VPS sebagai **Server address**
5. Dashboard akan generate command yang tinggal copy-paste

---

## Metode 2: Manual Install — Linux (Ubuntu/Debian)

### Step 1: Import GPG Key & Repository

```bash
# Import GPG key
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | sudo gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import && sudo chmod 644 /usr/share/keyrings/wazuh.gpg

# Add repository
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | sudo tee -a /etc/apt/sources.list.d/wazuh.list

# Update package list
sudo apt update
```

### Step 2: Install Agent

```bash
# Install wazuh-agent dengan manager IP
WAZUH_MANAGER="70.153.19.42" sudo apt install -y wazuh-agent
```

### Step 3: Konfigurasi Agent

Edit file konfigurasi agent:

```bash
sudo nano /var/ossec/etc/ossec.conf
```

Pastikan `<address>` mengarah ke IP VPS:

```xml
<ossec_config>
  <client>
    <server>
      <address>70.153.19.42</address>
      <port>1514</port>
      <protocol>tcp</protocol>
    </server>
    <enrollment>
      <enabled>yes</enabled>
      <manager_address>70.153.19.42</manager_address>
      <port>1515</port>
    </enrollment>
  </client>
</ossec_config>
```

### Step 4: Start Agent

```bash
# Reload daemon
sudo systemctl daemon-reload

# Enable auto-start
sudo systemctl enable wazuh-agent

# Start agent
sudo systemctl start wazuh-agent

# Cek status
sudo systemctl status wazuh-agent
```

---

## Metode 3: Manual Install — Windows

### Step 1: Download Installer

Download MSI installer dari:
```
https://packages.wazuh.com/4.x/windows/wazuh-agent-4.9.0-1.msi
```

### Step 2: Install via Command Prompt (Admin)

Buka **Command Prompt as Administrator**:

```cmd
wazuh-agent-4.9.0-1.msi /q WAZUH_MANAGER="70.153.19.42" WAZUH_REGISTRATION_SERVER="70.153.19.42"
```

Atau install via GUI:
1. Double-click file `.msi`
2. Ikuti wizard
3. Masukkan Manager IP: `70.153.19.42`

### Step 3: Start Agent (Windows)

```cmd
REM Start service
net start WazuhSvc

REM Atau via PowerShell
Start-Service -Name WazuhSvc
```

### Step 4: Verifikasi (Windows)

- Buka **Services** → cari **Wazuh Agent** → pastikan status **Running**
- Atau cek di PowerShell:
```powershell
Get-Service WazuhSvc
```

Konfigurasi Windows ada di:
```
C:\Program Files (x86)\ossec-agent\ossec.conf
```

---

## Metode 4: Manual Install — macOS

```bash
# Download package
curl -so wazuh-agent.pkg https://packages.wazuh.com/4.x/macos/wazuh-agent-4.9.0-1.intel64.pkg

# Install dengan manager IP
sudo launchctl setenv WAZUH_MANAGER "70.153.19.42" && sudo installer -pkg wazuh-agent.pkg -target /

# Start agent
sudo /Library/Ossec/bin/wazuh-control start
```

---

## Verifikasi Agent Terdaftar

### Dari sisi Manager (SSH ke VPS):

```bash
# List semua agent yang terdaftar
sudo /var/ossec/bin/agent_control -l

# Output contoh:
# ID: 001, Name: laptop-andi, IP: any, Status: Active
# ID: 002, Name: laptop-budi, IP: any, Status: Active
# ID: 003, Name: laptop-cici, IP: any, Status: Active
```

### Dari Dashboard:
1. Login Dashboard
2. Klik **Agents** di sidebar
3. Semua agent harus muncul dengan status **Active** (hijau)

---

## Konfigurasi Agent untuk Monitoring Spesifik

### Enable File Integrity Monitoring (FIM)

Edit `/var/ossec/etc/ossec.conf` di agent:

```xml
<syscheck>
  <disabled>no</disabled>
  <frequency>300</frequency>
  <scan_on_start>yes</scan_on_start>

  <!-- Monitor direktori penting -->
  <directories realtime="yes" check_all="yes">/etc</directories>
  <directories realtime="yes" check_all="yes">/home</directories>
  <directories realtime="yes" check_all="yes">/var/www</directories>
  <directories realtime="yes" check_all="yes">/tmp/test-fim</directories>

  <!-- Untuk Windows -->
  <!-- <directories realtime="yes" check_all="yes">C:\Users</directories> -->
  <!-- <directories realtime="yes" check_all="yes">C:\Windows\System32</directories> -->
</syscheck>
```

### Enable Log Collection

```xml
<localfile>
  <log_format>syslog</log_format>
  <location>/var/log/auth.log</location>
</localfile>

<localfile>
  <log_format>syslog</log_format>
  <location>/var/log/syslog</location>
</localfile>

<!-- Apache logs (jika install Apache) -->
<localfile>
  <log_format>apache</log_format>
  <location>/var/log/apache2/access.log</location>
</localfile>

<localfile>
  <log_format>apache</log_format>
  <location>/var/log/apache2/error.log</location>
</localfile>
```

### Setelah Edit Config, Restart Agent:

```bash
# Linux
sudo systemctl restart wazuh-agent

# Windows (Admin CMD)
net stop WazuhSvc && net start WazuhSvc

# macOS
sudo /Library/Ossec/bin/wazuh-control restart
```

---

## Troubleshooting Agent

### Agent tidak mau connect:

```bash
# Cek log agent
sudo tail -f /var/ossec/logs/ossec.log

# Cek koneksi ke manager
telnet 70.153.19.42 1514
telnet 70.153.19.42 1515

# Jika timeout, masalah di firewall VPS
```

### Agent status "Disconnected":

```bash
# Restart agent
sudo systemctl restart wazuh-agent

# Cek apakah manager IP benar di ossec.conf
grep -A5 "<server>" /var/ossec/etc/ossec.conf

# Cek apakah enrollment berhasil
sudo cat /var/ossec/etc/client.keys
# Harus ada entry — kalau kosong, enrollment gagal
```

### Agent enrollment gagal:

```bash
# Di agent: register manual
sudo /var/ossec/bin/agent-auth -m 70.153.19.42

# Di manager: cek auth log
sudo tail -f /var/ossec/logs/ossec.log | grep -i auth
```
