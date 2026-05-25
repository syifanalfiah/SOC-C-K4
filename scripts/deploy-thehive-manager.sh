#!/bin/bash
# ================================================================
# DEPLOY THEHIVE + INTEGRASI WAZUH ke Manager VPS
# ================================================================
# Cara pakai:
#   1. SSH ke server:  ssh wazuh-manager@70.153.19.42
#   2. sudo su
#   3. Copy-paste SEMUA isi file ini ke terminal
#   4. Ikuti instruksi di layar
# ================================================================

echo "================================================="
echo "  DEPLOY THEHIVE 5 + WAZUH INTEGRATION"
echo "  $(date)"
echo "================================================="
echo ""

# ============================================================
# STEP 1: Install Docker (jika belum ada)
# ============================================================
echo "[1/7] Cek & Install Docker..."
if command -v docker &>/dev/null; then
    echo "  [SKIP] Docker sudah terinstall: $(docker --version)"
else
    echo "  Installing Docker..."
    curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
    sh /tmp/get-docker.sh
    echo "  [DONE] Docker terinstall"
fi

# Install Docker Compose plugin & jq
apt-get install -y docker-compose-plugin jq -qq 2>/dev/null
echo "  Docker Compose: $(docker compose version 2>/dev/null || echo 'not found')"
echo ""

# ============================================================
# STEP 2: Install TheHive 5 via Docker
# ============================================================
echo "[2/7] Setup TheHive 5..."
mkdir -p /opt/thehive
cd /opt/thehive

if [ -d "docker" ]; then
    echo "  [SKIP] TheHive docker directory sudah ada"
else
    git clone https://github.com/StrangeBeeCorp/docker.git
    echo "  [DONE] Repo StrangeBee cloned"
fi

cd docker
echo "  Menjalankan init script..."
./init.sh

echo "  Starting TheHive containers..."
docker compose up -d

# Tunggu TheHive siap
echo "  Menunggu TheHive startup (30 detik)..."
sleep 30

# Cek status
if docker ps | grep -q thehive; then
    echo "  [DONE] TheHive RUNNING di port 9000"
else
    echo "  [WARNING] TheHive mungkin belum siap. Cek: docker ps"
fi
echo ""

# ============================================================
# STEP 3: Install thehive4py di Python Wazuh
# ============================================================
echo "[3/7] Install thehive4py library..."
/var/ossec/framework/python/bin/pip3 install thehive4py==1.8.1 2>/dev/null
echo "  [DONE] thehive4py terinstall"
echo ""

# ============================================================
# STEP 4: Upload script integrasi Wazuh → TheHive
# ============================================================
echo "[4/7] Upload integration scripts..."

cat > /var/ossec/integrations/custom-w2thive.py << 'PYTHON_EOF'
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
PYTHON_EOF

cat > /var/ossec/integrations/custom-w2thive << 'WRAPPER_EOF'
#!/bin/sh
WPYTHON_BIN="/var/ossec/framework/python/bin/python3"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
SCRIPT_PATH="${SCRIPT_DIR}/custom-w2thive.py"
if [ ! -f "${WPYTHON_BIN}" ]; then
    echo "$(date) | TheHive | ERROR | Python not found" >> /var/ossec/logs/integrations.log
    exit 1
fi
${WPYTHON_BIN} ${SCRIPT_PATH} "$@"
WRAPPER_EOF

chmod 755 /var/ossec/integrations/custom-w2thive.py
chmod 755 /var/ossec/integrations/custom-w2thive
chown root:wazuh /var/ossec/integrations/custom-w2thive.py
chown root:wazuh /var/ossec/integrations/custom-w2thive

echo "  [DONE] Integration scripts uploaded + permissions set"
echo ""

# ============================================================
# STEP 5: Prompt user untuk API Key
# ============================================================
echo "[5/7] Konfigurasi API Key TheHive..."
echo ""
echo "  ┌────────────────────────────────────────────────────────────┐"
echo "  │  AKSI MANUAL DIPERLUKAN:                                   │"
echo "  │                                                            │"
echo "  │  1. Buka browser: http://70.153.19.42:9000                │"
echo "  │  2. Login: admin@thehive.local / secret                   │"
echo "  │  3. Buka Admin → Users → klik user → Create API Key      │"
echo "  │  4. Copy API Key                                          │"
echo "  │                                                            │"
echo "  └────────────────────────────────────────────────────────────┘"
echo ""
echo -n "  Paste API Key TheHive disini (lalu tekan Enter): "
read THEHIVE_API_KEY

if [ -z "$THEHIVE_API_KEY" ]; then
    echo "  [WARNING] API Key kosong! Anda harus edit ossec.conf manual nanti."
    THEHIVE_API_KEY="YOUR_THEHIVE_API_KEY"
fi
echo ""

# ============================================================
# STEP 6: Tambahkan integrasi TheHive ke ossec.conf
# ============================================================
echo "[6/7] Tambahkan TheHive integration ke ossec.conf..."

if grep -q "custom-w2thive" /var/ossec/etc/ossec.conf; then
    echo "  [SKIP] TheHive integration sudah ada di ossec.conf"
else
    # Hapus </ossec_config> terakhir, tambah blok integrasi, lalu tutup kembali
    sed -i '/<\/ossec_config>/d' /var/ossec/etc/ossec.conf

    cat >> /var/ossec/etc/ossec.conf << THEHIVE_EOF

  <!-- ============================================================ -->
  <!-- THEHIVE INTEGRATION — Incident Response & Case Management    -->
  <!--                                                              -->
  <!-- Setiap alert Wazuh level >= 10 otomatis dikirim ke TheHive   -->
  <!-- sebagai Alert yang bisa di-convert menjadi Case              -->
  <!-- ============================================================ -->
  <integration>
    <name>custom-w2thive</name>
    <hook_url>http://127.0.0.1:9000</hook_url>
    <api_key>${THEHIVE_API_KEY}</api_key>
    <level>10</level>
    <alert_format>json</alert_format>
  </integration>

</ossec_config>
THEHIVE_EOF
    echo "  [DONE] TheHive integration ditambahkan ke ossec.conf"
fi
echo ""

# ============================================================
# STEP 7: Test & restart Wazuh Manager
# ============================================================
echo "[7/7] Test konfigurasi & restart Wazuh..."

echo "  Testing configuration..."
/var/ossec/bin/wazuh-analysisd -t
if [ $? -eq 0 ]; then
    echo "  Configuration OK. Restarting wazuh-manager..."
    systemctl restart wazuh-manager
    sleep 3
    if systemctl is-active --quiet wazuh-manager; then
        echo "  [DONE] Wazuh Manager running!"
    else
        echo "  [ERROR] Wazuh Manager gagal start!"
        systemctl status wazuh-manager
    fi
else
    echo "  [ERROR] Ada error di konfigurasi! Cek ossec.conf"
fi

echo ""
echo "================================================="
echo "  DEPLOY THEHIVE + INTEGRASI SELESAI!"
echo "================================================="
echo ""
echo "  TheHive Dashboard : http://70.153.19.42:9000"
echo "  Wazuh Dashboard   : https://70.153.19.42:443"
echo ""
echo "  Langkah selanjutnya:"
echo "  1. Login TheHive → ganti password default"
echo "  2. Jalankan simulasi DDoS dari laptop Agent"
echo "  3. Cek alert di TheHive → buat Case"
echo "================================================="
