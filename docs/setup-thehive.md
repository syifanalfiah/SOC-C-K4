# Setup TheHive 5 — Security Incident Response Platform

> **Tujuan:** Mengintegrasikan TheHive dengan Wazuh agar setiap alert DDoS (dan alert lainnya) otomatis menjadi Alert/Case di TheHive untuk diinvestigasi tim SOC.

---

## Apa Itu TheHive?

**TheHive** adalah platform open-source untuk **Incident Response** dan **Case Management**. Ketika digabungkan dengan Wazuh:

| | Wazuh Saja | Wazuh + TheHive |
|--|---|---|
| **Deteksi** | ✅ Ya | ✅ Ya |
| **Automated Response** | ✅ Ya (SOAR) | ✅ Ya (SOAR) |
| **Case Management** | ❌ Tidak | ✅ Ya! |
| **Kolaborasi Tim** | ❌ Terbatas | ✅ Ya! |
| **Workflow Investigasi** | ❌ Tidak | ✅ Ya! |

### Arsitektur Setelah Integrasi

```
                     SERANGAN (DDoS, Brute Force, dll)
                              │
                              ▼
                    ┌─────────────────────┐
                    │   Wazuh Agent       │
                    │   (di laptop)       │
                    └──────────┬──────────┘
                               │ TCP 1514
                               ▼
                    ┌─────────────────────┐
                    │   Wazuh Manager     │
                    │   (Azure Server)    │
                    │                     │
                    │   Rule Matching     │
                    │   ┌─────┴─────┐     │
                    │   │           │     │
                    │   ▼           ▼     │
                    │ Active     TheHive  │
                    │ Response   Integration
                    │ (blokir    (buat     │
                    │  IP)       Alert)    │
                    └─────┬────────┬──────┘
                          │        │
                    ┌─────▼──┐ ┌──▼──────────────┐
                    │iptables│ │  TheHive 5       │
                    │ BLOCK  │ │  (Docker)        │
                    │        │ │  Port 9000       │
                    └────────┘ │                  │
                               │  • Alert/Case    │
                               │  • Investigasi   │
                               │  • Kolaborasi    │
                               └──────────────────┘
```

---

## Prerequisites

Sebelum mulai, pastikan:
1. Sudah SSH ke VPS Azure (70.153.19.42)
2. Sudah jadi root (`sudo su`)
3. Port **9000** sudah dibuka di Azure Networking

### Buka Port 9000 di Azure

1. Buka [Azure Portal](https://portal.azure.com/) → Virtual Machine → Wazuh-Manager
2. Menu kiri → **Settings** → **Networking**
3. Klik **+ Add inbound port rule**
4. Isi:
   - **Destination port ranges:** `9000`
   - **Protocol:** `TCP`
   - **Action:** `Allow`
   - **Name:** `TheHive-Port`
5. Klik **Add**

---

## Step 1: Install Docker & Docker Compose

```bash
# SSH ke server
ssh wazuh-manager@70.153.19.42
sudo su

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Install Docker Compose plugin
apt-get install -y docker-compose-plugin jq

# Verifikasi
docker --version
docker compose version
```

---

## Step 2: Install TheHive 5 via Docker Compose

```bash
# Buat direktori untuk TheHive
mkdir -p /opt/thehive
cd /opt/thehive

# Clone repo resmi StrangeBee
git clone https://github.com/StrangeBeeCorp/docker.git
cd docker

# Jalankan init script
./init.sh

# Start TheHive
docker compose up -d

# Cek status container
docker ps
```

**Output yang diharapkan:**
```
CONTAINER ID   IMAGE              STATUS         PORTS
xxxxxxxxxxxx   strangebee/thehive Up 2 minutes   0.0.0.0:9000->9000/tcp
```

---

## Step 3: Login Pertama Kali ke TheHive

1. Buka browser: `http://70.153.19.42:9000`
2. Login dengan default credentials:
   - **Username:** `analyst@thehive.local`
   - **Password:** `secret`
3. **SEGERA ganti password!**
   - Klik profil (kanan atas) → Change Password

---

## Step 4: Buat API Key untuk Integrasi Wazuh

1. Di TheHive, klik **⚙️ Admin** (sidebar) → **Users**
2. Klik user `analyst@thehive.local` (atau buat user khusus `wazuh-integration`)
3. Scroll ke bagian **API Key**
4. Klik **Create** / **Renew** API Key
5. **Copy API Key** — simpan baik-baik! (dipakai di Step 5)

---

## Step 5: Install Library Python & Tulis Script Integrasi

```bash
# Install thehive4py di Python Wazuh
/var/ossec/framework/python/bin/pip3 install thehive4py==1.8.1

# Tulis script Python ke /var/ossec/integrations/custom-w2thive.py
cat << 'EOF' > /var/ossec/integrations/custom-w2thive.py
#!/var/ossec/framework/python/bin/python3
import json
import sys
import os
import re
import logging
from datetime import datetime

LOG_FILE = '/var/ossec/logs/integrations.log'
logging.basicConfig(
    filename=LOG_FILE,
    level=logging.INFO,
    format='%(asctime)s | TheHive-Integration | %(levelname)s | %(message)s'
)

def get_severity(level):
    level = int(level)
    if level >= 14: return 4
    elif level >= 10: return 3
    elif level >= 7: return 2
    else: return 1

def get_tlp(level):
    level = int(level)
    if level >= 14: return 3
    elif level >= 10: return 2
    else: return 1

def create_thehive_alert(alert_data, thehive_url, thehive_api_key):
    try:
        from thehive4py.api import TheHiveApi
        from thehive4py.models import Alert, AlertArtifact
    except ImportError:
        logging.error("thehive4py not installed!")
        return

    try:
        api = TheHiveApi(thehive_url, thehive_api_key)
        rule = alert_data.get('rule', {})
        agent = alert_data.get('agent', {})
        data = alert_data.get('data', {})
        location = alert_data.get('location', '')
        full_log = alert_data.get('full_log', '')
        timestamp = alert_data.get('timestamp', datetime.now().isoformat())
        rule_id = rule.get('id', '0')
        rule_level = rule.get('level', '0')
        rule_description = rule.get('description', 'Wazuh Alert')
        rule_groups = rule.get('groups', [])
        agent_name = agent.get('name', 'unknown')
        agent_id = agent.get('id', '000')
        srcip = data.get('srcip', '')

        alert_type = 'wazuh-alert'
        if 'ddos' in rule_groups or 'soar' in rule_groups: alert_type = 'soar-ddos'
        elif 'brute_force' in rule_groups: alert_type = 'brute-force'
        elif 'web' in rule_groups: alert_type = 'web-attack'
        elif 'syscheck' in rule_groups: alert_type = 'file-integrity'

        tags = ['wazuh', f'rule-{rule_id}', f'level-{rule_level}', f'agent-{agent_name}']
        for group in rule_groups: tags.append(group)

        description = f"""## Wazuh Alert Details
**Rule ID:** {rule_id}
**Rule Level:** {rule_level}
**Rule Description:** {rule_description}
**Groups:** {', '.join(rule_groups)}

### Agent Info
- **Agent Name:** {agent_name}
- **Agent ID:** {agent_id}

### Source Info
- **Source IP:** {srcip if srcip else 'N/A'}
- **Location:** {location}

### Full Log
```
{full_log}
```

### Raw Alert Data
```json
{json.dumps(alert_data, indent=2, default=str)}
```"""

        artifacts = []
        if srcip:
            artifacts.append(AlertArtifact(dataType='ip', data=srcip, message=f'Source IP Rule {rule_id}', tags=['wazuh']))

        alert_id = alert_data.get('id', '')
        source_ref = re.sub(r'[^a-zA-Z0-9\-_]', '_', f"wazuh-{rule_id}-{alert_id}-{timestamp}")[:64]

        thehive_alert = Alert(
            title=f"[Wazuh] {rule_description}",
            tlp=get_tlp(rule_level),
            severity=get_severity(rule_level),
            tags=tags,
            description=description,
            type=alert_type,
            source='Wazuh-SIEM',
            sourceRef=source_ref,
            artifacts=artifacts
        )

        response = api.create_alert(thehive_alert)
        if response.status_code == 201:
            logging.info(f"Alert dibuat: Rule {rule_id} - {rule_description}")
        else:
            logging.error(f"Gagal: HTTP {response.status_code} - {response.text}")

    except Exception as e:
        logging.error(f"Error: {str(e)}")

def main():
    if len(sys.argv) < 4:
        logging.error(f"Argumen kurang: {len(sys.argv)}")
        sys.exit(1)
    try:
        with open(sys.argv[1], 'r') as f:
            alert_json = json.load(f)
    except Exception as e:
        logging.error(f"Gagal baca alert: {str(e)}")
        sys.exit(1)
    create_thehive_alert(alert_json, sys.argv[3], sys.argv[2])

if __name__ == "__main__":
    main()
EOF

# Tulis wrapper script ke /var/ossec/integrations/custom-w2thive
cat << 'EOF' > /var/ossec/integrations/custom-w2thive
#!/bin/sh
WPYTHON_BIN="/var/ossec/framework/python/bin/python3"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
SCRIPT_PATH="${SCRIPT_DIR}/custom-w2thive.py"
if [ ! -f "${WPYTHON_BIN}" ]; then
    echo "$(date) | TheHive | ERROR | Python not found" >> /var/ossec/logs/integrations.log
    exit 1
fi
${WPYTHON_BIN} ${SCRIPT_PATH} "$@"
EOF

# Set permissions (WAJIB!)
chmod 755 /var/ossec/integrations/custom-w2thive.py
chmod 755 /var/ossec/integrations/custom-w2thive
chown root:wazuh /var/ossec/integrations/custom-w2thive.py
chown root:wazuh /var/ossec/integrations/custom-w2thive
```

---

## Step 6: Tambahkan Integrasi TheHive ke ossec.conf

```bash
nano /var/ossec/etc/ossec.conf
```

Tambahkan blok berikut **sebelum** tag `</ossec_config>`:

```xml
  <!-- ============================================================ -->
  <!-- THEHIVE INTEGRATION — Incident Response & Case Management    -->
  <!--                                                              -->
  <!-- Setiap alert Wazuh level >= 10 otomatis dikirim ke TheHive   -->
  <!-- sebagai Alert yang bisa di-convert menjadi Case              -->
  <!-- ============================================================ -->
  <integration>
    <name>custom-w2thive</name>
    <hook_url>http://127.0.0.1:9000</hook_url>
    <api_key>PASTE_API_KEY_DARI_STEP_4_DISINI</api_key>
    <level>10</level>
    <alert_format>json</alert_format>
  </integration>
```

> **PENTING:** Ganti `PASTE_API_KEY_DARI_STEP_4_DISINI` dengan API Key yang sudah dicopy di Step 4!

---

## Step 7: Restart Wazuh Manager

```bash
# Test konfigurasi
/var/ossec/bin/wazuh-analysisd -t

# Restart
systemctl restart wazuh-manager

# Cek status
systemctl status wazuh-manager
```

---

## Step 8: Validasi Integrasi

### Cek Log Integrasi
```bash
# Pantau log integrasi real-time
tail -f /var/ossec/logs/integrations.log
```

### Trigger Alert untuk Test
Dari laptop agent, jalankan simulasi DDoS:
```bash
sudo bash scripts/attack-ddos.sh
```

### Cek di TheHive
1. Buka `http://70.153.19.42:9000`
2. Login → klik **Alerts** di sidebar
3. Seharusnya ada alert baru dari Wazuh dengan judul seperti:
   - `[SOAR-DDoS] SYN Flood terdeteksi`
   - `[SOAR-DDoS] CRITICAL: Massive DDoS Attack`
4. Klik alert → **Merge into Case** untuk mulai investigasi

---

## Troubleshooting

### TheHive tidak bisa diakses?
```bash
# Cek container running
docker ps | grep thehive

# Cek logs
cd /opt/thehive/docker
docker compose logs --tail=50

# Restart container
docker compose restart
```

### Alert tidak muncul di TheHive?
```bash
# Cek log integrasi Wazuh
tail -50 /var/ossec/logs/integrations.log

# Cek apakah script bisa dijalankan manual
echo '{"rule":{"description":"Test","level":"10"},"id":"12345"}' > /tmp/test-alert.json
/var/ossec/integrations/custom-w2thive /tmp/test-alert.json YOUR_API_KEY http://127.0.0.1:9000

# Cek koneksi ke TheHive
curl -H "Authorization: Bearer YOUR_API_KEY" http://127.0.0.1:9000/api/v1/alert?range=0-5
```

### TheHive kehabisan memory?
```bash
# Cek penggunaan memory
free -h
docker stats --no-stream

# Jika RAM penuh, kurangi memory Elasticsearch
# Edit docker-compose.yml → services → elasticsearch → environment
# Tambah: ES_JAVA_OPTS=-Xms512m -Xmx512m
```
